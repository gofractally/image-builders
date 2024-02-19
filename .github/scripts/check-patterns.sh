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


run_tc="0"
for pattern in ${TOOL_CONFIG_PATTERNS[@]}; do
    if matches_pattern $pattern; then
        run_tc="1"
        break
    fi
done

run_2004="0"
for pattern in ${BUILDER_2004_PATTERNS[@]}; do
    if matches_pattern $pattern; then
        run_2004="1"
        break
    fi
done

run_2204="0"
for pattern in ${BUILDER_2204_PATTERNS[@]}; do
    if matches_pattern $pattern; then
        run_2204="1"
        break
    fi
done

run_contrib="0"
if [[ "$run_tc" == "1" ]] || [[ "$run_2204" == "1" ]]; then
    run_contrib="1"
else
    for pattern in ${CONTRIB_PATTERNS[@]}; do
        if matches_pattern $pattern; then
            run_contrib="1"
            break
        fi
    done
fi

echo "${run_tc} ${run_2004} ${run_2204} ${run_contrib}"
