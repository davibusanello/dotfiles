echo 'Increasing the amount of inotify watchers'
#Debian / RedHat...
#echo fs.inotify.max_user_watches=524288 | sudo tee -a /etc/sysctl.conf && sudo sysctl -p
#Arch/Manjaro
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf && sudo sysctl --system

# After docker installation
echo 'Setting up Docker user group & service'
sudo groupadd docker
sudo usermod -aG docker $USER
sudo systemctl enable docker
sudo systemctl start docker

echo 'Done! :D'