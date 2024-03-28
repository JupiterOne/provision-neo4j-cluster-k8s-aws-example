# Overview

This is an example project that deploys a Neo4J cluster on AWS using a modified Neo4J helm chart to deploy multiple replicas per helm release to respect pod disruption budgets.

# Adjust variables

Adjust variables.tf for your environment - this example should work out of the box though.

# Deploying Neo4J Cluster

terraform init --reconfigure

terraform plan  

terraform apply -auto-approve
