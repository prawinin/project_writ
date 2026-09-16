#!/usr/bin/env python3
"""One-time download of the offline reranker (~23 MB).

MiniLM-L6-v2 int8 ONNX (Xenova export) + tokenizer, into models/minilm/.
Same pattern as the LLM: bundled at setup, reused forever after.
Usage: ./venv/bin/python scripts/setup_reranker.py
"""
import os
import sys
import urllib.request

BASE = "https://huggingface.co/Xenova/all-MiniLM-L6-v2/resolve/main"
FILES = {
    "onnx/model_quantized.onnx": "model.onnx",
    "tokenizer.json": "tokenizer.json",
}
DEST = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                    "models", "minilm")


def main():
    os.makedirs(DEST, exist_ok=True)
    for src, name in FILES.items():
        out = os.path.join(DEST, name)
        if os.path.exists(out) and os.path.getsize(out) > 1000:
            print(f"{name} already present — keeping it.")
            continue
        print(f"Downloading {name} (~23 MB total)...")
        urllib.request.urlretrieve(f"{BASE}/{src}", out)
        print(f"  saved {out} ({os.path.getsize(out) // 1024} KB)")
    # Smoke test
    sys.path.insert(0, os.path.dirname(DEST))
    import rerank
    assert rerank.available(), "files missing after download"
    s = rerank.cosine_scores("anticipatory bail", ["anticipatory bail under section 438",
                                                   "how to bake a chocolate cake"])
    print(f"smoke test similarities: {[round(x, 3) for x in s]}")
    assert s[0] > s[1], "reranker sanity check failed"
    print("Reranker ready.")


if __name__ == "__main__":
    main()
