# Minecraft Map-Art Upscale Settings

These are safe starting settings for an RTX 4060. Use tiled workflows for large images and test on a smaller crop first.

## RTX 4060 Safe Mode

- Upscaler: `4x-UltraSharp` first
- Backup upscalers: `RealESRGAN_x4plus`, `BSRGAN`
- Tile size: `512`
- Tile overlap/padding: `64`
- Denoise: `0.15` to `0.22`
- CFG: `4` to `6`
- Steps: `20` to `28`
- Sampler: `DPM++ 2M Karras`

## Rules For Large Images

- Do not start with high denoise.
- Do not attempt full 16K all at once.
- Test on a smaller crop first.
- Use tiled workflows only for large images.
- Save comparison outputs before committing to a final render.

## Goal

- Preserve original composition.
- Clean edges.
- Keep strong color separation.
- Use low hallucination settings.
- Produce output that converts cleanly into the Minecraft carpet palette.

## Warning

High denoise can change faces, text, hands, spider webs, and small details. It can also make Minecraft carpet palette conversion worse by adding colors and textures that were not in the source.
