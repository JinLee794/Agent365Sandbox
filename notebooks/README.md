# Agent 365 Tutorial Notebooks

This folder contains the three tutorial notebooks for Agent 365:
- 01-introduction.ipynb (concepts, no Azure required)
- 02-rest-api.ipynb (Graph API, Azure required)
- 03-sdk-usage.ipynb (Azure AI Search RBAC demo, Azure required)

Quick setup (Python 3.11+ recommended 3.13) using uv:
1) Ensure uv is installed (`pip install uv` or see https://github.com/astral-sh/uv).
2) Create and activate an env with uv: `uv venv .venv` then `source .venv/bin/activate` (Windows: `.venv\Scripts\activate`).
3) Install dependencies via uv: `uv pip install -r requirements.txt`.
4) Copy env template: `cp .env.example .env` and fill tenant ID, client ID, cert path, cert thumbprint, blueprint ID, and (for notebook 03) search endpoint/index.
5) Launch Jupyter: `uv run jupyter lab` (or `uv run jupyter notebook`) and open the notebooks above.

For detailed setup, Azure prerequisites, and troubleshooting, see ../specs/001-agent365-notebooks/quickstart.md.
