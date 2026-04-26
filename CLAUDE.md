# Local LLM — Claude Code Context

This file gives you (Claude Code / real Sonnet) full context to monitor, debug, and improve the local LLM stack running on this machine. Read this before doing anything.

---

## Who you are talking to

**pawan0305** — the owner of this machine. He runs local LLMs for:
- **qwencode** — Claude Code sessions using Qwen3.6-27B instead of real Claude (saves API credits)
- **Hermes agent** — autonomous agent tasks
- **OpenClaw** — agent workflows

He wants you (real Claude) to review what the local models are doing, catch problems, and suggest improvements.

---

## The Stack

```
Claude Code (real Sonnet) ← you are here
      │
      ▼
qwencode / vllmcode / Hermes / OpenClaw / opencode
      │
      ▼
LiteLLM proxy (port 4000)   ← ~/Local LLM/qwen3/litellm-config.yaml
      │                         (used by Claude Code harnesses only)
      ▼
llama-server OR vLLM (port 6970)
  llama-server: ~/Local LLM/qwen3/qwen3.sh  (Qwen3.6-27B UD-Q4_K_XL GGUF)
  vLLM:         ~/Local LLM/qwen3/vllm.sh   (Lorbus AutoRound int4)
      │
      ▼
Qwen3.6-27B                 ← ~/Local LLM/models/qwen3/
RTX 3090 24GB VRAM
```

**Two server options on the same port 6970 — pick one:**
| Server | Script | Model | Est. TPS |
|--------|--------|-------|----------|
| llama-server (llama.cpp) | `qwen3.sh` | UD-Q4_K_XL GGUF | ~60 TPS |
| vLLM | `vllm.sh` | Lorbus AutoRound int4 | ~85 TPS |

---

## Key Files

| File | Purpose |
|------|---------|
| `~/Local LLM/qwen3/qwen3.sh` | llama-server launch (GGUF, port 6970, ctx 131072) |
| `~/Local LLM/qwen3/vllm.sh` | vLLM launch (AutoRound int4, port 6970, ctx 131072) |
| `~/Local LLM/qwen3/qwen3code.sh` | Claude Code via llama-server + LiteLLM |
| `~/Local LLM/qwen3/vllmcode.sh` | Claude Code via vLLM + LiteLLM |
| `~/Local LLM/qwen3/litellm-config.yaml` | LiteLLM model routing + system prompt injection |
| `~/.hermes/config.yaml` | Hermes agent config — model, provider, base_url: localhost:6970 |
| `~/.hermes/SOUL.md` | Hermes persona |
| `~/.config/opencode/config.json` | OpenCode config — points to qwen3 on port 6970 |
| `/tmp/qwen3.log` | Live llama-server log |
| `/tmp/vllm.log` | Live vLLM log |
| `/tmp/litellm.log` | Live LiteLLM proxy log |
| `~/.claude/projects/-home-pawan/*.jsonl` | Claude Code session histories |

---

## Current Qwen3 Server Settings (llama-server)

```bash
-ngl 999              # full GPU offload
-np 1                 # 1 parallel session
--ctx-size 131072     # 128K context (reduced from 256K for speed + headroom)
--cache-type-k q4_0   # quantized KV cache (~2GB at 128K)
--cache-type-v q4_0
--flash-attn on
--reasoning on        # thinking enabled — useful for Hermes / coding agents
--temp 0.6
--top-k 20
--presence-penalty 0.0
```

**VRAM budget:** ~16.4GB model + ~2GB KV cache = ~18.4GB / 24GB. ~5.6GB headroom.

## vLLM Server Settings

```bash
--dtype float16
--gpu-memory-utilization 0.95
--max-model-len 131072
--max-num-seqs 1
--enable-prefix-caching
--enable-chunked-prefill
--speculative-config '{"method":"mtp","num_speculative_tokens":3}'
```

Model: `Lorbus/Qwen3.6-27B-int4-AutoRound` at `~/Local LLM/models/qwen3/lorbus-autoround/`
venv: `~/Local LLM/venv-vllm/` (Python 3.11)

---

## Ports

| Service | Port | Health check |
|---------|------|-------------|
| Qwen3.6 llama-server | 6970 | `curl http://localhost:6970/health` |
| SuperGemma4 llama-server | 6969 | `curl http://localhost:6969/health` |
| LiteLLM proxy | 4000 | `curl http://localhost:4000/health` |
| Open WebUI | 3000 | browser only |

---

## Shell Aliases (in ~/.bashrc)

```bash
# llama-server (GGUF)
startqwen / stopqwen / qwenlogs / qwencode

# vLLM (AutoRound int4, faster)
startvllm / stopvllm / vllmlogs / vllmcode

# Shared
startlitellm / stoplitellm
startwebui / stopwebui
```

