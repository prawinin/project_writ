"""Offline semantic reranker: MiniLM-L6-v2 (int8 ONNX, ~22 MB) + numpy cosine.

No torch / sentence-transformers needed (neither ships Python 3.14 wheels).
Model files live in models/minilm/ (model.onnx + tokenizer.json), fetched
once by scripts/setup_reranker.py — same pattern as the LLM download.
"""
import os

MODEL_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "models", "minilm")
_session = None
_tokenizer = None


def available():
    return (os.path.exists(os.path.join(MODEL_DIR, "model.onnx"))
            and os.path.exists(os.path.join(MODEL_DIR, "tokenizer.json")))


def _load():
    global _session, _tokenizer
    if _session is None:
        import onnxruntime as ort
        from tokenizers import Tokenizer
        _tokenizer = Tokenizer.from_file(os.path.join(MODEL_DIR, "tokenizer.json"))
        _tokenizer.enable_truncation(max_length=256)
        _tokenizer.enable_padding(pad_id=0, pad_token="[PAD]")
        opts = ort.SessionOptions()
        opts.intra_op_num_threads = max(1, (os.cpu_count() or 4) - 1)
        _session = ort.InferenceSession(
            os.path.join(MODEL_DIR, "model.onnx"),
            sess_options=opts, providers=["CPUExecutionProvider"])
    return _session, _tokenizer


def cosine_scores(query, texts):
    """Return cosine similarities between query and each text. Never raises."""
    import numpy as np
    try:
        if not texts:
            return []
        sess, tok = _load()
        enc = tok.encode_batch([query] + texts)
        ids = np.array([e.ids for e in enc], dtype=np.int64)
        mask = np.array([e.attention_mask for e in enc], dtype=np.int64)
        inputs = {"input_ids": ids, "attention_mask": mask}
        if any(i.name == "token_type_ids" for i in sess.get_inputs()):
            inputs["token_type_ids"] = np.zeros_like(ids)
        out = sess.run(None, inputs)[0].astype(np.float32)
        m = mask[:, :, None].astype(np.float32)
        emb = (out * m).sum(axis=1) / m.sum(axis=1).clip(min=1e-6)
        emb = emb / np.linalg.norm(emb, axis=1, keepdims=True).clip(min=1e-9)
        return [float(np.dot(emb[0], v)) for v in emb[1:]]
    except Exception:
        return []


def rrf_fuse(bm25_order, emb_scores, k=60):
    """Reciprocal-rank fuse BM25 ordering with embedding scores.

    bm25_order: list of indices best-first. emb_scores: parallel cosine list.
    Returns indices best-first. Scale-free — no score calibration needed.
    """
    emb_order = sorted(range(len(emb_scores)), key=lambda i: emb_scores[i], reverse=True)
    rrf = {}
    for rank, i in enumerate(bm25_order):
        rrf[i] = rrf.get(i, 0.0) + 1.0 / (k + rank + 1)
    for rank, i in enumerate(emb_order):
        rrf[i] = rrf.get(i, 0.0) + 1.0 / (k + rank + 1)
    return sorted(rrf, key=lambda i: rrf[i], reverse=True)
