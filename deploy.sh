#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$BASE_DIR/.templates"
GENERATED_FILE="$BASE_DIR/docker-compose.yml"
SCRIPTS_DIR="$BASE_DIR/scripts"

# Colores
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
RESET="\e[0m"

SELECTED_SERVICES=()

function check_dependencies() {
  if ! command -v docker &>/dev/null; then
    echo "❌ Docker no está instalado o en PATH."
    exit 1
  fi
}

function select_services() {
  echo -e "${BLUE}Paso 1:${RESET} Seleccionar los servicios\n"

  # Usa whiptail si existe
  if command -v whiptail &>/dev/null; then
    local options=(
      "portainer" "Gestión web de contenedores" OFF
      "postgres"  "Base de datos PostgreSQL" OFF
      "n8n"       "Automatización de flujos" OFF
      "netdata"   "Monitoreo de rendimiento" OFF
      "jupyterlab" "Entorno JupyterLab" OFF
      "code-server" "Editor de código en la nube" OFF
    )
    local choices
    choices=$(whiptail --title "LDDS - Selección de Servicios" \
      --checklist "Usa espacio para marcar/desmarcar, Enter para continuar:" 20 70 10 \
      "${options[@]}" 3>&2 2>&1 1>&3)

    IFS=" " read -r -a SELECTED_SERVICES <<<"${choices//\"/}"
  else
    echo "whiptail no encontrado, usando selección manual."
    echo "Selecciona servicios (ej: 1 3 para portainer y n8n):"
    echo "1) portainer"
    echo "2) postgres"
    echo "3) n8n"
    echo "4) netdata"
    echo "5) jupyterlab"
    echo "6) code-server"
    read -rp "Servicios: " choices
    for num in $choices; do
      case $num in
        1) SELECTED_SERVICES+=("portainer") ;;
        2) SELECTED_SERVICES+=("postgres") ;;
        3) SELECTED_SERVICES+=("n8n") ;;
        4) SELECTED_SERVICES+=("netdata") ;;
        5) SELECTED_SERVICES+=("jupyterlab") ;;
        6) SELECTED_SERVICES+=("code-server") ;;
        *) echo "Opción inválida: $num" ;;
      esac
    done
  fi

  echo -e "\nServicios seleccionados: ${YELLOW}${SELECTED_SERVICES[*]:-ninguno}${RESET}"
}

function show_progress() {
  echo -e "\n${BLUE}Paso 2:${RESET} Creando docker-compose..."
  for i in {1..20}; do
    printf "▰"
    sleep 0.05
  done
  echo -e "\n"
}

function generate_compose() {
  echo "version: '3.8'" >"$GENERATED_FILE"
  echo "services:" >>"$GENERATED_FILE"

  # Guardamos los volúmenes que necesitamos
  declare -A volumes_needed

  for svc in "${SELECTED_SERVICES[@]}"; do
    template="$TEMPLATE_DIR/$svc/service.yml"
    if [[ -f "$template" ]]; then
      echo "  # $svc" >>"$GENERATED_FILE"
      sed 's/^/  /' "$template" >>"$GENERATED_FILE"

      # Marcar volúmenes necesarios según servicio
      case $svc in
        portainer) volumes_needed[portainer_data]=1 ;;
        postgres)  volumes_needed[postgres_data]=1 ;;
        n8n)       volumes_needed[n8n_data]=1 ;;
        netdata)   volumes_needed[netdata_config]=1; volumes_needed[netdata_lib]=1; volumes_needed[netdata_cache]=1 ;;
        jupyterlab) volumes_needed[jupyter_data]=1 ;;
        code-server) volumes_needed[code_server_data]=1 ;;
      esac
    fi
  done

  # Generar la sección de volúmenes según lo marcado
  if [[ ${#volumes_needed[@]} -gt 0 ]]; then
    echo -e "\nvolumes:" >>"$GENERATED_FILE"
    for vol in "${!volumes_needed[@]}"; do
      echo "  $vol:" >>"$GENERATED_FILE"
    done
  fi
}


function ask_start() {
  echo -e "${BLUE}Paso 3:${RESET} ¿Deseas levantar los servicios ahora?"
  read -rp "Responder [s/n]: " opt
  case "$opt" in
    s|S|y|Y)
      echo "🚀 Levantando stack..."
      bash "$SCRIPTS_DIR/start.sh"
      ;;
    *)
      echo -e "\nPuedes levantarlos más tarde con:"
      echo -e "${YELLOW}docker compose -f docker-compose.yml up -d${RESET}"
      ;;
  esac
}

# Ejecución
check_dependencies
select_services
show_progress
generate_compose
ask_start

echo -e "\n${GREEN}✅ LDDS completado correctamente.${RESET}"
