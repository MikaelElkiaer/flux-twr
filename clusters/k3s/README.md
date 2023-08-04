# Bootstrapping rootless k3s on a fresh Arch install

```bash
# Install dependencies
sudo pacman -S --noconfirm curl fuse3

# Download k3s binary and make it executable
sudo curl -Lo /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.26.5+k3s1/k3s
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

# Add k3s config
cat <<EOF | sudo tee /etc/rancher/k3s/config.yaml
cluster-init: true
disable-helm-controller: true
disable: traefik
write-kubeconfig-mode: "0700"
EOF

# Reload configs and start service
systemctl daemon-reload
systemctl --user enable --now k3s-rootless.service

# Configure port forward rules and persist
sudo iptables -t nat -A PREROUTING -i enp3s0 -p tcp --dport 80 -j REDIRECT --to-port 10080
sudo iptables -t nat -A PREROUTING -i enp3s0 -p tcp --dport 443 -j REDIRECT --to-port 10443
sudo iptables-save -f /etc/iptables/iptables.rules
```

## Set up for home assistant

```bash
cat <<EOF | sudo tee /etc/udev/rules.d/99-perm.rules
SUBSYSTEM=="usb", ATTRS{serial}=="20221101110016", OWNER="me"
EOF
```
