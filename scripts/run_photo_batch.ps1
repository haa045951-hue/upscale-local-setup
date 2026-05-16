$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
& "$Root\ComfyUI_windows_portable\python_embeded\python.exe" "$Root\scripts\comfy_batch_upscale.py" `
  --category "photos" `
  --workflow "$Root\workflows\PHOTO_4x16x.json" `
  --input-dir "$Root\input_batch\photos" `
  --output-4x "$Root\output_batch\photos\4x" `
  --output-final "$Root\output_batch\photos\final" `
  --log "$Root\logs\photos_batch.csv"
