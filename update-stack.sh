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
