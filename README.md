# Docker-compose-Project

Collection de stacks Docker Compose auto-hébergées (WordPress, Nextcloud, Mastodon, Matomo, Plex...), toutes exposées via un reverse proxy SSL commun.

### Testé sur

* [x] Debian 12 (bookworm)
* [x] Ubuntu 22.04 / 24.04 LTS

> Debian 8/9 sont EOL depuis longtemps, les scripts d'installation dédiés ont été retirés au profit d'un script unique basé sur le script officiel Docker.

## ⚠️ Avant de déployer en production

Tous les fichiers `docker-compose.yml` de ce dépôt contiennent des valeurs par défaut à usage de démo, à changer impérativement avant toute exposition publique :

- **Mots de passe** : `mypassword`, `admin`, `changeme`, `mysupersecretkey` apparaissent en clair dans plusieurs stacks (bases de données, Flarum, Nextcloud, rTorrent...). Remplacez-les avant le premier `docker compose up -d`.
- **Domaines** : les variables `VIRTUAL_HOST` / `LETSENCRYPT_HOST` pointent vers des domaines d'exemple (`*.domain.com`) et `LETSENCRYPT_EMAIL` vers `toto@yopmail.fr`. Adaptez-les à vos propres domaines et à une adresse e-mail que vous consultez réellement (Let's Encrypt s'en sert pour les alertes d'expiration).
- **Dashboard Traefik** (`cont_traefik_portainer`) : la commande active `--api.insecure=true`, qui expose le dashboard sans authentification sur le port 8080. À restreindre (basicauth, IP whitelist) ou désactiver avant toute exposition publique.
- Les secrets ne doivent jamais être committés une fois remplacés par de vraies valeurs — utilisez `.gitignore` ou un gestionnaire de secrets si vous versionnez votre configuration.

## Prérequis

```
apt-get install git curl sudo
```

## Installation de Docker et Docker Compose

L'installation de Docker Engine et du plugin Docker Compose v2 (commande `docker compose`) se fait via le script `install.sh`, basé sur le script officiel [get.docker.com](https://get.docker.com).

```
git clone https://github.com/ThePharaohOps/docker-compose-project.git
cd docker-compose-project
chmod +x install.sh && ./install.sh
```

## Réseaux partagés

Les stacks exposées via `cont_nginx_proxy` (nginx-proxy) partagent un réseau Docker externe, à créer une seule fois :

```
docker network create webproxy
```

Le stack `cont_traefik_portainer` utilise de son côté son propre réseau externe `int` :

```
docker network create int
```

## Déploiement du reverse proxy Nginx et de Let's Encrypt

Pour mettre en place un reverse proxy nginx sur Docker supportant les connexions SSL, on utilise les images maintenues `nginxproxy/nginx-proxy` et `nginxproxy/acme-companion` (successeurs de `jwilder/nginx-proxy` et `jrcs/letsencrypt-nginx-proxy-companion`, tous deux abandonnés).

Que fait ce docker-compose (`cont_nginx_proxy/docker-compose.yml`) ?
- Il lance une instance de nginx-proxy qui écoute sur les ports 80 et 443
- Il stocke les certificats générés par acme-companion dans un volume Docker nommé `certs`
- Il instancie acme-companion, qui génère puis renouvelle automatiquement les certificats Let's Encrypt pour tout conteneur du réseau `webproxy` exposant `VIRTUAL_HOST` / `LETSENCRYPT_HOST`

```
cd cont_nginx_proxy
docker compose up -d
```

Vous disposez maintenant de nginx en reverse proxy SSL, avec son companion qui génère puis renouvelle automatiquement les certificats.

Pour exposer n'importe quel autre stack derrière ce proxy, il suffit de préciser ces 3 variables d'environnement sur le service concerné :

```
environment:
    - VIRTUAL_HOST=monapp.domain.com
    - LETSENCRYPT_HOST=monapp.domain.com
    - LETSENCRYPT_EMAIL=toto@yopmail.fr
```

## Liste des stacks disponibles

