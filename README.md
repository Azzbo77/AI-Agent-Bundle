# AI-Agent-Bundle

This project sets up a local, self-hosted AI chat system using n8n for workflow automation, Ollama for running large language models (LLMs), Redis for chat memory, and Qdrant for vector storage. It’s designed to run in Docker, leveraging GPU acceleration for Ollama, and provides a foundation for building conversational AI applications with persistent context and similarity search capabilities.

## Features

- **Chat Interface:** Trigger workflows via chat messages in n8n.
- **AI Model:** Uses Ollama with models like llama3.1:8b (~4.7 GB, tool-supporting) for chat responses, with resource limits for stability.
- **Memory:** Redis for conversation history, optimised with RDB persistence for faster startup.
- **Vector Storage:** Saves embeddings in Qdrant for similarity search or long-term memory.
- **Local Deployment:** Runs entirely on your machine with Docker, no cloud dependencies.
- **Secure Access:** n8n runs over HTTPS with self-signed certificates (configurable for external access).
- **Logging:** Centralised log collection with Loki and Promtail for debugging and monitoring.
- **Visualization:** Grafana dashboard for viewing logs in a browser-based interface.
- **Auto-Updates:** Keeps all components (n8n, Ollama, Qdrant, etc.) updated automatically via a scheduled script.

## Prerequisites

- **Docker:** Installed and running (with Docker Compose support).
- **NVIDIA GPU:** Optional but recommended for Ollama (requires NVIDIA Container Toolkit).
- **Hardware:** At least 16 GB RAM, 8 GB VRAM if using GPU, and 20 GB free disk space.
- **OS:** Tested on Linux (e.g., Ubuntu); should work on macOS/Windows with Docker adjustments.
- **OpenSSL:** Required to generate self-signed certificates for HTTPS.
- **Ports:** Ensure 5678 (n8n), 11434 (ollama), 6379 (redis), 6333-6334 (qdrant), 3100 (loki), and 3000 (grafana) are available.
- **Cron:** For scheduling auto-updates (Linux/macOS; use Task Scheduler on Windows).

## Setup Instructions

**1. Clone the Repository**
```bash
git clone https://github.com/Azzbo77/AI-Agent-Bundle
cd AI-Agent-Bundle
```
**2. Install NVIDIA Container Toolkit (if using GPU)**
```bash
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

**3. Generate Self-Signed Certificates for HTTPS**
```bash
mkdir -p certs
cd certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout n8n-key.pem -out n8n-cert.pem \
  -subj "/C=US/ST=State/L=City/O=Home/CN=<your-host-ip>"
cd ..
```
- Replace <your-host-ip> with your host IP (e.g., 192.168.1.11).

**4. Configure Environment Variables**
- Copy the example .env file and edit it
```bash
cp .env.example .env
nano .env
```
- Update N8N_HOST and WEBHOOK_URL with your host IP (e.g., 192.168.1.11).

**5. Start the Containers**
```bash
sudo docker compose up -d
```

**6. Pull the Ollama Model**
- Download the llama3.1:8b model (~4.7 GB, supports tools):
```bash
sudo docker exec -it ollama ollama pull llama3.1:8b
```
**7. Configure Qdrant Collection**
- Create a collection for vector storage (assuming 4096 dimensions for llama3.1):
```bash
curl -X PUT http://<your-host-ip>:6333/collections/my_collection \
  -H "Content-Type: application/json" \
  -d '{"vectors": {"size": 4096, "distance": "Cosine"}}'
```

**8. Set Up Logging and Visualization**
- Logging is handled by Loki and Promtail, configured via loki-config.yaml and promtail-config.yaml in the project root.
- Grafana provides a UI at http://<your-host-ip>:3000:
 1. Login: admin / <your_secure_password> (set in .env or defaults to admin).
 2. Add Loki data source: http://loki:3100 → “Save & Test.”
 3. Explore logs: Query {container=~".+"} or {container="ollama-n8n-compose-ollama-1"} in “Explore.”
 4. Dashboard: Create “AI Agent Logs”:
    - Add visualization → Loki → Query: {container=~".+"}.
    - Set visualization to “Logs.”
    - Save as “AI Agent Logs.”

**9. Set Up Auto-Updates**
- The stack auto-updates daily using a script:
 1. Ensure Dockerfile.ollama and Dockerfile.qdrant are in the project root:
 ```Dockerfile 
