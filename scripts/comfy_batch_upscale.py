import argparse
import copy
import csv
import json
import os
import shutil
import subprocess
import sys
import time
import uuid
from pathlib import Path
from urllib.parse import urlencode

import requests


ROOT = Path(__file__).resolve().parents[1]
PORTABLE = ROOT / "ComfyUI_windows_portable"
COMFY = PORTABLE / "ComfyUI"
PYTHON = PORTABLE / "python_embeded" / "python.exe"
LAUNCHER = PORTABLE / "run_nvidia_gpu.bat"
COMFY_OUTPUT = COMFY / "output"
SERVER = "http://127.0.0.1:8188"
SUPPORTED_EXTS = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tif", ".tiff"}


def parse_args():
    parser = argparse.ArgumentParser(description="Batch upscales images through ComfyUI API one file at a time.")
    parser.add_argument("--category", required=True)
    parser.add_argument("--workflow", required=True)
    parser.add_argument("--input-dir", required=True)
    parser.add_argument("--output-4x", required=True)
    parser.add_argument("--output-final", required=True)
    parser.add_argument("--log", required=True)
    parser.add_argument("--server", default=SERVER)
    parser.add_argument("--timeout", type=int, default=900)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument("--keep-comfy-output", action="store_true")
    return parser.parse_args()


def ensure_server(server, timeout):
    if server_ready(server):
        return
    if not LAUNCHER.exists():
        raise RuntimeError(f"ComfyUI launcher missing: {LAUNCHER}")
    print("ComfyUI is not running. Starting it in a new console window...")
    subprocess.Popen(
        ["cmd.exe", "/c", str(LAUNCHER)],
        cwd=str(PORTABLE),
        creationflags=getattr(subprocess, "CREATE_NEW_CONSOLE", 0),
    )
    deadline = time.time() + timeout
    while time.time() < deadline:
        if server_ready(server):
            return
        time.sleep(3)
    raise TimeoutError(f"ComfyUI did not become ready within {timeout} seconds at {server}")


def server_ready(server):
    try:
        response = requests.get(f"{server}/system_stats", timeout=3)
        return response.status_code == 200
    except requests.RequestException:
        return False


def load_workflow(path):
    with open(path, "r", encoding="utf-8") as handle:
        return json.load(handle)


def validate_server_objects(server, template):
    required_classes = sorted({node.get("class_type") for node in template.values() if node.get("class_type")})
    for class_type in required_classes:
        response = requests.get(f"{server}/object_info/{class_type}", timeout=30)
        if response.status_code != 200 or class_type not in response.json():
            raise RuntimeError(f"ComfyUI is missing required node class: {class_type}")

    checks = [
        ("CheckpointLoaderSimple", "ckpt_name", "checkpoint"),
        ("UpscaleModelLoader", "model_name", "upscale model"),
    ]
    for class_type, input_name, label in checks:
        response = requests.get(f"{server}/object_info/{class_type}", timeout=30)
        if response.status_code != 200:
            continue
        info = response.json().get(class_type, {})
        choices = info.get("input", {}).get("required", {}).get(input_name, [[]])[0]
        if not isinstance(choices, list):
            continue
        for node in template.values():
            if node.get("class_type") != class_type:
                continue
            expected = node.get("inputs", {}).get(input_name)
            if expected and expected not in choices:
                raise RuntimeError(
                    f"ComfyUI does not currently see {label}: {expected}. "
                    "Restart ComfyUI after adding models, then rerun the batch."
                )


def upload_image(server, image_path):
    with open(image_path, "rb") as handle:
        files = {"image": (image_path.name, handle, "application/octet-stream")}
        data = {"overwrite": "true", "type": "input", "subfolder": "batch_api"}
        response = requests.post(f"{server}/upload/image", files=files, data=data, timeout=120)
    response.raise_for_status()
    payload = response.json()
    name = payload["name"]
    subfolder = payload.get("subfolder") or ""
    return f"{subfolder}/{name}" if subfolder else name


