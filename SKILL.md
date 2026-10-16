---
name: macos-disk-cleanup
description: >-
  Use when a macOS machine is low on disk space and you need to audit and safely
  free space, learning over time which paths a human has approved for automatic
  deletion.
---
# macOS disk cleanup (verified, learning)

Goal: free space on a Mac without deleting anything the human would miss. Paths are only deleted automatically after a human has confirmed that class of path once.

## Persistent state (keep next to the skill, e.g. `~/.macos-disk-cleanup/`)
- `rules.json`: ordered path patterns. Each has a class, `SAFE`, `ASK` or `NEVER`; a `cleanup_command` if one exists; a `rationale`; `confirmed_by_human` with `confirmed_at`; and optional conditions such as `only_if_app_not_running`, `older_than_hours`, `keep_newest` or `truncate_over_gb`.
- `history/<run>.json`: free space before and after, plus each item with its size, the amount freed, the action taken and why.
- `README.md`: this workflow, a list of disabled services and how to turn each back on.
- `scripts/verify.sh <path>`: prints SAFE, ASK or NEVER for a path, based on rules.json.
- Optional structured log (for example a spreadsheet or database table): one row per item per run, with the fields Run ID, date, trigger, free before/after, path, rule, category, class, human-confirmed, action, command, size, freed, regenerable, owner app, real last-modified, in-use check, result and error.

## Run steps
1. Copy `rules.example.json` to `rules.json` on first use. Run `df -h /System/Volumes/Data` and record the free space before.
2. Audit with `du` and per-command timeouts, tolerating permission errors. Look at ~/Library/Caches, package-manager caches (pnpm, npm, yarn, uv, pip, go modules, brew), ~/.cache/*, app updater (ShipIt) caches, ~/Library/Application Support (the largest folders), logs, ~/Downloads, ~/Movies, /tmp build and recording artifacts, Docker, iOS backups, and runaway log files.
3. Classify each path with `verify.sh`.
4. Auto-clean only rules that are both SAFE and `confirmed_by_human`. Before each delete:
   - Check that the path exists and matches the rule.
   - Run `lsof +D` and `pgrep` for the owning app. If the path is in use, skip it; never force a lock.
   - Prefer the official command: `pnpm store prune`, `uv cache clean`, `go clean -modcache`, `npm cache clean --force`, `brew cleanup -s`.
   - Respect the rule's conditions. For example, delete only if the app isn't running, keep the newest clone, or truncate a log that is still being written with `: > file` instead of deleting it.
5. Never auto-delete ASK paths. List them with their size and modification time, then ask the human once. When they approve, update rules.json:
   - Regenerable paths can become SAFE and confirmed.
   - User-data folders (Downloads, Movies) stay ASK and are confirmed each time.
6. Before deleting irreversible artifacts such as recordings, offer to copy them to cloud storage first. Delete only after the upload is verified and the files haven't changed since the upload.
7. Even within approved deletions, keep account-recovery files (password-manager emergency kits) and personal documents such as CVs and ID scans, and ask about them.
8. Record the free space after, write the history file and the structured log, and report free space before and after, the space freed per item, what was skipped and why, and the remaining ASK candidates.

## Root-cause checks
- If space drops again quickly, compare against the previous run to find what grew. Usual causes: updater caches downloading again, build or source clones, crash-looping services writing logs.
- For a log that keeps growing, find the writer (`launchctl list`, `lsof`). Propose fixing the dependency, or disabling the job with `launchctl bootout` + `launchctl disable`, keeping the plist. Write down the commands to turn it back on.

## Never
- Restart the machine, kill processes the human hasn't approved, or touch Documents, Desktop, Photos, keychains, or app databases.
- Delete paths that another agent asks about unless the human has approved them in their own chat.

## Daily check
Run this skill from a daily routine when free space is under a threshold (for example 10G). Stay quiet when space is fine.
