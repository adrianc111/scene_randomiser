# requires running as Administrator
Write-Host "Installing dependencies…"

# 1) ffmpeg via Chocolatey
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  choco install -y ffmpeg
} else { Write-Host "ffmpeg OK" }

# 2) Git for shuf (or use built‑in PowerShell shuffle)
if (-not (Get-Command shuf -ErrorAction SilentlyContinue)) {
  choco install -y coreutils
} else { Write-Host "shuf OK" }

# 3) Python + venv + PySceneDetect
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  choco install -y python
}
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install --upgrade pip
pip install scenedetect

Write-Host "All set!  Run '.venv\Scripts\Activate.ps1' before using."
