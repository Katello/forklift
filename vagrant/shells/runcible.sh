#!/bin/bash -xe

sudo yum install -y -q ruby-devel rubygem-bundler libxml2-devel ruby rake gcc wget git nss
sudo yum install -y -q http://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
sudo yum install -y -q http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
sudo yum install -y -q puppet
sudo yum install -y -q https://fedorapeople.org/groups/katello/releases/yum/nightly/katello/el7/x86_64/katello-repos-latest.rpm
sudo yum update -y -q glib2

cd /etc/yum.repos.d
sudo wget https://repos.fedorapeople.org/repos/pulp/pulp/rhel-pulp.repo

sudo sh -c 'cat > ostree.repo <<EOL
[atomic7-testing]
name=atomic7-testing
baseurl=http://cbs.centos.org/repos/atomic7-testing/x86_64/os/
gpgcheck=0
enabled=1
EOL'

sudo yum install -y -q ostree

gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable --ruby

pushd /home/vagrant
gem install librarian-puppet
git clone https://github.com/katello/puppet-pulp.git

pushd puppet-pulp
cat > Puppetfile <<EOL
forge "https://forgeapi.puppetlabs.com"

metadata
EOL

librarian-puppet install

pushd modules
ln -s ../ pulp
popd
popd

cat > test.pp <<EOL
class { pulp:
  enable_rpm => true,
  enable_docker => true,
  enable_puppet => true,
  enable_python => true,
  enable_ostree => true
}
EOL

sudo puppet apply --modulepath=puppet-pulp/modules test.pp
sudo chmod 644 /etc/pulp/server.conf

git clone https://github.com/Katello/runcible.git

source ~/.bashrc

pushd runcible
source "$HOME/.rvm/scripts/rvm"
rvm gemset create runcible
rvm gemset use runcible

gem install bundler
bundle
rake test mode=all
popd
