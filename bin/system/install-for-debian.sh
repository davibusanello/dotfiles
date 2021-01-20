#!/usr/bin/env bash
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
# System requirements
sudo apt install -y git gpg gnupg2 apt-transport-https unzip
#  Toolchain
wget 'https://bintray.com/user/downloadSubjectPublicKey?username=bintray' -q -O- | sudo apt-key add -
sudo echo "deb [arch=amd64] https://dl.bintray.com/bvaisvil/debian stable main" > /etc/apt/sources.list.d/zenith.list
sudo apt update
sudo apt install -y tree direnv fzf ripgrep bat nmap htop zenith
# Development
sudo apt install -y vim neovim
sudo apt install -y build-essential pkg-config libssl-dev cmake libpq-dev postgresql-client
# Ruby
sudo apt install -y zlib1g-dev libreadline-dev imagemagick libmagickwand-dev shellcheck hunspell