---

## How to Monitor

### Check if everything is running
```bash
curl -s http://localhost:6970/health && echo "Qwen3 UP" || echo "Qwen3 DOWN"
curl -s http://localhost:4000/health | grep -q healthy && echo "LiteLLM UP" || echo "LiteLLM DOWN"
nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader
```

### Watch live activity
```bash
tail -f /tmp/qwen3.log      # llama-server: token processing, slot usage, errors
tail -f /tmp/litellm.log    # proxy: request counts, errors, model routing
```

### Read recent qwencode sessions
```bash
# List sessions by recency
ls -lt ~/.claude/projects/-home-pawan/*.jsonl | head -5

# Read what a session did (last 50 tool calls + messages)
tail -c 10000 ~/.claude/projects/-home-pawan/<session-id>.jsonl | python3 -c "
import sys, json
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        d = json.loads(line)
        t = d.get('type','')
        if t == 'assistant':
            c = d.get('message',{}).get('content','')
            if isinstance(c,list):
                for x in c:
                    if isinstance(x,dict) and x.get('type')=='text': print('ASST:', x['text'][:300])
                    if isinstance(x,dict) and x.get('type')=='tool_use': print('TOOL:', x.get('name'), str(x.get('input',''))[:200])
        elif t == 'user':
            c = d.get('message',{}).get('content','')
            if isinstance(c,list):
                for x in c:
                    if isinstance(x,dict) and x.get('type')=='text' and x['text'].strip(): print('USER:', x['text'][:200])
    except: pass
"
```

---

## Known Issues & Quirks

### LiteLLM 404 on token counting
```
HTTP error in CountTokens handler: Client error '404 Not Found' for url '.../v1/responses/input_tokens'
```
**This is harmless.** LiteLLM falls back to local tokenizer automatically. Ignore it.

### qwencode refuses to use tools
If Qwen3.6 says "I can't access your filesystem" — it's ignoring the system prompt.
Fix: the `system_prompt` in `~/Local LLM/qwen3/litellm-config.yaml` injects an agentic primer.
If still broken, restart LiteLLM: `stoplitellm && sleep 2 && cd ~/Local\ LLM && qwencode`

### OOM on startup
If llama-server fails with `cudaMalloc failed: out of memory`:
- Drop `-np 2` to `-np 1` in `~/Local LLM/qwen3/qwen3.sh`
- This happens when desktop/browser is using extra VRAM

### startqwen/stopqwen chaining fails
Aliases use `pkill -f llama-server 2>/dev/null; sleep 1; nohup ...` — the kill is fire-and-forget so it never blocks the chain.

---

## Improvement Areas to Evaluate

When reviewing qwencode sessions, look for:

1. **Tool refusals** — model saying "I can't" instead of calling a tool → tweak system prompt in litellm-config.yaml
2. **Empty content responses** — `content: ""` with all output in `reasoning_content` → thinking leaked through, check `--reasoning off` is set
3. **Repetitive tool loops** — model calling the same tool 10+ times → prompt quality issue, note the task type
4. **Context window pressure** — log line `n_tokens > ctx_size` → session too long, note what triggered it
5. **Slow generation** — check `nvidia-smi` for VRAM pressure or thermal throttling
6. **LiteLLM errors** — anything other than 404 token count errors is worth investigating

---

## Hermes Config Location

```
~/.hermes/
├── config.yaml     ← model: custom/qwen3, provider: custom, base_url: http://localhost:6970/v1
├── .env            ← env vars (no API keys needed for local)
├── SOUL.md         ← persona: "You are Hermes, running locally on pawan's Ubuntu machine..."
├── skills/         ← installed Hermes skills
└── logs/           ← Hermes session logs
```

Hermes talks **directly to llama-server port 6970** — no LiteLLM proxy needed.

---

## How to Update llama.cpp

```bash
cd ~/Local\ LLM/llama.cpp
git pull
cmake --build build --config Release -j$(nproc)
# Then: startqwen
```

---

## GitHub Repos

| Repo | URL | Contents |
|------|-----|---------|
| local-llm | https://github.com/pawan0305/local-llm | this setup (scripts, configs, README) |
| supergemma-setup | https://github.com/pawan0305/supergemma-setup | SuperGemma4 installer |

To push changes after editing scripts:
```bash
cd ~/Local\ LLM
git add -A && git commit -m "your message" && git push
```

---

## Fresh Machine Restore

```bash
git clone https://github.com/pawan0305/local-llm.git ~/Local\ LLM
cd ~/Local\ LLM && chmod +x install.sh && ./install.sh
# Then download models (see README.md)
```
