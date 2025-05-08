#!/usr/bin/env bash
set -euo pipefail

echo "Installing dependencies…"

# 1) Ensure Python3 & pip are present
if ! command -v python3 &>/dev/null; then
  echo "Error: Python3 not found. On macOS, install Xcode CLT; on Linux, 'sudo apt install python3'."
  exit 1
fi

# 2) Install ffmpeg
if ! command -v ffmpeg &>/dev/null; then
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Installing ffmpeg via Homebrew…"
    brew install ffmpeg
  else
    echo "Installing ffmpeg via apt…"
    sudo apt update
    sudo apt install -y ffmpeg
  fi
else
  echo "ffmpeg OK"
fi

# 3) Install GNU coreutils (for shuf)
if ! command -v shuf &>/dev/null; then
  if [[ "$(uname)" == "Darwin" ]]; then
    echo "Installing coreutils via Homebrew…"
    brew install coreutils
    ln -sf "$(brew --prefix)/bin/gshuf" /usr/local/bin/shuf
  else
    echo "coreutils should already include shuf on Linux"
  fi
else
  echo "shuf OK"
fi

# 4) Set up Python venv & PySceneDetect
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