| Dossier | Service | Image |
|---|---|---|
| `cont_nginx_proxy` | Reverse proxy SSL | nginxproxy/nginx-proxy + nginxproxy/acme-companion |
| `cont_wordpress` | WordPress + MariaDB | wordpress, mariadb |
| `cont_nextcloud` | Nextcloud + MariaDB | nextcloud, mariadb |
| `cont_flarum` | Forum Flarum + MariaDB | mondedie/docker-flarum, mariadb |
| `cont_dozzle` | Visualisation des logs Docker | amir20/dozzle |
| `cont_mastodon` | Instance Mastodon | ghcr.io/mastodon/mastodon, postgres, redis |
| `cont_netdata` | Supervision système | netdata/netdata |
| `cont_matomo` | Analytics Matomo (ex-Piwik) | matomo, mariadb |
| `cont_plex` | Serveur média Plex + Tautulli | linuxserver/plex, linuxserver/tautulli |
| `cont_rutorrent` | Client BitTorrent + ruTorrent | linuxserver/rutorrent |
| `cont_portainer` | Administration Docker | portainer/portainer-ce |
| `cont_traefik_portainer` | Reverse proxy Traefik v3 + Portainer (stack autonome) | traefik:v3.1, portainer/portainer-ce |

Sauf mention contraire, chaque stack se déploie de la même façon :

```
cd cont_<nom>
docker compose up -d
```

### cont_wordpress

WordPress + MariaDB. Changez `MYSQL_ROOT_PASSWORD` / `MYSQL_PASSWORD` et `VIRTUAL_HOST` avant de lancer. Accès ensuite via `https://wp.domain.com`.

### cont_nextcloud

Nextcloud + MariaDB (image officielle). Changez `NEXTCLOUD_ADMIN_PASSWORD`, les mots de passe MySQL et `NEXTCLOUD_TRUSTED_DOMAINS`.

### cont_flarum

Forum Flarum + MariaDB. Changez `DB_PASS` et `FORUM_URL`. Les extensions et assets sont persistés dans `./extensions` et `./assets`.

### cont_dozzle

Visualisation des logs de tous les conteneurs Docker en temps réel, sans configuration particulière. Lit `/var/run/docker.sock` en lecture seule.

### cont_mastodon

Instance Mastodon complète (web, streaming, sidekiq, PostgreSQL, Redis). Avant le premier lancement, complétez `.env.production` : `LOCAL_DOMAIN`, `SECRET_KEY_BASE`, `OTP_SECRET`, `VAPID_PRIVATE_KEY`/`VAPID_PUBLIC_KEY` (générés avec `docker compose run --rm web bundle exec rake secret` / `rake mastodon:webpush:generate_vapid_key`), et la configuration SMTP.

### cont_netdata

Supervision système temps réel (CPU, RAM, disque, conteneurs). Nécessite l'accès à `/var/run/docker.sock` pour la supervision des conteneurs.

### cont_matomo

Analytics Matomo (anciennement Piwik) + MariaDB. Changez les mots de passe MySQL avant le premier lancement ; l'assistant d'installation web configure le reste.

### cont_plex

Serveur média Plex + Tautulli (anciennement PlexPy). Récupérez un `PLEX_CLAIM` sur https://www.plex.tv/claim (valable 4 minutes) avant de lancer, et adaptez `PUID`/`PGID`/`TZ`.

### cont_rutorrent

Client BitTorrent avec interface web ruTorrent. Adaptez `PUID`/`PGID`/`TZ` ; les téléchargements sont persistés dans `./torrents`.

### cont_portainer

Interface d'administration Docker (remplace l'ancien Rancher 1.x, en fin de vie). Accessible directement sur le port 9000 ou via `admin.domain.com`.

### cont_traefik_portainer

Alternative autonome à `cont_nginx_proxy` + `cont_portainer` : reverse proxy Traefik v3 avec labels de routage, associé à Portainer. Nécessite le réseau externe `int` (voir plus haut). Ne pas déployer en même temps que `cont_nginx_proxy` sur les mêmes ports 80/443.

## Nettoyage des images et conteneurs non utilisés

Ce script nettoie automatiquement les images, conteneurs, réseaux et caches de build inutilisés, via la commande native `docker system prune` (le script tiers historique n'est plus maintenu).

```
chmod +x docker-cleanup.sh && ./docker-cleanup.sh
```

## Maintenance des images Docker

Si vous souhaitez mettre à jour toutes vos images Docker, il est nécessaire de lancer le script `update-images-full.sh`.

```
chmod +x update-images-full.sh && ./update-images-full.sh
```
