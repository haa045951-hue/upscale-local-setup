import argparse
import csv
import json
import re
import sys
import time
import uuid
from pathlib import Path
from urllib.parse import urlencode

import requests
from PIL import Image


# These batch outputs are intentionally huge. Pillow's default decompression
# bomb guard blocks files above about 178M pixels even when they were generated
# locally by this script.
Image.MAX_IMAGE_PIXELS = None

ROOT = Path(__file__).resolve().parents[1]
PORTABLE = ROOT / "ComfyUI_windows_portable"
COMFY = PORTABLE / "ComfyUI"
COMFY_OUTPUT = COMFY / "output"
MODEL_NAME = "4x-UltraSharp.pth"
MODEL_PATH = COMFY / "models" / "upscale_models" / MODEL_NAME
SERVER = "http://127.0.0.1:8188"
INPUT_DIR = ROOT / "input_batch" / "until_16k"
OUTPUT_DIR = ROOT / "output_batch" / "ultrasharp_min16k"
LOG_PATH = ROOT / "logs" / "ultrasharp_until_16k.csv"
SUPPORTED_EXTS = {".png", ".jpg", ".jpeg", ".webp"}
TARGET_SIZE = 16000


def parse_args():
    parser = argparse.ArgumentParser(
        description="Run 4x-UltraSharp repeatedly until each image is at least 16000x16000."
    )
    parser.add_argument("--server", default=SERVER)
    parser.add_argument("--input-dir", default=str(INPUT_DIR))
    parser.add_argument("--output-dir", default=str(OUTPUT_DIR))
    parser.add_argument("--log", default=str(LOG_PATH))
    parser.add_argument("--timeout", type=int, default=1800)
    parser.add_argument("--keep-comfy-output", action="store_true")
    return parser.parse_args()


def require_server(server):
    try:
        response = requests.get(f"{server}/system_stats", timeout=5)
        response.raise_for_status()
    except requests.RequestException as exc:
        raise RuntimeError(
            f"ComfyUI is not reachable at {server}. Start ComfyUI first, then rerun this script."
        ) from exc


def require_model_file():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(
            f"Missing upscale model: {MODEL_PATH}\n"
            "Run scripts\\download_upscale_models.bat, then restart ComfyUI."
        )


def require_server_nodes(server):
    required_classes = {
        "LoadImage": None,
        "UpscaleModelLoader": ("model_name", MODEL_NAME),
        "ImageUpscaleWithModel": None,
        "SaveImage": None,
    }
    for class_type, model_check in required_classes.items():
        response = requests.get(f"{server}/object_info/{class_type}", timeout=30)
        response.raise_for_status()
        info = response.json()
        if class_type not in info:
            raise RuntimeError(f"ComfyUI is missing required node class: {class_type}")
        if model_check:
            input_name, expected_value = model_check
            choices = info[class_type].get("input", {}).get("required", {}).get(input_name, [[]])[0]
            if isinstance(choices, list) and expected_value not in choices:
                raise RuntimeError(
                    f"ComfyUI does not currently see {MODEL_NAME}. "
                    "Restart ComfyUI after adding the model, then rerun this script."
                )


def image_size(path):
    with Image.open(path) as image:
        return image.width, image.height


def image_files(input_dir):
    input_path = Path(input_dir)
    if not input_path.exists():
        input_path.mkdir(parents=True, exist_ok=True)
    return sorted(
        path
        for path in input_path.rglob("*")
        if path.is_file() and path.suffix.lower() in SUPPORTED_EXTS
    )


def duplicate_stems(paths):
    by_stem = {}
    for path in paths:
        by_stem.setdefault(path.stem.lower(), []).append(path)
    return {stem: matches for stem, matches in by_stem.items() if len(matches) > 1}


