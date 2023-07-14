# twr-flux

# Install latest flux components
# - also used for upgrading or altering installation
flux install --components-extra=image-reflector-controller,image-automation-controller

# Add git source - will output SSH public key to be added as Deploy key
flux create source git flux-system --branch=main --url=ssh://git@github.com/MikaelElkiaer/twr-flux

# Add kustomization - root component to watch and apply source changes to cluster
flux create kustomization flux-system --path="clusters/k3s" --source=flux-system --prune=true

# If resources were pushed in between creating the git source and kustomization
# it might be necessary to reconcile before the kustomization can be successfully created
flux reconcile source git flux-system
