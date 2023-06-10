function(replicas)
  (import 'apps/node-startup-timer.libsonnet') + {
    _config+:: {
      resources: {
        cpu: '28',
        memory: '50Gi',
      },
    },
    statefulSet+: {
      spec+: {
        replicas: replicas,
      },
    },
  }