def log_row(log_path, row):
    log_path.parent.mkdir(parents=True, exist_ok=True)
    exists = log_path.exists()
    fields = [
        "time",
        "input",
        "original_width",
        "original_height",
        "pass",
        "multiplier",
        "output_width",
        "output_height",
        "saved_file",
        "prompt_id",
        "status",
        "message",
    ]
    with open(log_path, "a", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        if not exists:
            writer.writeheader()
        writer.writerow(row)


def base_log_row(image_path, original_width, original_height):
    return {
        "time": time.strftime("%Y-%m-%d %H:%M:%S"),
        "input": str(image_path),
        "original_width": original_width,
        "original_height": original_height,
        "pass": "",
        "multiplier": "",
        "output_width": "",
        "output_height": "",
        "saved_file": "",
        "prompt_id": "",
        "status": "",
        "message": "",
    }


def upload_image(server, image_path):
    with open(image_path, "rb") as handle:
        files = {"image": (image_path.name, handle, "application/octet-stream")}
        data = {"overwrite": "true", "type": "input", "subfolder": "ultrasharp_until_16k"}
        response = requests.post(f"{server}/upload/image", files=files, data=data, timeout=180)
    response.raise_for_status()
    payload = response.json()
    name = payload["name"]
    subfolder = payload.get("subfolder") or ""
    return f"{subfolder}/{name}" if subfolder else name


def safe_prefix_part(value):
    safe = re.sub(r"[^A-Za-z0-9._-]+", "_", value).strip("._")
    return safe or "image"


def build_prompt(uploaded_image, filename_prefix):
    return {
        "1": {
            "class_type": "LoadImage",
            "inputs": {"image": uploaded_image},
        },
        "2": {
            "class_type": "UpscaleModelLoader",
            "inputs": {"model_name": MODEL_NAME},
        },
        "3": {
            "class_type": "ImageUpscaleWithModel",
            "inputs": {"upscale_model": ["2", 0], "image": ["1", 0]},
        },
        "4": {
            "class_type": "SaveImage",
            "inputs": {"images": ["3", 0], "filename_prefix": filename_prefix},
        },
    }


def queue_prompt(server, prompt, client_id):
    response = requests.post(
        f"{server}/prompt",
        json={"prompt": prompt, "client_id": client_id},
        timeout=120,
    )
    response.raise_for_status()
    payload = response.json()
    if "error" in payload:
        raise RuntimeError(json.dumps(payload["error"], indent=2))
    return payload["prompt_id"]


def wait_for_history(server, prompt_id, timeout):
    deadline = time.time() + timeout
    while time.time() < deadline:
        response = requests.get(f"{server}/history/{prompt_id}", timeout=30)
        response.raise_for_status()
        history = response.json()
        if prompt_id in history:
            item = history[prompt_id]
            status = item.get("status", {})
            if status.get("status_str") == "error":
                raise RuntimeError(json.dumps(status, indent=2))
            return item
        time.sleep(2)
    raise TimeoutError(f"Prompt did not finish within {timeout} seconds: {prompt_id}")


def output_images(history_item):
    outputs = history_item.get("outputs", {})
    node = outputs.get("4", {})
    return node.get("images", [])


def download_first_image(server, image_infos, destination):
    if not image_infos:
        raise RuntimeError(f"No image output found for {destination}")
    info = image_infos[0]
    query = urlencode(
        {
            "filename": info["filename"],
            "subfolder": info.get("subfolder", ""),
            "type": info.get("type", "output"),
        }
    )
    response = requests.get(f"{server}/view?{query}", timeout=600)
    response.raise_for_status()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with open(destination, "wb") as handle:
        handle.write(response.content)
    return info


def cleanup_saved_image(info):
    subfolder = info.get("subfolder") or ""
    filename = info.get("filename")
    if not filename:
        return
    target = COMFY_OUTPUT / subfolder / filename
    try:
        if target.exists() and target.is_file():
            target.unlink()
    except OSError:
        pass


def stage_name(image_path, multiplier):
    return f"{image_path.stem}_{multiplier}x.png"


def run_pass(server, client_id, source_image, image_stem, multiplier, timeout):
    uploaded = upload_image(server, source_image)
    run_id = uuid.uuid4().hex[:12]
    prefix = f"api_ultrasharp_until_16k/{run_id}/{safe_prefix_part(image_stem)}_{multiplier}x"
    prompt = build_prompt(uploaded, prefix)
    prompt_id = queue_prompt(server, prompt, client_id)
    history = wait_for_history(server, prompt_id, timeout)
    return prompt_id, output_images(history)


def process_image(args, image_path, log_path, output_dir, client_id):
    original_width, original_height = image_size(image_path)
    current_width, current_height = original_width, original_height
    current_source = image_path
    pass_number = 0
    multiplier = 1

    print(f"Input: {image_path} ({original_width}x{original_height})")

    if current_width >= TARGET_SIZE and current_height >= TARGET_SIZE:
        row = base_log_row(image_path, original_width, original_height)
        row.update(
            {
                "pass": 0,
                "multiplier": 1,
                "output_width": current_width,
                "output_height": current_height,
                "status": "skipped",
                "message": "input already meets 16000x16000 minimum",
            }
        )
        log_row(log_path, row)
        print("  skipped: input already meets 16000x16000 minimum")
        return

    while current_width < TARGET_SIZE or current_height < TARGET_SIZE:
        pass_number += 1
        multiplier *= 4
        destination = output_dir / stage_name(image_path, multiplier)
        prompt_id = ""
        try:
            print(f"  pass {pass_number}: {multiplier}x")
            prompt_id, image_infos = run_pass(
                args.server,
                client_id,
                current_source,
                image_path.stem,
                multiplier,
                args.timeout,
            )
            saved_info = download_first_image(args.server, image_infos, destination)
            if not args.keep_comfy_output:
                cleanup_saved_image(saved_info)
            current_width, current_height = image_size(destination)

            row = base_log_row(image_path, original_width, original_height)
            row.update(
                {
                    "pass": pass_number,
                    "multiplier": multiplier,
                    "output_width": current_width,
                    "output_height": current_height,
                    "saved_file": str(destination),
                    "prompt_id": prompt_id,
                    "status": "success",
                    "message": "ok",
                }
            )
            log_row(log_path, row)
            print(f"    saved: {destination.name} ({current_width}x{current_height})")
            current_source = destination
        except Exception as exc:
            row = base_log_row(image_path, original_width, original_height)
            row.update(
                {
                    "pass": pass_number,
                    "multiplier": multiplier,
                    "saved_file": str(destination),
                    "prompt_id": prompt_id,
                    "status": "failed",
                    "message": str(exc),
                }
            )
            log_row(log_path, row)
            raise


def main():
    args = parse_args()
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output_dir)
    log_path = Path(args.log)

    require_model_file()
    require_server(args.server)
    require_server_nodes(args.server)
    output_dir.mkdir(parents=True, exist_ok=True)

    files = image_files(input_dir)
    if not files:
        print(f"No png/jpg/jpeg/webp images found in {input_dir}")
        return 0

    duplicates = duplicate_stems(files)
    duplicate_failures = 0
    if duplicates:
        for paths in duplicates.values():
            for image_path in paths:
                duplicate_failures += 1
                width, height = image_size(image_path)
                row = base_log_row(image_path, width, height)
                row.update(
                    {
                        "status": "failed",
                        "message": "duplicate input filename stem would overwrite preserved output filename",
                    }
                )
                log_row(log_path, row)
                print(
                    f"FAILED: duplicate input filename stem would overwrite output: {image_path}",
                    file=sys.stderr,
                )
        files = [path for path in files if path.stem.lower() not in duplicates]

    client_id = str(uuid.uuid4())
    seen = set()
    failures = duplicate_failures
    for image_path in files:
        resolved = image_path.resolve()
        if resolved in seen:
            continue
        seen.add(resolved)
        try:
            process_image(args, image_path, log_path, output_dir, client_id)
        except Exception as exc:
            failures += 1
            print(f"FAILED: {image_path}: {exc}", file=sys.stderr)

    if failures:
        print(f"Finished with {failures} failed image(s). See log: {log_path}", file=sys.stderr)
        return 1
    print(f"Finished. See log: {log_path}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except KeyboardInterrupt:
        print("ERROR: cancelled by user", file=sys.stderr)
        raise SystemExit(130)
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        raise SystemExit(1)
