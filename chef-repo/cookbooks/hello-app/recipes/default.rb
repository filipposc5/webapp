#
# Cookbook Name:: hello-app
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# based on
# https://github.com/jbergantine/chef-cookbook-flaskproj/blob/master/recipes/default.rb

#require_recipe "python"


node.default['app']['venv_root'] = '/opt/venv'
node.default['app']['subdir'] = 'app'
# haven't fully utilised the port one but it could be specified in 
# config.json and templated .. 
node.default['app']['port'] = 3001 
node.default['app']['repo'] = 'https://github.com/filipposc5/flask-hello'

APP_PATH = node['app']['venv_root']
APP_FULL_PATH = "#{APP_PATH}/#{node['app']['subdir']}"

%w[ supervisor python-pip python-virtualenv git ruby ruby-dev ].each do |pkg|
  apt_package pkg do
    action :install
  end
end 

directory APP_PATH do 
  owner 'vagrant'
  group 'www-data'
  mode '0775'
  action :create
end

python_virtualenv "#{APP_FULL_PATH}" do
  interpreter "python2.7"
  owner "vagrant"
  action :create
  not_if "test -d #{APP_FULL_PATH}/bin"
end


bash "install modules for project" do
  user "vagrant"
  code <<-EOH
    source #{APP_FULL_PATH}/bin/activate
    # could have been using requirements.txt
    pip install Flask gunicorn
  EOH
  not_if "test -d #{APP_FULL_PATH}/lib/python2.7/site-packages/flask"
end


# Ruby gems
gems = Array.new

gems |= %w/
  serverspec
  serverspec-extended-types
/


# install gems systemwide 
# funnily enough without "ruby" this didn't throw an error??
gems.each do |gem|
  gem_package gem do
    action :install
  end
end

# this runs after check out completes
bash "from git to live" do
  user "vagrant"
  code <<-EOH
  mv "#{APP_FULL_PATH}/co/"* "#{APP_FULL_PATH}"
  # this rm -rf could be commented out if we dont want to update every time 
  # or we can add a not_if to check the 'HEAD' eg
  # 
  cd "#{APP_FULL_PATH}" && rm -rf co 
  EOH
  action :nothing
  notifies :restart, 'supervisor_service[hello-app]', :delayed
end

supervisor_service "hello-app" do
  action [ :enable ]
  #action [ :enable, :start ]
  command "#{APP_FULL_PATH}/bin/python #{APP_FULL_PATH}/FlaskWebServer.py"
  user "vagrant"
  autostart true
  autorestart true
  startsecs 5
  stdout_logfile "#{APP_FULL_PATH}/flask.stdout.log"
  redirect_stderr true
end

# check out temporarily into 'co' dir
git "#{APP_FULL_PATH}/co" do 
  user "vagrant"
  repository "#{node['app']['repo']}"
  reference "master"
  action :sync
  # trigger 'mv' to live, and restart the service (though in theory 
  # Flask reloads the changed files automatically)
  notifies :run, 'bash[from git to live]', :immediate
end

#template '#{APP_FULL_PATH}/config.json'
#
#  source '...'
#  variables({
#    :dontworry => "about it"
#  })
#  notifies :restart, ...
##end



