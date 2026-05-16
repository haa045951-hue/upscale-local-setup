$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
& "$Root\ComfyUI_windows_portable\python_embeded\python.exe" "$Root\scripts\comfy_batch_upscale.py" `
  --category "safe_restore" `
  --workflow "$Root\workflows\SAFE_RESTORE_ONLY.json" `
  --input-dir "$Root\input_batch\safe_restore" `
  --output-4x "$Root\output_batch\safe_restore\4x" `
  --output-final "$Root\output_batch\safe_restore\final" `
  --log "$Root\logs\safe_restore_batch.csv"
