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

provider "google" {}
provider "tls" {}

locals {
  algorithm = "RSA_PKCS1_4096_SHA256"
  lifetime  = "999999999s" # A very long time
}

resource "google_project_service" "privateca_api" {
  service            = "privateca.googleapis.com"
  disable_on_destroy = false
}

# Create a pool for the root CA
resource "google_privateca_ca_pool" "root_pool" {
  name        = "asm-ca-pool-root"
  location    = var.region
  tier        = "DEVOPS"

  publishing_options {
    publish_ca_cert = true
    publish_crl = false
  }

  issuance_policy {
    baseline_values {
      ca_options {
        is_ca = false
      }
      key_usage {
        base_key_usage {
          cert_sign           = false
          crl_sign            = false
          digital_signature   = false
          content_commitment  = false
          key_encipherment    = false
          data_encipherment   = false
          key_agreement       = false
          decipher_only       = false
        }
        extended_key_usage {
          server_auth         = true
          client_auth         = true
          email_protection    = true
          code_signing        = true
          time_stamping       = true
        }
      }
    }
  }
}

# Create a separate pool for the subordinate CA.
# sets an identity constraint to ensure that it only issues
# certs with a "SPIFFE" idenitifier in the SAN URI.
resource "google_privateca_ca_pool" "sub_pool" {
  name     = "asm-ca-pool-sub"
  location = var.region
  tier     = "DEVOPS"
  publishing_options {
    publish_ca_cert = true
    publish_crl     = false
  }
  issuance_policy {
    baseline_values {
      ca_options {
        is_ca = false
      }
      key_usage {
        base_key_usage {
          digital_signature = true
          key_encipherment  = true
        }
        extended_key_usage {
          server_auth = true
          client_auth = true
        }
      }
    }
    identity_constraints {
      allow_subject_passthrough = false
      allow_subject_alt_names_passthrough = true
      cel_expression {
        expression = "subject_alt_names.all(san, san.type == URI && san.value.startsWith(\"spiffe://${data.google_project.project.name}.svc.id.goog/ns/\") )"
      }
    }
  }
}

# Create a root CA
resource "google_privateca_certificate_authority" "root_ca" {
  certificate_authority_id = "asm-authority-root"
  location                 = var.region
  pool                     = google_privateca_ca_pool.root_pool.name
  config {
   subject_config {
      subject {
        country_code        = "us"
        organization        = "google"
        organizational_unit = "enterprise"
        locality            = "mountain view"
        province            = "california"
        street_address      = "1600 amphitheatre parkway"
        postal_code         = "94109"
        common_name         = "asm-ca"
      }
    }
    x509_config {
      ca_options {
        is_ca = true
      }
      key_usage {
        base_key_usage {
          cert_sign = true
          crl_sign  = true
        }
        extended_key_usage {
          server_auth = false
        }
      }
    }
  }
  key_spec {
    algorithm = local.algorithm
  }

  // Disable CA deletion related safe checks for easier cleanup.
  deletion_protection                    = false
  skip_grace_period                      = true
  ignore_active_certificates_on_deletion = true
}

# Create a subordinate CA
resource "google_privateca_certificate_authority" "sub_ca" {
  certificate_authority_id = "asm-authority-sub"
  location                 = var.region
  pool                     = google_privateca_ca_pool.sub_pool.name
  subordinate_config {
    certificate_authority = google_privateca_certificate_authority.root_ca.name
  }
  config {
    subject_config {
      subject {
        country_code        = "us"
        organization        = "google"
        organizational_unit = "enterprise"
        locality            = "mountain view"
        province            = "california"
        street_address      = "1600 amphitheatre parkway"
        postal_code         = "94109"
        common_name         = "asm-sub-ca"
      }
    }
    x509_config {
      ca_options {
        is_ca = true
        # Force the sub CA to only issue leaf certs
        max_issuer_path_length = 0
      }
      key_usage {
        base_key_usage {
          digital_signature  = true
          content_commitment = true
          key_encipherment   = true
          data_encipherment  = true
          key_agreement      = true
          cert_sign          = true
          crl_sign           = true
          decipher_only      = true
        }
        extended_key_usage {
          server_auth      = true
          client_auth      = true
          email_protection = true
          code_signing     = true
          time_stamping    = true
        }
      }
    }
  }
  lifetime = local.lifetime
  key_spec {
    algorithm = local.algorithm
  }
  type = "SUBORDINATE"

  // Disable CA deletion related safe checks for easier cleanup.
  deletion_protection                    = false
  skip_grace_period                      = true
  ignore_active_certificates_on_deletion = true
}

resource "google_privateca_certificate_template" "workload_cert_template" {
  location    = var.region
  name        = "workload-cert-template"
  description = "Certificate template for workload/leaf certificates"

  identity_constraints {
    allow_subject_passthrough = false
    allow_subject_alt_names_passthrough = true
    cel_expression {
      expression = "subject_alt_names.all(san, san.type == URI && san.value.startsWith(\"spiffe://${data.google_project.project.name}.svc.id.goog/ns/\") )"
    }
  }

  predefined_values {
    ca_options {
      is_ca = false
    }
    key_usage {
      base_key_usage {
        digital_signature = true
        key_encipherment  = true
      }
      extended_key_usage {
        server_auth = true
        client_auth = true
      }
    }
  }
}
