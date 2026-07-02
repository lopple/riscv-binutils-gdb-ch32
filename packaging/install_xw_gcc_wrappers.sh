#!/usr/bin/env bash
set -euo pipefail

prefix="${1:?usage: install_xw_gcc_wrappers.sh <prefix> <wrapper>}"
wrapper="${2:?usage: install_xw_gcc_wrappers.sh <prefix> <wrapper>}"

for tool in gcc g++ c++; do
  path="$prefix/bin/riscv-none-embed-$tool"
  if [ -f "$path" ]; then
    real="$path.real"
    if [ -e "$real" ]; then
      echo "refusing to overwrite existing wrapper target: $real" >&2
      exit 1
    fi
    mv "$path" "$real"
    cp "$wrapper" "$path"
    chmod +x "$path"
  fi
done
