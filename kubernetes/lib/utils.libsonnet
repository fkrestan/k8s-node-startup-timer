local k = import 'k.libsonnet';

local container = k.core.v1.container;
local servicePort = k.core.v1.servicePort;
local service = k.core.v1.service;

{
  debug(expr, source=''):: (
    local hr = '\n============================== DEBUG ' + source + '==============================\n';
    std.trace(hr + std.manifestJsonEx(expr, '  ') + hr, expr)
  ),

  serviceFor(controller, nameFormat='%(port)s')::
    local ports = [
      servicePort.newNamed(
        name=(nameFormat % { container: c.name, port: port.name }),
        port=port.containerPort,
        targetPort=port.containerPort
      ) +
      if std.objectHas(port, 'protocol')
      then servicePort.withProtocol(port.protocol)
      else {}
      for c in controller.spec.template.spec.containers
      for port in (c + container.withPortsMixin([])).ports
    ];

    service.new(
      controller.metadata.name,
      controller.spec.selector.matchLabels,
      ports,
    ) +
    service.mixin.metadata.withLabels(
      std.get(controller.metadata, 'labels', default={})
    ),
}
