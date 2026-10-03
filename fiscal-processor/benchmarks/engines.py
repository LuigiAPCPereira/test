"""Explicit local model paths; no downloader in this benchmark."""

import hashlib
import importlib.metadata
import subprocess
from pathlib import Path

HASHES = {
    "PP-OCRv6_det_small.onnx": "090f04abcd9d9a7498bc4ebf677e4cb9bdce1fe4197ddb7e529f1ef44e1ff94f",
    "PP-OCRv6_rec_small.onnx": "6f327246b50388f3c176ae304bd95767ea6dc0c9ae92153ef8cbe210b3c14884",
    "PP-OCRv6_det_medium.onnx": "92078b7355007ccfffcd4c8cd441a3afd4538904d06881b29a155e1e679907c2",
    "PP-OCRv6_rec_medium.onnx": "eef444829dbbe18d7fea59a3f6eb75647518d2b3a9568d27c92e42940204894b",
    "ch_ppocr_mobile_v2.0_cls_mobile.onnx": (
        "e47acedf663230f8863ff1ab0e64dd2d82b838fceb5957146dab185a89d6215c"
    ),
}


def verify_model(path: Path) -> None:
    expected = HASHES[path.name]
    with path.open("rb") as stream:
        actual = hashlib.file_digest(stream, "sha256").hexdigest()
    if actual != expected:
        raise ValueError(f"model hash mismatch: {path.name}")


class RapidEngine:
    def __init__(self, size: str, model_dir: Path):
        if size not in {"small", "medium"}:
            raise ValueError("unsupported model size")
        for package, version in [("rapidocr", "3.9.2"), ("onnxruntime", "1.24.2")]:
            if importlib.metadata.version(package) != version:
                raise ValueError(f"{package} must be {version}")
        paths = {
            "Det": model_dir / f"PP-OCRv6_det_{size}.onnx",
            "Rec": model_dir / f"PP-OCRv6_rec_{size}.onnx",
            "Cls": model_dir / "ch_ppocr_mobile_v2.0_cls_mobile.onnx",
        }
        for path in paths.values():
            verify_model(path)
        self.model_bytes = sum(path.stat().st_size for path in paths.values())
        from rapidocr import ModelType, RapidOCR

        params = {f"{task}.model_path": str(path.resolve()) for task, path in paths.items()}
        params.update(
            {
                "Global.log_level": "critical",
                "Global.use_cls": False,
                "EngineConfig.onnxruntime.intra_op_num_threads": 1,
                "EngineConfig.onnxruntime.inter_op_num_threads": 1,
                "Det.model_type": ModelType(size),
                "Rec.model_type": ModelType(size),
                "Det.lang_type": "pt",
                "Rec.lang_type": "pt",
            }
        )
        self.engine = RapidOCR(params=params)

    def recognize(self, path: Path) -> str:
        output = self.engine(str(path))
        return "\n".join(output.txts or ())


class TesseractEngine:
    def __init__(self, model_dir: Path, language: str = "por"):
        if language not in {"por", "eng"}:
            raise ValueError("unsupported language")
        model = model_dir / f"{language}.traineddata"
        if not model.is_file():
            raise FileNotFoundError(model)
        self.model_bytes = model.stat().st_size
        self.model_sha256 = hashlib.sha256(model.read_bytes()).hexdigest()
        if language == "por" and self.model_sha256 != (
            "c4932b937207a9514b7514d518b931a99938c02a28a5a5a553f8599ed58b7deb"
        ):
            raise ValueError("por.traineddata hash mismatch")
        self.model_dir = model_dir
        self.language = language
        self.version = subprocess.run(
            ["tesseract", "--version"], check=True, capture_output=True, text=True, timeout=10
        ).stdout.splitlines()[0]
        if not self.version.startswith("tesseract 5."):
            raise ValueError("Tesseract 5 required")

    def recognize(self, path: Path) -> str:
        return subprocess.run(
            [
                "tesseract",
                str(path),
                "stdout",
                "--tessdata-dir",
                str(self.model_dir),
                "-l",
                self.language,
                "--oem",
                "1",
                "--psm",
                "6",
            ],
            check=True,
            capture_output=True,
            text=True,
            timeout=60,
        ).stdout
