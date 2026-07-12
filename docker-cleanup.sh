#!/bin/sh
# Nettoie les images, conteneurs, reseaux et caches de build Docker non utilises.
# Remplace l'ancien script tiers (gist wdullaer/docker-cleanup, obsolete depuis
# que `docker system prune` fait la meme chose nativement).

set -e

docker system prune -f

# Ajouter -a pour supprimer aussi toutes les images sans conteneur associe:
# docker system prune -af
