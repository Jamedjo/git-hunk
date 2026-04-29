#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0
TMPDIR=""

cleanup() {
    if [ -n "$TMPDIR" ] && [ -d "$TMPDIR" ]; then
        rm -rf "$TMPDIR"
    fi
}
trap cleanup EXIT

setup_repo() {
    TMPDIR="$(mktemp -d)"
    cd "$TMPDIR"
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"

    cat > file.txt <<'CONTENT'
line 1
line 2
line 3
line 4
line 5
line 6
line 7
line 8
line 9
line 10
line 11
line 12
line 13
line 14
line 15
line 16
line 17
line 18
line 19
line 20
CONTENT
    git add file.txt
    git commit -q -m "initial"
}

make_two_hunks() {
    sed -i '3s/.*/line 3 MODIFIED/' file.txt
    sed -i '18s/.*/line 18 MODIFIED/' file.txt
}

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        echo "    expected: $expected"
        echo "    actual:   $actual"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL: $desc"
        echo "    expected to contain: $needle"
        echo "    got: $haystack"
        FAIL=$((FAIL + 1))
    fi
}

assert_not_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -qF "$needle"; then
        echo "  FAIL: $desc"
        echo "    should not contain: $needle"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS: $desc"
        PASS=$((PASS + 1))
    fi
}

assert_exit() {
    local desc="$1" expected="$2" actual="$3"
    assert_eq "$desc (exit code)" "$expected" "$actual"
}

add_hunk() {
    python3 "$SCRIPT_DIR/git-add-hunk" "$@"
}

checkout_hunk() {
    python3 "$SCRIPT_DIR/git-checkout-hunk" "$@"
}

extract_hunk_ids() {
    git diff "$@" | grep -oP '@@ -\d+,\d+ \+\d+,\d+' | grep -oP '\+\d+,\d+'
}

# --- Tests ---

echo "=== add-hunk: stages single hunk ==="
setup_repo
make_two_hunks
HUNK1="$(extract_hunk_ids | head -1)"
HUNK2="$(extract_hunk_ids | tail -1)"
add_hunk file.txt "$HUNK1"
staged="$(git diff --cached)"
unstaged="$(git diff)"
assert_contains "staged has first change" "+line 3 MODIFIED" "$staged"
assert_not_contains "staged does not have second change" "+line 18 MODIFIED" "$staged"
assert_contains "unstaged still has second change" "+line 18 MODIFIED" "$unstaged"

echo "=== add-hunk: stages multiple hunks ==="
cleanup
setup_repo
make_two_hunks
HUNK1="$(extract_hunk_ids | head -1)"
HUNK2="$(extract_hunk_ids | tail -1)"
add_hunk file.txt "$HUNK1" "$HUNK2"
staged="$(git diff --cached)"
assert_contains "staged has first change" "+line 3 MODIFIED" "$staged"
assert_contains "staged has second change" "+line 18 MODIFIED" "$staged"
unstaged="$(git diff)"
assert_eq "nothing left unstaged" "" "$unstaged"

echo "=== add-hunk: unknown hunk ID exits 1 ==="
cleanup
setup_repo
make_two_hunks
HUNK1="$(extract_hunk_ids | head -1)"
exit_code=0
output="$(add_hunk file.txt +99,1 2>&1 || true)"
add_hunk file.txt +99,1 2>/dev/null || exit_code=$?
assert_exit "unknown hunk" "1" "$exit_code"
assert_contains "names the bad ID" "unknown hunk: +99,1" "$output"
assert_contains "lists available hunks" "$HUNK1" "$output"

echo "=== add-hunk: file not in diff exits 1 ==="
cleanup
setup_repo
make_two_hunks
exit_code=0
output="$(add_hunk nosuchfile.txt +1,1 2>&1 || true)"
add_hunk nosuchfile.txt +1,1 2>/dev/null || exit_code=$?
assert_exit "file not in diff" "1" "$exit_code"
assert_contains "error message" "no unstaged changes" "$output"

echo "=== add-hunk: no args exits 1 ==="
exit_code=0
add_hunk 2>/dev/null || exit_code=$?
assert_exit "no args" "1" "$exit_code"

echo "=== checkout-hunk: discards single hunk ==="
cleanup
setup_repo
make_two_hunks
HUNK1="$(extract_hunk_ids | head -1)"
checkout_hunk file.txt "$HUNK1"
remaining="$(git diff)"
assert_not_contains "first change discarded" "+line 3 MODIFIED" "$remaining"
assert_contains "second change kept" "+line 18 MODIFIED" "$remaining"

echo "=== checkout-hunk: discards all hunks ==="
cleanup
setup_repo
make_two_hunks
HUNK1="$(extract_hunk_ids | head -1)"
HUNK2="$(extract_hunk_ids | tail -1)"
checkout_hunk file.txt "$HUNK1" "$HUNK2"
remaining="$(git diff)"
assert_eq "no changes remain" "" "$remaining"

echo "=== checkout-hunk: unknown hunk ID exits 1 ==="
cleanup
setup_repo
make_two_hunks
exit_code=0
output="$(checkout_hunk file.txt +99,1 2>&1 || true)"
checkout_hunk file.txt +99,1 2>/dev/null || exit_code=$?
assert_exit "unknown hunk" "1" "$exit_code"
assert_contains "names the bad ID" "unknown hunk: +99,1" "$output"

echo "=== checkout-hunk: file not in diff exits 1 ==="
cleanup
setup_repo
make_two_hunks
exit_code=0
output="$(checkout_hunk nosuchfile.txt +1,1 2>&1 || true)"
checkout_hunk nosuchfile.txt +1,1 2>/dev/null || exit_code=$?
assert_exit "file not in diff" "1" "$exit_code"
assert_contains "error message" "no unstaged changes" "$output"

echo "=== checkout-hunk: no args exits 1 ==="
exit_code=0
checkout_hunk 2>/dev/null || exit_code=$?
assert_exit "no args" "1" "$exit_code"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
