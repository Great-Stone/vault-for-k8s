resource "kubernetes_pod" "curl" {
  metadata {
    name = "curl"

    labels = {
      run = "curl"
    }
  }

  spec {
    container {
      name              = "curl"
      image             = "curlimages/curl"
      args              = ["sh"]
      image_pull_policy = "Always"
    }

    restart_policy = "Always"
  }
}

