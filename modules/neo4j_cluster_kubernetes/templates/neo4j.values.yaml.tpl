# This file is merged with the defaults values.yaml file from the upstream Neo4J Helm chart here: https://github.com/neo4j/helm-charts/blob/dev/neo4j/values.yaml
# See the upstream values.yaml file for more information on the default values, descriptions and the options available for the Neo4J Helm chart.
# For all available Neo4J configuration options for the enterprise edition, see: https://github.com/neo4j/helm-charts/blob/dev/neo4j/neo4j-enterprise.conf
# Neo4J configuration options taken from the upstream file neo4j-enterprise.conf should be added to the config section of this file.
neo4j:
  # Name of your cluster
  name: "${cluster_name}"
  # If password is not set or empty a random password will be generated during installation.
  # Ignored if `neo4j.passwordFromSecret` is provided
  %{ if neo4j_auth_enabled == "true" }
  password: "${neo4j_password}"
  %{ endif }

  # Neo4j Edition to use (community|enterprise)
  # To use Neo4j Enterprise Edition you must have a Neo4j license agreement.
  # More information is also available at: https://neo4j.com/licensing/
  # Email inquiries can be directed to: licensing@neo4j.com
  edition: "${neo4j_edition}"
  
  # set edition: "enterprise" to use Neo4j Enterprise Edition
  # Set acceptLicenseAgreement: "yes" to confirm that you have a Neo4j license agreement.
  acceptLicenseAgreement: "${neo4j_accept_license_agreement}"

  # Minimum number of machines initially required to form a clustered database. The StatefulSet will not reach the ready state
  # until at least this many members have discovered each other. The default is 1 (standalone)
  minimumClusterSize: ${cluster_num_primaries}

  # set offlineMaintenanceModeEnabled: true to restart the StatefulSet without the Neo4j process running
  # this can be used to perform tasks that cannot be performed when Neo4j is running such as `neo4j-admin dump`
  offlineMaintenanceModeEnabled: ${neo4j_offline_maintenance_mode_enabled}
  
  labels:
    ${indent(4,additional_labels)}
    
  # set resources for the Neo4j Container. The values set will be used for both "requests" and "limit".
  resources:
    cpu: "${neo4j_resources_resources_cpu}"
    memory: "${neo4j_resources_resources_memory}"
    
statefulset:
  replicas: "${replicas}"

# Volumes for Neo4j
volumes:
  data:
    # labels to set on pvc/pv - these labels will be passed to the created ebs volume
    labels:
      ${indent(6,volume_labels)}

    # Set it to true when you do not want to use the subPathExpr
    disableSubPathExpr: false
    
    mode: dynamic
    dynamic:
      storageClassName: "${storage_class}"
      accessModes:
        - ReadWriteOnce
      requests:
        storage: "${ebs_volume_size}"
    
  # provide a volume to use for backups
  # n.b. backups will be written to /backups on the volume
  # any of the volume modes shown above for data can be used for backups
  backups:
    #labels for backups pvc on creation (Valid only when mode set to selector | defaultStorageClass | dynamic | volumeClaimTemplate)
    labels: {}
    disableSubPathExpr: false
    mode: "share" # share an existing volume (e.g. the data volume)
    share:
      name: "data"

  # provide a volume to use for logs
  # n.b. logs will be written to /logs/$(POD_NAME) on the volume
  # any of the volume modes shown above for data can be used for logs
  logs:
    #labels for logs pvc on creation (Valid only when mode set to selector | defaultStorageClass | dynamic | volumeClaimTemplate)
    labels: {}
    disableSubPathExpr: false
    mode: "share" # share an existing volume (e.g. the data volume)
    share:
      name: "data"

  # provide a volume to use for csv metrics (csv metrics are only available in Neo4j Enterprise Edition)
  # n.b. metrics will be written to /metrics/$(POD_NAME) on the volume
  # any of the volume modes shown above for data can be used for metrics
  metrics:
    #labels for metrics pvc on creation (Valid only when mode set to selector | defaultStorageClass | dynamic | volumeClaimTemplate)
    labels: {}
    disableSubPathExpr: false
    mode: "share" # share an existing volume (e.g. the data volume)
    share:
      name: "data"  

  # provide a volume to use for import storage
  # n.b. import will be mounted to /import on the underlying volume
  # any of the volume modes shown above for data can be used for import
  import:
    #labels for import pvc on creation (Valid only when mode set to selector | defaultStorageClass | dynamic | volumeClaimTemplate)
    labels: {}
    disableSubPathExpr: false
    mode: "share" # share an existing volume (e.g. the data volume)
    share:
      name: "data"

  # provide a volume to use for licenses
  # n.b. licenses will be mounted to /licenses on the underlying volume
  # any of the volume modes shown above for data can be used for licenses
  licenses:
    #labels for licenses pvc on creation (Valid only when mode set to selector | defaultStorageClass | dynamic | volumeClaimTemplate)
    labels: {}
    disableSubPathExpr: false
    mode: "share" # share an existing volume (e.g. the data volume)
    share:
      name: "data"
 
