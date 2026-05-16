$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
& "$Root\ComfyUI_windows_portable\python_embeded\python.exe" "$Root\scripts\comfy_batch_upscale.py" `
  --category "digital_art" `
  --workflow "$Root\workflows\DIGITAL_ART_4x16x.json" `
  --input-dir "$Root\input_batch\digital_art" `
  --output-4x "$Root\output_batch\digital_art\4x" `
  --output-final "$Root\output_batch\digital_art\final" `
  --log "$Root\logs\digital_art_batch.csv"
