require 'spec_helper'

# supervisord nginx ruby .. and so on .. 
%w[ supervisor nginx ruby  ].each do |pkg| 
  describe package(pkg) do
    it { should be_installed }
  end
end

# could do as above ... 
describe service('nginx') do
  it { should be_enabled }
  it { should be_running }
end

describe port(81) do
  it { should be_listening }
end

# test for 10 nodes?
 
 knifenodes = `cd /vagrant/knife && knife exec -E 'nodes.all {|n| puts "\#{n.name} " << n["network"]["interfaces"]["eth1"]["addresses"].select{  |address, data| data["family"] == "inet"  }.to_a[0][0].to_s       }'`
 
##   puts "#{ENV['TARGET_HOST']}"
puts "List of nodes from chef"
knifenodes.each_line do |line|
  puts "#{line}"
##   x = line.split() 
##   puts "#{x[1]}"
## 
## # this works but it's a hack .. and produces ugly output
## # to be fixed..
## #  ENV['TARGET_HOST'] = x[1]
## #  describe http_get(3001, 'hello-main', '/') do 
## #      its(:status) { should eq 200 } 
## #  end 
end
puts "End of List"
puts " "
puts "main host:"
## 
