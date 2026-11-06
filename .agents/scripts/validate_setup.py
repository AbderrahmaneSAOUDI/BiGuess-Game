#!/usr/bin/env python3
"""Read-only structural checks for the repository's agent development setup.

Uses only the Python standard library. Does not execute hooks, Git commands,
Flutter, version scripts, or daemons; compile() writes no bytecode cache.
"""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from urllib.parse import unquote, urlsplit


REQUIRED_RULES = (
    "code-quality-and-safety", "codebase-indexing",
    "game-standards-and-architecture", "git-workflow-and-versioning",
    "release-automation", "speed-and-efficiency", "strict-scope-and-additions",
)
REQUIRED_SKILLS = (
    "agent-maintenance", "backend-development", "biguess-ota-release",
    "codebase-indexer", "create-hook", "create-rule", "create-skill",
    "debugging", "feature-development", "git-commit-push",
    "topic-pack-maintenance",
)
REQUIRED_MAPS = (
    "architecture", "file-map", "integrations", "known-issues",
    "roadmap-status", "test-map",
)
HOOK_EVENTS = {"SessionStart", "PreToolUse", "PostToolUse", "Stop"}
PLACEHOLDER = re.compile(
    r"\[(?:TODO|TBD)(?::[^\]]*)?\]"
    r"|\b(?:TODO|TBD):\s*(?:replace|fill|complete|describe|implement|add)\b"
    r"|<(?:skill-name|hook-name|rule-name|project-name|description)>",
    re.IGNORECASE,
)
LINK = re.compile(r"\[[^\]\n]*\]\((<[^>\n]+>|[^\s)]+)(?:\s+\"[^\"]*\")?\)")
HOOK_TARGET = re.compile(r"(\.agents/hooks/[A-Za-z0-9_./-]+\.py)\b")


def outside_fences(content: str) -> str:
    """Remove fenced examples while preserving line numbers for diagnostics."""
    result: list[str] = []
    fence: str | None = None
    for line in content.splitlines():
        match = re.match(r"^\s*(`{3,}|~{3,})", line)
        if match:
            token = match.group(1)
            if fence is None:
                fence = token
            elif token[0] == fence[0] and len(token) >= len(fence):
                fence = None
            result.append("")
        else:
            result.append(line if fence is None else "")
    return "\n".join(result)


