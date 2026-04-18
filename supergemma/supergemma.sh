#!/bin/bash
# =============================================================================
# SuperGemma4 26B — Start llama-server (OpenAI-compatible API)
#
# Usage:
#   ~/supergemma.sh              # start server (foreground)
#   ~/supergemma.sh &            # start in background
#
# API endpoint: http://localhost:8080/v1
# Health check: http://localhost:8080/health
# Web UI:       http://localhost:8080 (built-in chat UI)
#
# Hardware tested: RTX 3090 24GB VRAM + 32GB RAM
#   - 999 GPU layers → full model fits in 24GB VRAM
#   - Speed: ~60-80+ tokens/sec generation
#   - KV cache quantized to q4_0 → enables 128K context within 24GB VRAM
# =============================================================================

LLAMA_DIR="$HOME/Local LLM/llama.cpp"
MODEL="$HOME/Local LLM/models/supergemma4/supergemma4-26b-Q4_K_M.gguf"
TEMPLATE="$LLAMA_DIR/models/templates/google-gemma-4-31B-it-interleaved.jinja"

# Sanity checks
if [ ! -f "$MODEL" ]; then
  echo "ERROR: Model not found at $MODEL"
  echo "Run ./install.sh first."
  exit 1
fi

if [ ! -f "$TEMPLATE" ]; then
  echo "ERROR: Chat template not found at $TEMPLATE"
  exit 1
fi

echo "Starting SuperGemma4 26B..."
echo "  Model:    $MODEL"
echo "  GPU layers: 999 (full model on GPU)"
echo "  Context:  131072 tokens (128K, KV cache quantized to q4_0)"
echo "  API:      http://localhost:6969/v1"
echo "  UI:       http://localhost:6969"
echo ""
echo "Press Ctrl+C to stop."
echo ""

exec "$LLAMA_DIR/build/bin/llama-server" \
  -m "$MODEL" \
  --chat-template-file "$TEMPLATE" \
  -ngl 999 \
  --ctx-size 131072 \
  --cache-type-k q4_0 \
  --cache-type-v q4_0 \
  -t 8 \
  --reasoning off \
  --host 0.0.0.0 \
  --port 6969 \
  --alias supergemma4
