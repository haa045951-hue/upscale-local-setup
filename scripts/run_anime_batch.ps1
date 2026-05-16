$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
& "$Root\ComfyUI_windows_portable\python_embeded\python.exe" "$Root\scripts\comfy_batch_upscale.py" `
  --category "anime" `
  --workflow "$Root\workflows\ANIME_ILLUSTRATION_4x16x.json" `
  --input-dir "$Root\input_batch\anime" `
  --output-4x "$Root\output_batch\anime\4x" `
  --output-final "$Root\output_batch\anime\final" `
  --log "$Root\logs\anime_batch.csv"
