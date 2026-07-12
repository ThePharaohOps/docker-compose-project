#!/bin/sh
# Installe Docker Engine + le plugin Docker Compose v2 (commande `docker compose`)
# via le script officiel get.docker.com. Fonctionne sur toutes les distributions
# Debian/Ubuntu actuellement supportees (remplace install-dockerdebian8.sh/9.sh,
# obsoletes car Debian 8/9 sont en fin de vie).

set -e

# Script only works if sudo caches the password for a few minutes
sudo true

# Installe Docker Engine, le CLI, containerd et le plugin docker-compose-plugin
curl -fsSL https://get.docker.com | sh

# Autorise l'utilisateur courant a utiliser docker sans sudo
sudo usermod -aG docker "$(whoami)"

sudo systemctl enable --now docker

echo
echo "Installation terminee. Deconnecte-toi/reconnecte-toi pour utiliser 'docker' sans sudo."
echo "Verification:"
docker --version
docker compose version
