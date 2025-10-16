#!/bin/zsh

# Caminho base do gerenciador
SCRIPT_DIR="${0:a:h}"
CONFIG_FILE="$SCRIPT_DIR/db-configs.yaml"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yaml"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Função para ler config do YAML
read_config() {
    local project=$1
    local key=$2
    grep -A 6 "^${project}:" "$CONFIG_FILE" | grep "^\s*${key}:" | awk '{print $2}'
}

# Função para expandir ~ para home
expand_path() {
    echo "${1/#\~/$HOME}"
}

# Função para mostrar uso
show_usage() {
    echo "${YELLOW}Uso:${NC}"
    echo "  docker-db.sh up <projeto>     - Inicia o banco do projeto"
    echo "  docker-db.sh down <projeto>   - Para o banco do projeto"
    echo "  docker-db.sh restart <projeto> - Reinicia o banco do projeto"
    echo "  docker-db.sh status           - Mostra status de todos os bancos"
    echo "  docker-db.sh logs <projeto>   - Mostra logs do banco"
    echo "  docker-db.sh list             - Lista projetos disponíveis"
}

# Função para listar projetos
list_projects() {
    echo "${GREEN}Projetos configurados:${NC}"
    grep "^[a-z]" "$CONFIG_FILE" | grep ":" | sed 's/://' | while read project; do
        container=$(read_config "$project" "container_name")
        status=$(docker ps -a --filter "name=$container" --format "{{.Status}}" 2>/dev/null)
        if [ -n "$status" ]; then
            echo "  ${GREEN}✓${NC} $project - $status"
        else
            echo "  ${YELLOW}○${NC} $project - não iniciado"
        fi
    done
}

# Função para mostrar status
show_status() {
    echo "${GREEN}Status dos containers:${NC}"
    docker ps -a --filter "name=postgres-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Função para subir o banco
db_up() {
    local project=$1
    
    if ! grep -q "^${project}:" "$CONFIG_FILE"; then
        echo "${RED}Erro: Projeto '$project' não encontrado no arquivo de configuração${NC}"
        list_projects
        return 1
    fi
    
    # Lê as configurações
    local container_name=$(read_config "$project" "container_name")
    local db_name=$(read_config "$project" "db_name")
    local db_user=$(read_config "$project" "db_user")
    local db_password=$(read_config "$project" "db_password")
    local db_port=$(read_config "$project" "db_port")
    local volume_path=$(expand_path $(read_config "$project" "volume_path"))
    
    # Verifica se o container já está rodando
    if docker ps --filter "name=$container_name" --format "{{.Names}}" | grep -q "$container_name"; then
        echo "${YELLOW}Container '$container_name' já está rodando${NC}"
        return 0
    fi
    
    # Cria o diretório do volume se não existir
    mkdir -p "$volume_path"
    
    echo "${GREEN}Iniciando banco para o projeto: $project${NC}"
    echo "  Container: $container_name"
    echo "  Database: $db_name"
    echo "  Port: $db_port"
    echo "  Volume: $volume_path"
    
    # Exporta variáveis de ambiente e sobe o container
    CONTAINER_NAME="$container_name" \
    DB_NAME="$db_name" \
    DB_USER="$db_user" \
    DB_PASSWORD="$db_password" \
    DB_PORT="$db_port" \
    VOLUME_PATH="$volume_path" \
    docker compose -f "$COMPOSE_FILE" up -d
    
    if [ $? -eq 0 ]; then
        echo "${GREEN}✓ Container iniciado com sucesso!${NC}"
        echo "Conexão: postgresql://$db_user:$db_password@localhost:$db_port/$db_name"
    else
        echo "${RED}✗ Erro ao iniciar container${NC}"
        return 1
    fi
}

# Função para parar o banco
db_down() {
    local project=$1
    local container_name=$(read_config "$project" "container_name")
    
    if [ -z "$container_name" ]; then
        echo "${RED}Erro: Projeto '$project' não encontrado${NC}"
        return 1
    fi
    
    echo "${YELLOW}Parando banco do projeto: $project${NC}"
    docker stop "$container_name" && docker rm "$container_name"
    
    if [ $? -eq 0 ]; then
        echo "${GREEN}✓ Container parado e removido${NC}"
    else
        echo "${RED}✗ Erro ao parar container${NC}"
        return 1
    fi
}

# Função para reiniciar o banco
db_restart() {
    local project=$1
    echo "${YELLOW}Reiniciando banco do projeto: $project${NC}"
    db_down "$project"
    sleep 2
    db_up "$project"
}

# Função para mostrar logs
db_logs() {
    local project=$1
    local container_name=$(read_config "$project" "container_name")
    
    if [ -z "$container_name" ]; then
        echo "${RED}Erro: Projeto '$project' não encontrado${NC}"
        return 1
    fi
    
    docker logs -f "$container_name"
}

# Main
case "$1" in
    up)
        if [ -z "$2" ]; then
            echo "${RED}Erro: Especifique o projeto${NC}"
            show_usage
            exit 1
        fi
        db_up "$2"
        ;;
    down)
        if [ -z "$2" ]; then
            echo "${RED}Erro: Especifique o projeto${NC}"
            show_usage
            exit 1
        fi
        db_down "$2"
        ;;
    restart)
        if [ -z "$2" ]; then
            echo "${RED}Erro: Especifique o projeto${NC}"
            show_usage
            exit 1
        fi
        db_restart "$2"
        ;;
    status)
        show_status
        ;;
    logs)
        if [ -z "$2" ]; then
            echo "${RED}Erro: Especifique o projeto${NC}"
            show_usage
            exit 1
        fi
        db_logs "$2"
        ;;
    list)
        list_projects
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
