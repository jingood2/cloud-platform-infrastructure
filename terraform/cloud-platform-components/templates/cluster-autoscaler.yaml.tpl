replicaCount: 1
rbac:
  create: true

sslCertPath: /etc/ssl/certs/ca-bundle.crt

cloudProvider: aws
awsRegion: eu-west-2

autoDiscovery:
  clusterName: ${cluster_name}
  enabled: true
  tags:
  - k8s.io/cluster-autoscaler/enabled
  - k8s.io/cluster/${cluster_name}.cloud-platform.service.justice.gov.uk
  - k8s.io/role/node

podAnnotations:
  iam.amazonaws.com/role: ${iam_role}

serviceMonitor:
  enabled: true
  interval: "10s"
   # Namespace Prometheus is installed in
  namespace: monitoring
   ## Defaults to whats used if you follow CoreOS [Prometheus Install Instructions](https://github.com/helm/charts/tree/master/stable/prometheus-operator#tldr)
   ## [Prometheus Selector Label](https://github.com/helm/charts/tree/master/stable/prometheus-operator#prometheus-operator-1)
   ## [Kube Prometheus Selector Label](https://github.com/helm/charts/tree/master/stable/prometheus-operator#exporters)
  selector:
    prometheus: kube-prometheus

extraArgs:
  v: 4
  stderrthreshold: info
  logtostderr: true