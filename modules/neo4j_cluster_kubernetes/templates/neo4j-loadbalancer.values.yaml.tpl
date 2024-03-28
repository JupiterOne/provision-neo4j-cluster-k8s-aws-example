# This file is merged with the defaults values.yaml file from the upstream Neo4J Helm chart here: https://github.com/neo4j/helm-charts/blob/dev/neo4j-loadbalancer/values.yaml
# See the upstream values.yaml file for more information on the default values, descriptions and the options available for the Neo4J Helm chart.
neo4j:
  # Name of your cluster
  name: "${cluster_name}-${role}"
  # Neo4j Edition to use (community|enterprise)
  # To use Neo4j Enterprise Edition you must have a Neo4j license agreement.
  # More information is also available at: https://neo4j.com/licensing/
  # Email inquiries can be directed to: licensing@neo4j.com
  edition: "${neo4j_edition}"

# Annotations for the external service  
annotations:
  service.beta.kubernetes.io/aws-load-balancer-scheme: "internal"
  external-dns.alpha.kubernetes.io/hostname: "${neo4j_loadbalancer_hostname}"
      
# Neo4j ports to include in external service
ports:
  http:
    enabled: true #Set this to false to remove HTTP from this service (this does not affect whether http is enabled for the neo4j process)
    # uncomment to publish http on port 80 (neo4j default is 7474)
    #port: 80
    #targetPort: 7474
    #name: "http"
    #nodePort: <your-nodeport>, enabled only when type set to NodePort
  https:
    enabled: true #Set this to false to remove HTTPS from this service (this does not affect whether https is enabled for the neo4j process)
    # uncomment to publish http on port 443 (neo4j default is 7474)
    #port: 443
    #targetPort: 7473
    #name: "https"
    #nodePort: <your-nodeport>, enabled only when type set to NodePort
  bolt:
    enabled: true #Set this to false to remove BOLT from this service (this does not affect whether https is enabled for the neo4j process)
    # Uncomment to explicitly specify the port to publish Neo4j Bolt (7687 is the default)
    #port: 7687
    #targetPort: 7687
    #name: "tcp-bolt"
    #nodePort: <your-nodeport>, enabled only when type set to NodePort
  backup:
    enabled: false #Set this to true to expose backup port externally (n.b. this could have security implications. Backup is not authenticated by default)
    # Uncomment to explicitly specify the port to publish Neo4j Backup (6362 is the default)
    #port: 6362
    #targetPort: 6362
    #name: "tcp-backup"
    #nodePort: <your-nodeport>, enabled only when type set to NodePort

selector:
  "helm.neo4j.com/neo4j.loadbalancer": "include"
  # for neo4j cluster enable this selector
  helm.neo4j.com/clustering: "true"
  app: "${cluster_name}"
  # For writer connection string, need to restrict routing to only primary instances
  %{ if role == "primary" }
  role: "primary"
  %{ endif }

# Add additional Service.spec here if needed
spec:
  type: LoadBalancer
  # in most cloud environments LoadBalancer type will receive an ephemeral public IP address automatically.
  # If you need to specify a static ip here use:
  #loadBalancerIP: ...

# Kubernetes cluster domain suffix
clusterDomain: "cluster.local"

#this flag allows you to open internal neo4j ports necessary in multi zone /region neo4j cluster scenario
multiCluster: false