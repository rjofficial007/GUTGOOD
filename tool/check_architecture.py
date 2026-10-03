#!/usr/bin/env python3
"""Static architecture and import checks for the GutGood Flutter project.

This check intentionally does not replace flutter analyze or flutter test. It
only validates repository-local boundaries that can be checked without the
Flutter SDK or generated firebase_options.dart.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
TEST = ROOT / "test"

PACKAGE_IMPORT_RE = re.compile(
    r"(?:import|export)\s+['\"]package:gutgood/([^'\"]+)['\"]"
)
RELATIVE_DIRECTIVE_RE = re.compile(
    r"(?:import|export|part)\s+['\"](?!package:)([^'\"]+\.dart)['\"]"
)
PART_RE = re.compile(r"part\s+['\"]([^'\"]+\.dart)['\"]")
PART_OF_RE = re.compile(r"part\s+of\s+['\"]([^'\"]+)['\"]")
TYPED_DI_REGISTRATION_RE = re.compile(r"register(?:Lazy)?Singleton<([^>]+)>")

# These are retired source paths. Historical prose may mention a former
# generic core area, but these concrete adapter paths must not return in code
# or current documentation.
LEGACY_TOKENS = (
    "package:gutgood/core/ai/client/ai_proxy_client.dart",
    "package:gutgood/core/services/firestore/",
    "package:gutgood/core/services/analytics_service.dart",
    "package:gutgood/core/services/crashlytics_service.dart",
    "package:gutgood/core/services/remote_config_service.dart",
    "package:gutgood/core/services/storage_service.dart",
    "package:gutgood/core/services/notification_service.dart",
    "package:gutgood/core/services/off_service.dart",
    "package:gutgood/core/services/app_services.dart",
    "package:gutgood/core/services/app_version_services.dart",
    "package:gutgood/core/services/device_info_services.dart",
    "package:gutgood/core/services/internet_connection_checker.dart",
    "package:gutgood/core/services/purchase_service.dart",
    "package:gutgood/core/services/pattern_engine_service.dart",
    "package:gutgood/core/services/domain_event_persister.dart",
    "package:gutgood/core/services/debug_mock_data_service.dart",
    "package:gutgood/features/chat/domain/usecases/persist_ai_response_usecase.dart",
    "lib/core/ai/client/ai_proxy_client.dart",
    "lib/core/services/firestore/",
    "lib/core/services/analytics_service.dart",
    "lib/core/services/crashlytics_service.dart",
    "lib/core/services/remote_config_service.dart",
    "lib/core/services/storage_service.dart",
    "lib/core/services/notification_service.dart",
    "lib/core/services/off_service.dart",
    "lib/core/services/app_services.dart",
    "lib/core/services/app_version_services.dart",
    "lib/core/services/device_info_services.dart",
    "lib/core/services/internet_connection_checker.dart",
    "lib/core/services/purchase_service.dart",
    "lib/core/services/pattern_engine_service.dart",
    "lib/core/services/domain_event_persister.dart",
    "lib/core/services/debug_mock_data_service.dart",
    "lib/features/chat/domain/usecases/persist_ai_response_usecase.dart",
)

# Infrastructure that must not leak into feature domain code. Pure shared
# packages such as equatable/json helpers are intentionally not blocked here.
DOMAIN_BLOCKED_IMPORTS = (
    "package:flutter/",
    "package:flutter_",
    "package:firebase_",
    "package:cloud_firestore/",
    "package:shared_preferences/",
    "package:dio/",
    "package:purchases_flutter/",
    "package:device_info_plus/",
    "package:package_info_plus/",
    "package:permission_handler/",
    "package:timezone/",
    "package:gutgood/infrastructure/",
)


def dart_files() -> list[Path]:
    return sorted((*LIB.rglob("*.dart"), *TEST.rglob("*.dart")))


def source_files() -> list[Path]:
    return sorted((*LIB.rglob("*.dart"), *TEST.rglob("*.dart"), ROOT / "README.md", *ROOT.glob("docs/*.md")))


def display(path: Path) -> str:
    return str(path.relative_to(ROOT))


def main() -> int:
    files = dart_files()
    missing_package: list[tuple[Path, str]] = []
    missing_relative: list[tuple[Path, str]] = []
    missing_parts: list[tuple[Path, str]] = []
    bad_part_owners: list[tuple[Path, Path, str]] = []
    legacy: list[tuple[Path, str]] = []
    domain_imports: list[tuple[Path, str]] = []
    typed_di_registrations: dict[str, tuple[Path, int]] = {}
    duplicate_di_registrations: list[tuple[str, tuple[Path, int], tuple[Path, int]]] = []

    for path in files:
        text = path.read_text(errors="replace")

        for import_path in PACKAGE_IMPORT_RE.findall(text):
            if import_path == "firebase_options.dart":
                continue
            if not (LIB / import_path).exists():
                missing_package.append((path, import_path))

        for relative_path in RELATIVE_DIRECTIVE_RE.findall(text):
            if not (path.parent / relative_path).exists():
                missing_relative.append((path, relative_path))

        for part_path in PART_RE.findall(text):
            target = path.parent / part_path
            if not target.exists():
                missing_parts.append((path, part_path))
                continue
            part_text = target.read_text(errors="replace")
            owners = PART_OF_RE.findall(part_text)
            expected_file = path.name
            if not any(owner == expected_file or owner.endswith(f"/{expected_file}") for owner in owners):
                bad_part_owners.append((path, target, expected_file))

        if path.parent == ROOT / "lib/app/di":
            for line_number, line in enumerate(text.splitlines(), 1):
                match = TYPED_DI_REGISTRATION_RE.search(line)
                if not match:
                    continue
                registration_type = match.group(1).strip()
                location = (path, line_number)
                previous = typed_di_registrations.get(registration_type)
                if previous is not None:
                    duplicate_di_registrations.append((registration_type, previous, location))
                else:
                    typed_di_registrations[registration_type] = location

        if "/domain/" in display(path):
            for line in text.splitlines():
                if line.lstrip().startswith("import ") or line.lstrip().startswith("export "):
                    if any(token in line for token in DOMAIN_BLOCKED_IMPORTS):
                        domain_imports.append((path, line.strip()))

    for path in source_files():
        text = path.read_text(errors="replace")
        for token in LEGACY_TOKENS:
            if token in text:
                legacy.append((path, token))

    def report_list(title: str, entries: list[tuple], limit: int = 20) -> None:
        if not entries:
            return
        print(f"\n{title}:")
        for entry in entries[:limit]:
            print("  ", entry)
        if len(entries) > limit:
            print(f"  ... and {len(entries) - limit} more")

    report_list("Missing package imports", missing_package)
    report_list("Missing relative imports", missing_relative)
    report_list("Missing part files", missing_parts)
    report_list("Invalid part owners", bad_part_owners)
    report_list("Legacy path references", legacy)
    report_list("Feature-domain infrastructure imports", domain_imports)
    report_list("Duplicate typed DI registrations", duplicate_di_registrations)

    failures = [
        missing_package,
        missing_relative,
        missing_parts,
        bad_part_owners,
        legacy,
        domain_imports,
        duplicate_di_registrations,
    ]
    if any(failures):
        return 1

    print(f"Dart files scanned: {len(files)}")
    print("Missing package imports (excluding generated firebase_options.dart): 0")
    print("Missing relative imports: 0")
    print("Missing part files: 0")
    print("Invalid part owners: 0")
    print("Legacy path references: 0")
    print("Feature-domain infrastructure imports: 0")
    print(f"Typed DI registrations: {len(typed_di_registrations)}")
    print("Duplicate typed DI registrations: 0")
    return 0


if __name__ == "__main__":
    sys.exit(main())
