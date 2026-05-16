# Workflow Import Notes

## Load A Workflow JSON

1. Start ComfyUI with:

   ```bat
   scripts\launch_comfyui_nvidia.bat
   ```

2. Open:

   ```text
   http://127.0.0.1:8188
   ```

3. Drag a workflow `.json` file into the ComfyUI browser window, or use ComfyUI's workflow load option from the UI.

4. Check every red or missing node warning. If nodes are missing, install custom nodes with:

   ```bat
   scripts\install_custom_nodes.bat
   ```

## Load An Image

- Drag an image directly into the ComfyUI canvas if the workflow supports image loading.
- Or use the image loader node in the workflow and select an image from ComfyUI's input folder.
- Keep source images in:

  ```text
  input
  ```

## Output Location

ComfyUI normally saves generated images under:

```text
ComfyUI_windows_portable\ComfyUI\output
```

This workspace also has a separate folder for your own exports and comparisons:

```text
output
```

## Test Before A Full 16K Render

- Crop a representative section first, especially around faces, text, thin lines, hands, spider webs, gradients, and high-detail edges.
- Run the same crop through `4x-UltraSharp`, `RealESRGAN_x4plus`, and `BSRGAN`.
- Compare edge clarity, color separation, and whether details changed too much.
- Keep denoise low for source preservation. Start around `0.15` to `0.22`.
- Increase tile size only after a smaller test succeeds without VRAM errors.

## Compare Upscalers

Use the same source crop and the same workflow settings for each upscaler:

- `4x-UltraSharp.pth`: try first for crisp map-art style edges.
- `RealESRGAN_x4plus.pth`: compare for general image cleanup and detail recovery.
- `BSRGAN.pth`: compare when RealESRGAN looks too sharp or artificial.

Pick the model that preserves the original composition and converts best to the Minecraft carpet palette. The cleanest visual result is not always the best map-art result.
