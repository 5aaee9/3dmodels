#!/usr/bin/env bash
set -eu

OPENSCAD_BIN="${OPENSCAD_BIN:-openscad}"
if [ -n "${BOSL2_PATH:-}" ]; then
    if [ -n "${OPENSCADPATH:-}" ]; then
        export OPENSCADPATH="${BOSL2_PATH}:${OPENSCADPATH}"
    else
        export OPENSCADPATH="${BOSL2_PATH}"
    fi
fi

"$OPENSCAD_BIN" --export-format binstl \
    -o desiccant_box_rebuilt.stl desiccant_box.scad
"$OPENSCAD_BIN" --export-format binstl \
    -o desiccant_baffle_rebuilt.stl desiccant_baffle.scad
"$OPENSCAD_BIN" --export-format binstl \
    -o box_lid_rebuilt.stl box_lid.scad
