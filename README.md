# Local LLM Setup

Complete local AI inference stack for **pawan0305** — two models, OpenAI-compatible API, Claude Code integration.

**Hardware:** RTX 3090 24GB VRAM + 32GB RAM | Ubuntu | CUDA 12.4

---

## Quick Restore (fresh machine)

```bash
git clone https://github.com/pawan0305/local-llm.git ~/Local\ LLM
cd ~/Local\ LLM
chmod +x install.sh && ./install.sh
```

Then download models (see [Models](#models) section), open a new terminal, and run `startqwen` or `startgemma`.

---

## Directory Layout

```
~/Local LLM/                        ← this repo
├── install.sh                      ← master installer (run this first)
├── README.md
├── supergemma/
│   ├── supergemma.sh               ← llama-server launcher (port 6969)
│   ├── gemmacode.sh                ← Claude Code via SuperGemma
│   └── litellm-config.yaml         ← LiteLLM config for SuperGemma
├── qwen3/
│   ├── qwen3.sh                    ← llama-server launcher (port 6970)
│   ├── qwen3code.sh                ← Claude Code via Qwen3.6
│   ├── litellm-config.yaml         ← LiteLLM config for Qwen3.6
│   ├── install.sh                  ← Qwen3-specific installer
│   └── README.md
│
├── llama.cpp/                      ← git clone (excluded from this repo)
├── models/
│   ├── supergemma4/                ← excluded from this repo
│   │   └── supergemma4-26b-Q4_K_M.gguf
│   └── qwen3/                     ← excluded from this repo
│       └── Qwen3.6-35B-A3B-UD-Q4_K_M.gguf
└── supergemma-setup/               ← git clone (excluded from this repo)
```

**Home directory wrappers** (installed by `install.sh`):
- `~/supergemma.sh` — thin wrapper
- `~/gemmacode.sh` — thin wrapper  
- `~/qwen3.sh` → `~/Local LLM/qwen3/qwen3.sh`
- `~/qwen3code.sh` → `~/Local LLM/qwen3/qwen3code.sh`
- `~/litellm-config.yaml` — SuperGemma LiteLLM config

---

## Models

### Qwen3.6-35B-A3B (primary, port 6970)

| Spec | Value |
|------|-------|
| Total params | 35B |
| Active params | 3B (MoE) |
| Context | 262K native |
| Quantization | UD-Q4_K_M (22.1GB, imatrix calibrated) |
| Source | [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) |
| Speed | ~100 t/s on RTX 3090 |

Download:
```bash
hf download unsloth/Qwen3.6-35B-A3B-GGUF Qwen3.6-35B-A3B-UD-Q4_K_M.gguf \
  --local-dir ~/Local\ LLM/models/qwen3/
```

### SuperGemma4 26B (secondary, port 6969)

| Spec | Value |
|------|-------|
| Total params | 26B (Gemma 4 MoE) |
| Quantization | Q4_K_M (16GB) |
| Source | [Jiunsong/supergemma4-26b-uncensored-gguf-v2](https://huggingface.co/Jiunsong/supergemma4-26b-uncensored-gguf-v2) |

Download:
```bash
hf download Jiunsong/supergemma4-26b-uncensored-gguf-v2 \
  supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf \
  --local-dir ~/Local\ LLM/models/supergemma4/
mv ~/Local\ LLM/models/supergemma4/supergemma4-26b-uncensored-fast-v2-Q4_K_M.gguf \
  ~/Local\ LLM/models/supergemma4/supergemma4-26b-Q4_K_M.gguf
```

---

## Commands

| Command | Action |
|---------|--------|
| `startqwen` | Start Qwen3.6 server in background |
| `stopqwen` | Stop Qwen3.6 server |
| `qwenlogs` | Watch Qwen3.6 live logs |
| `qwencode` | Launch Claude Code via Qwen3.6 |
| `startgemma` | Start SuperGemma4 server in background |
| `stopgemma` | Stop SuperGemma4 server |
| `gemmalogs` | Watch SuperGemma4 live logs |
| `gemmacode` | Launch Claude Code via SuperGemma4 |
| `startlitellm` | Start LiteLLM proxy (SuperGemma config) |
| `stoplitellm` | Stop LiteLLM proxy |
| `startwebui` | Start Open WebUI on port 3000 |

---

## Ports

| Service | Port |
|---------|------|
| Qwen3.6 llama-server | 6970 |
| SuperGemma4 llama-server | 6969 |
| LiteLLM proxy | 4000 |
| Open WebUI | 3000 |

---

## Architecture

```
Claude Code / Agent
      │
      ▼
LiteLLM Proxy (port 4000)          ← qwencode/gemmacode start this
      │   translates Anthropic API → OpenAI format
      ▼
llama-server (port 6970 or 6969)   ← startqwen/startgemma
      │   runs the GGUF model on GPU
      ▼
RTX 3090 24GB VRAM
```

**Note:** Hermes agent connects directly to llama-server port 6970 (no LiteLLM needed).
Config at `~/.hermes/config.yaml` — model: `custom/qwen3`, provider: `custom`, base_url: `http://localhost:6970/v1`

---

## Updating llama.cpp

```bash
cd ~/Local\ LLM/llama.cpp
git pull
cmake --build build --config Release -j$(nproc)
```

---

## Key Settings (Qwen3.6)

- `-ngl 999` — full GPU offload (22.1GB fits in 24GB VRAM)
- `-np 2` — 2 parallel sessions (for simultaneous Claude Code + Hermes)
- `--ctx-size 262144` — 256K context (model native limit)
- `--cache-type-k/v q4_0` — quantized KV cache to save VRAM
- `--reasoning off` — thinking disabled (optimized for agentic use)
- `--flash-attn on` — flash attention enabled

---

## VRAM Budget (RTX 3090 24GB)

| Component | VRAM |
|-----------|------|
| Model weights (UD-Q4_K_M) | ~20.6 GB |
| KV cache (256K × 2 sessions, q4_0) | ~0.7 GB |
| Recurrent state (DeltaNet layers) | ~0.3 GB |
| Compute buffers | ~0.8 GB |
| **Total** | **~22.4 GB** |
| Free | ~1.6 GB |
