# Déploiement automatisé — Image_to_Cluster (Séquence 3)

Ce dépôt propose une solution **simple et reproductible** pour :

1. **Construire** une image Docker Nginx personnalisée (avec votre `index.html`) via **Packer**
2. **Créer** un cluster **k3d** (Kubernetes local)
3. **Importer** l’image dans le cluster k3d
4. **Déployer** l’application sur Kubernetes via **Ansible**
5. **Accéder** à l’application via un `port-forward` (compatible Codespaces)

L’objectif est de pouvoir déployer l’ensemble en **1 commande**.

---

## Prérequis

- Un environnement Linux (ex : **GitHub Codespaces** recommandé)
- Docker disponible (dans Codespaces c’est généralement déjà OK)

> ✅ La plupart des dépendances (Packer, Ansible, k3d, kubectl, librairies Python) sont installées automatiquement via `make bootstrap`.

---

## Structure du projet (repères)

- `index.html` : page web servie par Nginx (personnalisée)
- `packer/nginx.pkr.hcl` : build de l’image Docker avec Packer
- `ansible/deploy.yml` : playbook Ansible de déploiement Kubernetes
- `ansible/manifests/app.yml` : manifests Kubernetes (Deployment + Service)
- `scripts/bootstrap.sh` : installation + correctifs (dépendances + erreurs fréquentes)
- `Makefile` : orchestration “1 commande”

---

## Pourquoi cette automatisation ?

Pendant le lab, plusieurs problèmes peuvent bloquer le déploiement. La solution automatisée les **corrige en amont** :

### Problèmes déjà rencontrés + corrections intégrées

- **APT bloqué par Yarn (NO_PUBKEY / dépôt non signé)**
  - Le script `bootstrap.sh` **désactive automatiquement** le repo Yarn s’il empêche `apt update`.
- **Packer : erreur `docker-tag` (type list)**
  - Le template Packer est corrigé (`tag = ["1.0"]` au lieu de `tag = "1.0"`).
- **Ansible : le module k8s nécessite la lib Python `kubernetes`**
  - Installation automatique via `pip` dans `bootstrap.sh`.
- **Erreur “Namespace is required for apps/v1.Deployment”**
  - Le namespace est explicitement défini dans les manifests (`metadata.namespace: default`).
- **Image non disponible dans k3d**
  - Étape `k3d image import` intégrée dans le workflow.

---

## Utilisation (workflow recommandé)

### Étape 1 — Tout faire automatiquement (recommandé)

Depuis la racine du projet :

```bash
make all

## Accéder à l’application (obligatoire après `make all`)

> ⚠️ Important : la commande `make all` **ne lance pas** le port-forward.
> Le port-forward est une commande interactive qui reste attachée au terminal, donc elle se lance **à part**.

1) Après `make all`, lancer le port-forward sur un port libre (ex : 8081) :

```bash
make port-forward PORT=8081
