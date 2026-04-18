# Commands Reference

All shell aliases and scripts on this machine. Run `source ~/.bashrc` after a fresh terminal if aliases aren't found.

---

## Local LLM — Qwen3.6-35B-A3B (primary, port 6970)

| Command | Action |
|---------|--------|
| `startqwen` | Kill any running model, start Qwen3.6 in background |
| `stopqwen` | Stop Qwen3.6 server |
| `qwenlogs` | Stream live Qwen3.6 logs |
| `qwencode` | Launch Claude Code using Qwen3.6 (starts LiteLLM automatically) |
| `qwencodereview` | Launch real Claude Code to review recent qwencode sessions + suggest improvements |

## Local LLM — SuperGemma4 26B (secondary, port 6969)

| Command | Action |
|---------|--------|
| `startgemma` | Kill any running model, start SuperGemma4 in background |
| `stopgemma` | Stop SuperGemma4 server |
| `gemmalogs` | Stream live SuperGemma4 logs |
| `gemmacode` | Launch Claude Code using SuperGemma4 (starts LiteLLM automatically) |

## LiteLLM Proxy (port 4000)

| Command | Action |
|---------|--------|
| `startlitellm` | Start LiteLLM with SuperGemma config |
| `stoplitellm` | Stop LiteLLM proxy |

> Note: `qwencode` and `gemmacode` restart LiteLLM with the correct config automatically. No need to run `startlitellm` manually when using those.

## Open WebUI (port 3000)

| Command | Action |
|---------|--------|
| `startwebui` | Start Open WebUI (points to SuperGemma port 6969) |
| `stopwebui` | Stop Open WebUI |

## Hermes Agent

| Command | Action |
|---------|--------|
| `hermesreview` | Launch real Claude Code to review Hermes config + recent sessions |
| `hermes` | Start Hermes (if installed in PATH, check `~/.hermes/`) |

## Claude Code

| Command | Action |
|---------|--------|
| `claude` | Real Claude Code (Sonnet via Anthropic API) |
| `qwencode` | Claude Code via local Qwen3.6 (free, ~100 t/s) |
| `gemmacode` | Claude Code via local SuperGemma4 (free) |
| `qwencodereview` | Real Claude reviews qwencode sessions |
| `hermesreview` | Real Claude reviews Hermes sessions |

---

## Ports Quick Reference

| Service | Port | Health Check |
|---------|------|-------------|
| Qwen3.6 llama-server | 6970 | `curl http://localhost:6970/health` |
| SuperGemma4 llama-server | 6969 | `curl http://localhost:6969/health` |
| LiteLLM proxy | 4000 | `curl http://localhost:4000/health` |
| Open WebUI | 3000 | browser → http://localhost:3000 |

---

## Logs

| Command | Log file |
|---------|----------|
| `qwenlogs` | `/tmp/qwen3.log` |
| `gemmalogs` | `/tmp/supergemma.log` |
| LiteLLM logs | `/tmp/litellm.log` |
| Open WebUI logs | `/tmp/openwebui.log` |

---

## Key Locations

| Path | Contents |
|------|---------|
| `~/Local LLM/` | All LLM scripts, configs, models, llama.cpp |
| `~/Local LLM/qwen3/qwen3.sh` | Qwen3 server settings (ngl, ctx, np, etc.) |
| `~/Local LLM/qwen3/litellm-config.yaml` | LiteLLM routing + system prompt |
| `~/Local LLM/llama.cpp/` | llama.cpp source + CUDA build |
| `~/Local LLM/models/qwen3/` | Qwen3.6-35B-A3B GGUF (~22GB) |
| `~/Local LLM/models/supergemma4/` | SuperGemma4 26B GGUF (~16GB) |
| `~/.hermes/` | Hermes agent — config, skills, logs, memory |
| `~/Local LLM/CLAUDE.md` | Full context doc for Claude Code monitoring sessions |

---

## Update llama.cpp

```bash
cd ~/Local\ LLM/llama.cpp && git pull && cmake --build build --config Release -j$(nproc)
```

## Push changes to GitHub

```bash
cd ~/Local\ LLM && git add -A && git commit -m "your message" && git push
```

## GitHub Repos

- **local-llm**: https://github.com/pawan0305/local-llm
- **supergemma-setup**: https://github.com/pawan0305/supergemma-setup
