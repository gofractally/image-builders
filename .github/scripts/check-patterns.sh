#!/bin/bash

ALL_CHANGED_FILES="$1"

TOOL_CONFIG_PATTERNS="docker/tool-config.Dockerfile .github/workflows/tool-config.yml docker/conf/*"
BUILDER_2004_PATTERNS="docker/ubuntu-2004-builder.Dockerfile .github/workflows/builder-2004.yml"
BUILDER_2204_PATTERNS="docker/ubuntu-2204-builder.Dockerfile .github/workflows/builder-2204.yml"
CONTRIB_PATTERNS="docker/psibase-contributor.Dockerfile .github/workflows/contributor.yml"

matches_pattern() {
    local pattern="$1"
    for file in ${ALL_CHANGED_FILES}; do
        if [[ "$file" == $pattern ]]; then
            return 0 # Success
        fi
    done
    return 1
}

# Possible dispatching cases and their return values
# 1: run tool config (and all dependent workflows)
# 2: run 2004 builder
# 3: run 2204 builder (and dependent)
# 4: run both builders (and dependent)
# 5: run contributor 
# 0: don't run anything

if matches_pattern "${TOOL_CONFIG_PATTERNS[@]}"; then
    echo 1
    exit
fi

run_2004=false
if matches_pattern "${BUILDER_2004_PATTERNS[@]}"; then
    run_2004=true
fi

run_2204=false
if matches_pattern "${BUILDER_2204_PATTERNS[@]}"; then
    run_2204=true
fi

if $run_2004 && $run_2204; then
    echo 4
    exit
elif $run_2004; then
    echo 2
    exit
elif $run_2204; then
    echo 3
    exit
fi

if matches_pattern "${CONTRIB_PATTERNS[@]}"; then
    echo 5
    exit
fi

echo 0
