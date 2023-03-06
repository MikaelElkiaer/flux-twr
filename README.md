# twr-flux

Bootstrap flux (or upgrade):

```bash
flux bootstrap github \
  --owner=MikaelElkiaer \
  --repository=twr-flux \
  --path=clusters/k3s \
  --personal
```

Reconcile after upgrade:

```bash
flux reconcile kustomization flux-system --with-source
```
