#!/bin/bash
# =============================================================================
# Qwen3.6-27B — vLLM server (OpenAI-compatible API)
#
# Drop-in replacement for qwen3.sh on the same port 6970.
# Uses AutoRound int4 + MTP speculative decoding.
#
# API endpoint: http://localhost:6970/v1
# Health check: curl http://localhost:6970/health
#
# Hardware: RTX 3090 24GB VRAM
#   Model: Lorbus/Qwen3.6-27B-int4-AutoRound
#   MTP spec-decode: 3 draft tokens (uses built-in MTP heads)
#   Context: 131072 (128K)
# =============================================================================

VENV="$HOME/Local LLM/venv-vllm"
MODEL="$HOME/Local LLM/models/qwen3/lorbus-autoround"

if [ ! -d "$MODEL" ]; then
  echo "ERROR: Model not found at $MODEL"
  echo "Run: hf download Lorbus/Qwen3.6-27B-int4-AutoRound --local-dir \"$MODEL\""
  exit 1
fi

if [ ! -f "$VENV/bin/vllm" ]; then
  echo "ERROR: vLLM not found at $VENV"
  echo "Run: python3.11 -m venv \"$VENV\" && \"$VENV/bin/pip\" install vllm"
  exit 1
fi

echo "Starting Qwen3.6-27B (vLLM)..."
echo "  Model:   $MODEL"
echo "  Context: 131072 (128K)"
echo "  Spec:    MTP n=3"
echo "  API:     http://localhost:6970/v1"
echo ""
echo "Press Ctrl+C to stop."
echo ""

exec "$VENV/bin/vllm" serve "$MODEL" \
  --host 0.0.0.0 \
  --port 6970 \
  --served-model-name qwen3 \
  --dtype float16 \
  --gpu-memory-utilization 0.95 \
  --max-model-len 131072 \
  --max-num-seqs 1 \
  --enable-prefix-caching \
  --enable-chunked-prefill \
  --speculative-config '{"method":"mtp","num_speculative_tokens":3}' \
  --trust-remote-code
