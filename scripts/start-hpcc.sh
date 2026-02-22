#!/bin/bash
# start-hpcc.sh - Submit Ollama job to HPCC

PARTITION="${1:-matador}"
GPUS="${2:-1}"
TIME="${3:-04:00:00}"
PORT="${4:-55077}"
MODEL="${5:-granite4}"
JOB_NAME="ollama-${MODEL}"

cat << EOF > /tmp/${JOB_NAME}.sh
#!/bin/bash
#SBATCH -J ${JOB_NAME}
#SBATCH -o %x.o%j
#SBATCH -e %x.e%j
#SBATCH -p ${PARTITION}
#SBATCH --gpus-per-node=${GPUS}
#SBATCH -t ${TIME}

module load gcc cuda podman

podman run -d --name ollama-${MODEL} \
  -p ${PORT}:${PORT} \
  -v ollama:/root/.ollama \
  -e OLLAMA_HOST=0.0.0.0:${PORT} \
  quay.io/ollama/ollama serve

podman exec ollama-${MODEL} ollama pull ${MODEL}

echo "Ollama running on port ${PORT}"
EOF

chmod +x /tmp/${JOB_NAME}.sh
echo "Submitting job to HPCC..."
sbatch /tmp/${JOB_NAME}.sh
