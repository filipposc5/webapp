# -*- mode: ruby -*-
# vi: set ft=ruby :

APPNAME = "hello"
# define 10 nodes. acceptable values: 1-99
nodes = 10

# use hostname to apply a specific recipe otherwise apply default
chef_nodes = { 
  "default" => {
    :run_list => [ "apt::default", "base", "sudo", "hello-app" ], 
    # to fix error: "Parent directory /etc/supervisor.d does not exist."
    "supervisor" => {
      :dir => "/etc/supervisor/conf.d"
    },
    "app" => {
      :venv_root => "/opt/venv"
    },
    :authorization => { 
      :sudo => {
        "groups" => [ "vagrant", "admins", "wheel" ],
        "users" => [ "root", "vagrant" ],
        "passwordless" => true,
        # lifted from Ubuntu existing/live sudoers config
        "sudoers_defaults" => [ 
          'env_reset',
          'secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"',
          'mail_badpass'
        ]	
        # intentionally leaving sudoers.d out 
      }  
    } # end authorization block
  } # end default block
}

# we could have custom json per hostname but decided to just 
# override the run list when needed rather than re-keying everything
#  ,
#  "#{APPNAME}-main" => {
#    :run_list => [ ]
#  }
#}



# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"
  config.vm.box_version = "1.0.1"
  #config.vm.box_url = "https://vagrantcloud.com/puppetlabs/boxes/ubuntu-14.04-64-nocm"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  #config.vm.network "private_network", ip: "172.16.100.20"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
     vb.memory = 512
     vb.cpus = 2
  end

  # http://stackoverflow.com/questions/11325479/how-to-control-the-version-of-chef-that-vagrant-uses-to-provision-vms
  # creates requirement: vagrant plugin install vagrant-omnibus
  config.omnibus.chef_version = :latest
  #config.omnibus.installer_download_path = "/vagrant/cache"
  #config.omnibus.install_url = 'https://www.opscode.com/chef/install.sh'

  config.vm.define APPNAME + "-main" do |m|
    m.vm.hostname = "#{APPNAME}-main"
    m.vm.network "private_network", ip: "172.16.100.10"
    m.vm.provision "shell", inline: <<-SHELL
      echo '==='
      echo '============='
      echo Hostname: ${HOSTNAME}
      sed -i 's/..\.archive\./gb.archive\./g' /etc/apt/sources.list
      echo '============='
      echo '==='
      #apt-get update
      if [ ! -d /opt/chef/embedded ]; then 
        curl -L https://www.opscode.com/chef/install.sh -o install2.sh && sudo bash install2.sh -d /vagrant/cache 
      fi
    SHELL
    #m.vm.provision "chef_client" do |chef|
      #chef_base = File.dirname(File.expand_path(__FILE__))
      #chef.cookbooks_path = "chef-repo/cookbooks"
      #chef.roles_path = "chef-repo/roles"
      #chef.nodes_path = "chef-repo/nodes"
      #chef.delete_client = true
