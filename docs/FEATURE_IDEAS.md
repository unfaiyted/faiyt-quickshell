# Feature Ideas for faiyt-qs Desktop Shell

A collection of feature ideas for future development, organized by category and priority.
---

## Sidebar Left - AI Tab Enhancements

### 1. Complete Provider Integrations
Currently Claude is the only working provider. Implement the stubbed ones:
- **Gemini**: Google's API is straightforward, similar to Claude
- **GPT**: OpenAI ChatCompletion API
- **Ollama**: Local LLM support (excellent for privacy/offline use)

### 2. AI Conversation Features
- **Search conversations**: Full-text search across saved conversations
- **Conversation export**: Export to markdown, PDF, or share link
- **Branching/forking**: Branch from any message to explore alternatives
- **Token counter**: Show token usage per message and conversation total
- **Context window indicator**: Visual indicator of how much context remains
- **Pin important conversations**: Keep frequently referenced chats at top

### 3. MCP Server Enhancements
- **Visual MCP server manager**: See connected servers, their tools, status
- **Quick tool palette**: Searchable list of available MCP tools to invoke directly
- **Tool result history**: Log of MCP tool executions with outputs

---

## Sidebar Left - Tools Tab Enhancements

### New Developer Tools

| Tool | Description | Category |
|------|-------------|----------|
| **Git Branch Manager** | List branches, switch, create, delete, show ahead/behind | Dev |
| **Git Stash Manager** | View stashes, apply, pop, drop with preview | Dev |
| **Git Log Viewer** | Recent commits with diff preview | Dev |
| **Environment Vars** | View/edit .env files across projects | Dev |
| **Package Manager** | npm/pnpm/yarn outdated packages, update commands | Dev |
| **Database Status** | Check PostgreSQL, MySQL, Redis, MongoDB connections | Dev |
| **Service Status** | systemctl status for common dev services | Dev |
| **SSH Connections** | Quick connect to saved SSH hosts | Dev |

### New System Tools

