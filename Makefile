SHELL := /bin/bash

# --- Config ---
CLUSTER   ?= lab
SERVERS   ?= 1
AGENTS    ?= 2

IMAGE     ?= custom-nginx:1.0
NAMESPACE ?= default
APP_SVC   ?= image-to-cluster
PORT      ?= 8081

# --- Targets ---
.PHONY: help bootstrap cluster delete-cluster packer-init build import deploy status port-forward open all clean

help:
	@echo "Targets:"
	@echo "  make bootstrap       # fix apt/yarn + install deps (packer/ansible/k3d) + pip kubernetes + ansible collections"
	@echo "  make cluster         # create k3d cluster $(CLUSTER) if missing (servers=$(SERVERS), agents=$(AGENTS))"
	@echo "  make build           # packer build image $(IMAGE)"
	@echo "  make import          # import image into k3d cluster $(CLUSTER)"
	@echo "  make deploy          # deploy with ansible to namespace $(NAMESPACE)"
	@echo "  make status          # show k8s resources"
	@echo "  make port-forward    # forward svc $(APP_SVC) to localhost:$(PORT)"
	@echo "  make all             # bootstrap + cluster + build + import + deploy + status"
	@echo "  make clean           # delete k8s resources (deployment+service)"
	@echo "  make delete-cluster  # delete k3d cluster $(CLUSTER)"

bootstrap:
	@./scripts/bootstrap.sh

cluster: bootstrap
	@command -v k3d >/dev/null 2>&1 || (echo "k3d not installed. Run 'make bootstrap'." && exit 1)
	@if k3d cluster list | awk 'NR>1{print $$1}' | grep -qx "$(CLUSTER)"; then \
		echo "k3d cluster '$(CLUSTER)' already exists"; \
	else \
		echo "Creating k3d cluster '$(CLUSTER)' (servers=$(SERVERS), agents=$(AGENTS))"; \
		k3d cluster create $(CLUSTER) --servers $(SERVERS) --agents $(AGENTS); \
	fi
	@kubectl get nodes

delete-cluster:
	@k3d cluster delete $(CLUSTER) || true

packer-init:
	@packer init ./packer

build: bootstrap packer-init
	@packer build -var "image_name=$(IMAGE)" ./packer
	@docker images | grep -E "$$(echo $(IMAGE) | cut -d: -f1)" || true

import:
	@k3d image import $(IMAGE) -c $(CLUSTER)

deploy:
	@ansible-playbook -i localhost, ansible/deploy.yml

status:
	@kubectl get deploy,svc,pods -n $(NAMESPACE) -o wide

port-forward:
	@echo "Port-forward: http://localhost:$(PORT) -> svc/$(APP_SVC):80 (ns: $(NAMESPACE))"
	@kubectl -n $(NAMESPACE) port-forward svc/$(APP_SVC) $(PORT):80

open:
	@echo "Codespaces: open tab PORTS -> port $(PORT) -> Open in Browser (set Public if needed)"

all: bootstrap cluster build import deploy status

clean:
	@kubectl delete deploy/$(APP_SVC) svc/$(APP_SVC) -n $(NAMESPACE) --ignore-not-found=true
