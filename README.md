# git-hunk

Non-interactive hunk staging for Git. Designed for LLM agents and scripts that can't use `git add -p`.

## Commands

```bash
git add-hunk <file> <hunk-id>...        # stage specific hunks
git checkout-hunk <file> <hunk-id>...   # discard specific hunks
```

## Hunk IDs

Hunk IDs are `+offset,count` from the `@@` header in unified diff output:

```
@@ -1,6 +1,6 @@        →  hunk ID is +1,6
@@ -15,6 +15,6 @@       →  hunk ID is +15,6
```

Use `git diff` to see hunks and their IDs, then pass them to `add-hunk` or `checkout-hunk`:

```bash
git diff src/main.c
git add-hunk src/main.c +1,6
git checkout-hunk src/main.c +15,6
```

Multiple hunks can be staged or discarded at once:

```bash
git add-hunk src/main.c +1,6 +15,6
```

IDs are stable as long as the working tree doesn't change.

## Install

```bash
sudo make install
```

Git auto-discovers `git-<name>` executables on PATH, so they become `git add-hunk` and `git checkout-hunk`.
