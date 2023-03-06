# twr-flux

Bootstrap flux (or upgrade):

```bash
flux bootstrap github \
  --components-extra=image-reflector-controller,image-automation-controller \
  --owner=MikaelElkiaer \
  --repository=twr-flux \
  --path=clusters/k3s \
  --personal
```

Reconcile after upgrade:

```bash
flux reconcile kustomization flux-system --with-source
```
