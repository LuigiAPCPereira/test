from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[1]
source = root / "solution" / "test-candidate"
dist = root / "dist"
dist.mkdir(exist_ok=True)
output = dist / "ControledenotasFiscais_TestCandidate_0_1_0_0.zip"

with ZipFile(output, "w", ZIP_DEFLATED) as zf:
    for path in sorted(source.rglob("*")):
        if path.is_file():
            zf.write(path, path.relative_to(source).as_posix())

print(output)
