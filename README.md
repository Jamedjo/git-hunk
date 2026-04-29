# git-hunk

Non-interactive hunk staging for Git. Designed for LLM agents and scripts that can't use `git add -p`.

## Commands

```bash
git add-hunk <file> <hunk-id>...        # stage specific hunks
git checkout-hunk <file> <hunk-id>...   # discard specific hunks
```

## Hunk IDs

A hunk ID is `+offset,count` — the **NEW file side** of the `@@` header. Always starts with `+`, never `-`.

```
@@ -1,6 +1,6 @@        →  hunk ID is +1,6
     ^^^^                    (ignore the OLD side)
          ^^^^^              (use the NEW side)

@@ -10,5 +12,7 @@       →  hunk ID is +12,7 (NOT -10,5)
```

### Workflow

```bash
git diff src/main.c                       # see hunks and @@ headers
git add-hunk src/main.c +1,6             # stage one hunk
git add-hunk src/main.c +1,6 +15,6       # stage multiple hunks
git checkout-hunk src/main.c +15,6        # discard a hunk
```

IDs are stable as long as the working tree doesn't change.

## Install

```bash
sudo make install
```

Git auto-discovers `git-<name>` executables on PATH, so they become `git add-hunk` and `git checkout-hunk`.
