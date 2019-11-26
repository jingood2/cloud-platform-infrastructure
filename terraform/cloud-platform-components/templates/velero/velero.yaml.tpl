##
## Configuration settings that directly affect the Velero deployment YAML.
##

# Details of the container image to use in the Velero deployment & daemonset (if
# enabling restic). Required.
image:
  repository: gcr.io/heptio-images/velero
  tag: v1.1.0
#  tag: master
  pullPolicy: IfNotPresent

# Annotations to add to the Velero deployment's pod template. Optional.
#
# If using kube2iam or kiam, use the following annotation with your AWS_ACCOUNT_ID
# and VELERO_ROLE_NAME filled in:
#  iam.amazonaws.com/role: arn:aws:iam::<AWS_ACCOUNT_ID>:role/<VELERO_ROLE_NAME>
podAnnotations: {}

# Resource requests/limits to specify for the Velero deployment. Optional.
resources: {}

# Init containers to add to the Velero deployment's pod spec. Optional.
initContainers: []
  # - name:
  #   image:
  #   volumeMounts:
  #     - name: plugins
  #       mountPath: /target

# Tolerations to use for the Velero deployment. Optional.
tolerations: []

# Node selector to use for the Velero deployment. Optional.
nodeSelector: {}

# Settings for Velero's prometheus metrics. Disabled by default.
metrics:
  enabled: true
  scrapeInterval: 30s

  # Pod annotations for Prometheus
  podAnnotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8085"
    prometheus.io/path: "/metrics"

  serviceMonitor:
    enabled: true
    additionalLabels: {}

##
## End of deployment-related settings.
##


##
## Parameters for the `default` BackupStorageLocation and VolumeSnapshotLocation,
## and additional server settings.
##
configuration:
  # Cloud provider being used (e.g. aws, azure, gcp).
  provider: aws

  # Parameters for the `default` BackupStorageLocation. See
  # https://velero.io/docs/v1.0.0/api-types/backupstoragelocation/
  backupStorageLocation:
    # Cloud provider where backups should be stored. Usually should
    # match `configuration.provider`. Required.
    name: aws
    # Bucket to store backups in. Required.
    bucket: cloud-platform-velero-bucket-test
    # Prefix within bucket under which to store backups. Optional.
    prefix:
    # Additional provider-specific configuration. See link above
    # for details of required/optional fields for your provider.
    config:
      region: eu-west-2
    #  s3ForcePathStyle:
    #  s3Url:
    #  kmsKeyId:
    #  resourceGroup:
    #  storageAccount:
    #  publicUrl:

  # Parameters for the `default` VolumeSnapshotLocation. See
  # https://velero.io/docs/v1.0.0/api-types/volumesnapshotlocation/
  volumeSnapshotLocation:
    # Cloud provider where volume snapshots are being taken. Usually
    # should match `configuration.provider`. Required.,
    name: aws
    # Additional provider-specific configuration. See link above
    # for details of required/optional fields for your provider.
    config:
      region: eu-west-2
  #    apitimeout:
  #    resourceGroup:
  #    snapshotLocation:
  #    project:

  # These are server-level settings passed as CLI flags to the `velero server` command. Velero
  # uses default values if they're not passed in, so they only need to be explicitly specified
  # here if using a non-default value. The `velero server` default values are shown in the
  # comments below.
  # --------------------
  # `velero server` default: 1m
  backupSyncPeriod:
  # `velero server` default: 1h
  resticTimeout:
  # `velero server` default: namespaces,persistentvolumes,persistentvolumeclaims,secrets,configmaps,serviceaccounts,limitranges,pods
  restoreResourcePriorities:
  # `velero server` default: false
  restoreOnlyMode:

  # additional key/value pairs to be used as environment variables such as "AWS_CLUSTER_NAME: 'yourcluster.domain.tld'"
  extraEnvVars: {}

##
## End of backup/snapshot location settings.
##


##
## Settings for additional Velero resources.
##

# Whether to create the Velero cluster role binding.
rbac:
  create: true

# Information about the Kubernetes service account Velero uses.
serviceAccount:
  server:
    create: true
    name:

# Info about the secret to be used by the Velero deployment, which
# should contain credentials for the cloud provider IAM account you've
# set up for Velero.
credentials:
  # Whether a secret should be used as the source of IAM account
  # credentials. Set to false if, for example, using kube2iam or
  # kiam to provide IAM credentials for the Velero pod.
  useSecret: false
  # Name of a pre-existing secret (if any) in the Velero namespace
  # that should be used to get IAM account credentials. Optional.
  existingSecret:
  # Data to be stored in the Velero secret, if `useSecret` is
  # true and `existingSecret` is empty. This should be the contents
  # of your IAM credentials file.
  secretContents:
#    cloud: |
 #     [default]
# Wheter to create volumesnapshotlocation crd, if false => disable snapshot feature
snapshotsEnabled: true

# Whether to deploy the restic daemonset.
deployRestic: false

restic:
  podVolumePath: /var/lib/kubelet/pods
  privileged: false
  # Resource requests/limits to specify for the Restic daemonset deployment. Optional.
  resources: {}

# Backup schedules to create.
# Eg:
# schedules:
#   mybackup:
#     schedule: "0 0 * * *"
#     template:
#       ttl: "240h"
#       includedNamespaces:
#        - foo
schedules:
  allnamespacebackup:
    schedule: "0/30 * * * *"

# Velero ConfigMaps.
# Eg:
# configMaps:
#   restic-restore-action-config:
#     labels:
#       velero.io/plugin-config: ""
#       velero.io/restic: RestoreItemAction
#     data:
#       image: gcr.io/heptio-images/velero-restic-restore-help
configMaps: {}

##
## End of additional Velero resource settings.
##
