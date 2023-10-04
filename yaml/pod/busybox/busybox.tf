resource "kubernetes_pod" "busybox" {
  metadata {
    name = "busybox"

    labels = {
      integration-test = "busybox"
    }
  }

  spec {
    container {
      name              = "busybox"
      image             = "gcr.io/k8s-minikube/busybox:1.28.4-glibc"
      command           = ["sleep", "3600"]
      image_pull_policy = "IfNotPresent"
    }

    restart_policy = "Always"
  }
}

