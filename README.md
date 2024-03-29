# FluxCD for home server

These are the instructions for setting up a new Kubernetes cluster and bootstrapping FluxCD.
It is based on a minimal Arch linux installation.

## Bootstrap rootless k3s

```bash
# Install system dependencies
sudo pacman -S --noconfirm curl fuse3

# Download k3s binary and make it executable
sudo curl -Lo /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.28.2+k3s1/k3s
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
disable:
  - traefik
write-kubeconfig-mode: "0700"
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
cat <<EOF | sudo tee /etc/iptables/iptables.rules
*nat
-A PREROUTING -i enp3s0 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 10080
-A PREROUTING -i enp3s0 -p tcp -m tcp --dport 443 -j REDIRECT --to-ports 10443
COMMIT
EOF
sudo systemctl enable --now iptables

# Enable ip forwarding
# - in theory, this should allow resolving of source IP for proxied requests
# - in practice, still not able to do this
cat <<EOF | sudo tee /etc/sysctl.conf
net.ipv4.ip_forward=1
net.ipv4.ip_unprivileged_port_start = 80
net.ipv6.conf.all.forwarding=1
EOF
```

## Set up for home assistant

```bash
# Give user ownership of Zigbee USB dongle
cat <<EOF | sudo tee /etc/udev/rules.d/99-perm.rules
SUBSYSTEMS=="usb", KERNEL=="ttyACM*", ATTRS{serial}=="20221101110016", OWNER="me"
EOF
```

## Bootstrap FluxCD

```bash
# Install flux base controllers and extra controller components
# - this can also be used for upgrading or altering the installation
flux install --components-extra=image-reflector-controller,image-automation-controller

# This will output SSH public key to be added as 'Deploy key' to the GitHub repository
flux create source git flux-system --branch=main --url=ssh://git@github.com/mikaelelkiaer/twr-flux

# The root component to watch and apply source changes to cluster
flux create kustomization flux-system --path="flux-system" --source=flux-system --prune=true

# If resources were pushed in between creating the git source and kustomization
# - it might be necessary to reconcile before the kustomization can be successfully created
# - it can also be used at will, to avoid waiting for sync intervals
flux reconcile kustomization flux-system --with-source
```
