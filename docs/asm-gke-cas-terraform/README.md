## Managed Anthos Service Mesh on GKE with Terraform and Google CA Service

This Terraform sample configures Managed Anthos Service Mesh on GKE. The mesh is configured so that sidecar proxies request their workload certificates from [Google Certificate Authority Service](https://cloud.google.com/certificate-authority-service/docs/ca-service-overview). This allows the use of a custom root CA and other advanced CA Service features.

This sample relies on the [Kubernetes Terraform provider](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs) to create an `istio-system` namespace and an `asm-options` ConfigMap. The ConfigMap must be created before enabling the "servicemesh" Fleet feature.

The ConfigMap contains a key named `ASM_OPTS`, containing a semi-colon delimited string of keys and values for configuring the mesh to request certificates from CA Service. The `CAAddr` option is used to specify the CA Service [pool](https://cloud.google.com/certificate-authority-service/docs/ca-pool) and an optional [certificate template](https://cloud.google.com/certificate-authority-service/docs/creating-certificate-template).

Example ConfigMap:

```
apiVersion: v1
kind: ConfigMap
metadata:
  name: asm-options
  namespace: istio-system
data:
  ASM_OPTS: CA=PRIVATECA;CAAddr=projects/<a project ID>/locations/<location>/caPools/<CA pool name>:projects/<a project ID>/locations/<location>/certificateTemplates/<cert template name>
```

If you need to make a modification to the ConfigMap after configuring the "servicemesh" Fleet feature, you restart the managed control plane instance with this command:
```
kubectl annotate controlplanerevisions.mesh.cloud.google.com \
    -n istio-system \
    asm-managed \
    mesh.cloud.google.com/force-reprovision=true
```

This sample is an extension of the [asm-gke-terraform sample](../asm-gke-terraform/). See that sample for instructions on how to apply this configuration.
