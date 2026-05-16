# Batch Upscaling Model Guide

Use the batch folders and scripts by image type. The scripts process files one by one through the ComfyUI API, so they do not repeat the same image like some UI-only batch loaders can.

## Photo

Use:

```text
workflows\PHOTO_4x16x.json
scripts\run_photo_batch.bat
```

Input:

```text
input_batch\photos
```

Best for:

- train photo -> `PHOTO_4x16x`
- lighthouse photo -> `PHOTO_4x16x`
- portraits, camera photos, real-world images

Defaults:

- Upscaler: `RealESRGAN_x4plus.pth`
- Checkpoint: `realisticVisionV60B1_v60B1VAE.safetensors`
- Denoise: `0.12`
- Tile size: `512`
- Tile padding: `64`

## Anime / Illustration

Use:

```text
workflows\ANIME_ILLUSTRATION_4x16x.json
scripts\run_anime_batch.bat
```

Input:

```text
input_batch\anime
```

Best for:

- anime wallpaper -> `ANIME_ILLUSTRATION_4x16x`
- scenic stylized art -> `ANIME_ILLUSTRATION_4x16x`
- illustrated characters, anime backgrounds, clean line art

Defaults:

- Upscaler: `4x-UltraSharp.pth`
- Checkpoint: `meinamix_v12Final.safetensors`
- Denoise: `0.16`
- Tile size: `512`
- Tile padding: `64`

## Digital Art

Use:

```text
workflows\DIGITAL_ART_4x16x.json
scripts\run_digital_art_batch.bat
```

Input:

```text
input_batch\digital_art
```

Best for:

- concept-art scene -> `DIGITAL_ART_4x16x`
- stylized digital painting
- game art, fantasy art, concept environments

Defaults:

- Upscaler: `4x-UltraSharp.pth`
- Checkpoint: `dreamshaper_8.safetensors`
- Alternate checkpoint installed: `revAnimated_v122.safetensors`
- Denoise: `0.14`
- Tile size: `512`
- Tile padding: `64`

## Safe Restore

Use:

```text
workflows\SAFE_RESTORE_ONLY.json
scripts\run_safe_restore_batch.bat
```

Input:

```text
input_batch\safe_restore
```

Best for:

- fragile grayscale art -> `SAFE_RESTORE_ONLY`
- monochrome art
- paintings
- special edits
- images where composition and exact shapes matter more than added detail

Defaults:

- Upscaler: `BSRGAN.pth`
- No SD checkpoint
- No denoise
- The final file is a second BSRGAN upscale to 16x, without SD denoise.

## Output Names

If the input is:

```text
myimage.png
```

The script writes:

```text
myimage_4x.png
myimage_final.png
```

The scripts preserve the original base filename, aspect ratio, and full image bounds. They do not crop or stretch.
