# Local LLM — Claude Code Context

This file gives you (Claude Code / real Sonnet) full context to monitor, debug, and improve the local LLM stack running on this machine. Read this before doing anything.

---

## Who you are talking to

**pawan0305** — the owner of this machine. He runs local LLMs for:
- **qwencode** — Claude Code sessions using Qwen3.6-27B instead of real Claude (saves API credits)
- **Pi (oh-my-pi)** — lightweight terminal coding agent, direct to port 6970
- **OpenCode** — coding agent, direct to port 6970
- **Hermes agent** — autonomous agent tasks, direct to port 6970

He wants you (real Claude) to review what the local models are doing, catch problems, and suggest improvements.

---

## The Stack

```
Claude Code (real Sonnet) ← you are here
      │
      ▼
qwencode / vllmcode         Pi / OpenCode / Hermes
      │                            │
      ▼                            ▼
LiteLLM proxy (port 4000)   llama-server (port 6970)
thinking: OFF               thinking: ON
      │                            │
      └──────────────┬─────────────┘
                     ▼
          llama-server OR vLLM (port 6970)
  llama-server: ~/Local LLM/qwen3/qwen3.sh  (Qwen3.6-27B UD-Q4_K_XL GGUF)
  vLLM:         ~/Local LLM/qwen3/vllm.sh   (Lorbus AutoRound int4)
                     │
                     ▼
          Qwen3.6-27B  ←  ~/Local LLM/models/qwen3/
          RTX 3090 24GB VRAM
```

**Two server options on the same port 6970 — pick one:**
| Server | Script | Model | Est. TPS |
|--------|--------|-------|----------|
| llama-server (llama.cpp) | `qwen3.sh` | UD-Q4_K_XL GGUF | ~37 TPS raw |
| vLLM | `vllm.sh` | Lorbus AutoRound int4 | ~37 TPS (32K ctx only) |

---

## Key Files

| File | Purpose |
|------|---------|
| `~/Local LLM/qwen3/qwen3.sh` | llama-server launch (GGUF, port 6970, ctx 131072) |
| `~/Local LLM/qwen3/vllm.sh` | vLLM launch (AutoRound int4, port 6970, ctx 32768) |
| `~/Local LLM/qwen3/qwen3code.sh` | Claude Code via llama-server + LiteLLM |
| `~/Local LLM/qwen3/vllmcode.sh` | Claude Code via vLLM + LiteLLM |
| `~/Local LLM/qwen3/litellm-config.yaml` | LiteLLM routing + system prompt + thinking OFF |
| `~/.omp/agent/models.yml` | Pi (oh-my-pi) config — points to port 6970 |
| `~/.config/opencode/config.json` | OpenCode config — points to port 6970 |
| `~/.hermes/config.yaml` | Hermes agent config — model, provider, base_url: localhost:6970 |
| `~/.hermes/SOUL.md` | Hermes persona |
| `/tmp/qwen3.log` | Live llama-server log |
| `/tmp/vllm.log` | Live vLLM log |
| `/tmp/litellm.log` | Live LiteLLM proxy log |
| `~/.claude/projects/-home-pawan/*.jsonl` | Claude Code session histories |

---

## Coding Harnesses — Which to Use

| Harness | Command | Route | Thinking | Best For |
|---------|---------|-------|----------|----------|
| qwencode | `qwencode` | port 4000 (LiteLLM) | OFF | Quick coding, faster visible TPS |
| vllmcode | `vllmcode` | port 4000 (LiteLLM) | OFF | Same as qwencode, vLLM backend |
| Pi | `pi` or `omp` | port 6970 (direct) | ON | Quality coding, lean tool harness |
| OpenCode | `opencode` | port 6970 (direct) | ON | Quality coding, TUI interface |
| Hermes | `hermes` | port 6970 (direct) | ON | Autonomous/long-running tasks |

**Thinking ON vs OFF:** qwencode/vllmcode go through LiteLLM which sets
`chat_template_kwargs: {enable_thinking: false}`. Pi/OpenCode/Hermes bypass LiteLLM
and get thinking tokens — better quality, half the visible TPS.

---

## Current Qwen3 Server Settings (llama-server)

```bash
-ngl 999              # full GPU offload
-np 1                 # 1 parallel session
--ctx-size 215040     # 210K context
--cache-type-k q4_0   # quantized KV cache (~3.3GB at 210K)
--cache-type-v q4_0
--flash-attn on
--ubatch-size 2048    # physical batch for faster prefill
--reasoning on        # thinking enabled — Pi/Hermes/OpenCode use it
--temp 0.6
--top-k 20
--top-p 0.95
--presence-penalty 0.0
```

**VRAM budget:** ~16.4GB model + ~2GB KV cache = ~18.4GB / 24GB. ~5.6GB headroom.

