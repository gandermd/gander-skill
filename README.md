# gander-skill

An end-user [Agent Skill](https://agentskills.io) for the [gander](https://github.com/gandermd/gander-cli) markdown-preview CLI. Works with OpenCode, Claude Code, Codex CLI, and any other tool that loads `SKILL.md` files from `.agents/skills/` or `.claude/skills/`.

## What it does

- **Render, share, manage markdown** with the `gander` CLI (render locally, share on gander.md, list/remove shares, open the dashboard, sign up, rotate tokens, upgrade).
- **Watch for new markdown files** in any directory and prompt to gander each one (`y` = preview, `s` = share, `N` = skip). Foreground or `--background`.
- **Save agent-produced plans as markdown** to `./plans/YYYY-MM-DD-<slug>.md`, then offer to gander the result.

## Install

```bash
cd /Users/scott/Workspace/gander-skill
./install.sh
```

This symlinks `.agents/skills/gander` into:

- `~/.agents/skills/gander` — picked up by Codex CLI and OpenCode
- `~/.claude/skills/gander` — picked up by Claude Code

The symlinks point at this directory, so any edits to `SKILL.md` or the bundled scripts take effect immediately — no reinstall needed.

## Uninstall

```bash
rm ~/.agents/skills/gander ~/.claude/skills/gander
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

Save an agent-produced plan as a markdown file; offer to gander it.

```bash
cat plan.txt | scripts/save-plan.sh "Add token rotation to gander"
scripts/save-plan.sh "Refactor share rendering" plan.md
PLAN_SOURCE=opencode scripts/save-plan.sh "Plan title here"
```

Saves to `./plans/YYYY-MM-DD-<slug>.md` with a title heading and metadata block. Override the save directory with `PLAN_DIR=/some/path`.

## Editing

Edit `SKILL.md` or any script in place — the symlinks mean changes take effect immediately for every agent that has the skill loaded. No reinstall needed.

If you add new files under `.agents/skills/gander/` (e.g. `references/`, `assets/`), they'll be picked up by agents via the skill directory at `$HOME/.agents/skills/gander` — but only if the new files live inside this repo (since the symlink target is this directory).

## License

MIT.