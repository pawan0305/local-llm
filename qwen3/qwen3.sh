#!/bin/bash
# =============================================================================
# Qwen3.6-27B — Start llama-server (OpenAI-compatible API)
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
#   - 999 GPU layers → full ~18GB model fits with 6GB headroom
#   - Hybrid DeltaNet+Attention: KV cache only needed for 16/64 attention layers
#   - 256K context fits comfortably at -np 1 with q4_0 KV cache
# =============================================================================

LLAMA_DIR="$HOME/Local LLM/llama.cpp"
MODEL="$HOME/Local LLM/models/qwen3/Qwen3.6-27B-UD-Q4_K_XL.gguf"

# Sanity checks
if [ ! -f "$MODEL" ]; then
  echo "ERROR: Model not found at $MODEL"
  echo "Run: hf download unsloth/Qwen3.6-27B-GGUF 'Qwen3.6-27B-UD-Q4_K_XL.gguf' --local-dir ~/Local\ LLM/models/qwen3/"
  exit 1
fi

echo "Starting Qwen3.6-27B..."
echo "  Model:    $MODEL"
echo "  GPU layers: 999 (full model on GPU, ~18GB)"
echo "  Context:  215040 tokens (210K, KV cache quantized to q4_0)"
echo "  API:      http://localhost:6970/v1"
echo ""
echo "  Web UI →  http://localhost:6970"
echo ""
echo "Press Ctrl+C to stop."
echo ""

exec "$LLAMA_DIR/build/bin/llama-server" \
  -m "$MODEL" \
  --jinja \
  --reasoning on \
  -ngl 999 \
  -np 1 \
  --ctx-size 215040 \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  --flash-attn on \
  -t 8 \
  --ubatch-size 2048 \
  --temp 0.6 \
  --top-k 20 \
  --top-p 0.95 \
  --min-p 0.0 \
  --presence-penalty 0.0 \
  --host 0.0.0.0 \
  --port 6970 \
  --alias qwen3
