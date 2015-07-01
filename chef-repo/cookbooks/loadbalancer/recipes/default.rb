#
# Cookbook Name:: loadbalancer
# Recipe:: default
#
# Copyright 2015, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

require_recipe "nginx"

# http://serverfault.com/questions/412127/chef-recipe-read-attributes-from-another-node
upstream_servers = Array.new 

# we could specify a role as well .. but in our case doesn't really matter 
# search(:node, "interfaces:172.16.100.* AND role:backend_server") do |n|

search(:node, "interfaces:172.16.100.*") do |n|
  n["network"]["interfaces"]["eth1"]["addresses"].each_pair do |address,value|
    upstream_servers << address if value.has_key?("broadcast")
  end #if n["network"]["interfaces"]["eth1"]
end



bash "enable site" do
  code <<-EOH
  cd /etc/nginx/sites-enabled/ && \
  ln -sf ../sites-available/hello-app hello-app
  EOH
  action :nothing
  notifies :reload, resources(:service => "nginx") 
end


template '/etc/nginx/sites-available/hello-app' do
#template '/etc/nginx/sites-available/default' do
  source 'loadbalancer.conf.erb'
  variables({
    :upstream_servers => upstream_servers
  })
  notifies :run, 'bash[enable site]', :immediate
#  notifies :restart, resources(:service => "nginx")
end
