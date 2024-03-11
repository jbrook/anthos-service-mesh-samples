## Managed Anthos Service Mesh on GKE with Terraform and Google CA Service

This Terraform sample configures Managed Anthos Service Mesh on GKE. The mesh is configured so that sidecar proxies request their workload certificates from Google Certificate Authority Service. This allows the use of a custom root CA and other advanced CA Service features.

This sample is an extension of the [asm-gke-terraform sample](../asm-gke-terraform/). See that sample for instructions on how to apply this configuration.
