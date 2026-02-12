#!/bin/bash

# Script de déploiement sécurisé pour Vaultwarden
# Ce script configure l'environnement et génère les tokens sécurisés

set -e

echo "=== Déploiement de Vaultwarden en Production ==="
echo ""

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que docker et docker-compose sont installés
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker n'est pas installé. Veuillez l'installer d'abord.${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}Docker Compose n'est pas installé. Veuillez l'installer d'abord.${NC}"
    exit 1
fi

# Créer la structure de répertoires
echo -e "${GREEN}Création de la structure de répertoires...${NC}"
mkdir -p secrets
mkdir -p vw-data/templates
mkdir -p vw-data/images
mkdir -p backups
mkdir -p caddy-data
mkdir -p caddy-config

# Générer l'ADMIN_TOKEN si nécessaire
if [ ! -f secrets/admin_token.txt ]; then
    echo -e "${YELLOW}Génération d'un ADMIN_TOKEN sécurisé...${NC}"
    
    # Générer un token aléatoire sécurisé
    ADMIN_TOKEN=$(openssl rand -base64 48 | tr -d "=+/" | cut -c1-64)
    
    # Hasher le token avec Argon2
    # Note: Vaultwarden attend le token en clair dans le fichier secret
    # Le hachage est fait en interne par Vaultwarden
    echo "$ADMIN_TOKEN" > secrets/admin_token.txt
    chmod 600 secrets/admin_token.txt
    
    echo -e "${GREEN}ADMIN_TOKEN généré et stocké dans secrets/admin_token.txt${NC}"
    echo -e "${YELLOW}IMPORTANT: Conservez ce token en lieu sûr !${NC}"
    echo ""
    echo -e "${YELLOW}Appuyez sur Entrée pour continuer...${NC}"
    read
else
    echo -e "${GREEN}ADMIN_TOKEN existant trouvé.${NC}"
fi

# Créer le fichier .env s'il n'existe pas
if [ ! -f .env ]; then
    echo -e "${YELLOW}Création du fichier .env...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Veuillez éditer le fichier .env${NC}"
    echo -e "${YELLOW}Appuyez sur Entrée une fois terminé...${NC}"
    read
fi

# Afficher les informations de déploiement
echo ""
echo -e "${YELLOW}Prochaines étapes:${NC}"
echo "1. Vérifiez et modifiez le fichier .env avec vos paramètres SMTP"
echo "2. Lancez le déploiement avec: docker-compose up -d"
echo ""
echo -e "${GREEN}Pour démarrer Vaultwarden:${NC}"
echo "  docker-compose up -d"
echo ""
echo -e "${GREEN}Pour voir les logs:${NC}"
echo "  docker-compose logs -f"
echo ""
echo -e "${YELLOW}Les sauvegardes seront créées automatiquement dans le dossier backups/${NC}"
echo ""