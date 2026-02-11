#!/bin/bash

# Script de vérification du déploiement Vaultwarden
# Vérifie que tout est correctement configuré

set -e

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Vérification du déploiement Vaultwarden ===${NC}"
echo ""

# Fonction de vérification
check_ok() {
    echo -e "${GREEN}✓${NC} $1"
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_error() {
    echo -e "${RED}✗${NC} $1"
}

# Compteurs
OK=0
WARN=0
ERROR=0

echo -e "${BLUE}1. Vérification des fichiers requis${NC}"

# Vérifier docker-compose.yml
if [ -f "docker-compose.yml" ]; then
    check_ok "docker-compose.yml présent"
    ((OK++))
else
    check_error "docker-compose.yml manquant"
    ((ERROR++))
fi

# Vérifier Caddyfile
if [ -f "Caddyfile" ]; then
    check_ok "Caddyfile présent"
    ((OK++))
else
    check_error "Caddyfile manquant"
    ((ERROR++))
fi

# Vérifier .env
if [ -f ".env" ]; then
    check_ok ".env présent"
    ((OK++))
else
    check_warn ".env manquant (copiez .env.example vers .env)"
    ((WARN++))
fi

echo ""
echo -e "${BLUE}2. Vérification des secrets${NC}"

# Vérifier le dossier secrets
if [ -d "secrets" ]; then
    check_ok "Dossier secrets/ présent"
    ((OK++))
    
    # Vérifier admin_token.txt
    if [ -f "secrets/admin_token.txt" ]; then
        TOKEN=$(cat secrets/admin_token.txt)
        if [ -n "$TOKEN" ]; then
            check_ok "admin_token.txt configuré (longueur: ${#TOKEN} caractères)"
            ((OK++))
        else
            check_error "admin_token.txt vide"
            ((ERROR++))
        fi
    else
        check_error "secrets/admin_token.txt manquant"
        ((ERROR++))
    fi
    
    # Vérifier smtp_password.txt
    if [ -f "secrets/smtp_password.txt" ]; then
        check_ok "smtp_password.txt présent"
        ((OK++))
    else
        check_warn "secrets/smtp_password.txt manquant"
        ((WARN++))
    fi
else
    check_error "Dossier secrets/ manquant"
    ((ERROR++))
fi

echo ""
echo -e "${BLUE}3. Vérification de la structure des répertoires${NC}"

# Vérifier les répertoires
for dir in "vw-data" "vw-data/templates" "vw-data/images" "backups" "caddy-data" "caddy-config"; do
    if [ -d "$dir" ]; then
        check_ok "$dir/ présent"
        ((OK++))
    else
        check_warn "$dir/ manquant (sera créé au premier lancement)"
        ((WARN++))
    fi
done

echo ""
echo -e "${BLUE}4. Vérification de la personnalisation${NC}"

# Vérifier les logos
if [ -f "vw-data/images/custom.logo.png" ]; then
    check_ok "Logo personnalisé présent"
    ((OK++))
else
    check_warn "Logo personnalisé manquant (utilisera le logo par défaut)"
    ((WARN++))
fi

for favicon in "favicon.ico" "favicon-16x16.png" "favicon-32x32.png"; do
    if [ -f "vw-data/images/$favicon" ]; then
        check_ok "$favicon présent"
        ((OK++))
    else
        check_warn "$favicon manquant"
        ((WARN++))
    fi
done

echo ""
echo -e "${BLUE}5. Vérification Docker${NC}"

# Vérifier que Docker est installé
if command -v docker &> /dev/null; then
    check_ok "Docker installé ($(docker --version))"
    ((OK++))
else
    check_error "Docker n'est pas installé"
    ((ERROR++))
fi

# Vérifier Docker Compose
if command -v docker-compose &> /dev/null || docker compose version &> /dev/null; then
    if command -v docker-compose &> /dev/null; then
        check_ok "Docker Compose installé ($(docker-compose --version))"
    else
        check_ok "Docker Compose installé ($(docker compose version))"
    fi
    ((OK++))
else
    check_error "Docker Compose n'est pas installé"
    ((ERROR++))
fi

echo ""
echo -e "${BLUE}6. Vérification des services Docker${NC}"

# Vérifier si les conteneurs sont en cours d'exécution
if command -v docker &> /dev/null; then
    if docker ps | grep -q vaultwarden; then
        check_ok "Conteneur Vaultwarden en cours d'exécution"
        ((OK++))
    else
        check_warn "Conteneur Vaultwarden non démarré"
        ((WARN++))
    fi
    
    if docker ps | grep -q caddy-proxy; then
        check_ok "Conteneur Caddy en cours d'exécution"
        ((OK++))
    else
        check_warn "Conteneur Caddy non démarré"
        ((WARN++))
    fi
    
    if docker ps | grep -q vaultwarden-backup; then
        check_ok "Conteneur Backup en cours d'exécution"
        ((OK++))
    else
        check_warn "Conteneur Backup non démarré"
        ((WARN++))
    fi
fi

echo ""
echo -e "${BLUE}7. Vérification des ports${NC}"

# Vérifier que les ports 80 et 443 sont disponibles ou utilisés
if netstat -tuln 2>/dev/null | grep -q ":80 "; then
    check_ok "Port 80 en écoute"
    ((OK++))
else
    check_warn "Port 80 non utilisé (normal si pas encore démarré)"
    ((WARN++))
fi

if netstat -tuln 2>/dev/null | grep -q ":443 "; then
    check_ok "Port 443 en écoute"
    ((OK++))
else
    check_warn "Port 443 non utilisé (normal si pas encore démarré)"
    ((WARN++))
fi

echo ""
echo -e "${BLUE}8. Vérification de la configuration .env${NC}"

if [ -f ".env" ]; then
    # Vérifier SMTP_HOST
    if grep -q "^SMTP_HOST=" .env && ! grep -q "^SMTP_HOST=smtp.example.com" .env; then
        check_ok "SMTP_HOST configuré"
        ((OK++))
    else
        check_warn "SMTP_HOST non configuré ou utilise la valeur par défaut"
        ((WARN++))
    fi
    
    # Vérifier SMTP_FROM
    if grep -q "^SMTP_FROM=" .env && ! grep -q "example.com" .env; then
        check_ok "SMTP_FROM configuré"
        ((OK++))
    else
        check_warn "SMTP_FROM non configuré ou utilise la valeur par défaut"
        ((WARN++))
    fi
fi

echo ""
echo -e "${BLUE}=== Résumé ===${NC}"
echo -e "✓ Tests réussis:  ${GREEN}$OK${NC}"
echo -e "⚠ Avertissements: ${YELLOW}$WARN${NC}"
echo -e "✗ Erreurs:        ${RED}$ERROR${NC}"
echo ""

if [ $ERROR -gt 0 ]; then
    echo -e "${RED}⚠ Des erreurs ont été détectées. Corrigez-les avant de déployer.${NC}"
    exit 1
elif [ $WARN -gt 0 ]; then
    echo -e "${YELLOW}⚠ Des avertissements ont été émis. Vérifiez la configuration.${NC}"
    echo -e "${YELLOW}  Vous pouvez continuer le déploiement si ces avertissements sont acceptables.${NC}"
    exit 0
else
    echo -e "${GREEN}✓ Tout semble correct ! Vous pouvez déployer avec: docker-compose up -d${NC}"
    exit 0
fi