# Dockerfile.ollama
FROM ollama/ollama
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```

```Dockerfile
# Dockerfile.qdrant
FROM qdrant/qdrant:latest
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*
```
 2. The update-stack.sh script is included:
 ```bash
 #!/bin/bash
cd ~/ollama-n8n-compose

# Check volumes
docker volume inspect ollama-n8n-compose_n8n_data ollama-n8n-compose_ollama_data ollama-n8n-compose_redis_data ollama-n8n-compose_qdrant_data ollama-n8n-compose_grafana_data ollama-n8n-compose_loki_data || {
  echo "Error: Missing volumes. Check your setup!"
  exit 1
}

# Pull public images
docker compose pull

# Rebuild custom images
docker compose build --pull ollama qdrant

# Restart all services
docker compose up -d

# Clean up
docker image prune -f
```

3. Make it executable:
```bash
chmod +x update-stack.sh
```
4. Schedule with cron (e.g., 3 AM local time; adjust for your timezone):
```bash
crontab -e
# For UTC: 0 3 * * * /path/to/AI-Agent-Bundle/update-stack.sh >> update-stack.log 2>&1
# For EST (UTC-5): 0 8 * * * /path/to/AI-Agent-Bundle/update-stack.sh >> update-stack.log 2>&1
```
- Replace /path/to/AI-Agent-Bundle with your repo path.

**10. Access n8n**
- Open your browser: https://<your-host-ip>:5678
- Accept the self-signed certificate warning.
- Set up your first workflow (see below).

## Example Workflow

**1. Chat Trigger:** Triggers on incoming chat messages.
**2. AI Agent (Ollama Chat Mode):**
- Model: llama3.1:8b
- Base URL: http://ollama:11434
- Tools: Enabled (if desired).
**3. Memory (Redis):**
- Host: redis
- Port: 6379
- Database: 0
**4. Vector Store (Qdrant):**
- Collection: my_collection
- Host: http://qdrant:6333
- Use an HTTP Request node to generate embeddings:
  - URL: http://ollama:11434/api/embeddings
  - Body: {"model": "llama3.1:8b", "prompt": "{{$json.message}}"}
Test by sending "hello" in the n8n chat interface.

## Usage

- **Chat:** Send messages to https://<your-host-ip>:5678/webhook/chat (configure webhook as needed).
- **Memory:** Conversation history is stored in Redis.
- **Vectors:** Embeddings are saved in Qdrant’s my_collection for similarity search.
- **Monitoring:** View logs in Grafana (http:/<your-host-ip>/:3000) with queries like {container="ollama-n8n-compose-ollama-1"}.

## Troubleshooting
- **Check Logs:**
```bash
sudo docker compose logs <service>
```
**Update Failures:** Check update-stack.log if cron runs fail:
```bash
cat update-stack.log
```
- **Grafana:** 
   - Check docker logs ollama-n8n-compose-grafana-1 if login fails.
   - Remove data source: “Data Sources” → Select “Loki” → “Delete” at bottom.
- **Loki Query Error:** Use {container=".+"} instead of {container=".*"}.
- **Dashboard Error:** If “Data is missing a number field,” switch visualization to “Logs.”
- **Firewall:** Ensure ports 5678, 11434, 6379, 6333-6334, 3100, and 3000 are open:
```bash
sudo ufw allow <port>
```

- **HTTPS Issues:** Verify certificates are in certs/ and paths match .env values.
- **Resource Limits:** If ollama slows down, adjust cpus/memory in docker-compose.yml.

##  Contributing
Feel free to fork this repository, submit issues, or send pull requests to improve the setup!

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.