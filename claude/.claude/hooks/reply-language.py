#!/usr/bin/env python3
"""Claude Code hook: keep replies in the user's language.

UserPromptSubmit: detect the language of the prompt, remember it per session,
and remind Claude to answer in it.
SessionStart (source=compact): compaction drops the user's own messages, so
re-inject the remembered language; fall back to the transcript if needed.
Python 3.9 compatible (macOS system python3).
"""
import json
import os
import re
import sys
import tempfile

STATE_DIR = os.path.join(tempfile.gettempdir(), "claude-reply-language")

LANGS = [
    ("ja", re.compile(r"[\u3040-\u30ff]"), "Japanese (日本語)"),
    ("ko", re.compile(r"[\uac00-\ud7af]"), "Korean (한국어)"),
    ("zh", re.compile(r"[\u4e00-\u9fff]"), "Chinese (中文, same script as the user)"),
]
LATIN = re.compile(r"[A-Za-z]")


def detect(text):
    text = re.sub(r"```.*?```|`[^`]*`|https?://\S+", " ", text, flags=re.S)
    for code, pattern, _ in LANGS:  # kana before Han: Japanese also uses kanji
        if len(pattern.findall(text)) >= 2:
            return code
    return "en" if len(LATIN.findall(text)) >= 8 else None


def name(code):
    for c, _, n in LANGS:
        if c == code:
            return n
    return "English"


def state_path(session_id):
    return os.path.join(STATE_DIR, re.sub(r"[^A-Za-z0-9_-]", "_", session_id))


def from_transcript(path):
    """Language of the most recent real user message in the transcript."""
    try:
        with open(path, "rb") as f:
            f.seek(0, 2)
            f.seek(max(0, f.tell() - 8_000_000))
            lines = f.read().decode("utf-8", "ignore").splitlines()
    except OSError:
        return None
    for line in reversed(lines):
        try:
            row = json.loads(line)
        except ValueError:
            continue
        if row.get("type") != "user" or row.get("isMeta") or row.get("isCompactSummary"):
            continue
        content = row.get("message", {}).get("content")
        if isinstance(content, list):
            content = " ".join(
                p.get("text", "") for p in content if isinstance(p, dict) and p.get("type") == "text"
            )
        if isinstance(content, str) and content.strip() and not content.lstrip().startswith("<"):
            code = detect(content)
            if code:
                return code
    return None


def reminder(code):
    lang = name(code)
    return (
        f"The user writes in {lang}. Write every user-visible message in {lang}: "
        "short progress notes between tool calls, questions, and final summaries alike, "
        "even when the context so far (summaries, docs, tool output) is in another language. "
        "Code, identifiers, and commit messages follow the repo's own rules."
    )


def emit(event, code):
    print(json.dumps({"hookSpecificOutput": {"hookEventName": event, "additionalContext": reminder(code)}}))


def main():
    data = json.load(sys.stdin)
    event = data.get("hook_event_name")
    session = data.get("session_id") or "default"

    if event == "UserPromptSubmit":
        prompt = data.get("prompt") or ""
        if prompt.lstrip().startswith("<"):  # turns Claude Code starts itself
            return
        code = detect(prompt)
        if not code:
            return
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(state_path(session), "w") as f:
            f.write(code)
        if code != "en":
            emit(event, code)
    elif event == "SessionStart" and data.get("source") == "compact":
        code = None
        try:
            with open(state_path(session)) as f:
                code = f.read().strip() or None
        except OSError:
            pass
        code = code or from_transcript(data.get("transcript_path") or "")
        if code:
            emit(event, code)


if __name__ == "__main__":
    try:
        main()
    except Exception as e:  # a broken hook must never block the user's prompt
        print(f"reply-language hook: {e}", file=sys.stderr)
