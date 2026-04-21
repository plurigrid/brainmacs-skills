---
name: clickability
description: 'This skill should be used when the user invokes "/clickability" to diagnose (and optionally remediate) terminal-Emacs TUI click wiring: xterm-mouse-mode, tab-line, clipetty, causal transients, per-frame tty setup.'
tools: Bash
disable-model-invocation: true
---

# Diagnose and remediate TUI clickability

When the user reports "clicks don't work in Emacs" — tabs not selectable by
mouse, Cmd+C not reaching pasteboard, `C-o` transient buttons inert — run the
diagnostic probe first, then (with user approval) remediate.

First, locate `agent-skill-clickability.el` alongside this SKILL.md at
`skills/clickability/agent-skill-clickability.el` in the emacs-skills plugin
directory.

## Phase 1 — diagnose (always safe)

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/clickability/agent-skill-clickability.el" nil t)
  (agent-skill-clickability-probe))'
```

Returns a plist covering:

- `:xterm-mouse-mode` — must be `t` for any mouse event to reach Emacs
- `:global-tab-line-mode` — required for clickable mode-line tabs
- `:clipetty-feature` / `:global-clipetty-mode` — OSC 52 clipboard to pasteboard
- `:causal-feature` — `C-o` transients
- `:frames` — per-frame `tty-type` (the daemon's env `TERM` is irrelevant; each attached frame has its own)
- `:post-command-hook-length` / `:messages-tail` — cascade evidence
- `:launched-with-q` — true if `*Messages*` contains the `-q` diagnostic string

## Phase 2 — remediate (requires approval)

If `:launched-with-q` is `t` the daemon ran without its init file. Prefer
**narrow flip** over full reload:

```sh
emacsclient --eval '
(progn
  (load "/path/to/skills/clickability/agent-skill-clickability.el" nil t)
  (agent-skill-clickability-enable))'
```

This enables `xterm-mouse-mode`, `global-tab-line-mode`, and
`global-clipetty-mode` without re-executing init.el.

## Known footguns

- **`global-tab-line-mode` + many buffers + broken `post-command-hook`**:
  enabling tab-line on a daemon with a partially-loaded strobe (`horsin/apply`
  void-function cascading on every command) or similar hook damage can wedge
  the command loop. Before running `-enable`, probe
  `:post-command-hook-length` and `:messages-tail` for `void-function`
  signatures. If present, fix hooks first.
- **`TERM=dumb` in daemon env**: benign — only the per-frame `tty-type`
  matters; new `emacsclient -t` attaches set this correctly.
- **xterm-mouse-mode + already-attached frames**: the mode toggles its
  escape-sequence enable on new-frame-created. Frames that were attached
  *before* the mode flipped may need a bounce (detach + reattach).

## Rules

- Always run `-probe` first; never run `-enable` without reviewing the probe.
- Locate `agent-skill-clickability.el` relative to this skill file's directory.
- Run `emacsclient --eval` via the Bash tool.
- Never `pkill` or `kill-emacs` without per-item user approval — the daemon
  may hold in-memory buffer state the user cares about.
