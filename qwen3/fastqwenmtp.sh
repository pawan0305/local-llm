#!/bin/bash
# =============================================================================
# Qwen3.6-27B-MTP — Start llama-server with Multi-Token Prediction speculative
# decoding (OpenAI-compatible API).
#
# MTP delivers ~1.5-2x faster generation than base Qwen3.6-27B with no quality
# loss. Requires llama.cpp >= 2026-05-16 (PR #22673) and the MTP-specific GGUF.
#
# Usage:
#   ~/fastqwenmtp.sh        # start server (foreground)
#   ~/fastqwenmtp.sh &      # start in background
#
# API endpoint: http://localhost:6970/v1
# Health check: http://localhost:6970/health
# Web UI:       http://localhost:6970
#
# Hardware: RTX 3090 24GB VRAM
#   - 999 GPU layers → full ~17.9GB model fits with ~4GB headroom
#   - MTP adds <10% memory overhead
#   - -np 1 (MTP does not support parallel slots yet)
# =============================================================================

LLAMA_DIR="$HOME/Local LLM/llama.cpp"
MODEL="$HOME/Local LLM/models/qwen3/mtp/Qwen3.6-27B-UD-Q4_K_XL.gguf"

# Sanity checks
if [ ! -f "$MODEL" ]; then
  echo "ERROR: Model not found at $MODEL"
  echo "Run: hf download unsloth/Qwen3.6-27B-MTP-GGUF 'Qwen3.6-27B-UD-Q4_K_XL.gguf' --local-dir ~/Local\ LLM/models/qwen3/mtp/"
  exit 1
fi

echo "Starting Qwen3.6-27B-MTP (fast)..."
echo "  Model:    $MODEL"
echo "  GPU layers: 999 (full model on GPU, ~17.9GB)"
echo "  Context:  215040 tokens (210K, KV cache quantized to q4_0)"
echo "  MTP:      --spec-type draft-mtp --spec-draft-n-max 6 (~1.5-2x speedup)"
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
  --spec-type draft-mtp \
  --spec-draft-n-max 6 \
  --temp 0.6 \
  --top-k 20 \
  --top-p 0.95 \
  --min-p 0.0 \
  --presence-penalty 0.0 \
  --host 0.0.0.0 \
  --port 6970 \
  --alias qwen3
