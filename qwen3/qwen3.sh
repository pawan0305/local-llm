#!/bin/bash
# =============================================================================
# Qwen3.6-35B-A3B — Start llama-server (OpenAI-compatible API)
#
# Usage:
#   ~/qwen3.sh              # start server (foreground)
#   ~/qwen3.sh &            # start in background
#
# API endpoint: http://localhost:6970/v1
# Health check: http://localhost:6970/health
# Web UI:       http://localhost:6970
#
# Hardware: RTX 3090 24GB VRAM
#   - 999 GPU layers → full 22.1GB model fits in 24GB VRAM
#   - Speed: ~80-100+ tokens/sec generation (MoE, only 3B active params)
#   - KV cache quantized to q4_0 → enables 256K context comfortably
# =============================================================================

LLAMA_DIR="$HOME/Local LLM/llama.cpp"
MODEL="$HOME/Local LLM/models/qwen3/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf"

# Sanity checks
if [ ! -f "$MODEL" ]; then
  echo "ERROR: Model not found at $MODEL"
  echo "Run: $HOME/Local LLM/qwen3/install.sh"
  exit 1
fi

echo "Starting Qwen3.6-35B-A3B..."
echo "  Model:    $MODEL"
echo "  GPU layers: 999 (full model on GPU, ~22.1GB)"
echo "  Context:  262144 tokens (256K, KV cache quantized to q4_0)"
echo "  API:      http://localhost:6970/v1"
echo ""
echo "  Web UI →  http://localhost:6970"
echo ""
echo "Press Ctrl+C to stop."
echo ""

exec "$LLAMA_DIR/build/bin/llama-server" \
  -m "$MODEL" \
  --jinja \
  --reasoning off \
  -ngl 999 \
  -np 2 \
  --ctx-size 262144 \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  --flash-attn on \
  -t 8 \
  --temp 0.6 \
  --top-k 20 \
  --top-p 0.95 \
  --min-p 0.0 \
  --presence-penalty 1.5 \
  --host 0.0.0.0 \
  --port 6970 \
  --alias qwen3
