#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


REQUIRED = (
    "README.md", "manifest.json", "install.ps1", "Env4BCSetup.pyw",
    "docs/更新与修复规则.md", "docs/API与CCSwitch配置.md",
    "program/cc-switch/cc-switch.exe", "program/cc-switch/LICENSE",
    "program/Seedance API配置工具.exe", "scripts/configure_ccswitch_model.py",
)
FORBIDDEN_NAMES = {
    "credentials.json", "doubao_api_config.json", "cc-switch.db", "task-log.jsonl",
    ".env", "providers.json", "provider.json", "install-state.json",
}
FORBIDDEN_SUFFIXES = {
    ".db", ".db-wal", ".db-shm", ".sqlite", ".sqlite3", ".bak", ".backup",
}
FORBIDDEN_USER_PARTS = {".cc-switch", "backups", "api_pool", "runtime", "user-data"}
FORBIDDEN_BUSINESS_PARTS = {
    "1.projects", "2.submission", "6.snapshot", "角色音色素材", "文字素材",
    "已生成视频", "已转mp3",
}
TEXT_SUFFIXES = {".md", ".json", ".py", ".pyw", ".ps1", ".txt", ".yaml", ".yml"}
SECRET_PATTERNS = (
    re.compile(r'"(?:api[_-]?key|token|secret|access[_-]?token)"\s*:\s*"(?!YOUR_API_KEY|你的API_KEY|<[^>]+>|\*+|\$\{|self\.)[^"]{10,}"', re.I),
    re.compile(r"\b(?:sk|gh[opsu])[-_][A-Za-z0-9_-]{20,}\b"),
    re.compile(r"Authorization\s*[:=]\s*[\"']Bearer\s+[A-Za-z0-9._-]{16,}", re.I),
)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package-root", required=True)
    args = parser.parse_args()
    root = Path(args.package_root).resolve()
    errors: list[str] = []

    for item in REQUIRED:
        if not (root / item).is_file():
            errors.append(f"missing: {item}")

    for path in root.rglob("*"):
        rel = path.relative_to(root)
        lowered_parts = {part.lower() for part in rel.parts}
        if "__pycache__" in lowered_parts or path.suffix.lower() == ".pyc":
            errors.append(f"cache: {rel}")
        if any(part.lower() in lowered_parts for part in FORBIDDEN_BUSINESS_PARTS):
            errors.append(f"business/material directory: {rel}")
        if any(part.lower() in lowered_parts for part in FORBIDDEN_USER_PARTS):
            errors.append(f"user/runtime directory: {rel}")
        if not path.is_file():
            continue
        if path.name.lower() in FORBIDDEN_NAMES:
            errors.append(f"private/runtime file: {rel}")
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            errors.append(f"database/backup file: {rel}")
        if path.suffix.lower() in TEXT_SUFFIXES:
            try:
                content = path.read_text(encoding="utf-8-sig")
            except UnicodeDecodeError:
                errors.append(f"text file is not UTF-8: {rel}")
                continue
            if any(pattern.search(content) for pattern in SECRET_PATTERNS):
                errors.append(f"possible secret: {rel}")

    try:
        manifest = json.loads((root / "manifest.json").read_text(encoding="utf-8-sig"))
        if manifest.get("update_policy") != "repair-missing-only":
            errors.append("update policy must be repair-missing-only")
        if manifest.get("material_policy") != "never-touch-user-materials":
            errors.append("material policy must be never-touch-user-materials")
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"invalid manifest: {exc}")

    if errors:
        print("VALIDATION FAILED")
        for error in errors:
            print(f"- {error}")
        return 1
    print("VALIDATION PASSED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