#      chef.json = {}
#      chef.add_recipe "apt::default"
#      chef.add_recipe "nginx"
#      if chef_nodes.has_key?(m.vm.hostname.to_s)
#        chef.run_list = chef_nodes[m.vm.hostname.to_s]['run_list']
#      else
#	puts " XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX Default provisioner"
#        chef.run_list = chef_nodes['default']['run_list']
#      end
    #end

    m.vm.provision "shell", inline: <<-SHELL
      # bring up a temporary chef-zero for the additional nodes to register their info in
      # for more dynamic results!
      
      printf ".\n..\n...C0\n..\n.\n"
      # check if this hasn't run before .. 
      if [ ! -d ~/.chef/ ]; then 
        /opt/chef/embedded/bin/chef-zero -H 172.16.100.10 -d --log-file /vagrant/main-chef-zero.log && \
        mkdir -m 775 -p ~/.chef/
        ln -sf /vagrant/knife/knife.rb  ~/.chef/knife.rb
        knife cookbook upload --all 
      fi
      pgrep -lf chef-zero || /opt/chef/embedded/bin/chef-zero -H 172.16.100.10 -d --log-file /vagrant/main-chef-zero.log
      echo main chef zero should be up by now

      # uncomment bellow if you want to always upload recipes (use while developing recipes)
      #knife cookbook upload --all 
    SHELL
     # provision with chef client now against our newly formed chef server
     # To install vagrant-triggers plugin, simply run :
     # "vagrant plugin install vagrant-triggers"
     
     #if Vagrant.has_plugin?("vagrant-triggers")
     #  m.trigger.before :destroy do
     #    run_remote "echo $HOSTNAME dying >> /vagrant/nodes.txt"
	 #run_remote "echo im dying here "
     #  end
     #end

    # run an empty run_list just to register the node the first time
    # This hopefully works around 'empty' upstream servers on 1st provision 
    # that can sometimes occur (encountered in OSX)
    m.vm.provision "chef_client" do |chef|
      #chef.installer_download_path = "/vagrant/cache"
      chef.chef_server_url = "http://172.16.100.10:8889"
      chef.validation_key_path = "knife/dummy2.pem"
      chef.delete_node = false
      chef.delete_client = false 
      chef.run_list = [ ]
    end
    
    # provision with chef client now against our newly formed chef server
    m.vm.provision "chef_client" do |chef|
      chef.installer_download_path = "/vagrant/cache"
      chef.chef_server_url = "http://172.16.100.10:8889"
      chef.validation_key_path = "knife/dummy2.pem"
      chef.json = chef_nodes['default']
      # override run list since this is the main node
      chef.run_list = [ "apt::default", "nginx", "hello-app", "loadbalancer" ]

      # If the main node is going no point to delete the node in current setup
      # When using an external chef server set the next 2 lines to true 
      chef.delete_node = false
      chef.delete_client = false 
      # we could have done it all a bit more dynamic 
      #      if chef_nodes.has_key?(m.vm.hostname.to_s) 
      #        chef.run_list = chef_nodes[m.vm.hostname.to_s]['run_list'] 
      #      else 
      #        chef.run_list = chef_nodes['default']['run_list']
      #      end
    end


    m.vm.provision "shell", inline: <<-SHELL
      # run some checks 
      echo XXXXXXXXXX
      echo XX running some checks / tests
      echo XXXXXXXXXX
      echo run visudo / nginx tests
      visudo -c
      /etc/init.d/nginx configtest
      echo XXXXXXXXXX
      echo run serverspec
      #cd /vagrant/serverspec && rake1.9.1
      cd /vagrant/serverspec && rspec
      echo -- '-=-'
      echo app output from curl main nginx 
      curl --connect-timeout 10 http://localhost:81/ 2> /dev/null
      tmpf=$(mktemp)
      echo "gathering app output through round robin load balancer (hits same url but should show different nodes)"
      for x in 0 $(seq -w 1 #{nodes}) ; do 
        # since config is round robin we could just be testing port 81 only
        # (curl --connect-timeout 10 http://172.16.100.1${x}:3001/; echo ) >> ${tmpf}  2> /dev/null
        (curl --connect-timeout 10 http://localhost:81/; echo ) >> ${tmpf}  2> /dev/null
      done
      echo XXXXXXXXXX
      echo "X   Nodes up:" $(cut -d/ -f3- ${tmpf} | sort -u )
      echo XXXXXXXXXX
      echo xx
      echo "X curl output can be examined from main node's fs under ${tmpf}"

    SHELL
  end
  # ----- main node finishes here ------------

  #               * * * 

  # ----- backend nodes start here ----------- 
  (1..nodes).each do |i|
    config.vm.define "#{APPNAME}-node#{i}", autostart: false do |n|
      n.vm.hostname = "#{APPNAME}-node#{i}"
      # not sure how this should be set but might be nice to autostart only 
      # some nodes to begin with  something like.. 
      #      if i <= autostart
      #        n.autostart = true
      #      end

      # all nodes start at 172.16.100.101, max 99 nodes..
      n.vm.network "private_network", ip: "172.16.100.1" + i.to_s.rjust(2,'0')
      n.vm.provision "shell",
        inline: "echo hello from node #{i} "
      n.vm.provision "chef_client" do |chef|
        chef.chef_server_url = "http://172.16.100.10:8889"
        chef.validation_key_path = "knife/dummy2.pem"
        chef.installer_download_path = "/vagrant/cache"
        # if a host exists in chef_nodes use it , otherwise load the default 
        if chef_nodes.has_key?(n.vm.hostname.to_s)
	      chef.json = chef_nodes[n.vm.hostname.to_s]
          #chef.run_list = chef_nodes[n.vm.hostname.to_s]['run_list']
        else
          chef.json = chef_nodes['default']
        end
        # for best results, delete the nodes when running on client
        chef.delete_node = true
        chef.delete_client = true
      end
    end
  end

  config.vm.provision "shell", inline: <<-SHELL
    echo ${HOSTNAME}
    sed -i 's/..\.archive\./gb.archive\./g' /etc/apt/sources.list
    apt-get update
    cd ~
  SHELL
  #
  # View the documentation for the provider you are using for more
  # information on available options.


  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  # config.vm.provision "shell", inline: <<-SHELL
  #   sudo apt-get update
  #   sudo apt-get install -y apache2
  # SHELL
end
