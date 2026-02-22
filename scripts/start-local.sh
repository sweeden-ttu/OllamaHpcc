#!/bin/bash
# start-local.sh - Start local Ollama containers

PORTS=(55077 55088 66044 66033)
MODELS=("granite4" "deepseek-r1" "qwen2.5-coder" "codellama")
NAMES=("ollama-granite4" "ollama-thinking" "ollama-qwen" "ollama-code")

echo "Starting local Ollama containers..."

for i in "${!PORTS[@]}"; do
    PORT="${PORTS[$i]}"
    MODEL="${MODELS[$i]}"
    NAME="${NAMES[$i]}"
    
    echo "Starting $NAME on port $PORT with model $MODEL..."
    
    # Stop existing container if present
    podman stop "$NAME" 2>/dev/null
    podman rm "$NAME" 2>/dev/null
    
    # Start new container
    podman run -d --name "$NAME" \
        -p "$PORT:$PORT" \
        -v ollama:/root/.ollama \
        -e OLLAMA_HOST=0.0.0.0:$PORT \
        quay.io/ollama/ollama serve &
        
    # Pull model in background
    sleep 2
    podman exec "$NAME" ollama pull "$MODEL" &
done

echo "All containers starting..."
echo "Monitor with: podman ps"
