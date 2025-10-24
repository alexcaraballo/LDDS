#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$BASE_DIR/.templates"
GENERATED_FILE="$BASE_DIR/docker-compose.yml"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Colors
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

SELECTED_SERVICES=()

# Check if required dependencies are installed
function check_dependencies() {
  if ! command -v docker &>/dev/null; then
    echo "❌ Docker is not installed or not in PATH."
    read -rp "Do you want to install Docker now? [y/N]: " install_docker
    case "$install_docker" in
      y|Y)
        echo "⚡ Installing Docker..."
        # Update package index and install dependencies
        if command -v apt-get &>/dev/null; then
          sudo apt-get update
          sudo apt-get install -y ca-certificates curl gnupg lsb-release
          sudo mkdir -p /etc/apt/keyrings
          curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
          echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
          sudo apt-get update
          sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        else
          echo "⚠️ Automatic Docker installation is only supported on Debian/Ubuntu. Please install Docker manually."
          exit 1
        fi
        ;;
      *)
        echo "❌ Docker is required. Exiting."
        exit 1
        ;;
    esac
  fi
}

# Select services to include in the stack
function select_services() {
  echo -e "${BLUE}Step 1:${RESET} Select services\n"

  # Use whiptail if available
  if command -v whiptail &>/dev/null; then
    local options=(
      "portainer" "Web container management" OFF
      "postgres"  "PostgreSQL database" OFF
      "n8n"       "Workflow automation" OFF
      "netdata"   "Performance monitoring" OFF
      "jupyterlab" "JupyterLab environment" OFF
      "code-server" "Cloud code editor" OFF
      "mongodb" "MongoDB database" OFF
      "redis" "Redis in-memory data store" OFF
    )
    local choices
    choices=$(whiptail --title "LDDS - Service Selection" \
      --checklist "Use space to toggle, Enter to continue:" 20 70 10 \
      "${options[@]}" 3>&2 2>&1 1>&3)

    IFS=" " read -r -a SELECTED_SERVICES <<<"${choices//\"/}"
  else
    echo "whiptail not found, using manual selection."
    echo "Select services (e.g., 1 3 for portainer and n8n):"
    echo "1) portainer"
    echo "2) postgres"
    echo "3) n8n"
    echo "4) netdata"
    echo "5) jupyterlab"
    echo "6) code-server"
    echo "7) mongodb"
    echo "8) redis"
    read -rp "Services: " choices
    for num in $choices; do
      case $num in
        1) SELECTED_SERVICES+=("portainer") ;;
        2) SELECTED_SERVICES+=("postgres") ;;
        3) SELECTED_SERVICES+=("n8n") ;;
        4) SELECTED_SERVICES+=("netdata") ;;
        5) SELECTED_SERVICES+=("jupyterlab") ;;
        6) SELECTED_SERVICES+=("code-server") ;;
        7) SELECTED_SERVICES+=("mongodb") ;;
        8) SELECTED_SERVICES+=("redis") ;;
        *) echo "Invalid option: $num" ;;
      esac
    done
  fi

  echo -e "\nSelected services: ${YELLOW}${SELECTED_SERVICES[*]:-none}${RESET}"
}

# Show fake progress bar while generating compose
function show_progress() {
  echo -e "\n${BLUE}Step 2:${RESET} Generating docker-compose..."
  for i in {1..20}; do
    printf "▰"
    sleep 0.05
  done
  echo -e "\n"
}

# Generate docker-compose.yml dynamically
function generate_compose() {
  echo "version: '3.8'" >"$GENERATED_FILE"
  echo "services:" >>"$GENERATED_FILE"

  # Track volumes required by selected services
  declare -A volumes_needed

  for svc in "${SELECTED_SERVICES[@]}"; do
    template="$TEMPLATE_DIR/$svc/service.yml"
    if [[ -f "$template" ]]; then
      echo "  # $svc" >>"$GENERATED_FILE"
      sed 's/^/  /' "$template" >>"$GENERATED_FILE"

      # Mark volumes required for this service
      case $svc in
        portainer) volumes_needed[portainer_data]=1 ;;
        postgres)  volumes_needed[postgres_data]=1 ;;
        n8n)       volumes_needed[n8n_data]=1 ;;
        netdata)   volumes_needed[netdata_config]=1; volumes_needed[netdata_lib]=1; volumes_needed[netdata_cache]=1 ;;
        jupyterlab) volumes_needed[jupyter_data]=1 ;;
        code-server) volumes_needed[code_server_data]=1 ;;
        mongodb)   volumes_needed[mongo_data]=1 ;;
        redis)     volumes_needed[redis_data]=1 ;;
      esac
    fi
  done

  # Generate volumes section based on selected services
  if [[ ${#volumes_needed[@]} -gt 0 ]]; then
    echo -e "\nvolumes:" >>"$GENERATED_FILE"
    for vol in "${!volumes_needed[@]}"; do
      echo "  $vol:" >>"$GENERATED_FILE"
    done
  fi
}

# Ask user if they want to start services now
function ask_start() {
  echo -e "${BLUE}Step 3:${RESET} Do you want to start the services now?"
  read -rp "Answer [y/n]: " opt
  case "$opt" in
    s|S|y|Y)
      echo "🚀 Starting stack..."
      bash "$SCRIPTS_DIR/start.sh" "${SELECTED_SERVICES[@]}"
      ;;
    *)
      echo -e "\nYou can start them later with:"
      echo -e "${YELLOW}docker compose -f docker-compose.yml up -d${RESET}"
      ;;
  esac
}

# Execution flow
check_dependencies
select_services
show_progress
generate_compose
ask_start

echo -e "\n${GREEN}✅ LDDS completed successfully.${RESET}"
