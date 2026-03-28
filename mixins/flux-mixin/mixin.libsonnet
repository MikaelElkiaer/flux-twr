local fluxMixin = import "github.com/fluxcd-community/flux-mixin/mixin.libsonnet";

local flux = fluxMixin {
  _config+:: {
  },
};

{
  "flux-alerts.json": {
    apiVersion: 'monitoring.coreos.com/v1',
    kind: 'PrometheusRule',
    metadata: {
      labels: {
        release: 'prom-stack',
      },
      name: 'flux-mixin-alerts',
    },
    spec: flux.prometheusAlerts,
  }
}
+
{
  // Iterate through all dashboards in the mixin
  [name]: {
    local nameWithoutExt = std.strReplace(name, '.json', ''),
    apiVersion: 'v1',
    kind: 'ConfigMap',
    metadata: {
      name: nameWithoutExt + '-dashboard',
      labels: {
        grafana_dashboard: '1',  // Label for the Grafana sidecar to find it
      },
    },
    data: {
      [name]: std.manifestJsonEx(flux.grafanaDashboards[name], '  '),
    },
  }
  for name in std.objectFields(flux.grafanaDashboards)
}
