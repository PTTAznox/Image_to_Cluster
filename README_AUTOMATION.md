# Image_to_Cluster — Automatisation Séquence 3

Ce projet met en place une chaîne **simple, claire et reproductible** pour déployer une page web Nginx sur un cluster Kubernetes local **k3d**, à partir d’une image construite automatiquement.

L’objectif est de pouvoir passer de **zéro** à une application déployée avec **une commande**, puis d’y accéder via Codespaces.

---

## Objectifs de la solution

La solution automatise les étapes suivantes :

1. **Installer/Préparer** l’environnement (Packer, Ansible, k3d, kubectl, dépendances Python)
2. **Créer** un cluster Kubernetes avec **k3d**
3. **Construire** une image Docker Nginx personnalisée (avec `index.html`) via **Packer**
4. **Importer** l’image dans le cluster k3d (car k3d/containerd ne voit pas automatiquement les images Docker locales)
5. **Déployer** l’application sur Kubernetes via **Ansible**
6. **Accéder** à l’application via un **port-forward** (Codespaces)

---

## Pourquoi cette automatisation ?

Pendant le lab, certaines erreurs bloquaient le déploiement. La solution les corrige **en amont** :

### Problèmes rencontrés + correctifs intégrés

- **APT bloqué par Yarn (NO_PUBKEY / dépôt non signé)**
  - `scripts/bootstrap.sh` désactive automatiquement le dépôt Yarn s’il empêche `apt update`.
- **Packer : erreur `docker-tag` (type attendu = liste)**
  - Le template Packer utilise `tag = ["1.0"]` (et non `tag = "1.0"`).
- **Ansible : module Kubernetes nécessite la librairie Python `kubernetes`**
  - Installation automatique via `pip` dans `bootstrap.sh`.
- **Erreur “Namespace is required for apps/v1.Deployment”**
  - Le namespace est explicitement défini dans les manifests : `metadata.namespace: default`.
- **Image non disponible dans k3d**
  - Étape `k3d image import` incluse dans le workflow.

---

## Structure du projet (repères)

- `index.html` : page web à servir via Nginx
- `packer/nginx.pkr.hcl` : template Packer pour builder l’image Docker
- `ansible/manifests/app.yml` : manifests Kubernetes (Deployment + Service)
- `ansible/deploy.yml` : playbook Ansible (déploiement via kubernetes.core.k8s)
- `scripts/bootstrap.sh` : installation + correctifs
- `Makefile` : commandes simples pour tout automatiser

---

## Prérequis

- Recommandé : **GitHub Codespaces**
- Docker disponible (dans Codespaces, en général c’est déjà le cas)

> ✅ Les outils (Packer, Ansible, k3d, kubectl, dépendances Python) sont installés automatiquement via `make bootstrap`.

---

## Utilisation (méthode recommandée)

### 1) Déployer l’ensemble automatiquement

Depuis la racine du projet :

```bash
make all
make port-forward PORT=8081
```

Après make port-forward, il faut ouvrir l’application dans le navigateur via l’onglet PORTS de Codespaces (bouton Open in Browser).