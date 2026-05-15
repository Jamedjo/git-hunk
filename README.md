# git-hunk

Non-interactive hunk staging for Git. Designed for LLM agents and scripts that can't use `git add -p`.

## Commands

```bash
git add-hunk <file> <hunk-id>...        # stage specific hunks
git reset-hunk <file> <hunk-id>...      # unstage specific hunks
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
git diff --cached src/main.c              # see staged hunks
git reset-hunk src/main.c +1,6           # unstage a hunk
git checkout-hunk src/main.c +15,6        # discard a hunk
```

IDs are stable as long as the working tree doesn't change.

### Editing hunks

To stage a hand-edited patch, use `git apply --cached` with a heredoc:

```bash
git apply --cached <<'EOF'
diff --git a/src/main.c b/src/main.c
index abc1234..def5678 100644
--- a/src/main.c
+++ b/src/main.c
@@ -10,4 +10,5 @@ void init() {
     setup();
+    validate();
     run();
     cleanup();
EOF
```

## Install

```bash
sudo make install
```

Git auto-discovers `git-<name>` executables on PATH, so they become `git add-hunk`, `git reset-hunk`, and `git checkout-hunk`.