class SetupValidator:
    def __init__(self, root: Path):
        self.root = root.resolve()
        self.errors: list[str] = []
        self.checks = 0

    def label(self, path: Path) -> str:
        try:
            return str(path.relative_to(self.root))
        except ValueError:
            return str(path)

    def require(self, condition: bool, message: str) -> bool:
        self.checks += 1
        if not condition:
            self.errors.append(message)
        return condition

    def read(self, path: Path) -> str | None:
        try:
            return path.read_text(encoding="utf-8")
        except (OSError, UnicodeError) as exc:
            self.errors.append(f"{self.label(path)}: cannot read ({exc})")
            return None

    def read_json(self, path: Path) -> object | None:
        content = self.read(path)
        if content is None:
            return None
        try:
            return json.loads(content)
        except json.JSONDecodeError as exc:
            self.errors.append(f"{self.label(path)}:{exc.lineno}: invalid JSON")
            return None

    def frontmatter(self, path: Path, *, skill: bool) -> None:
        content = self.read(path)
        if content is None:
            return
        match = re.match(r"\A---\r?\n(.*?)\r?\n---(?:\r?\n|$)", content, re.DOTALL)
        if not self.require(bool(match), f"{self.label(path)}: missing YAML frontmatter"):
            return
        assert match is not None
        fields = dict(re.findall(r"^([a-z_]+):\s*(.*?)\s*$", match.group(1), re.MULTILINE))
        description = fields.get("description", "").strip("'\"")
        self.require(bool(description) and description not in {"|", ">"},
                     f"{self.label(path)}: description must be a nonempty scalar")
        if skill:
            name = fields.get("name", "").strip("'\"")
            self.require(name == path.parent.name and bool(re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name)),
                         f"{self.label(path)}: name must match its kebab-case directory")
        else:
            self.require(fields.get("trigger", "").strip("'\"") == "always_on",
                         f"{self.label(path)}: expected trigger: always_on")

    def markdown(self, path: Path) -> None:
        content = self.read(path)
        if content is None:
            return
        prose = outside_fences(content)
        for number, line in enumerate(prose.splitlines(), 1):
            # Meta playbooks legitimately document paths such as
            # `.agents/rules/<rule-name>.md`; those are examples, not scaffolds.
            plain = re.sub(r"(`+).*?\1", "", line)
            self.require(not PLACEHOLDER.search(plain),
                         f"{self.label(path)}:{number}: unfinished scaffold placeholder")
            for match in LINK.finditer(line):
                destination = match.group(1).strip("<>")
                parts = urlsplit(destination)
                if parts.scheme or parts.netloc or not parts.path:
                    continue
                target = Path(unquote(parts.path))
                if target.is_absolute():
                    continue
                resolved = (path.parent / target).resolve()
                cache = self.root / ".agents/cache"
                if resolved == cache or cache in resolved.parents:
                    continue
                self.require(resolved.exists(),
                             f"{self.label(path)}:{number}: missing link target {destination}")

    def hooks(self) -> None:
        canonical = self.root / ".agents/hooks.json"
        native = self.root / ".codex/hooks.json"
        self.require(native.is_file() and native.resolve() == canonical.resolve(),
                     ".codex/hooks.json: must resolve to .agents/hooks.json")
        data = self.read_json(canonical)
        if not self.require(isinstance(data, dict), ".agents/hooks.json: expected JSON object"):
            return
        events = data.get("hooks")
        if not self.require(isinstance(events, dict), ".agents/hooks.json: expected hooks object"):
            return
        self.require(set(events) == HOOK_EVENTS,
                     ".agents/hooks.json: expected SessionStart, PreToolUse, PostToolUse, Stop")
        for event, groups in sorted(events.items()):
            if not self.require(isinstance(groups, list) and bool(groups), f"hooks {event}: expected nonempty group list"):
                continue
            for index, group in enumerate(groups):
                where = f"hooks {event}[{index}]"
                if not self.require(isinstance(group, dict), f"{where}: expected object"):
                    continue
                if "matcher" in group:
                    self.require(isinstance(group["matcher"], str) and bool(group["matcher"]),
                                 f"{where}: matcher must be a nonempty string")
                commands = group.get("hooks")
                if not self.require(isinstance(commands, list) and bool(commands), f"{where}: expected hooks list"):
                    continue
                for command in commands:
                    if not self.require(isinstance(command, dict), f"{where}: command must be an object"):
                        continue
                    self.require(command.get("type") == "command", f"{where}: expected command hook")
                    timeout = command.get("timeout")
                    self.require(type(timeout) in (int, float) and 0 < timeout <= 60,
                                 f"{where}: timeout must be positive and at most 60 seconds")
                    text = command.get("command", "")
                    targets = HOOK_TARGET.findall(text) if isinstance(text, str) else []
                    if self.require(bool(targets), f"{where}: expected repository hook .py target"):
                        for target in targets:
                            self.require((self.root / target).is_file(), f"{where}: missing {target}")

    def sidecars(self) -> None:
        for name in ("codebase-index-daemon", "test-daemon"):
            path = self.root / ".agents/sidecars" / name / "sidecar.json"
            data = self.read_json(path)
            if not self.require(isinstance(data, dict), f"{self.label(path)}: expected object"):
                continue
            where = self.label(path)
            self.require(data.get("name") == name, f"{where}: name must match directory")
            self.require(data.get("enabled") is False, f"{where}: sidecar must remain opt-in")
            self.require(isinstance(data.get("description"), str) and bool(data["description"]),
                         f"{where}: missing description")
            self.require(data.get("working_directory") == "repository-root", f"{where}: expected repository-root working directory")
            self.require(data.get("restart_policy") == "never", f"{where}: expected restart_policy never")
            self.require(data.get("command") == "bash", f"{where}: expected bash launcher")
            args = data.get("args")
            if not self.require(isinstance(args, list) and bool(args) and all(isinstance(arg, str) for arg in args),
                                f"{where}: expected nonempty string args list"):
                continue
            for argument in args:
                if argument.startswith(".agents/"):
                    self.require((self.root / argument).is_file(), f"{where}: missing command argument {argument}")

    def run(self) -> int:
        required = ["AGENTS.md", ".agents/README.md", ".agents/hooks.json"]
        required += [f".agents/rules/{name}.md" for name in REQUIRED_RULES]
        required += [f".agents/skills/{name}/SKILL.md" for name in REQUIRED_SKILLS]
        required += [f".agents/sidecars/{name}.md" for name in REQUIRED_MAPS]
        for relative in required:
            self.require((self.root / relative).is_file(), f"missing required file {relative}")
        agents = self.root / ".agents"
        for path in sorted((agents / "skills").glob("*/SKILL.md")):
            self.frontmatter(path, skill=True)
        for path in sorted((agents / "rules").glob("*.md")):
            self.frontmatter(path, skill=False)
        documents = [self.root / "AGENTS.md"] + sorted(agents.rglob("*.md"))
        for path in documents:
            if "cache" not in path.relative_to(self.root).parts:
                self.markdown(path)
        self.hooks()
        self.sidecars()
        for path in sorted(agents.rglob("*.py")):
            if {"cache", "__pycache__"}.intersection(path.relative_to(agents).parts):
                continue
            content = self.read(path)
            if content is not None:
                try:
                    compile(content, str(path), "exec")
                    self.checks += 1
                except SyntaxError as exc:
                    self.errors.append(f"{self.label(path)}:{exc.lineno}: {exc.msg}")
        if self.errors:
            print(f"Agent setup: {len(self.errors)} error(s)")
            for error in self.errors:
                print(f"- {error}")
            return 1
        print(f"Agent setup valid ({self.checks} checks; no hooks or daemons executed)")
        return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2],
                        help="Repository root to inspect (defaults to this checkout)")
    args = parser.parse_args()
    return SetupValidator(args.root).run()


if __name__ == "__main__":
    raise SystemExit(main())
