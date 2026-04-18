#!/bin/bash
# Start SuperGemma + LiteLLM and launch Claude Code pointed at local model

export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# 1. Start SuperGemma if not running
if ! curl -s http://localhost:6969/health | grep -q "ok" 2>/dev/null; then
  echo "Starting SuperGemma4..."
  nohup ~/supergemma.sh > /tmp/supergemma.log 2>&1 &
  echo "  Waiting for model to load..."
  for i in {1..30}; do
    sleep 2
    if curl -s http://localhost:6969/health | grep -q "ok" 2>/dev/null; then
      echo "  SuperGemma ready."
      break
    fi
  done
else
  echo "SuperGemma already running."
fi

# 2. Always restart LiteLLM with supergemma config
pkill -f litellm 2>/dev/null; sleep 1
echo "Starting LiteLLM proxy (supergemma config)..."
nohup litellm --config ~/litellm-config.yaml --port 4000 > /tmp/litellm.log 2>&1 &
sleep 4
echo "  LiteLLM ready."

echo ""
echo "Launching Claude Code → SuperGemma4 (localhost:4000)"
echo "To switch back to real Claude: just run 'claude' normally"
echo ""

# 3. Launch Claude Code pointed at LiteLLM
ANTHROPIC_BASE_URL=http://localhost:4000 ANTHROPIC_API_KEY=local-supergemma claude "$@"
