"""Build-time model provisioning. Explicit command; never called by benchmark/runtime."""

import argparse
import hashlib
import importlib.metadata
import shutil
import urllib.request
from pathlib import Path

from .engines import HASHES, verify_model

POR_SHA256 = "c4932b937207a9514b7514d518b931a99938c02a28a5a5a553f8599ed58b7deb"


def download(url: str, target: Path, expected: str) -> None:
    if target.is_file() and hashlib.sha256(target.read_bytes()).hexdigest() == expected:
        return
    temporary = target.with_suffix(target.suffix + ".part")
    try:
        with urllib.request.urlopen(url, timeout=30) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output)
        if hashlib.sha256(temporary.read_bytes()).hexdigest() != expected:
            raise ValueError(f"hash mismatch: {target.name}")
        temporary.replace(target)
    finally:
        temporary.unlink(missing_ok=True)


def main() -> None:
    parser = argparse.ArgumentParser(__doc__)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--download-comparison-models", action="store_true")
    args = parser.parse_args()
    destination = args.destination.resolve()
    destination.mkdir(parents=True, exist_ok=True)
    distribution = importlib.metadata.distribution("rapidocr")
    if distribution.version != "3.9.2":
        raise ValueError("rapidocr 3.9.2 required")
    for name in HASHES:
        if "medium" in name:
            if args.download_comparison_models:
                task = name.split("_")[1]
                url = (
                    "https://www.modelscope.cn/models/RapidAI/RapidOCR/resolve/"
                    f"v3.9.2/onnx/PP-OCRv6/{task}/{name}"
                )
                download(url, destination / name, HASHES[name])
            continue
        source = Path(distribution.locate_file(f"rapidocr/models/{name}"))
        verify_model(source)
        target = destination / name
        if source.resolve() != target.resolve():
            shutil.copy2(source, target)
        verify_model(target)
    if args.download_comparison_models:
        download(
            "https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/4.1.0/por.traineddata",
            destination / "por.traineddata",
            POR_SHA256,
        )


if __name__ == "__main__":
    main()
