# add Chris Lea's launchpad repo
sudo apt-get update -y
sudo apt-get install -y python-software-properties
sudo apt-add-repository -y ppa:chris-lea/node.js
sudo apt-get update -y

# install nodejs
sudo apt-get install -y nodejs

# symlink nodejs for compatibility with scripts that use #!/usr/bin/env node.
sudo ln -s `which nodejs` /usr/local/bin/node

# install other stuff
sudo apt-get install -y git
sudo apt-get install -y ruby
sudo apt-get install -y make
sudo apt-get install -y ruby1.9.1-dev
sudo gem install jsduck

# install global packages
sudo npm install -g bower
sudo npm install -g grunt-cli
sudo npm install -g coffee-script
sudo npm install -g mocha

# install local packages
cd /vagrant
# npm install