#!/bin/bash
# Start Qwen3.6-27B via vLLM and launch Claude Code pointed at local model
# Faster alternative to qwen3code.sh (~85 TPS vs ~60 TPS)

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

QWEN_CONFIG="$HOME/Local LLM/qwen3/litellm-config.yaml"
VENV="$HOME/Local LLM/venv-vllm"

# 1. Start vLLM if not running
if ! curl -s http://localhost:6970/health | grep -q "ok" 2>/dev/null; then
  echo "Starting Qwen3.6-27B (vLLM)..."
  nohup "$HOME/Local LLM/qwen3/vllm.sh" > /tmp/vllm.log 2>&1 &
  echo "  Waiting for model to load (~60-90s for vLLM)..."
  for i in {1..60}; do
    sleep 3
    if curl -s http://localhost:6970/health | grep -q "ok" 2>/dev/null; then
      echo "  vLLM ready."
      break
    fi
  done
else
  echo "vLLM already running."
fi

# 2. Always restart LiteLLM with qwen3 config
pkill -f litellm 2>/dev/null; sleep 1
echo "Starting LiteLLM proxy (qwen3 config)..."
nohup litellm --config "$QWEN_CONFIG" --port 4000 > /tmp/litellm.log 2>&1 &
sleep 4
echo "  LiteLLM ready."

echo ""
echo "Launching Claude Code → Qwen3.6-27B via vLLM (localhost:4000)"
echo "To switch back to real Claude: run 'claude' normally"
echo ""

ANTHROPIC_BASE_URL=http://localhost:4000 ANTHROPIC_API_KEY=local-qwen3 claude \
  --settings '{"enabledPlugins": {"telegram@claude-plugins-official": false}}' \
  "$@"
