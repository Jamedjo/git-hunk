import subprocess
import re
from dataclasses import dataclass, field


@dataclass
class Hunk:
    id: str
    header_line: str
    body: str


@dataclass
class FileDiff:
    header: str
    hunks: list[Hunk] = field(default_factory=list)


def hunk_id(new_offset, new_count):
    return f"+{new_offset},{new_count}"


def run_git_diff(pathspecs=None):
    cmd = ["git", "diff"]
    if pathspecs:
        cmd += ["--"] + list(pathspecs)
    result = subprocess.run(cmd, capture_output=True, text=True, check=True)
    return result.stdout


HUNK_HEADER_RE = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")


def parse_diff(text):
    files = []
    current_file = None
    current_hunk = None
    header_lines = []

    for line in text.splitlines(keepends=True):
        if line.startswith("diff --git "):
            if current_hunk:
                current_hunk.body = current_hunk.body.rstrip("\n")
            if current_file and header_lines:
                current_file.header = "".join(header_lines)
            current_file = FileDiff(header="")
            files.append(current_file)
            header_lines = [line]
            current_hunk = None
            continue

        m = HUNK_HEADER_RE.match(line)
        if m:
            if current_hunk:
                current_hunk.body = current_hunk.body.rstrip("\n")
            if current_file and header_lines:
                current_file.header = "".join(header_lines)
                header_lines = []
            offset = int(m.group(1))
            count = int(m.group(2)) if m.group(2) else 1
            current_hunk = Hunk(
                id=hunk_id(offset, count),
                header_line=line.rstrip("\n"),
                body="",
            )
            if current_file:
                current_file.hunks.append(current_hunk)
        elif current_hunk is not None:
            current_hunk.body += line
        elif current_file is not None:
            header_lines.append(line)

    if current_hunk:
        current_hunk.body = current_hunk.body.rstrip("\n")
    if current_file and header_lines:
        current_file.header = "".join(header_lines)

    return files
