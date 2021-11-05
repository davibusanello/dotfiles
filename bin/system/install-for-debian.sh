#!/usr/bin/env bash
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
# System requirements
sudo apt install -y git gpg gnupg2 apt-transport-https unzip wget curl
#  Toolchain
wget 'https://bintray.com/user/downloadSubjectPublicKey?username=bintray' -q -O- | sudo apt-key add -
sudo echo "deb [arch=amd64] https://dl.bintray.com/bvaisvil/debian stable main" >/etc/apt/sources.list.d/zenith.list
sudo apt update
sudo apt install -y tree direnv fzf ripgrep bat nmap htop zenith speedtest
# Development
sudo apt install -y vim neovim
sudo apt install -y build-essential make pkg-config libssl-dev cmake libpq-dev \
    postgresql-client libncurses5-dev zlib1g-dev libbz2-dev libreadline-dev \
    libsqlite3-dev libsqlite3-dev llvm libncurses5-dev xz-utils \
    tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev libssh-4 m4
# Ruby
sudo apt install -y imagemagick libmagickwand-dev shellcheck hunspell
# Python
sudo apt install -y python3-dev python3-pip

# Tools from git
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.8.0
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
git clone https://github.com/pyenv/pyenv-virtualenv.git $(pyenv root)/plugins/pyenv-virtualenv
