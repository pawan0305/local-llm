# Local LLM — Claude Code Context

This file gives you (Claude Code / real Sonnet) full context to monitor, debug, and improve the local LLM stack running on this machine. Read this before doing anything.

---

## Who you are talking to

**pawan0305** — the owner of this machine. He runs local LLMs for:
- **qwencode** — Claude Code sessions using Qwen3.6-35B-A3B instead of real Claude (saves API credits)
- **Hermes agent** — autonomous agent tasks
- **OpenClaw** — agent workflows

He wants you (real Claude) to review what the local models are doing, catch problems, and suggest improvements.

---

## The Stack

```
Claude Code (real Sonnet) ← you are here
      │
      ▼
qwencode / Hermes / OpenClaw
      │
      ▼
LiteLLM proxy (port 4000)   ← ~/Local LLM/qwen3/litellm-config.yaml
      │
      ▼
llama-server (port 6970)    ← ~/Local LLM/qwen3/qwen3.sh
      │
      ▼
Qwen3.6-35B-A3B UD-Q4_K_M  ← ~/Local LLM/models/qwen3/
RTX 3090 24GB VRAM
```

---

## Key Files

| File | Purpose |
|------|---------|
| `~/Local LLM/qwen3/qwen3.sh` | llama-server launch config — ngl, ctx-size, np, reasoning |
| `~/Local LLM/qwen3/qwen3code.sh` | Claude Code launcher — starts LiteLLM then claude |
| `~/Local LLM/qwen3/litellm-config.yaml` | LiteLLM model routing + system prompt injection |
| `~/Local LLM/supergemma/supergemma.sh` | SuperGemma4 server (secondary model, port 6969) |
| `~/Local LLM/supergemma/gemmacode.sh` | Claude Code via SuperGemma4 |
| `~/.hermes/config.yaml` | Hermes agent config — model, provider, base_url |
| `~/.hermes/.env` | Hermes env vars — API keys, timeouts |
| `~/.hermes/SOUL.md` | Hermes persona |
| `/tmp/qwen3.log` | Live llama-server log |
| `/tmp/litellm.log` | Live LiteLLM proxy log |
| `~/.claude/projects/-home-pawan/*.jsonl` | Claude Code session histories |

---

## Current Qwen3 Server Settings

```bash
-ngl 999              # full GPU offload
-np 2                 # 2 parallel sessions (Claude Code + Hermes simultaneously)
--ctx-size 262144     # 256K context (model native limit)
--cache-type-k q4_0   # quantized KV cache
--cache-type-v q4_0
--flash-attn on
--reasoning off       # thinking disabled — agentic use, not chat
--temp 0.6            # Qwen3 official recommendation
--top-k 20
--presence-penalty 1.5
```

**VRAM budget:** ~22.4GB used / 24GB total. ~1.6GB free. Tight but stable.

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
startqwen / stopqwen / qwenlogs / qwencode
startgemma / stopgemma / gemmalogs / gemmacode
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