# Services for Neo4j
services:
  # A ClusterIP service with the same name as the Helm Release name should be used for Neo4j Driver connections originating inside the
  # Kubernetes cluster.
  default:
    # Annotations for the K8s Service object
    annotations: {}

  # A LoadBalancer Service for external Neo4j driver applications and Neo4j Browser
  # We deploy this separately so we can expose seperate load balancers for primary and read replicas
  neo4j:
    enabled: false

  # A service for admin/ops tasks including taking backups
  # This service is available even if the deployment is not "ready"
  admin:
    enabled: true
    # Annotations for the admin service
    annotations: { }
    spec:
      type: ClusterIP
    # n.b. there is no ports object for this service. Ports are autogenerated based on the neo4j configuration

  # A "headless" service for admin/ops and Neo4j cluster-internal communications
  # This service is available even if the deployment is not "ready"
  internals:
    enabled: true

    # Annotations for the internals service
    # Annotations that allows metrics scraping by NewRelic Agent
    annotations:
      prometheus.io/scrape: "true"
      prometheus.io/port: "2004"
      prometheus.io/path: "/metrics"

# Neo4j Configuration (yaml format)
config:
  # Configure server tags for routing purposes
  initial.server.tags: us,${neo4j_instance_type}
  # Configure server routing policies https://neo4j.com/docs/operations-manual/current/clustering/clustering-advanced/multi-data-center-routing/#mdc-load-balancing-framework
  dbms.routing.load_balancing.plugin: server_policies
  # Enables server side routing to ensure routing to the correct primary instance for a client's request that's tied to a particular database requirement
  # See docs: https://neo4j.com/docs/operations-manual/current/clustering/setup/routing/#clustering-routing
  dbms.routing.enabled: "true"
  dbms.routing.reads_on_primaries_enabled: "${reads_on_primaries_enabled}"
  dbms.routing.default_router: "SERVER"
  
  dbms.cluster.minimum_initial_system_primaries_count: "${minimum_initial_system_primaries_count}"
  # Automatically enable new servers - This will change their state from "Free" to "Enabled"
  initial.dbms.automatically_enable_free_servers: "true"
  # Set the default number of primaries for new databases
  initial.dbms.default_primaries_count: "${cluster_num_primaries}"
  # Set the default number of secondaries for new databases
  initial.dbms.default_secondaries_count: "${cluster_num_secondaries}"
  # Sets whether the Neo4J cluster instance is a primary or secondary
  initial.server.mode_constraint: "${neo4j_instance_type}"
  # Sets whether the Neo4J cluster instance is a primary or secondary
  server.cluster.system_database_mode: "${neo4j_instance_type}"
  
  # Disables authentication for POC purposes
  dbms.security.auth_enabled: "${neo4j_auth_enabled}"
  dbms.security.procedures.unrestricted: "apoc.*"
  server.config.strict_validation.enabled: "false"
  # Disabled by default, but setting a conservative limit of 2m let's us prevent run-away queries from killing cluster performance. See: https://neo4j.com/docs/operations-manual/current/configuration/configuration-settings/#config_db.transaction.timeout
  db.transaction.timeout: "2m"
  # Transactions can take longer then the default 30s (based on analyzed transaction logs - See: https://jupiterone.atlassian.net/wiki/spaces/ENGINEERING/pages/592019463/Runbooks+-+Neo4J) - so increase the limit for the transaction bookmark ready timeout
  # See: https://neo4j.com/docs/operations-manual/current/configuration/configuration-settings/#config_db.transaction.bookmark_ready_timeout
  # See: https://neo4j.com/docs/operations-manual/current/configuration/dynamic-settings/
  # Wait up to 3 minutes to confirm that data has been replicated to cluster instance members under heavy system load
  db.transaction.bookmark_ready_timeout: "180s"
  # https://neo4j.com/docs/operations-manual/current/configuration/configuration-settings/#config_db.lock.acquisition.timeout - Default is to disable the acquisition timeout
  db.lock.acquisition.timeout: "0s"
  server.directories.plugins: "/var/lib/neo4j/labs"
  # Exposes prometheus metrics on port 2004
  server.metrics.prometheus.enabled: "true"

  
  # Recommended settings from Neo4J
  db.logs.query.parameter_logging_enabled: "false"
  db.logs.query.threshold: "200ms"
  server.memory.heap.initial_size: "${server_memory_heap_initial_size}"
  server.memory.heap.max_size: "${server_memory_heap_max_size}"
  server.memory.pagecache.size: "${server_memory_pagecache_size}"

