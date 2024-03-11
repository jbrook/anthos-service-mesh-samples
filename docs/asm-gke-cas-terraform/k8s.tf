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

# [START servicemesh_cas_tf_create_configmap]
provider "kubernetes" {
  host                   = "https://${google_container_cluster.cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate,
  )
}

resource "kubernetes_namespace" "istio-system" {
  metadata {
    name = "istio-system"
  }
}

resource "kubernetes_config_map" "asm-options" {
  metadata {
    name = "asm-options"
    namespace = "istio-system"
  }

  data = {
    ASM_OPTS = "CA=PRIVATECA;CAAddr=projects/${data.google_project.project.name}/locations/${var.region}/caPools/${google_privateca_ca_pool.sub_pool.name}"
  }
}
# [END servicemesh_cas_tf_create_configmap]
