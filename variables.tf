variable "enabled" {
  description = "Enable the Neo4j cluster"
  type        = bool
  default     = true
}

variable "deploy_config" {
  type = map(string)
  default = {
    environment = "dev"
    project     = "provision-neo4j-cluster-k8s"
  }
}

variable "cluster_name" {
  type    = string
  default = "cluster-001"
}

variable "cluster_num_primaries" {
  description = "The number of dedicated Neo4J writers running in primary mode within a Neo4J cluster"
  type        = number
  default     = 3
}

variable "cluster_num_secondaries" {
  description = "The number of dedicated Neo4J readers running in secondary mode within a Neo4J cluster"
  type        = number
  default     = 2
}

variable "reads_on_primaries_enabled" {
  description = "Allows reads on primaries"
  type        = bool
  default     = true
}

variable "neo4j_auth_enabled" {
  description = "Enable Neo4j authentication"
  type        = bool
  default     = false
}

variable "neo4j_allow_multiple_cluster_instances_per_host" {
  description = "Allows multiple Neo4j instances per host. When set to false, an anti-affinity rule will be created to ensure that only one Neo4j cluster member for a given unique database cluster is deployed per host"
  type        = bool
  default     = false
}

variable "ebs_volume_size" {
  description = "The volume size for the Neo4j data volume"
  type        = string
  default     = "100Gi"
}

variable "ebs_volume_iops" {
  description = "The volume IOPS for the Neo4j data volume"
  type        = string
  default     = "3000"
}

variable "ebs_volume_throughput" {
  description = "The volume throughput for the Neo4j data volume"
  type        = string
  default     = "125"
}

variable "storage_class" {
  description = "The name of the Kubernetes storage class to use when creating persistent volume claims for Neo4J"
  type        = string
  default     = "gp2"
}

variable "k8s_labels" {
  description = "K8s resource labels"
  type        = map(string)
  default = {
    project = "provision-neo4j-cluster-k8s"
  }
}

variable "namespace" {
  description = "The namespace to deploy the Neo4j cluster into"
  type        = string
  default     = "neo4j-test"
}

# Neo4j Edition to use (community|enterprise)
variable "neo4j_edition" {
  description = "The edition of Neo4j to deploy"
  type        = string
  default     = "enterprise"
}

variable "neo4j_accept_license_agreement" {
  description = "Accept the Neo4j license agreement"
  type        = string
  default     = "yes"
}

variable "neo4j_offline_maintenance_mode_enabled" {
  description = "Enable offline maintenance mode"
  type        = bool
  default     = false
}

variable "neo4j_resources_resources_cpu" {
  description = "The amount of CPU to allocate to the Neo4j pods"
  type        = string
  default     = "2000m"
}

variable "neo4j_resources_resources_memory" {
  description = "The amount of CPU to allocate to the Neo4j pods"
  type        = string
  default     = "8Gi"
}

variable "fqdn_base" {
  description = "The base fully qualified domain name to use for reader and writer addresses/URIs/Connection Strings"
  type        = string
  default     = "internal.dev.jupiterone.io"
}

variable "availability_zones" {
  description = "The availability zones to deploy the Neo4j cluster into"
  type        = list(string)
  default     = []
}

variable "node_toleration_key" {
  description = "The node toleration key to allow scheduling on dedicated node pools"
  type        = string
  default     = ""
}

variable "node_toleration_value" {
  description = "The node toleration value to allow scheduling on dedicated node pools"
  type        = string
  default     = ""
}
