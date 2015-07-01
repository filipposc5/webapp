#current_dir = File.dirname(__FILE__)
log_level                :info
log_location             STDOUT
node_name                'vagrant'
client_key               '/vagrant/knife/dummy2.pem'
validation_client_name   'chef-validator'
validation_key           '/vagrant/knife/dummy2.pem'
chef_server_url          'http://172.16.100.10:8889'
#syntax_check_cache_path  '/vagrant/knife2/syntax_check_cache'
cookbook_path [ '/vagrant/chef-repo/cookbooks' ]
