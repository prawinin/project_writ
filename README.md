# Writ — Indian Legal Intelligence

Writ is a fully offline Indian legal research assistant. It combines a fine-tuned
large language model ([Vidhi LLM](https://huggingface.co/prawinin/vidhi)) with an
encrypted on-device knowledge base of judgments, acts, and curated legal notes,
queried through hybrid retrieval (keyword + neural rerank).

No account. No cloud. Queries never leave the machine.

---

## Installers

Pre-built standalone installers for Windows, macOS, and Linux are available from the
[Releases](../../releases) page.

### Windows
- Download `Writ-Setup-1.0.0-Windows.exe`.
- Run the installer and follow the setup wizard to install the application and desktop shortcuts.

### macOS
- Download `Writ-1.0.0-Mac.dmg`.
- Open the disk image and drag **Writ.app** into your **Applications** folder.
- Launch Writ from Applications or Spotlight.

### Linux
- Download `Writ-1.0.0-Linux.tar.gz`.
- Extract the archive:
  ```bash
  tar -xzf Writ-1.0.0-Linux.tar.gz
  cd Writ-1.0.0-Linux
  ./install.sh
  ```

### Prerequisites & On-Device Setup
Writ requires [Ollama](https://ollama.com) running locally for model inference.
- If not already present, install Ollama from [ollama.com](https://ollama.com).
- On initial launch, the application detects Ollama and downloads the Vidhi model (`hf.co/prawinin/vidhi`). If the model has already been pulled, it will be detected and used immediately without re-downloading.
- The encrypted knowledge base (`writ_data.dat`) is loaded locally into application data storage.

---

## Running from Source

```bash
python -m venv venv && ./venv/bin/pip install -r requirements.txt
./venv/bin/python app.py
```

---

## License

### Application code

Copyright (c) 2026 Prawin. All rights reserved.

This software is licensed for **personal, non-commercial use only**.

You may install and run this software on your own device for personal legal
research. You may not redistribute, sublicense, modify, reverse-engineer, or
use this software for any commercial purpose without explicit written permission
from the author.

For licensing inquiries, commercial use, or institutional deployments, contact:
**prawin@vyapai.tech**

### Vidhi LLM

Model weights are distributed separately. See the
[model card](https://huggingface.co/prawinin/vidhi) for applicable terms.

---

## Disclaimer

Writ provides research assistance only and does not constitute legal advice.
Always verify citations and analysis with qualified legal counsel before relying
on them for any legal matter.