## vLLM Server Settings

```bash
--dtype float16
--gpu-memory-utilization 0.97
--max-model-len 32768        # 32K max — 128K OOMs with this model format
--max-num-seqs 1
--enable-chunked-prefill
```

Model: `Lorbus/Qwen3.6-27B-int4-AutoRound` at `~/Local LLM/models/qwen3/lorbus-autoround/`
venv: `~/Local LLM/venv-vllm/` (Python 3.11)

Note: vLLM uses 20GB VRAM (vs 16.4GB GGUF) due to AutoRound fp16 scale tensors.
No speed advantage over llama.cpp. Use llama-server unless testing vLLM specifically.

---

## Ports

| Service | Port | Health check |
|---------|------|-------------|
| Qwen3.6 llama-server | 6970 | `curl http://localhost:6970/health` |
| SuperGemma4 llama-server | 6969 | `curl http://localhost:6969/health` |
| LiteLLM proxy | 4000 | `curl http://localhost:4000/health` |
| Open WebUI | 3000 | browser only |

---

## All Commands

### Server lifecycle
```bash
startqwen       # start llama-server (Qwen3.6-27B GGUF, port 6970)
stopqwen        # stop llama-server
qwenlogs        # tail llama-server log

startvllm       # start vLLM (AutoRound int4, port 6970)
stopvllm        # stop vLLM
vllmlogs        # tail vLLM log

startlitellm    # start LiteLLM proxy (port 4000)
stoplitellm     # stop LiteLLM

startwebui      # start Open WebUI (port 3000)
stopwebui       # stop Open WebUI
```

### Coding harnesses
```bash
qwencode        # Claude Code → LiteLLM → llama-server (thinking OFF)
vllmcode        # Claude Code → LiteLLM → vLLM (thinking OFF)
pi              # oh-my-pi → llama-server direct (thinking ON)
omp             # same as pi
opencode        # OpenCode → llama-server direct (thinking ON)
```

### Health checks
```bash
curl http://localhost:6970/health    # llama-server
curl http://localhost:4000/health    # LiteLLM
nvidia-smi --query-gpu=memory.used,memory.free --format=csv,noheader
```

### Reviews (triggers real Claude)
```bash
qwencodereview  # review recent qwencode sessions, suggest improvements
hermesreview    # review Hermes setup and recent activity
```

### Maintenance
```bash
# Update llama.cpp
cd ~/Local\ LLM/llama.cpp
git pull
cmake --build build --config Release -j$(nproc)
# Then: startqwen

# Push config changes to GitHub
cd ~/Local\ LLM
git add -A && git commit -m "your message" && git push
```

---

## Shell Aliases (in ~/.bashrc)

```bash
# llama-server (GGUF)
startqwen / stopqwen / qwenlogs / qwencode

# vLLM (AutoRound int4)
startvllm / stopvllm / vllmlogs / vllmcode

# Shared
startlitellm / stoplitellm
startwebui / stopwebui

# Coding agents (direct to port 6970)
pi / omp        # oh-my-pi (alias pi="omp")
opencode        # OpenCode
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
If still broken, restart LiteLLM: `stoplitellm && sleep 2 && startlitellm`

### OOM on startup
If llama-server fails with `cudaMalloc failed: out of memory`:
- Drop `-np 2` to `-np 1` in `~/Local LLM/qwen3/qwen3.sh`
- This happens when desktop/browser is using extra VRAM

### vLLM context limit
vLLM with the AutoRound int4 model uses 20GB VRAM, leaving only ~4GB for KV cache.
Max context is 32768 (32K). Setting --max-model-len higher will OOM.

### Thinking tokens visible in Pi/OpenCode
Pi and OpenCode talk directly to port 6970 with `--reasoning on`. The model generates
thinking tokens in `reasoning_content`. Both harnesses should handle this gracefully.
If you see raw `<think>` blocks, restart with `--reasoning off` or route through LiteLLM.

---

## Improvement Areas to Evaluate

When reviewing qwencode sessions, look for:

1. **Tool refusals** — model saying "I can't" instead of calling a tool → tweak system prompt in litellm-config.yaml
2. **Empty content responses** — `content: ""` with all output in `reasoning_content` → thinking leaked through (qwencode should have it disabled)
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

## Pi (oh-my-pi) Config Location

```
~/.omp/
├── agent/
│   └── models.yml  ← provider: qwen3-local, baseUrl: localhost:6970, model: qwen3
└── logs/           ← Pi session logs
```

Pi talks **directly to llama-server port 6970** — no LiteLLM proxy needed.
Launch with: `pi` or `omp`

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
# Install Pi: curl -fsSL https://raw.githubusercontent.com/can1357/oh-my-pi/main/scripts/install.sh | sh -s -- --binary
```
