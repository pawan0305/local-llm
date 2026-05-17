#!/bin/bash
# Start Qwen3.6-27B-MTP (fast) + LiteLLM and launch Claude Code pointed at local model.
# Same LiteLLM config as qwencode — model on port 6970, proxy on 4000, thinking OFF.

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

QWEN_CONFIG="$HOME/Local LLM/qwen3/litellm-config.yaml"

# 1. Start FastQwenMTP if not running
if ! curl -s http://localhost:6970/health | grep -q "ok" 2>/dev/null; then
  echo "Starting Qwen3.6-27B-MTP (fast)..."
  nohup "$HOME/Local LLM/qwen3/fastqwenmtp.sh" > /tmp/fastqwenmtp.log 2>&1 &
  echo "  Waiting for model to load (~30-60s)..."
  for i in {1..45}; do
    sleep 2
    if curl -s http://localhost:6970/health | grep -q "ok" 2>/dev/null; then
      echo "  FastQwenMTP ready."
      break
    fi
  done
else
  echo "Server on :6970 already running (could be qwen3 or fastqwenmtp — check qwenlogs / fastqwenmtplogs)."
fi

# 2. Always restart LiteLLM with qwen3 config
pkill -f litellm 2>/dev/null; sleep 1
echo "Starting LiteLLM proxy (qwen3 config)..."
nohup litellm --config "$QWEN_CONFIG" --port 4000 > /tmp/litellm.log 2>&1 &
sleep 4
echo "  LiteLLM ready."

echo ""
echo "Launching Claude Code → Qwen3.6-27B-MTP (localhost:4000)"
echo "To switch back to real Claude: just run 'claude' normally"
echo ""

# 3. Launch Claude Code pointed at LiteLLM (Telegram disabled — real claude session keeps the connection)
ANTHROPIC_BASE_URL=http://localhost:4000 ANTHROPIC_API_KEY=local-qwen3 claude \
  --settings '{"enabledPlugins": {"telegram@claude-plugins-official": false}}' \
  "$@"
