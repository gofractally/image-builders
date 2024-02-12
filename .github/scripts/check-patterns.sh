#!/bin/bash

# Enable globstar for recursive globbing
shopt -s globstar

ALL_CHANGED_FILES="$1"
IFS=' ' read -r -a changed <<< $ALL_CHANGED_FILES

TOOL_CONFIG_PATTERNS=("docker/tool-config.Dockerfile .github/workflows/tool-config.yml docker/conf/**")
BUILDER_2004_PATTERNS=("docker/ubuntu-2004-builder.Dockerfile .github/workflows/builder-ubuntu.yml")
BUILDER_2204_PATTERNS=("docker/ubuntu-2204-builder.Dockerfile .github/workflows/builder-ubuntu.yml")
CONTRIB_PATTERNS=("docker/psibase-contributor.Dockerfile .github/workflows/contributor.yml")

matches_pattern() {
    local pattern="$1"
    for file in ${changed[@]}; do
        if [[ $file == $pattern ]]; then
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

for pattern in ${TOOL_CONFIG_PATTERNS[@]}; do
    if matches_pattern $pattern; then
        echo 1
        exit
    fi
done

run_2004=false
for pattern in ${BUILDER_2004_PATTERNS[@]}; do
    if matches_pattern $pattern; then
        run_2004=true
    fi
done

run_2204=false
for pattern in ${BUILDER_2204_PATTERNS[@]}; do
    if matches_pattern $pattern; then
        run_2204=true
    fi
done

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

for pattern in ${CONTRIB_PATTERNS[@]}; do
    if matches_pattern $pattern; then
        echo 5
        exit
    fi
done

echo 0
