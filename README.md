# gander-skill

The Gander skill saves agent-produced plans as markdown, offers to watch
them on [gander.md](https://gander.md), and keeps the agent listening for
`@agent` review comments. Use it when the agent finishes a plan and a
human who is not in the IDE needs to review while the file is still
changing.

Works with OpenCode, Claude Code, Codex CLI, Cursor, Grok Build, and any
other runner that loads `SKILL.md` from `.agents/skills/` or `.claude/skills/`.
Needs the [gander CLI](https://github.com/gandermd/gander-cli) on `PATH`.

## What it does

- **Save the agent’s plan** as `./plans/YYYY-MM-DD-<slug>.md` with `status: draft`, then offer to **watch** it (live updates, not a static share).
- **Share vs watch by doc type**: reports are static snapshots (`gander share`); plans, RFCs, and drafts stay live-watched (`gander watch`). Type labels (`plan`, `rfc`, `draft`, `design`, `spec`, `report`) are additive — the CLI merges them; do not replace existing tags.
- **Watch a directory** for new `.md` files and prompt (preview / hosted watch / skip). The runner classifies each file (reports onboard as static shares labeled `report`; plans stay live-watched).
- **After a hosted watch**, poll for `@agent` comments (MCP preferred; `gander comments` fallback).
- Also **render, share, and manage** markdown with the `gander` CLI (render locally, share on gander.md, list/remove shares, mint team invites, open the dashboard, sign up, rotate tokens, upgrade).

## Install

```bash
gander skill
```

That downloads this repo into `~/.gander/skill` and symlinks the dests:

- `~/.agents/skills/gander` — picked up by Codex CLI and OpenCode
- `~/.claude/skills/gander` — picked up by Claude Code
- `~/.cursor/skills/gander` — picked up by Cursor

Clone this repo only to hack on `SKILL.md` or the scripts; then `./install.sh` from the checkout. The symlinks then point at the checkout, so edits take effect immediately — no reinstall needed.

## Uninstall

```bash
rm ~/.agents/skills/gander ~/.claude/skills/gander ~/.cursor/skills/gander
```

## Layout

```
gander-skill/
├── README.md                              # this file
├── install.sh                             # symlink installer
└── .agents/skills/gander/                 # the skill itself (source of truth)
    ├── SKILL.md                           # agent instructions (~165 lines)
    └── scripts/
        ├── watch-markdown.sh              # directory watcher + prompt
        └── save-plan.sh                   # plan → markdown + prompt
```

## Bundled scripts

### `scripts/watch-markdown.sh`

Watch a directory for new `.md` files; prompt to gander each one.

```bash
scripts/watch-markdown.sh                       # watch cwd
scripts/watch-markdown.sh ~/projects/notes      # watch a specific dir
scripts/watch-markdown.sh ~/notes --share       # default to share instead of preview
scripts/watch-markdown.sh ~/notes --background  # daemonize
scripts/watch-markdown.sh --stop                # stop backgrounded watcher
```

Requires `gander` in `PATH` plus `fswatch` (macOS) or `inotifywait` (linux).

### `scripts/save-plan.sh`

Save an agent-produced plan as a markdown file; offer to watch it.

```bash
cat plan.txt | scripts/save-plan.sh "Add token rotation to gander"
scripts/save-plan.sh "Refactor share rendering" plan.md
PLAN_SOURCE=opencode scripts/save-plan.sh "Plan title here"
```

Saves to `./plans/YYYY-MM-DD-<slug>.md` with YAML `status: draft`, a title heading, and a metadata block. Post-save `s` watches (`gander watch --silent`); it does not static-share. Piped runs skip the prompt without failing. Override the save directory with `PLAN_DIR=/some/path`.

## Editing

Edit `SKILL.md` or any script in place — the symlinks mean changes take effect immediately for every agent that has the skill loaded. No reinstall needed.

If you add new files under `.agents/skills/gander/` (e.g. `references/`, `assets/`), they'll be picked up by agents via the skill directory at `$HOME/.agents/skills/gander` — but only if the new files live inside this repo (since the symlink target is this directory).

## License

MIT.
