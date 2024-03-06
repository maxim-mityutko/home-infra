read -pr 'Username: ' u
read -pr 'Group: ' g
# Only pods root is needed. Persistent volumes
# will be created automatically via `nfs-subdir`
sudo mkdir -p /mnt/master/k8s/pods/

sudo chown -R "$u":"$g" /mnt/master/k8s/pods
sudo chmod -R 777 /mnt/master/k8s/pods

# Downloads root for the `media` apps
sudo mkdir -p /mnt/spin/torrent/watch
sudo mkdir -p /mnt/spin/torrent/downloads

sudo chown -R "$u":"$g"  /mnt/spin/torrent
sudo chmod -R 777  /mnt/spin/torrent

# NVR
sudo mkdir -p /mnt/spin/nvr
# Backups
sudo mkdir -p /mnt/spin/borg