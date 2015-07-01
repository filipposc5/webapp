# Webapp with chef and vagrant

## 1. What's cool about this? (short description for the busy people)
------
  chef reusability in many scenarios (standalone/enterprise/lab etc)  
  app nodes can join after main is up, so dynamic setup (pending main node reprovision)  
  dynamic discovery and testing (with possibility to extend) for additional nodes  
  works on my box, hopefully works on your box, but tested and works in osx AND windows  
  recipe and app itself leverage features (virtualenv/git) for possible complex / multi-app scenarios  
  You ask for 2 nodes I give you 10, up to 100!  
  I did not pick a python solution (my python > my ruby) so that I am outside of my comfort zone   
  No blind copy pasting, no shortcuts   
  A lot of testing has gone into it (it may still not be perfect)   

## 2. Setup instructions
-------

####Requirements
- Chef/ChefDK/knife (latest) 
- Vagrant (latest)
- The above are about 200-300mbyte download (in case you are on 3G / 4G )
- Virtualbox (realistically it's already there!)

*Windows*: 
  Install vagrant (and virtual box if needed)
  Install Chef for Windows
  Git may be needed if messing with the recipes

*OSX*: 
  Install vagrant (and virtual box if needed)  
  use homebrew for chef:  
  ```
    # install chefdk    
    # https://blog.osgiliath.net/?p=508   
    brew install caskroom/cask/brew-cask   
    brew cask install chefdk   
  ```

*Linux*:
  might need caution in the chef/vagrant versions as some distros might be lagging behind 


*ALL OS*:
  install needed vagrant plugins: 
  ```
  vagrant plugin install vagrant-omnibus
  # not really used, but explored
  vagrant plugin install vagrant-triggers 
  ```
  (if caching needed vagrant-cachier is recommended as chef is a 40MByte dl)  

####Testing
  It has been tested on (and adjusted to work on both)  
   Windows 8.1 Pro with Chef 12.2.1 and Vagrant 1.7.2  
   Osx 10.9.5 with Chef from brew/cask as below and with Vagrant 1.7.2 from vagrant.com   
      Chef Development Kit Version: 0.6.2  
      chef-client version: 12.3.0  
      berks version: 3.2.4  
      kitchen version: 1.4.0  

## 3. Usage
### Bring up hosts  
```
vagrant status
vagrant up hello-main
vagrant up hello-node[1-10] 
```
eg to bring nodes 1-3 up:  
```
vagrant up hello-node1 hello-node2 hello-node3
```
### Update configs  
To update hello-main so that nodeX exists and gets added to load balancer you will need to reprovision with chef eg  
```
vagrant provision --provision-with chef_client hello-main
```
To retest use shell provisioner again. Eitherway both chef and shell should be idempotent  
*WARNING*: Sometimes it takes a while for node IP info to make it into chef-zero. This is why in 'main' node we run chef client once with empty list just to register itself.   

## 4. Assumptions
A maximum of 100 nodes with current Vagrantfile but we only 'pre-create' 10 of them. This is configurable via  
nodes = 10
Main node will be at 172.16.100.10  
Node X will be at 172.16.100.100+ X - so node1 : 172.16.100.101 (this is printed during node#1 shell provisioning as well)  
App is listening on port 3001 on every vm (both main and node)  
Nginx loadbalancer is listening at port 81 on main node  
Multiple up/down for hello-main node should only download the .deb file once  
The "app" will always reload from git, this is per-design  
Running knife as vagrant user from main node also uses the main node chef zero as url 

Average run time on fast machines is just under 270 seconds including downloads. (S3 speeds are terrible)
Updating nginx configs after more nodes have joined the party takes about 70 seconds 

## 5. While you wait .. 

Objectives behind technology choices  
* Refresh ruby / chef knowledge
* Use chef zero (not used before)
* Avoid using static JSONs 

Why chef zero? 
------
  can be used to emulate a real server or real environment, as well as a standalone instance eg just a chef solo / zero without server  
  ability to use node attributes in a DYNAMIC fashion such that subsequent chef provisions refresh nginx LB configuration  
  ability to further leverage node awareness in order to test against these nodes (eg knife node stuff in serverspec)  
  ability to port recipes, test everything locally and properly, create more persistent scenarios if needed  
  ability to edit/upload recipes and have an easy dev cycle   


Drawback
-----
  May have hit some swapping at 512MB ram at times!
  Hit issues specific to vagrant/chef across win/osx and issues around chef zero provisioning 

Current features
------
  Support for arbitrary nodes  
  Custom recipe for flask application that installs virtualenv, supervisord, service for supervisord with notifications for templates (chef-repo/hello-app/ ) and cloning from git   
  All the benefits from "Why Chef Zero" , multiple 'knife' envs to keep configuration as static or as dynamic as needed, eg a lot of the devops dev occurred on 'main' node so an easy dev environment as well  
  Ability to use vagrant triggers to be more automated, though personally it felt a bit like a hack so I avoided it in the end (and not as portable when it came to Windows but an avenue worth exploring at times)  
  Demonstration that json structures could have been used in case we wanted a simpler solution  


Improvements (if time was not a constraint)
-----
  I added a configuration parameter file for port to flask-hello app that could 've been using config template
  Additional networking eg make main node have a public interface or forwarded port, and/or firewall the public interface
  Better testing, I discovered the serverspec extra types that could test the web service a bit late into the game. Originally I was thinking of phantomjs or selenium or similar, but that might be overkill in the cloud where memory might be a scarce commodity. 
  A bit more structure in the config management, more use of "roles" etc, better base system config (eg ntp, hardening)
  A more uniform idea for the app eg reusability of names end to end etc
  Centralised logging
  Centralised testing (eg have a node register in a pool, and register what sort of tests they would run against it)
  What if recipes are a bit uniform, what if it would be possible to automate some of the testing via analysing config files? Ie if a skeleton is provided for say a Flask app which contains a port, you already know that you need to test if that port is listening.
  If Large scale deployment it might be worth creating a chef recipe to build a release, and then just release the final app on the end nodes. This way you only have to troubleshoot once (hopefully) 
  If very large scale deployment, provide own boxes and move the config management on the box build level. 


Appendix: Random thoughts and troubleshooting
 
Sometimes vagrant status takes a long time. This is because it is trying to resolve the configuration of 'chef omnibus version latest' to an actual value. 

If hosts arent getting deleted from chef-zero it means that 'knife' is not working on the vagrant host (outside of VMs). 

Inconsistent behaviours
Vagrant on windows runs chef zero on 127.0.0.1:8889 within the VM and maps cookbooks and such under /tmp while in OSX vagrant runs it outside of the VM. This was a bit of a problem because originally I used this method:
 I asked for a chef zero provision with an empty run list such that I delegate the Chef installation to Vagrant. The benefit is that by allowing vagrant to do the installation I can be sure that it will always happen in a similar fashion. Then after chef gets installed I bring up my own chef zero which I share amongst nodes. Admittedly it might be considered a bit of a hack but for a decent reason

 Sometimes apt might fail, rerunning provision fixes it. I have added a shell provisioner update which might solve this. Error follows: 

==> hello-node2: ---- Begin output of apt-get -q -y install python-pip=1.5.4-1ubuntu3 ----
==> hello-node2: STDOUT: Reading package lists...
==> hello-node2: Building dependency tree...
==> hello-node2: Reading state information...
==> hello-node2: Some packages could not be installed. This may mean that you have
==> hello-node2: requested an impossible situation or if you are using the unstable
==> hello-node2: distribution that some required packages have not yet been created
==> hello-node2: or been moved out of Incoming.
==> hello-node2: The following information may help to resolve the situation:
==> hello-node2:
==> hello-node2: The following packages have unmet dependencies:
==> hello-node2:  python-pip : Depends: python-pip-whl (= 1.5.4-1ubuntu3) but it is not going to be installed
==> hello-node2:               Recommends: python-dev-all (>= 2.6) but it is not installable
==> hello-node2:               Recommends: python-wheel but it is not installable
==> hello-node2: STDERR: E: Unable to correct problems, you have held broken packages.
==> hello-node2: ---- End output of apt-get -q -y install python-pip=1.5.4-1ubuntu3 ----
==> hello-node2: Ran apt-get -q -y install python-pip=1.5.4-1ubuntu3 returned 100




