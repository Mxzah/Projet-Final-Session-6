#!/bin/bash
#
# Script de déploiement RestoQR
# Serveur: 206260753.system.shawinigan.info
# URL cible: http://206260753.system.shawinigan.info/admin
#
# Usage: ./deploy.sh
#
set -e

SERVER="206260753.system.shawinigan.info"
SSH_PORT=2069
SSH_USER="root"
SSH_PASS="KQpRjB3SGv"
APP_DIR="/opt/restoqr"

echo "========================================="
echo " Déploiement RestoQR"
echo " Cible: http://$SERVER/admin"
echo "========================================="
echo ""

# ============================================
# ÉTAPE 1: Vérifier les prérequis locaux
# ============================================
echo "[1/5] Vérification des prérequis locaux..."

if ! command -v sshpass &> /dev/null; then
    echo "  -> Installation de sshpass..."
    sudo apt-get install -y sshpass 2>/dev/null || {
        echo "ERREUR: Impossible d'installer sshpass."
        echo "Installez-le manuellement: sudo apt-get install sshpass"
        exit 1
    }
fi
echo "  -> OK"

# Fonction helper pour SSH
remote() {
    sshpass -p "$SSH_PASS" ssh -o StrictHostKeyChecking=no -p "$SSH_PORT" "$SSH_USER@$SERVER" "$@"
}

# Fonction helper pour SCP
remote_copy() {
    sshpass -p "$SSH_PASS" scp -o StrictHostKeyChecking=no -P "$SSH_PORT" -r "$1" "$SSH_USER@$SERVER:$2"
}

# ============================================
# ÉTAPE 2: Préparer le serveur
# ============================================
echo "[2/5] Préparation du serveur distant..."

remote bash << 'REMOTE_SETUP'
set -e

echo "  -> Mise à jour des paquets..."
apt-get update -qq

# Installer Docker si absent
if ! command -v docker &> /dev/null; then
    echo "  -> Installation de Docker..."
    apt-get install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
    apt-get update -qq
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    systemctl enable docker
    systemctl start docker
    echo "  -> Docker installé"
else
    echo "  -> Docker déjà installé"
fi

# Installer Apache si absent
if ! command -v apache2 &> /dev/null; then
    echo "  -> Installation d'Apache..."
    apt-get install -y apache2
    systemctl enable apache2
    systemctl start apache2
else
    echo "  -> Apache déjà installé"
fi

# Activer les modules Apache nécessaires
a2enmod proxy proxy_http rewrite headers 2>/dev/null || true
systemctl restart apache2

# Créer le répertoire de l'application
mkdir -p /opt/restoqr

echo "  -> Serveur prêt"
REMOTE_SETUP

# ============================================
# ÉTAPE 3: Transférer les fichiers
# ============================================
echo "[3/5] Transfert des fichiers vers le serveur..."

# Créer une archive du projet (sans node_modules, .git, tmp)
echo "  -> Création de l'archive..."
cd "$(dirname "$0")"
tar czf /tmp/restoqr-deploy.tar.gz \
    --exclude='Angular/node_modules' \
    --exclude='Angular/.angular' \
    --exclude='Rails/tmp' \
    --exclude='Rails/log' \
    --exclude='Rails/storage' \
    --exclude='.git' \
    --exclude='Rails/vendor/bundle' \
    .

echo "  -> Envoi vers le serveur..."
remote_copy /tmp/restoqr-deploy.tar.gz /tmp/restoqr-deploy.tar.gz

echo "  -> Extraction sur le serveur..."
remote bash << 'EXTRACT'
set -e
rm -rf /opt/restoqr/*
cd /opt/restoqr
tar xzf /tmp/restoqr-deploy.tar.gz
rm -f /tmp/restoqr-deploy.tar.gz
echo "  -> Fichiers extraits"
EXTRACT

rm -f /tmp/restoqr-deploy.tar.gz
echo "  -> Transfert terminé"

# ============================================
# ÉTAPE 4: Construire et lancer les conteneurs
# ============================================
echo "[4/5] Construction et lancement des conteneurs Docker..."

remote bash << 'DOCKER_UP'
set -e
cd /opt/restoqr

echo "  -> Arrêt des anciens conteneurs..."
docker compose down 2>/dev/null || true

echo "  -> Construction de l'image (peut prendre quelques minutes)..."
docker compose build --no-cache

echo "  -> Lancement des conteneurs..."
docker compose up -d

echo "  -> Attente du démarrage de MySQL..."
sleep 10

echo "  -> Initialisation de la base de données..."
docker compose exec -T web ./bin/rails db:prepare 2>&1 || true

echo "  -> Chargement des données initiales..."
docker compose exec -T web ./bin/rails db:seed 2>&1 || true

echo "  -> Conteneurs lancés"
docker compose ps
DOCKER_UP

# ============================================
# ÉTAPE 5: Configurer Apache reverse proxy
# ============================================
echo "[5/5] Configuration d'Apache (reverse proxy /admin)..."

remote bash << 'APACHE_CONFIG'
set -e

cat > /etc/apache2/sites-available/restoqr.conf << 'VHOST'
<VirtualHost *:80>
    ServerName 206260753.system.shawinigan.info

    # Reverse proxy /admin vers Rails (port 3000)
    ProxyPreserveHost On
    ProxyRequests Off

    # Rediriger /admin (sans slash) vers /admin/
    RedirectMatch ^/admin$ /admin/

    # Proxy /admin/ vers Rails
    <Location /admin/>
        ProxyPass http://127.0.0.1:3000/
        ProxyPassReverse http://127.0.0.1:3000/
    </Location>

    # Headers pour le bon fonctionnement des cookies/sessions
    <Location /admin/>
        RequestHeader set X-Forwarded-Proto "http"
        RequestHeader set X-Forwarded-Host "206260753.system.shawinigan.info"
        RequestHeader set X-Forwarded-Prefix "/admin"
    </Location>

    ErrorLog ${APACHE_LOG_DIR}/restoqr-error.log
    CustomLog ${APACHE_LOG_DIR}/restoqr-access.log combined
</VirtualHost>
VHOST

a2ensite restoqr.conf 2>/dev/null || true
a2dissite 000-default.conf 2>/dev/null || true
apache2ctl configtest
systemctl reload apache2

echo "  -> Apache configuré"
APACHE_CONFIG

echo ""
echo "========================================="
echo " Déploiement terminé!"
echo ""
echo " URL: http://206260753.system.shawinigan.info/admin"
echo ""
echo " Comptes par défaut:"
echo "   Admin:     admin@restoqr.ca / password123"
echo "   Serveur:   waiter@restoqr.ca / password123"
echo "   Cuisinier: cook@restoqr.ca / password123"
echo "========================================="
