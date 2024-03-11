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

# [START servicemesh_cas_tf_cert_roles]
locals {
  cert_roles = [
    "roles/privateca.workloadCertificateRequester",
    "roles/privateca.auditor"
   ]
}

resource "google_privateca_ca_pool_iam_member" "workload_cert_member" {
  for_each = toset(local.cert_roles)

  ca_pool = google_privateca_ca_pool.sub_pool.id

  # FIXME: It should really be the **Fleet** project ID
  # - could be different from the project(s) used for clusters
  member  = "group:${data.google_project.project.name}.svc.id.goog:/allAuthenticatedUsers/"

  role = each.value
}

resource "google_privateca_certificate_template_iam_member" "workload_cert_template_user" {
  certificate_template = google_privateca_certificate_template.workload_cert_template.id
  role = "roles/privateca.templateUser"
  member = "group:${data.google_project.project.name}.svc.id.goog:/allAuthenticatedUsers/"
}
# [END servicemesh_cas_tf_cert_roles]
