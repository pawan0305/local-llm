#!/bin/bash
# =============================================================================
# Qwen3.6-35B-A3B — Full Install Script
# Hardware: RTX 3090 24GB VRAM, Ubuntu 22.04+, CUDA 12.x
# =============================================================================

set -e

LOCAL_LLM="$HOME/Local LLM"
MODELS_DIR="$LOCAL_LLM/models/qwen3"
LLAMA_DIR="$LOCAL_LLM/llama.cpp"
MODEL_FILE="Qwen3.6-35B-A3B-UD-Q4_K_M.gguf"
MODEL_REPO="unsloth/Qwen3.6-35B-A3B-GGUF"

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║     Qwen3.6-35B-A3B — Setup Script                  ║"
echo "║     Target: RTX 3090 24GB VRAM                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: Check llama.cpp ───────────────────────────────────────────────────
echo "[1/4] Checking llama.cpp..."

if [ ! -f "$LLAMA_DIR/build/bin/llama-server" ]; then
  echo "  llama.cpp not built. Building now..."
  cd "$LLAMA_DIR"
  cmake -B build -DGGML_CUDA=ON
  cmake --build build --config Release -j$(nproc)
  echo "  Build complete."
else
  echo "  llama-server found at $LLAMA_DIR/build/bin/llama-server"
  echo "  To update llama.cpp: cd '$LLAMA_DIR' && git pull && cmake --build build --config Release -j\$(nproc)"
fi

# ── Step 2: Download model ────────────────────────────────────────────────────
echo ""
echo "[2/4] Downloading Qwen3.6-35B-A3B Q4_K_M (~22.1GB)..."
mkdir -p "$MODELS_DIR"

if [ -f "$MODELS_DIR/$MODEL_FILE" ]; then
  echo "  Model already exists at $MODELS_DIR/$MODEL_FILE, skipping."
else
  if command -v hf &>/dev/null; then
    hf download "$MODEL_REPO" "$MODEL_FILE" --local-dir "$MODELS_DIR"
  else
    echo "  hf not found. Installing..."
    uv tool install "huggingface_hub[cli]"
    hf download "$MODEL_REPO" "$MODEL_FILE" --local-dir "$MODELS_DIR"
  fi
fi

# ── Step 3: Install scripts to home directory ─────────────────────────────────
echo ""
echo "[3/4] Installing wrapper scripts to home directory..."
cp "$LOCAL_LLM/qwen3/qwen3_home.sh" "$HOME/qwen3.sh"
cp "$LOCAL_LLM/qwen3/qwen3code_home.sh" "$HOME/qwen3code.sh"
chmod +x "$HOME/qwen3.sh" "$HOME/qwen3code.sh"
echo "  Scripts installed."

# ── Step 4: Install Python tools & aliases ────────────────────────────────────
echo ""
echo "[4/4] Installing uv, LiteLLM and shell aliases..."

export PATH="$HOME/.local/bin:$PATH"

# Install uv if missing
if ! command -v uv &>/dev/null && [ ! -f "$HOME/.local/bin/uv" ]; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install LiteLLM if missing
if ! command -v litellm &>/dev/null; then
  uv tool install 'litellm[proxy]'
fi

# Add Qwen3 aliases to ~/.bashrc
if ! grep -q "Qwen3 shortcuts" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" << 'ALIASES'

# Qwen3 shortcuts
alias startqwen="nohup ~/qwen3.sh > /tmp/qwen3.log 2>&1 & echo 'Qwen3 started'"
alias stopqwen="pkill -f llama-server && echo 'Qwen3 stopped'"
alias qwenlogs="tail -f /tmp/qwen3.log"
alias qwencode="~/qwen3code.sh"
ALIASES
  echo "  Aliases added to ~/.bashrc"
else
  echo "  Qwen3 aliases already in ~/.bashrc, skipping."
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║  Done! Available commands (open a new terminal):     ║"
echo "║                                                       ║"
echo "║  startqwen    — start Qwen3 server in background     ║"
echo "║  stopqwen     — stop Qwen3 server                    ║"
echo "║  qwenlogs     — watch live logs                      ║"
echo "║  qwencode     — Claude Code via Qwen3.6-35B-A3B      ║"
echo "║                                                       ║"
echo "║  Or run everything at once:  qwencode                ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""
