# k3s

## Rootless k3s (not working)

```bash
apt install curl
curl -Lo /usr/local/bin/k3s https://github.com/k3s-io/k3s/releases/download/v1.26.5+k3s1/k3s; chmod a+x /usr/local/bin/k3s
groupadd -g 1001 -r k3s
useradd -m -g 1001 -u 1001 k3s
wget https://raw.githubusercontent.com/k3s-io/k3s/release-1.26/k3s-rootless.service -O /etc/systemd/system/k3s-rootless.service
# Add Service.User=k3s 
systemctl enable --now k3s-rootless
```
