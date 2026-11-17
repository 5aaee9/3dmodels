#!/usr/bin/env python3
"""Check OpenSCAD sources and configured variants without rendering STL files."""

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parents[1]
DIAGNOSTIC = re.compile(r"^\s*(?:WARNING|ERROR|Parser error):", re.MULTILINE)


def find_openscad():
    override = os.environ.get("OPENSCAD_BIN")
    if override:
        # An explicit override must not silently fall back to another version.
        binary = shutil.which(override)
        if binary:
            return binary
        raise ValueError(f"OPENSCAD_BIN is not an executable: {override}")

    names = ["openscad.com", "openscad"] if os.name == "nt" else ["openscad"]
    for name in names:
        binary = shutil.which(name)
        if binary:
            return binary

    candidates = [Path("/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD")]
    if os.name == "nt":
        candidates = [
            Path(os.environ.get(key, default)) / "OpenSCAD" / "openscad.com"
            for key, default in [
                ("ProgramFiles", r"C:\Program Files"),
                ("ProgramFiles(x86)", r"C:\Program Files (x86)"),
            ]
        ]
    for candidate in candidates:
        if candidate.is_file():
            return str(candidate)
    raise ValueError("OpenSCAD not found. Install OpenSCAD 2021.01+ or set OPENSCAD_BIN.")


def lint(binary, source, defines, output):
    command = [
        binary,
        "--hardwarnings",
        "--check-parameters=true",
        "--check-parameter-ranges=true",
        "-o", str(output),
    ]
    for definition in defines:
        command.extend(["-D", definition])
    command.append(str(source))
    result = subprocess.run(
        command, cwd=source.parent, capture_output=True,
        text=True, encoding="utf-8", errors="replace", timeout=120,
    )
    diagnostics = result.stdout + result.stderr
    # Some OpenSCAD versions return zero even for assertions/CSG diagnostics.
    passed = (
        result.returncode == 0
        and not DIAGNOSTIC.search(diagnostics)
        and output.is_file()
    )
    return passed, diagnostics


def main():
    try:
        binary = find_openscad()
        sources = sorted((ROOT / "models").rglob("*.scad"))
        if not sources:
            raise ValueError("No .scad sources found under models/.")
        cases = [(source, [], source.relative_to(ROOT).as_posix()) for source in sources]
        variants = json.loads((ROOT / ".openscad-lint.json").read_text(encoding="utf-8"))
        for variant in variants:
            source = ROOT / variant["file"]
            defines = variant["defines"]
            if source not in sources or not isinstance(defines, list) or not all(
                isinstance(value, str) for value in defines
            ):
                raise ValueError(f"Invalid lint variant: {variant!r}")
            label = f"{variant['file']} ({', '.join(defines)})"
            cases.append((source, defines, label))

        print(f"OpenSCAD: {binary}")
        failures = 0
        with tempfile.TemporaryDirectory(prefix="openscad-lint-") as directory:
            for index, (source, defines, label) in enumerate(cases):
                try:
                    passed, diagnostics = lint(
                        binary, source, defines, Path(directory) / f"{index}.csg",
                    )
                except (OSError, subprocess.TimeoutExpired) as error:
                    passed, diagnostics = False, str(error)
                print(f"{'PASS' if passed else 'FAIL'} {label}")
                if diagnostics.strip():
                    print(diagnostics.rstrip())
                failures += not passed
        print(f"{len(cases) - failures}/{len(cases)} checks passed.")
        return 1 if failures else 0
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(f"Lint setup error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
