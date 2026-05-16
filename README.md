# ComfyUI Batch Upscaling Setup

Workspace:

```text
Clone this repository anywhere on Windows.
```

## Fresh Setup

From a new clone, run:

```bat
setup.bat
```

That script creates the workspace folders, downloads/extracts ComfyUI Windows Portable, installs the custom nodes, and downloads the upscale/SD 1.5 model files. It expects Git, curl, and 7-Zip to be available on PATH or in the standard 7-Zip install location.

To remove local generated files before archiving or rebuilding:

```bat
clean.bat
```

`clean.bat` only removes files ignored by git and asks for confirmation before deleting anything.

Hardware target:

- NVIDIA RTX 4060, about 8 GB VRAM
- Ryzen 7 5700X
- 22 GB RAM

## Installed Components

- ComfyUI Windows Portable NVIDIA build
- ComfyUI Manager
- Ultimate SD Upscale for ComfyUI
- ControlNet Aux
- WAS Node Suite
- API batch runner: `scripts\comfy_batch_upscale.py`
- PowerShell and BAT launchers for each batch category

## Folder Layout

Inputs:

```text
input_batch\photos
input_batch\anime
input_batch\digital_art
input_batch\safe_restore
```

Outputs:

```text
output_batch\photos\4x
output_batch\photos\final
output_batch\anime\4x
output_batch\anime\final
output_batch\digital_art\4x
output_batch\digital_art\final
output_batch\safe_restore\4x
output_batch\safe_restore\final
```

Logs:

```text
logs
```

## Upscale Models

Installed in:

```text
ComfyUI_windows_portable\ComfyUI\models\upscale_models
```

Expected files:

- `4x-UltraSharp.pth`
- `RealESRGAN_x4plus.pth`
- `RealESRGAN_x4plus_anime_6B.pth`
- `BSRGAN.pth`

## SD 1.5 Checkpoints

Installed or attempted in:

```text
ComfyUI_windows_portable\ComfyUI\models\checkpoints
```

Expected files:

- `realisticVisionV60B1_v60B1VAE.safetensors`
- `epicrealism_naturalSinRC1VAE.safetensors`
- `meinamix_v12Final.safetensors`
- `Counterfeit-V3.0_fix_fp16.safetensors`
- `dreamshaper_8.safetensors`
- `revAnimated_v122.safetensors`

If any are missing, see:

```text
MODEL_DOWNLOAD_INSTRUCTIONS.txt
```

## VAE

Expected file:

```text
ComfyUI_windows_portable\ComfyUI\models\vae\vae-ft-mse-840000-ema-pruned.safetensors
```

The current workflows use the checkpoint VAE output by default. The downloaded VAE is available for manual workflow edits if needed.

## Workflows

API workflow templates:

```text
workflows\PHOTO_4x16x.json
workflows\ANIME_ILLUSTRATION_4x16x.json
workflows\DIGITAL_ART_4x16x.json
workflows\SAFE_RESTORE_ONLY.json
```

These are designed for the batch scripts. They preserve aspect ratio and do not crop or stretch.

Photo, anime, and digital-art workflows do:

1. Load one uploaded image.
2. Save an intermediate 4x model-upscale image.
3. Run a tiled Ultimate SD Upscale second pass at 4x scale.
4. Save final 16x output.

Safe restore does:

1. Load one uploaded image.
2. Run BSRGAN 4x upscale.
3. Run a second BSRGAN 4x upscale.
4. Save final 16x output without SD denoise.

## Launch ComfyUI

```bat
scripts\launch_comfyui_nvidia.bat
```

Open:

```text
http://127.0.0.1:8188
```

Keep the terminal open while using ComfyUI.

## Run Batch Scripts

Put images into the matching input folder, then run one of these:

```bat
scripts\run_photo_batch.bat
scripts\run_anime_batch.bat
scripts\run_digital_art_batch.bat
scripts\run_safe_restore_batch.bat
```

The scripts start ComfyUI automatically if it is not already running, then process images one by one through the API.

To redownload missing SD 1.5 checkpoints and the VAE later:

```bat
scripts\download_sd15_models.bat
```

## Output Filenames

If input is:

```text
myimage.png
```

Outputs are:

```text
myimage_4x.png
myimage_final.png
```

The scripts skip files whose two outputs already exist unless you run the Python helper with `--overwrite`.

## RTX 4060 Defaults

- Tile size: `512`
- Tile padding: `64`
- Batch size: `1`
- Tiled decode: enabled for SD refinement
- Photo denoise: `0.12`
- Anime denoise: `0.16`
- Digital art denoise: `0.14`
- Safe restore: no SD denoise

The final 16x pass can create very large files. Test one small image or crop before running a full folder.

## Troubleshooting

### Out Of VRAM

- Close other GPU-heavy apps.
- Use Safe Restore first.
- Reduce source image size before processing.
- Keep tile size at `512`; do not increase it on the RTX 4060.
- Edit the workflow JSON and reduce `tile_width` / `tile_height` to `384` if needed.

### Same Image Repeated Multiple Times

Use the batch scripts, not a UI-only batch loader. The scripts upload one image, queue one prompt, wait for completion, then move to the next file.

### Missing Node

Run:

```bat
scripts\install_custom_nodes.bat
```

Then restart ComfyUI.

### Missing Checkpoint

Check:

```text
ComfyUI_windows_portable\ComfyUI\models\checkpoints
```

Then read:

```text
MODEL_DOWNLOAD_INSTRUCTIONS.txt
```

### Missing Upscale Model

Run:

```bat
scripts\download_upscale_models.bat
```

Then restart ComfyUI.
