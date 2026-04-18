#!/bin/bash
# =============================================================================
# Local LLM — Master Install Script
#
# Restores the full local LLM setup on a fresh Ubuntu machine.
# Tested on: Ubuntu 24.04+, RTX 3090 24GB VRAM, 32GB RAM, CUDA 12.4+
#
# Usage:
#   git clone https://github.com/pawan0305/local-llm.git ~/Local\ LLM
#   cd ~/Local\ LLM
#   chmod +x install.sh && ./install.sh
#
# What this installs:
#   - NVIDIA CUDA toolkit
#   - llama.cpp (built from source with CUDA)
#   - uv (Python package manager)
#   - LiteLLM proxy
#   - huggingface-cli (hf)
#   - Shell aliases for all models
#   - supergemma-setup repo (for SuperGemma4 26B)
#   - Qwen3.6-35B-A3B scripts
#   - Home directory wrapper scripts
# =============================================================================

set -e

LOCAL_LLM="$HOME/Local LLM"
LLAMA_DIR="$LOCAL_LLM/llama.cpp"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Local LLM — Full Setup Script                    ║"
echo "║         Target: RTX 3090 24GB + Ubuntu + CUDA            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# ── Step 1: System dependencies ───────────────────────────────────────────────
echo "[1/8] Installing system dependencies..."
sudo apt update -q
sudo apt install -y build-essential cmake git wget curl

# ── Step 2: NVIDIA driver + CUDA toolkit ──────────────────────────────────────
echo ""
echo "[2/8] Checking NVIDIA driver and CUDA toolkit..."

if ! command -v nvidia-smi &>/dev/null; then
  echo "  Installing NVIDIA driver 580..."
  sudo apt install -y nvidia-driver-580
  echo "  ⚠ Reboot required after driver install. Re-run this script after reboot."
  echo "  Run: sudo reboot"
  exit 0
else
  echo "  NVIDIA driver found: $(nvidia-smi --query-gpu=driver_version --format=csv,noheader)"
fi

if ! command -v nvcc &>/dev/null; then
  echo "  Installing CUDA toolkit..."
  sudo apt install -y nvidia-cuda-toolkit
else
  echo "  CUDA toolkit found: $(nvcc --version | grep release | awk '{print $5}' | tr -d ',')"
fi

# Register Ollama CUDA libs if present (needed for older llama.cpp builds)
if [ -d "/usr/local/lib/ollama/cuda_v12" ] && [ ! -f "/etc/ld.so.conf.d/ollama-cuda12.conf" ]; then
  echo "/usr/local/lib/ollama/cuda_v12" | sudo tee /etc/ld.so.conf.d/ollama-cuda12.conf
  sudo ldconfig
fi

# ── Step 3: Clone & build llama.cpp ───────────────────────────────────────────
echo ""
echo "[3/8] Setting up llama.cpp..."

if [ ! -d "$LLAMA_DIR" ]; then
  git clone https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
else
  echo "  llama.cpp exists, pulling latest..."
  git -C "$LLAMA_DIR" pull
fi

echo "  Building with CUDA support (this takes 5-10 minutes)..."
cd "$LLAMA_DIR"
cmake -B build -DGGML_CUDA=ON
cmake --build build --config Release -j$(nproc)
echo "  Build complete."

# Symlink for rpath compatibility
if [ ! -L "$HOME/llama.cpp" ]; then
  ln -s "$LOCAL_LLM/llama.cpp" "$HOME/llama.cpp"
  echo "  Symlink created: ~/llama.cpp → ~/Local LLM/llama.cpp"
fi

# ── Step 4: Python tools ──────────────────────────────────────────────────────
echo ""
echo "[4/8] Installing Python tools (uv, LiteLLM, huggingface-cli)..."
export PATH="$HOME/.local/bin:$PATH"

if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi

if ! command -v litellm &>/dev/null; then
  uv tool install 'litellm[proxy]'
fi

if ! command -v hf &>/dev/null; then
  uv tool install "huggingface_hub[cli]"
fi

echo "  Tools installed."

# ── Step 5: Clone supergemma-setup ────────────────────────────────────────────
echo ""
echo "[5/8] Setting up SuperGemma4..."

SUPERGEMMA_DIR="$LOCAL_LLM/supergemma-setup"
if [ ! -d "$SUPERGEMMA_DIR" ]; then
  git clone https://github.com/pawan0305/supergemma-setup.git "$SUPERGEMMA_DIR"
else
  echo "  supergemma-setup already exists, pulling..."
  git -C "$SUPERGEMMA_DIR" pull
fi

# Create models directory
mkdir -p "$LOCAL_LLM/models/supergemma4"
mkdir -p "$LOCAL_LLM/models/qwen3"

