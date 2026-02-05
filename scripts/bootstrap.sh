#!/usr/bin/env bash
set -euo pipefail

# Fix: Yarn repo can break apt update (NO_PUBKEY 62D54FD4003F6525)
# If you don't need Yarn for this lab, disabling it is the safest.
if [ -f /etc/apt/sources.list.d/yarn.list ]; then
  echo "[bootstrap] Disabling Yarn apt repo (NO_PUBKEY can block apt update)"
  sudo rm -f /etc/apt/sources.list.d/yarn.list
fi

sudo apt-get update -y
sudo apt-get install -y curl wget gpg lsb-release python3-pip unzip ca-certificates

# Docker is usually already present in Codespaces; keep it minimal.

# Install k3d (if missing)
if ! command -v k3d >/dev/null 2>&1; then
  echo "[bootstrap] Installing k3d"
  curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
fi

# Install kubectl (if missing)
if ! command -v kubectl >/dev/null 2>&1; then
  echo "[bootstrap] Installing kubectl"
  sudo apt-get install -y kubectl
fi

# Install Packer (HashiCorp apt repo) if missing
if ! command -v packer >/dev/null 2>&1; then
  echo "[bootstrap] Installing packer"
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
    | sudo tee /etc/apt/sources.list.d/hashicorp.list >/dev/null
  sudo apt-get update -y
  sudo apt-get install -y packer
fi

# Install Ansible if missing
if ! command -v ansible >/dev/null 2>&1; then
  echo "[bootstrap] Installing ansible"
  sudo apt-get install -y ansible
fi

# Fix: kubernetes Python lib required by kubernetes.core.k8s module
python3 -m pip install --user --upgrade pip >/dev/null
python3 -m pip install --user kubernetes >/dev/null

# Install Ansible collection(s)
if [ -f ansible/requirements.yml ]; then
  echo "[bootstrap] Installing Ansible collections"
  ansible-galaxy collection install -r ansible/requirements.yml >/dev/null
fi

echo "[bootstrap] OK"
echo "[bootstrap] Versions:"
echo "  k3d:     $$(k3d version 2>/dev/null | head -n 1 || true)"
echo "  kubectl: $$(kubectl version --client --short 2>/dev/null || true)"
echo "  packer:  $$(packer version 2>/dev/null || true)"
echo "  ansible: $$(ansible --version 2>/dev/null | head -n 1 || true)"
