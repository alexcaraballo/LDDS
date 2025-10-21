# 🚀 LDDS — Linux Developer Delivery System

![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)
![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)
![Bash](https://img.shields.io/badge/Scripts-Bash-yellow.svg)

A **modular Linux Developer Delivery System** inspired by [LMDS](https://github.com/GreenFrogSB/LMDS).
LDDS lets you **select services** and dynamically **build a Docker Compose stack** tailored to your workflow.

---

## 📂 Project Structure

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

* **.templates/** — Service templates (minimal container definitions)
* **scripts/start.sh** — Script to launch the generated Docker Compose stack
* **deploy.sh** — Interactive deployment script
* **.env.example** — Example environment variables for easy configuration

---

## ⚙️ Prerequisites

You need **Docker** and **Docker Compose** installed on your system.

### Install Docker & Docker Compose:

```bash
curl -fsSL https://get.docker.com/ -o get-docker.sh
sudo sh get-docker.sh
```

### Add your user to the Docker group:

```bash
sudo usermod -aG docker ${USER}
```

### Apply changes:

```bash
sudo reboot
```

> For more info, check the official [Docker installation guide](https://docs.docker.com/engine/install/debian/).

---

## 🚀 Usage

Make the scripts executable and run LDDS:

```bash
chmod +x deploy.sh scripts/start.sh
./deploy.sh
```

### Steps:

1. **Select Services** — Choose the services you want in your stack (Portainer, PostgreSQL, n8n).
2. **Generate Docker Compose** — LDDS will create `docker-compose.yml` with a progress bar.
3. **Start Stack** — You can launch the stack immediately or later using:

```bash
docker compose -f docker-compose.yml up -d
```

---

## 💡 Notes & Best Practices

* **Centralized Configuration:** `.env` stores all ports, usernames, and passwords.
* **Easy Expansion:** Add more stacks by creating templates under `.templates/<service>/service.yml`.
* **Interactive & Safe:** Step-by-step prompts guide the user to prevent misconfigurations.
* **Cross-service Dependencies:** n8n depends on PostgreSQL; Portainer manages all containers.
* **Linux Focused:** Ensure your user has Docker permissions to avoid `permission denied` errors.

---

## 🛠️ Supported Services

* **Portainer:** Web UI for Docker management.
* **PostgreSQL:** Database for n8n workflows.
* **n8n:** Automation & workflow engine.

> Easily add new services by creating their respective `service.yml` templates.

---

## 📄 License

MIT License — see [LICENSE](./LICENSE) for details.
