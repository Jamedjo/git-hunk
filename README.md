# git-hunk

Non-interactive hunk staging for Git. Designed for LLM agents and scripts that can't use `git add -p`.

## Usage

```bash
git list-hunks [<pathspec>...]
git add-hunk <file> <hunk-id>...
```

### List hunks

```bash
git list-hunks src/main.c
#   src/main.c +10,7
#     @@ -10,5 +10,7 @@ function_name
#     ...diff lines...
#   src/main.c +30,4
#     @@ -30,3 +32,4 @@ another_function
#     ...diff lines...
```

### Stage specific hunks

```bash
git add-hunk src/main.c +10,7
git add-hunk src/main.c +10,7 +30,4
```

Hunk IDs are `+offset,count` from the unified diff `@@` header — stable as long as the working tree doesn't change.

## Install

```bash
make install
```

Symlinks `git-list-hunks` and `git-add-hunk` into `~/.local/bin/`. Git auto-discovers `git-<name>` executables on PATH, so they become `git list-hunks` and `git add-hunk`.
