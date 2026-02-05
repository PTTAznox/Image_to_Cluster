packer {
  required_plugins {
    docker = {
      source  = "github.com/hashicorp/docker"
      version = ">= 1.0.0"
    }
  }
}

variable "image_name" {
  type    = string
  default = "custom-nginx:1.0"
}

source "docker" "nginx" {
  image  = "nginx:alpine"
  commit = true
}

build {
  name    = "custom-nginx"
  sources = ["source.docker.nginx"]

  provisioner "file" {
    source      = "index.html"
    destination = "/usr/share/nginx/html/index.html"
  }

  provisioner "shell" {
    inline = [
      "chmod 644 /usr/share/nginx/html/index.html"
    ]
  }

  post-processor "docker-tag" {
    repository = split(":", var.image_name)[0]
    tag        = [split(":", var.image_name)[1]]
  }
}
