locals {
  helm_chart_repository                 = "https://helm.neo4j.com/neo4j"
  helm_chart_name_neo4j                 = "neo4j"
  helm_chart_name_neo4j_lb              = "neo4j-loadbalancer"
  helm_chart_version                    = "5.16.0"
  namespace                             = var.namespace
  memory_heap_pagecache                 = "${floor(tonumber(replace(var.neo4j_resources_resources_memory, "Gi", "")) * 0.3)}gb"
  neo4j_loadbalancer_hostname_primary   = "neo4j-${var.cluster_name}.${var.fqdn_base}"
  neo4j_loadbalancer_hostname_secondary = "neo4j-${var.cluster_name}-secondary.${var.fqdn_base}"
}

resource "kubernetes_namespace_v1" "namespace" {
  count = var.enabled ? 1 : 0
  metadata {
    labels = var.k8s_labels
    name   = var.namespace
  }
}

# Deploy this seperately to allow expansion of ebs volume, adjustment of iops & adjustment of throughput
# Updates to pvcs managed through Kubernetes statefulsets are not allowed at this time :(, but could be a feature in upcoming k8s releases :)
# See: https://github.com/kubernetes/enhancements/issues/661
# See: https://github.com/kubernetes/enhancements/pull/3412
resource "kubernetes_persistent_volume_claim_v1" "neo4j-primary" {
  count = var.enabled ? var.cluster_num_primaries : 0
  metadata {
    name      = "data-${local.helm_chart_name_neo4j}-${var.cluster_name}-${count.index}"
    namespace = local.namespace
    labels = {
      # the app name is used to link this persistent volume to the Neo4j StatefulSet
      "app"                                = var.cluster_name,
      "helm.neo4j.com/volume-role"         = "data"
      "statefulset.kubernetes.io/pod-name" = "${local.helm_chart_name_neo4j}-${var.cluster_name}-${count.index}"
    }
    # https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/modify-volume.md
    annotations = {
      "ebs.csi.aws.com/throughput" = "${var.ebs_volume_throughput}"
      "ebs.csi.aws.com/iops"       = "${var.ebs_volume_iops}"
    }
  }
  spec {
    resources {
      requests = {
        storage = var.ebs_volume_size
      }
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class
  }
  wait_until_bound = false
}

resource "helm_release" "neo4j" {
  depends_on       = [kubernetes_namespace_v1.namespace]
  count            = var.enabled ? 1 : 0
  name             = "${local.helm_chart_name_neo4j}-${var.cluster_name}"
  chart            = "${path.module}/charts/neo4j"
  namespace        = local.namespace
  create_namespace = false
  force_update     = false
  atomic           = false
  reuse_values     = false
  recreate_pods    = false
  timeout          = 180
  wait             = true


  values = [
    templatefile("${path.module}/templates/neo4j.values.yaml.tpl", {
      cluster_name                           = var.cluster_name
      neo4j_password                         = var.neo4j_password
      neo4j_edition                          = var.neo4j_edition
      replicas                               = var.cluster_num_primaries
      minimum_initial_system_primaries_count = var.cluster_num_primaries
      # Maintain a Raft Quorum
      pod_disruption_budget_max_unavailable  = (tonumber(var.cluster_num_primaries) - 1) / 2
      neo4j_accept_license_agreement         = tostring(var.neo4j_accept_license_agreement)
      neo4j_offline_maintenance_mode_enabled = tostring(var.neo4j_offline_maintenance_mode_enabled)
      neo4j_resources_resources_cpu          = var.neo4j_resources_resources_cpu
      neo4j_resources_resources_memory       = var.neo4j_resources_resources_memory
      volume_labels                          = yamlencode(var.k8s_labels)
      ebs_volume_size                        = tostring(var.ebs_volume_size)
      availability_zones                     = var.availability_zones
      cluster_num_primaries                  = tostring(var.cluster_num_primaries)
      cluster_num_secondaries                = tostring(var.cluster_num_secondaries)
      neo4j_instance_type                    = "PRIMARY"
      neo4j_auth_enabled                     = tostring(var.neo4j_auth_enabled)
      # Pod Anti-Affinity is only enabled if multiple cluster instances are not allowed per host
      pod_anti_affinity_enabled       = tostring(!var.neo4j_allow_multiple_cluster_instances_per_host)
      neo4j_service_account_name      = null
      reads_on_primaries_enabled      = tostring(var.reads_on_primaries_enabled)
      server_memory_heap_initial_size = local.memory_heap_pagecache
      server_memory_heap_max_size     = local.memory_heap_pagecache
      server_memory_pagecache_size    = local.memory_heap_pagecache
      additional_labels = yamlencode({
        role    = "primary",
        project = var.deploy_config.project
      })
      node_toleration_key   = var.node_toleration_key
      node_toleration_value = var.node_toleration_value
      storage_class         = var.storage_class
    })
  ]
}

resource "kubernetes_persistent_volume_claim_v1" "neo4j-secondary" {
  count = var.enabled && var.cluster_num_secondaries > 0 ? var.cluster_num_secondaries : 0
  metadata {
    name      = "data-${local.helm_chart_name_neo4j}-${var.cluster_name}-secondary-${count.index}"
    namespace = local.namespace
    labels = {
      # the app name is used to link this persistent volume to the Neo4j StatefulSet
      "app"                                = var.cluster_name,
      "helm.neo4j.com/volume-role"         = "data"
      "statefulset.kubernetes.io/pod-name" = "${local.helm_chart_name_neo4j}-${var.cluster_name}-secondary-${count.index}"
    }
    # https://github.com/kubernetes-sigs/aws-ebs-csi-driver/blob/master/docs/modify-volume.md
    annotations = {
      "ebs.csi.aws.com/throughput" = "${var.ebs_volume_throughput}"
      "ebs.csi.aws.com/iops"       = "${var.ebs_volume_iops}"
    }
  }
  spec {
    resources {
      requests = {
        storage = var.ebs_volume_size
      }
    }
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = var.storage_class
  }
  wait_until_bound = false
}

resource "helm_release" "neo4j-secondaries" {
  depends_on       = [kubernetes_namespace_v1.namespace, helm_release.neo4j]
  count            = var.enabled && var.cluster_num_secondaries > 0 ? 1 : 0
  name             = "${local.helm_chart_name_neo4j}-${var.cluster_name}-secondary"
  chart            = "${path.module}/charts/neo4j"
  namespace        = local.namespace
  create_namespace = false
  force_update     = false
  atomic           = false
  reuse_values     = false
  recreate_pods    = false
  timeout          = 300
  wait             = true

  values = [
    templatefile("${path.module}/templates/neo4j.values.yaml.tpl", {
      cluster_name                           = var.cluster_name
      neo4j_password                         = var.neo4j_password
      neo4j_edition                          = var.neo4j_edition
      replicas                               = var.cluster_num_secondaries
      minimum_initial_system_primaries_count = var.cluster_num_primaries
      pod_disruption_budget_max_unavailable  = tostring(max((tonumber(var.cluster_num_secondaries) - 1), 1))
      neo4j_accept_license_agreement         = tostring(var.neo4j_accept_license_agreement)
      neo4j_offline_maintenance_mode_enabled = tostring(var.neo4j_offline_maintenance_mode_enabled)
      neo4j_resources_resources_cpu          = var.neo4j_resources_resources_cpu
      neo4j_resources_resources_memory       = var.neo4j_resources_resources_memory
      volume_labels                          = yamlencode(var.k8s_labels)
      ebs_volume_size                        = tostring(var.ebs_volume_size)
      availability_zones                     = var.availability_zones
      cluster_num_primaries                  = tostring(var.cluster_num_primaries)
      cluster_num_secondaries                = tostring(var.cluster_num_secondaries)
      neo4j_instance_type                    = "SECONDARY"
      neo4j_auth_enabled                     = tostring(var.neo4j_auth_enabled)
      # Pod Anti-Affinity is only enabled if multiple cluster instances are not allowed per host
      pod_anti_affinity_enabled       = tostring(!var.neo4j_allow_multiple_cluster_instances_per_host)
      neo4j_service_account_name      = null
      reads_on_primaries_enabled      = tostring(var.reads_on_primaries_enabled)
      server_memory_heap_initial_size = local.memory_heap_pagecache
      server_memory_heap_max_size     = local.memory_heap_pagecache
      server_memory_pagecache_size    = local.memory_heap_pagecache
      additional_labels = yamlencode({
        role    = "secondary",
        project = var.deploy_config.project
      })
      node_toleration_key   = var.node_toleration_key
      node_toleration_value = var.node_toleration_value
      storage_class         = var.storage_class
    })
  ]
}

resource "helm_release" "neo4j-load-balancer-primary" {
  depends_on       = [kubernetes_namespace_v1.namespace, helm_release.neo4j]
  count            = var.enabled ? 1 : 0
  name             = "${local.helm_chart_name_neo4j_lb}-${var.cluster_name}-primary"
  chart            = "${path.module}/charts/neo4j-loadbalancer"
  namespace        = local.namespace
  create_namespace = false
  force_update     = false
  atomic           = false
  reuse_values     = false
  recreate_pods    = false
  timeout          = 30
  wait             = false

  values = [
    templatefile("${path.module}/templates/neo4j-loadbalancer.values.yaml.tpl", {
      cluster_name                = var.cluster_name
      neo4j_edition               = var.neo4j_edition
      neo4j_loadbalancer_hostname = local.neo4j_loadbalancer_hostname_primary
      role                        = "primary"
    })
  ]
}

resource "helm_release" "neo4j-load-balancer-secondary" {
  depends_on       = [kubernetes_namespace_v1.namespace, helm_release.neo4j]
  count            = var.enabled && var.cluster_num_secondaries > 0 ? 1 : 0
  name             = "${local.helm_chart_name_neo4j_lb}-${var.cluster_name}-secondary"
  chart            = "${path.module}/charts/neo4j-loadbalancer"
  namespace        = local.namespace
  create_namespace = false
  force_update     = false
  atomic           = false
  reuse_values     = false
  recreate_pods    = false
  timeout          = 30
  wait             = false

  values = [
    templatefile("${path.module}/templates/neo4j-loadbalancer.values.yaml.tpl", {
      cluster_name                = var.cluster_name
      neo4j_edition               = var.neo4j_edition
      neo4j_loadbalancer_hostname = local.neo4j_loadbalancer_hostname_secondary
      role                        = "secondary"
    })
  ]
}

