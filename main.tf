resource "random_uuid" "password" {
  keepers = {
    cluster_name = var.cluster_name
  }
}

module "neo4j_cluster_kubernetes" {
  source = "./modules/neo4j_cluster_kubernetes"

  enabled                                         = var.enabled
  deploy_config                                   = var.deploy_config
  cluster_name                                    = var.cluster_name
  cluster_num_primaries                           = var.cluster_num_primaries
  cluster_num_secondaries                         = var.cluster_num_secondaries
  reads_on_primaries_enabled                      = var.reads_on_primaries_enabled
  neo4j_auth_enabled                              = var.neo4j_auth_enabled
  neo4j_allow_multiple_cluster_instances_per_host = var.neo4j_allow_multiple_cluster_instances_per_host
  ebs_volume_size                                 = var.ebs_volume_size
  ebs_volume_iops                                 = var.ebs_volume_iops
  ebs_volume_throughput                           = var.ebs_volume_throughput
  storage_class                                   = var.storage_class
  k8s_labels                                      = var.k8s_labels
  namespace                                       = var.namespace
  neo4j_password                                  = random_uuid.password.result
  neo4j_edition                                   = var.neo4j_edition
  neo4j_accept_license_agreement                  = var.neo4j_accept_license_agreement
  neo4j_offline_maintenance_mode_enabled          = var.neo4j_offline_maintenance_mode_enabled
  neo4j_resources_resources_cpu                   = var.neo4j_resources_resources_cpu
  neo4j_resources_resources_memory                = var.neo4j_resources_resources_memory
  fqdn_base                                       = var.fqdn_base
  availability_zones                              = var.availability_zones
  node_toleration_key                             = var.node_toleration_key
  node_toleration_value                           = var.node_toleration_value
}
