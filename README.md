# FluxCD for home server

These are the instructions for setting up a new Kubernetes cluster and bootstrapping FluxCD.
It is based on a minimal Debian linux installation.

## Set up OS

```bash
# Automatic package upgrades and reboot
sudo apt install --yes unattended-upgrades

# SSH access
sudo apt install --yes ssh
sudo systemctl enable --now ssh

# System clock sync
sudo apt install systemd-timesyncd
sudo timedatectl set-ntp true

# Automatic spinning down of disks
sudo apt install hd-idle
sudo systemctl enable --now hd-idle
```

## Bootstrap rootless k3s

```bash
# Install system dependencies
sudo apt install --yes fuse3 slirp4netns uidmap

# Download k3s binary and make it executable
sudo curl -Lo /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.30.0+k3s1/k3s
sudo chmod a+x /usr/local/bin/k3s

# Create rootless service for local user
mkdir -p ~/.config/systemd/user
curl https://raw.githubusercontent.com/k3s-io/k3s/master/k3s-rootless.service > ~/.config/systemd/user/k3s-rootless.service

# Add delegate service to allow users resource permissions
sudo mkdir -p /etc/systemd/system/user@.service.d
cat <<EOF | sudo tee /etc/systemd/system/user@.service.d/delegate.conf
[Service]
Delegate=cpu cpuset io memory pids
EOF

# Reboot after this step

# Add k3s config
cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
cluster-init: true
disable-helm-controller: true
disable:
  - traefik
write-kubeconfig-mode: "0600"
EOF

# Reload configs and start service
systemctl daemon-reload
systemctl --user enable --now k3s-rootless.service

# Allow service start on host startup
# - otherwise service will start/stop with user login/logout
sudo loginctl enable-linger "$(whoami)"

# Configure port forward rules and persist
# - rootless k3s will offset privileged ports (below 1024) by 10000
# - these rules will allow use of the privileged ports, redirected to the offset equivalents

# nftables
sudo apt install --yes nftables
cat <<EOF | sudo tee --append /etc/nftables.conf
table ip nat {
        chain prerouting {
                type nat hook prerouting priority dstnat; policy accept;
                iifname "enp3s0" tcp dport 80 redirect to :10080
                iifname "enp3s0" tcp dport 443 redirect to :10443
        }
}
EOF
sudo systemctl enable --now nftables

# Enable ip forwarding
# - in theory, this should allow resolving of source IP for proxied requests
# - in practice, still not able to do this
cat <<EOF | sudo tee /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
EOF
sudo sysctl --system
```

## Set-up for home automation

```bash
# Give user ownership of Zigbee USB dongle
cat <<EOF | sudo tee /etc/udev/rules.d/99-perm.rules
SUBSYSTEMS=="usb", KERNEL=="ttyACM*", ATTRS{serial}=="20221101110016", OWNER="$(whoami)"
EOF
sudo udevadm control --reload
# A possible alternative
sudo usermod -aG dialout "$(whoami)"
```

## Bootstrap FluxCD

```bash
# Restore sealed secret token
kubectl apply --file sealed-secrets-token.yaml
```

```bash
# Install flux base controllers and extra controller components
# - this can also be used for upgrading or altering the installation
# This will output SSH public key to be added as 'Deploy key' to the GitHub repository
flux bootstrap git --url=ssh://git@github.com/mikaelelkiaer/flux-twr.git --branch=main --path=./bootstrap --components-extra=image-reflector-controller,image-automation-controller
```
