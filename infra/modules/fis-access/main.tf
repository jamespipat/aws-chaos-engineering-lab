resource "kubernetes_namespace_v1" "lab" {
  metadata {
    name = var.namespace
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "restricted"
      "pod-security.kubernetes.io/warn"    = "restricted"
      "app.kubernetes.io/part-of"          = "aws-chaos-lab"
    }
  }
}

resource "kubernetes_service_account_v1" "fis" {
  metadata {
    name      = "fis-experiment"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }
}

resource "kubernetes_role_v1" "experiments" {
  metadata {
    name      = "role-experiments"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["configmaps"]
    verbs      = ["get", "create", "patch", "delete"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["create", "list", "get", "delete", "deletecollection"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/ephemeralcontainers"]
    verbs      = ["update"]
  }
  rule {
    api_groups = [""]
    resources  = ["pods/exec"]
    verbs      = ["create"]
  }
  rule {
    api_groups = ["apps"]
    resources  = ["deployments"]
    verbs      = ["get"]
  }
}

resource "kubernetes_role_binding_v1" "experiments" {
  metadata {
    name      = "bind-role-experiments"
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.experiments.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.fis.metadata[0].name
    namespace = kubernetes_namespace_v1.lab.metadata[0].name
  }

  subject {
    kind      = "User"
    name      = "fis-experiment"
    api_group = "rbac.authorization.k8s.io"
  }
}