| Tool | Description | Category |
|------|-------------|----------|
| **Journal Viewer** | Recent journalctl entries with severity filtering | System |
| **Failed Services** | List failed systemd units with restart options | System |
| ~~**Temp Monitor**~~ | ~~CPU/GPU temperatures with warning thresholds~~ | ~~Monitor~~ | ✅ **IMPLEMENTED** - Bar module indicators for CPU/GPU temp |
| ~~**GPU Stats**~~ | ~~NVIDIA/AMD GPU usage, VRAM, temperature~~ | ~~Monitor~~ | ✅ **IMPLEMENTED** - Bar module indicators for GPU usage/VRAM/temp |
| **Battery Health** | Cycle count, capacity, wear level | System |
| **Boot Time** | Systemd-analyze blame (what's slowing boot) | System |
| **Kernel Info** | Version, parameters, modules | System |

### New Network Tools

| Tool | Description | Category |
|------|-------------|----------|
| **Speed Test** | Network speed test with history | Network |
| **Open Connections** | netstat/ss view of active connections | Network |
| **Firewall Status** | UFW/firewalld rules summary | Network |
| **VPN Status** | Active VPN connections and quick connect | Network |
| **Ping Monitor** | Continuous ping to hosts with latency graph | Network |

### Tool UX Improvements
- **Favorites/pins**: Pin frequently used tools to top
- **Recent tools**: Show last 5 used tools
- **Custom tools**: User-defined shell commands as tools
- **Tool shortcuts**: Keyboard shortcuts for favorite tools
- **Auto-refresh**: Optional periodic refresh for monitoring tools
- **Tool output history**: Keep last N results for each tool

---

## New Sidebar Tabs (Left)

### 1. Snippets/Clipboard Manager
- Clipboard history with search
- Saved snippets with categories
- Code snippet support with syntax highlighting
- Quick paste with keyboard shortcuts

### 2. Quick Notes
- Scratchpad for quick notes
- Markdown support
- Auto-save
- Optional sync to file

### 3. Timers/Pomodoro
- Multiple named timers
- Pomodoro timer with break reminders
- Stopwatch functionality
- Timer completion notifications

### 4. Bookmarks/Links
- Save frequently accessed URLs
- Categorized bookmarks
- Quick open in browser
- Import from browser bookmarks

---

## Bar Module Ideas

### New Modules

| Module | Description |
|--------|-------------|
| **Pomodoro indicator** | Timer in bar, click to control |
| **GitHub notifications** | PR reviews, issues, mentions |
| **Calendar events** | Next event countdown |
| **Package updates** | Pending system updates count |
| **VPN indicator** | Connection status with quick toggle |
| ~~**GPU usage**~~ | ~~Small GPU usage indicator~~ | ✅ **IMPLEMENTED** |
| **Docker status** | Running container count |
| **Spotify/Music mini** | Compact now playing with controls |

### Module Enhancements
- **Music module**: Add lyrics display option
- **Weather module**: Extended forecast on hover
- **Clock module**: World clocks on hover
- **Battery module**: Time remaining estimate
- **Network module**: Speed graph on hover

---

## Launcher Enhancements

### New Evaluators

| Evaluator | Examples |
|-----------|----------|
| **Currency** | "100 USD to EUR", "50 BTC in USD" |
| **Date/Time** | "days until christmas", "date + 2 weeks" |
| **Hash** | "md5 hello", "sha256 password" |
| **UUID** | "uuid" generates UUID, copies on enter |
| **Lorem** | "lorem 3" generates 3 paragraphs |
| **Password** | "pass 16" generates 16-char password |

### Launcher Features
~~- **Emoji picker**: Search and insert emojis~~
- **Calculator history**: Keep last N calculations
- ~~**Bookmark search**: Search saved bookmarks~~ ✅ **IMPLEMENTED** - Search Firefox/Zen browser bookmarks with favicon support
- **Snippet search**: Search and paste snippets
- **Recent files**: Search recently opened files
- **File search**: Integration with locate/fd

---

## Settings Enhancements

- **Backup/restore**: Export/import all settings
- **Profiles**: Multiple configuration profiles
- **Keyboard shortcuts editor**: Customize all hotkeys
- ~~**Theme editor**: Create custom color themes~~ ✅ **IMPLEMENTED** - Full theme manager with HSL color picker, 30 editable colors, custom theme creation/duplication/deletion
- **Widget playground**: Preview components with different settings

---

## System-wide Features

### 1. Command Palette (Ctrl+Shift+P style)
- Global command palette accessible anywhere
- Search all actions, settings, tools
- Recent commands
- Fuzzy matching

### 2. Global Search
- Search everything: files, apps, settings, conversations, notes
- Unified interface

### 3. Automation/Macros
- Record and replay action sequences
- Schedule recurring tasks
- Trigger actions on events (time, app launch, network change)

### 4. Dashboard Widget
- Customizable dashboard view
- Draggable widgets (clock, weather, calendar, system stats)
- Quick access shortcuts

---

## AI-Powered Features

### 1. Smart Clipboard
- AI summarization of copied text
- Translation of clipboard content
- Code explanation for copied code

### 2. Contextual Suggestions
- Suggest actions based on active window
- Smart notifications with AI context

### 3. Voice Input
- Voice-to-text for AI chat
- Voice commands for shell actions

### 4. Screen Context
- Screenshot + AI analysis
- OCR text extraction from images

---

## Priority Matrix

### High Impact, Reasonable Effort
1. **Clipboard manager tab** - Universal utility
2. **Git branch/stash tools** - Developer productivity
3. ~~**GPU/Temperature monitor**~~ - ~~System awareness~~ ✅ **IMPLEMENTED** - Bar module indicators with NVIDIA GPU + CPU temp
4. **Tool favorites/pins** - UX improvement
5. **Ollama provider** - Local AI, privacy

### High Impact, More Effort
1. **Command palette** - Power user feature
2. **Custom tools** - Extensibility
3. **Currency evaluator** - Common need
4. **Quick notes tab** - Productivity

### Nice to Have
1. Complete Gemini/GPT providers
2. Conversation search
3. Pomodoro timer
4. Dashboard widgets
