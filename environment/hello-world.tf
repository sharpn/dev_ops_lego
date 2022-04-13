resource "kubernetes_deployment" "hello_world" {
  metadata {
    name = "hello-world"
    labels = {
      app = "hello-world"
    }
  }

  spec {
    selector {
      match_labels = {
        app = "hello-world"
      }
    }

    replicas = 3

    template {
      metadata {
        labels = {
          app = "hello-world"
        }
      }

      spec {
        container {
          name              = "hello-world"
          image             = "sharpn/loadbalancer-test:latest"
          image_pull_policy = "Always"

          liveness_probe {
            http_get {
              path   = "/"
              port   = 3000
              scheme = "HTTP"
            }
          }

          readiness_probe {
            http_get {
              path   = "/"
              port   = 3000
              scheme = "HTTP"
            }
          }

          startup_probe {
            http_get {
              path   = "/"
              port   = 3000
              scheme = "HTTP"
            }

            failure_threshold = 60
            period_seconds    = 10
          }

          resources {
            requests = {
              cpu    = "0.2"
              memory = "250Mi"
            }
          }
        }
      }
    }
  }

  depends_on = [
    module.eks_cluster, // this is needed so that it gets destroyed before the cluster
    aws_security_group_rule.public_rules,
    aws_security_group_rule.node_rules,
    aws_security_group_rule.control_plane_rules
  ]
}

resource "kubernetes_service" "hello_world_service" {
  metadata {
    name = "hello-world-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.hello_world.metadata.0.labels.app
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
}

output "load_balancer_hostname" {
  value = kubernetes_service.hello_world_service.status.0.load_balancer.0.ingress.0.hostname
}
