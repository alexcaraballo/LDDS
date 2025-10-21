# LDDS — Linux Developer Delivery System

Sistema modular inspirado en [LMDS](https://github.com/GreenFrogSB/LMDS).
Permite seleccionar servicios y construir un docker-compose dinámico.

## Estructura

```
LDDS/
 ├── .templates/
 │   ├── portainer/service.yml
 │   ├── n8n/service.yml
 │   └── postgres/service.yml
 ├── scripts/
 │   └── start.sh
 ├── deploy.sh
 ├── .env.example
 └── README.md
```

## Uso

```bash
chmod +x deploy.sh scripts/start.sh
./deploy.sh
```

Selecciona los servicios y luego elige “Generar compose” y “start”.
