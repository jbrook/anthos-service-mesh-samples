# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START servicemesh_cas_tf_create_gke_cluster]
resource "google_container_cluster" "cluster" {
  name                = "asm-cluster"
  location            = var.region
  deletion_protection = false # Warning: Do not set deletion_protection to false for production clusters

  enable_autopilot = true
  fleet {
    project = data.google_project.project.name
  }
}

data "google_project" "project" {}

# [END servicemesh_cas_tf_create_gke_cluster]

# [START servicemesh_cas_tf_configure_fleet]
resource "google_project_service" "mesh_api" {
  service = "mesh.googleapis.com"

  disable_dependent_services = true
}

### IMPORTANT ###
# The ASM Fleet feature must not be enabled until the
# asm-options ConfigMap with the URI for the CA pool has
# been created in the istio-system namespace.

resource "google_gke_hub_feature" "feature" {
  name     = "servicemesh"
  location = "global"

  depends_on = [
    google_project_service.mesh_api,
    google_privateca_ca_pool_iam_member.workload_cert_member,
    google_privateca_certificate_template_iam_member.workload_cert_template_user,
    kubernetes_config_map.asm-options
  ]
}

resource "google_gke_hub_feature_membership" "feature_member" {
  location   = "global"
  feature    = google_gke_hub_feature.feature.name
  membership = google_container_cluster.cluster.fleet.0.membership
  membership_location = google_container_cluster.cluster.location
  mesh {
    management = "MANAGEMENT_AUTOMATIC"
  }
}
# [END servicemesh_cas_tf_configure_fleet]