apoc_config:
  apoc.import.file.enabled: "true"
  apoc.import.file.use.neo4j.config: "true"
  apoc.ttl.enabled: "true"
  apoc.ttl.schedule: "120"
  apoc.ttl.limit: "100000"

# additional environment variables for the Neo4j Container
env:
  NEO4J_PLUGINS: '["apoc"]'

# Other K8s configuration to apply to the Neo4j pod
%{ if availability_zones != null && node_toleration_key != "" && node_toleration_value != ""  } 
podSpec:
  annotations: {}
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            %{ if length(availability_zones) > 0 }        
            - key: topology.kubernetes.io/zone
              operator: In
              values: ${yamlencode(availability_zones)}
            %{ endif }
            %{ if node_toleration_key != "" && node_toleration_value != "" }        
            - key: ${node_toleration_key}
              operator: In
              values:
              - ${node_toleration_value}
            %{ endif }
%{ endif }
  # Anti Affinity
  # If set to true then an anti-affinity rule is applied to prevent database pods with the same `neo4j.name` running on a single Kubernetes node.
  # If set to false then no anti-affinity rules are applied
  # If set to an object then that object is used for the Neo4j podAntiAffinity
  # podAntiAffinity: ${pod_anti_affinity_enabled}

  # Add tolerations to the Neo4j pod
  # Have to explicitly set the toleration to allow the pod to be scheduled on a node for the dedicated node group
  %{ if node_toleration_key != "" && node_toleration_value != "" }        
  tolerations:
   - key: "${node_toleration_key}"
     operator: "Equal"
     value: "${node_toleration_value}"
     effect: "NoSchedule"
 %{ endif }    

  # Name of service account to use for the Neo4j Pod (optional)
  # this is useful if you want to use Workload Identity to grant permissions to access cloud resources e.g. cloud object storage (AWS S3 etc.)
  # For clusters, please ensure that it has the appropriate roles and role-bindings to be able to query kubernetes services
  %{ if neo4j_service_account_name != null }
  serviceAccountName: "${neo4j_service_account_name}"
  %{ endif }
  

  # How long the Neo4j pod is permitted to keep running after it has been signalled by Kubernetes to stop. Once this timeout elapses the Neo4j process is forcibly terminated.
  # A large value is used because Neo4j takes time to flush in-memory data to disk on shutdown.
  terminationGracePeriodSeconds: "120"

# print the neo4j user password set during install to the `helm install` log
logInitialPassword: true

# Jvm configuration for Neo4j
jvm:
  # If true any additional arguments are added after the Neo4j default jvm arguments.
  # If false Neo4j default jvm arguments are not used.
  useNeo4jDefaultJvmArguments: true
  # additionalJvmArguments is a list of strings. Each jvm argument should be a separate element:
  additionalJvmArguments: []

# define your podDisruptionBudget details here
# This should only be enabled if Neo4J supports running multiple replicas per statefulset, which is controlled here: https://github.com/neo4j/helm-charts/blob/0744e2de758acce110e11e82909098c690280cb3/neo4j/templates/neo4j-statefulset.yaml#L36
podDisruptionBudget:
  enabled: true
  maxUnavailable: "${pod_disruption_budget_max_unavailable}"

# Service Monitor for prometheus
# Please ensure prometheus operator or the service monitor CRD is present in your cluster before using service monitor config
serviceMonitor:
  enabled: false
  labels:
    release: prometheus