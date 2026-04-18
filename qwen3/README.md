# Qwen3.6-35B-A3B — Local Setup

Run **Qwen3.6-35B-A3B** (Qwen's MoE model) fully locally via llama.cpp with an OpenAI-compatible API.

**Hardware:** RTX 3090 24GB VRAM + 32GB RAM

---

## Model Specs

| Spec | Value |
|------|-------|
| Total Parameters | 35B |
| Active Parameters | ~3B (MoE, 8 activated / 256 total experts) |
| Context Length | 262K native |
| Architecture | Gated DeltaNet + MoE hybrid |
| GGUF Source | [unsloth/Qwen3.6-35B-A3B-GGUF](https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF) |
| Quantization | UD-Q4_K_M (~22.1GB) |

---

## First-Time Install

```bash
~/Local\ LLM/qwen3/install.sh
```

This will:
1. Check llama.cpp is built (builds if needed)
2. Download the UD-Q4_K_M GGUF (~22.1GB) from unsloth
3. Install shell aliases

---

## Start the Server

```bash
~/qwen3.sh           # foreground (Ctrl+C to stop)
startqwen            # background (alias)
```

| Endpoint | URL |
|----------|-----|
| OpenAI-compatible API | `http://localhost:6970/v1` |
| Health check | `http://localhost:6970/health` |
| Built-in chat UI | `http://localhost:6970` |

---

## Use with Claude Code

```bash
qwencode            # starts Qwen3 + LiteLLM proxy, launches Claude Code
~/qwen3code.sh      # same thing
```

---

## Performance (RTX 3090 24GB)

| Metric | Value |
|--------|-------|
| GPU layers | 999 (full model on GPU) |
| VRAM used | ~22.1GB of 24GB |
| Generation speed | ~80-100+ t/s (MoE — only 3B active params execute) |
| Context | 32K default (model supports 262K) |

---

## Server Settings

Key flags in `qwen3.sh`:

| Flag | Value | Reason |
|------|-------|--------|
| `--jinja` | on | Required for Qwen3 chat template |
| `-ngl 999` | full offload | Fits in 24GB VRAM |
| `--temp 0.6` | recommended | Qwen3 official recommendation |
| `--top-k 20` | recommended | Qwen3 official recommendation |
| `--presence-penalty 1.5` | recommended | Reduces repetition |
| `-fa` | flash attention | Faster inference |
| `-sm row` | row split | Better for single-GPU |

---

## Thinking Mode

Qwen3 has built-in thinking/reasoning. Control it per-request:

```json
{ "chat_template_kwargs": { "thinking": true } }   // enable thinking
{ "chat_template_kwargs": { "thinking": false } }  // disable thinking (faster)
```

---

## Increase Context (Optional)

The model natively supports 262K tokens. To use more context (requires more VRAM for KV cache):

```bash
# In qwen3.sh, change:
--ctx-size 65536    # 64K (uses ~1.2GB KV cache at q4_0)
--ctx-size 131072   # 128K (uses ~2.4GB KV cache at q4_0)
```

With 24GB VRAM and 22.1GB model, ~1.9GB is available for KV cache.
Stick to 32K for safe margin, or drop to Q3 quantization for larger contexts.