def prepare_prompt(template, uploaded_image, prefix_4x, prefix_final):
    prompt = copy.deepcopy(template)
    for node in prompt.values():
        inputs = node.get("inputs", {})
        if inputs.get("image") == "__INPUT_IMAGE__":
            inputs["image"] = uploaded_image
        if inputs.get("filename_prefix") == "__PREFIX_4X__":
            inputs["filename_prefix"] = prefix_4x
        if inputs.get("filename_prefix") == "__PREFIX_FINAL__":
            inputs["filename_prefix"] = prefix_final
    return prompt


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


def output_images(history_item, node_id):
    outputs = history_item.get("outputs", {})
    node = outputs.get(str(node_id), {})
    return node.get("images", [])


def download_first_image(server, image_infos, destination):
    if not image_infos:
        raise RuntimeError(f"No image output found for {destination}")
    info = image_infos[0]
    query = urlencode({
        "filename": info["filename"],
        "subfolder": info.get("subfolder", ""),
        "type": info.get("type", "output"),
    })
    response = requests.get(f"{server}/view?{query}", timeout=240)
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


def image_files(input_dir):
    return sorted(
        p for p in Path(input_dir).iterdir()
        if p.is_file() and p.suffix.lower() in SUPPORTED_EXTS
    )


def log_row(log_path, row):
    log_path.parent.mkdir(parents=True, exist_ok=True)
    exists = log_path.exists()
    with open(log_path, "a", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["time", "category", "input", "status", "message", "output_4x", "output_final", "prompt_id"])
        if not exists:
            writer.writeheader()
        writer.writerow(row)


def main():
    args = parse_args()
    workflow_path = Path(args.workflow)
    input_dir = Path(args.input_dir)
    output_4x = Path(args.output_4x)
    output_final = Path(args.output_final)
    log_path = Path(args.log)

    if not workflow_path.exists():
        raise FileNotFoundError(workflow_path)
    if not input_dir.exists():
        input_dir.mkdir(parents=True, exist_ok=True)

    ensure_server(args.server, args.timeout)
    template = load_workflow(workflow_path)
    validate_server_objects(args.server, template)
    files = image_files(input_dir)
    if not files:
        print(f"No supported images found in {input_dir}")
        return 0

    client_id = str(uuid.uuid4())
    for image_path in files:
        basename = image_path.stem
        out_4x = output_4x / f"{basename}_4x.png"
        out_final = output_final / f"{basename}_final.png"
        if not args.overwrite and out_4x.exists() and out_final.exists():
            print(f"Skipping existing outputs: {image_path.name}")
            continue

        prompt_id = ""
        try:
            print(f"Processing {image_path.name}...")
            uploaded = upload_image(args.server, image_path)
            run_id = uuid.uuid4().hex[:12]
            prefix_4x = f"api_batch/{args.category}/{basename}_{run_id}_4x"
            prefix_final = f"api_batch/{args.category}/{basename}_{run_id}_final"
            prompt = prepare_prompt(template, uploaded, prefix_4x, prefix_final)
            prompt_id = queue_prompt(args.server, prompt, client_id)
            history = wait_for_history(args.server, prompt_id, args.timeout)
            saved_4x = download_first_image(args.server, output_images(history, 4), out_4x)
            final_node = 9 if "9" in template else 6
            saved_final = download_first_image(args.server, output_images(history, final_node), out_final)
            if not args.keep_comfy_output:
                cleanup_saved_image(saved_4x)
                cleanup_saved_image(saved_final)
            log_row(log_path, {
                "time": time.strftime("%Y-%m-%d %H:%M:%S"),
                "category": args.category,
                "input": str(image_path),
                "status": "success",
                "message": "ok",
                "output_4x": str(out_4x),
                "output_final": str(out_final),
                "prompt_id": prompt_id,
            })
            print(f"OK: {out_4x.name}, {out_final.name}")
        except Exception as exc:
            log_row(log_path, {
                "time": time.strftime("%Y-%m-%d %H:%M:%S"),
                "category": args.category,
                "input": str(image_path),
                "status": "failed",
                "message": str(exc),
                "output_4x": str(out_4x),
                "output_final": str(out_final),
                "prompt_id": prompt_id,
            })
            print(f"FAILED: {image_path.name}: {exc}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
