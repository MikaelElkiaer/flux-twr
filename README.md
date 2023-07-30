# twr-flux

## Install latest flux components

This can also be used for upgrading or altering the installation.

```bash
flux install --components-extra=image-reflector-controller,image-automation-controller
```

## Add git source

This will output SSH public key to be added as 'Deploy key' to the GitHub repository.

```bash
flux create source git flux-system --branch=main --url=ssh://git@github.com/MikaelElkiaer/twr-flux
```

## Add kustomization

The root component to watch and apply source changes to cluster.

```bash
flux create kustomization flux-system --path="clusters/k3s" --source=flux-system --prune=true
```

## Triggering an update

If resources were pushed in between creating the git source and kustomization, it might be necessary to reconcile before the kustomization can be successfully created.
It can also be used at will, to avoid waiting for sync intervals.

```bash
flux reconcile kustomization flux-system --with-source
```
