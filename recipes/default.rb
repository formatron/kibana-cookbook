version = node['formatron_kibana']['version']
checksum = node['formatron_kibana']['checksum']

cache = Chef::Config[:file_cache_path]
kibana_group = 'kibana'
kibana_user = 'kibana'
kibana_install_dir = '/opt/kibana'

group kibana_group do
  system true
end

user kibana_user do
  system true
  gid kibana_group
end

kibana_tar_gz = File.join cache, 'kibana.tar.gz' 
kibana_tar_gz_url = "https://download.elastic.co/kibana/kibana/kibana-#{version}-linux-x64.tar.gz"
kibana_linked_dir = "#{kibana_install_dir}-#{version}"

directory kibana_linked_dir do
  recursive true
end

remote_file kibana_tar_gz do
  source kibana_tar_gz_url
  checksum checksum
  notifies :run, 'bash[install_kibana]', :immediately
end

bash 'install_kibana' do
  code <<-EOH.gsub(/^ {4}/, '')
    tar zxf #{kibana_tar_gz} --strip-components=1
    chown -R #{kibana_user}:#{kibana_group} *
  EOH
  cwd kibana_linked_dir
  action :nothing
  notifies :create, "link[#{kibana_install_dir}]", :immediately
end

link kibana_install_dir do
  to kibana_linked_dir
  notifies :restart, 'service[kibana]', :delayed
end

template '/etc/init.d/kibana' do
  mode 0755
  source 'kibana_init.erb'
  variables(
    install_dir: kibana_install_dir
  )
  notifies :restart, 'service[kibana]', :delayed
end

template '/etc/default/kibana' do
  mode 0600
  source 'kibana_default.erb'
  variables(
    user: kibana_user
  )
  notifies :restart, 'service[kibana]', :delayed
end

service 'kibana' do
  supports status: true, restart: true, reload: false
  action [ :enable, :start ]
end
