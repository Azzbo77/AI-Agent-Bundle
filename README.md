# AI-Agent-Bundle

This project sets up a local, self-hosted AI chat system using n8n for workflow automation, Ollama for running large language models (LLMs), Redis for chat memory, and Qdrant for vector storage. It’s designed to run in Docker, leveraging GPU acceleration for Ollama, and provides a foundation for building conversational AI applications with persistent context and similarity search capabilities.

## Features

- Chat Interface: Trigger workflows via chat messages in n8n.
- AI Model: Uses Ollama with models like llama3.1:8b (~4.7 GB, tool-supporting) for chat responses.
- Memory: Stores conversation history in Redis for context-aware responses.
- Vector Storage: Saves embeddings in Qdrant for similarity search or long-term memory.
- Local Deployment: Runs entirely on your machine with Docker, no cloud dependencies.

## Prerequisites

- Docker: Installed and running (with Docker Compose support).
- NVIDIA GPU: Optional but recommended for Ollama (requires NVIDIA Container Toolkit).
- Hardware: At least 16 GB RAM, 8 GB VRAM if using GPU, and 20 GB free disk space.
- OS: Tested on Linux (e.g., Ubuntu); should work on macOS/Windows with Docker adjustments.

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
**3. Start the Containers**
```bash
sudo docker compose up -d
```
**4. Pull the Ollama Model**
- Download the llama3.1:8b model (~4.7 GB, supports tools):
```bash
sudo docker exec -it ollama-n8n-chat-ollama-1 ollama pull llama3.1:8b
```
**5. Configure Qdrant Collection**
- Create a collection for vector storage (assuming 4096 dimensions for llama3.1):
```bash
curl -X PUT http://<yourip>:6333/collections/my_collection \
  -H "Content-Type: application/json" \
  -d '{"vectors": {"size": 4096, "distance": "Cosine"}}'
```
**6. Access n8n**
- Open your browser: http://<hostip>:5678
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

- **Chat:** Send messages to http://<hostip>:5678/webhook/chat (configure webhook as needed).
- **Memory:** Conversation history is stored in Redis.
- **Vectors:** Embeddings are saved in Qdrant’s my_collection for similarity search.

## Troubleshooting
- Check Logs:
```bash
sudo docker logs ollama-n8n-chat-n8n-1
sudo docker logs ollama-n8n-chat-ollama-1
sudo docker logs ollama-n8n-chat-redis-1
sudo docker logs ollama-n8n-chat-qdrant-1
```
- Firewall: Ensure ports 5678, 11434, 6379, and 6333 are open:
bash
```
sudo ufw allow 5678
sudo ufw allow 11434
sudo ufw allow 6379
sudo ufw allow 6333
```

##  Contributing
Feel free to fork this repository, submit issues, or send pull requests to improve the setup!

## License
This project is licensed under the MIT License - see the LICENSE file for details.