# ── Step 6: Install home scripts ──────────────────────────────────────────────
echo ""
echo "[6/8] Installing home directory scripts..."

# SuperGemma
cp "$LOCAL_LLM/supergemma/supergemma.sh" "$HOME/supergemma.sh"
cp "$LOCAL_LLM/supergemma/gemmacode.sh" "$HOME/gemmacode.sh"
cp "$LOCAL_LLM/supergemma/litellm-config.yaml" "$HOME/litellm-config.yaml"
chmod +x "$HOME/supergemma.sh" "$HOME/gemmacode.sh"

# Qwen3
cat > "$HOME/qwen3.sh" << 'EOF'
#!/bin/bash
exec "$HOME/Local LLM/qwen3/qwen3.sh" "$@"
EOF
cat > "$HOME/qwen3code.sh" << 'EOF'
#!/bin/bash
exec "$HOME/Local LLM/qwen3/qwen3code.sh" "$@"
EOF
chmod +x "$HOME/qwen3.sh" "$HOME/qwen3code.sh" \
  "$LOCAL_LLM/qwen3/qwen3.sh" \
  "$LOCAL_LLM/qwen3/qwen3code.sh" \
  "$LOCAL_LLM/qwen3/install.sh"

echo "  Scripts installed."

# ── Step 7: Shell aliases ─────────────────────────────────────────────────────
echo ""
echo "[7/8] Adding shell aliases..."

if ! grep -q "Local LLM — SuperGemma" "$HOME/.bashrc"; then
  cat >> "$HOME/.bashrc" << 'ALIASES'

# Local LLM — SuperGemma4 shortcuts
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"
alias startgemma="pkill -f llama-server 2>/dev/null; sleep 1; nohup ~/supergemma.sh > /tmp/supergemma.log 2>&1 & echo 'SuperGemma starting...'"
alias stopgemma="pkill -f llama-server 2>/dev/null && echo 'SuperGemma stopped' || echo 'SuperGemma was not running'"
alias gemmalogs="tail -f /tmp/supergemma.log"
alias startwebui="OPENAI_API_BASE_URL=http://localhost:6969/v1 OPENAI_API_KEY=none nohup open-webui serve --port 3000 > /tmp/openwebui.log 2>&1 & echo 'Open WebUI started'"
alias stopwebui="pkill -f open-webui && echo 'Open WebUI stopped'"
alias startlitellm="nohup litellm --config ~/litellm-config.yaml --port 4000 > /tmp/litellm.log 2>&1 & echo 'LiteLLM started'"
alias stoplitellm="pkill -f litellm 2>/dev/null && echo 'LiteLLM stopped' || echo 'LiteLLM was not running'"
alias gemmacode="~/gemmacode.sh"

# Local LLM — Qwen3.6-35B-A3B shortcuts
alias startqwen="pkill -f llama-server 2>/dev/null; sleep 1; nohup ~/qwen3.sh > /tmp/qwen3.log 2>&1 & echo 'Qwen3 starting...'"
alias stopqwen="pkill -f llama-server 2>/dev/null && echo 'Qwen3 stopped' || echo 'Qwen3 was not running'"
alias qwenlogs="tail -f /tmp/qwen3.log"
alias qwencode="~/qwen3code.sh"
ALIASES
  echo "  Aliases added to ~/.bashrc"
else
  echo "  Aliases already present, skipping."
fi

# ── Step 8: Download models ───────────────────────────────────────────────────
echo ""
echo "[8/8] Model downloads (optional)..."
echo ""
echo "  To download SuperGemma4 26B (~16GB):"
echo "    hf download Jiunsong/supergemma4-26b-uncensored-gguf-v2 supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf \\"
echo "      --local-dir ~/Local\ LLM/models/supergemma4/"
echo "    mv ~/Local\ LLM/models/supergemma4/supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf \\"
echo "      ~/Local\ LLM/models/supergemma4/supergemma4-26b-Q4_K_M.gguf"
echo ""
echo "  To download Qwen3.6-35B-A3B (~22GB):"
echo "    hf download unsloth/Qwen3.6-35B-A3B-GGUF Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \\"
echo "      --local-dir ~/Local\ LLM/models/qwen3/"
echo ""

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Setup complete! Open a new terminal, then:              ║"
echo "║                                                           ║"
echo "║  startqwen    — start Qwen3.6-35B-A3B (port 6970)       ║"
echo "║  qwencode     — Claude Code via Qwen3.6                  ║"
echo "║  startgemma   — start SuperGemma4 (port 6969)            ║"
echo "║  gemmacode    — Claude Code via SuperGemma4              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
