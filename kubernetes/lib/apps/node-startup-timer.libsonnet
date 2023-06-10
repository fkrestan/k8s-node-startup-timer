local k = import 'k.libsonnet';
local u = import 'utils.libsonnet';

local container = k.core.v1.container;
local ns = k.core.v1.namespace;
local service = k.core.v1.service;
local sts = k.apps.v1.statefulSet;

{
  _images:: {
    pause: 'gcr.io/google-containers/pause:3.2',
  },
  _config:: {
    name: 'node-startup-timer',
    resources: {
      cpu: '10',
      memory: '20Gi',
    },
  },

  pauseContainer:: container.new('pause', $._images.pause) +
                   container.resources.withRequests($._config.resources) +
                   container.resources.withLimits($._config.resources),

  namespace: ns.new($._config.name),
  service: u.serviceFor($.statefulSet) +
           service.spec.withClusterIP('None'),
  statefulSet: sts.new($._config.name, 1, [$.pauseContainer]) +
               sts.spec.withServiceName($._config.name),

}
