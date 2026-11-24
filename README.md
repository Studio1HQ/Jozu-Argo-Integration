<div align="center">

<img src="https://raw.githubusercontent.com/Studio1HQ/Studio1HQ/main/assets/banners/Jozu-Argo-Integration.webp" alt="KitOps and Argo Workflows on Jozu Hub: Serve a KitOps model from Jozu Hub with Docker, Kubernetes and Argo" width="100%" />

<br />
<br />

# KitOps and Argo Workflows on Jozu Hub

### Serve a KitOps model from Jozu Hub with Docker, Kubernetes and Argo

A sample project that packages a scikit-learn text classifier as a ModelKit, pulls it from Jozu Hub, serves it behind a Flask API and web UI, and runs inference through Argo Workflows.

<br />

[![Built by Studio1](https://img.shields.io/badge/Built_by_Studio1-f97316?style=for-the-badge&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNjAgMTYwIiBmaWxsPSJub25lIj48cGF0aCBmaWxsLXJ1bGU9ImV2ZW5vZGQiIGNsaXAtcnVsZT0iZXZlbm9kZCIgZD0iTTAgMzVDMCAxNi42ODA3IDE0LjA3NDQgMS42NDg0NCAzMiAwLjEyNjk1M1YxNDFINTEuMDUyM0M1Mi40MzA4IDEzNy4zNDQgNTQuNzQ0NiAxMzMuNjg5IDU3Ljk5MzggMTMwLjAzM0M2MS4xNDQ2IDEyNi41MDggNjQuNjg5MiAxMjMuNDQgNjguNjI3NyAxMjAuODI5QzcyLjU2NjIgMTE4LjM0OSA3Ni4zNTY5IDExNi43ODIgODAgMTE2LjEyOVY4Ni43NTQ0Qzc1LjQ3MDggODcuOTI5MiA3MS4zODQ2IDg5LjY5MTkgNjcuNzQxNSA5Mi4wNDE1QzY0IDk0LjUyMjUgNjAuNzUwOCA5Ny40NiA1Ny45OTM4IDEwMC44NTRDNTYuNTM0NSAxMDIuNzIgNTUuMjU0NSAxMDQuNjU5IDU0LjE1MzkgMTA2LjY3MVYwSDEyNUMxNDQuMzMgMCAxNjAgMTUuNjY5OSAxNjAgMzVWMTI1QzE2MCAxNDQuMzMgMTQ0LjMzIDE2MCAxMjUgMTYwSDEyNFYxOEgxMDQuOTQ4QzEwMy41NjkgMjEuNjgxNiAxMDEuMjU1IDI1LjM2MjggOTguMDA2MiAyOS4wNDQ0Qzk0Ljg1NTQgMzIuNTk0MiA5MS4zMTA4IDM1LjY4NDEgODcuMzcyMyAzOC4zMTRDODMuNDMzOCA0MC44MTIgNzkuNjQzMSA0Mi4zODk2IDc2IDQzLjA0NzRWNzIuNjMwNEM4MC41MjkyIDcxLjQ0NzMgODQuNjE1NCA2OS42NzI0IDg4LjI1ODUgNjcuMzA1N0M5MiA2NC44MDc2IDk1LjI0OTIgNjEuODQ5MSA5OC4wMDYyIDU4LjQzMDdDOTkuNDY1NSA1Ni41NTEzIDEwMC43NDUgNTQuNTk4NiAxMDEuODQ2IDUyLjU3MjNWMTYwSDM1QzE1LjY3IDE2MCAwIDE0NC4zMyAwIDEyNVYzNVoiIGZpbGw9IiNmZmZmZmYiLz48L3N2Zz4K)](https://studio1hq.com)
[![Built with Jozu](https://img.shields.io/badge/Built_with_Jozu-141414?style=for-the-badge)](https://jozu.com)

[Jozu docs](https://jozu.com/docs) &nbsp;·&nbsp; [Jozu](https://jozu.com) &nbsp;·&nbsp; [KitOps](https://kitops.org) &nbsp;·&nbsp; [More examples](https://github.com/Studio1HQ) &nbsp;·&nbsp; [studio1hq.com](https://studio1hq.com)

</div>

<br />

## Overview

This project shows how to take a machine learning model through KitOps, Jozu Hub and Argo Workflows so that other people can run it with Docker or Kubernetes. The model is a scikit-learn sentiment (text classification) model packaged as a ModelKit.

You pull the ModelKit from Jozu Hub, serve it behind a Flask inference API with a web UI, and run single or batch inference as Argo workflows on a Kubernetes cluster.

## Features

- **Model packaging**: `models/Kitfile` describes the model (`model.pkl`) with `model_info.json`, `requirements.txt` and `sample-inputs.json` as parts, and the repo as code.
- **Model registry**: The model is pulled from Jozu Hub with `pull_model.sh` after `login_kit.sh`.
- **Inference API**: `models/inference_server.py` is a Flask app on port 8000 with `/health`, `/predict` and `/v1/completions`.
- **Web UI**: A static page served by Nginx (`web-ui/`) for trying the model.
- **Three deployment paths**: Docker Compose, a direct Kubernetes pod, or full Kubernetes manifests.
- **Argo Workflows**: Workflow templates for single and batch inference, including one that uses only public images.
- **CI**: `.github/workflows/model-deploy.yml` packages the model with KitOps, pushes it to Jozu Hub and configures Kubernetes.

## Tech stack

| Layer | Tool |
| --- | --- |
| Packaging | [KitOps](https://kitops.org) |
| Registry | [Jozu Hub](https://jozu.ml) |
| Model | [scikit-learn](https://scikit-learn.org) |
| API | [Flask](https://flask.palletsprojects.com) |
| Web server | [Nginx](https://nginx.org) |
| Orchestration | [Kubernetes](https://kubernetes.io), [Argo Workflows](https://argoproj.github.io/workflows/) |
| Local deployment | [Docker](https://www.docker.com) and Docker Compose |

## Getting started

### Prerequisites

- Docker and Docker Compose for local deployment
- Kubernetes and `kubectl` for cluster deployment
- KitOps CLI for pulling and packaging the model
- A Jozu Hub account
- Argo Workflows installed in your cluster (only for the workflow step)

### Installation

```bash
git clone https://github.com/Studio1HQ/Jozu-Argo-Integration.git
cd Jozu-Argo-Integration
```

### Environment variables

No `.env` file. Authentication to Jozu Hub is done by `login_kit.sh` (and `setup-jozu-auth.sh` for cluster image pulls). The CI workflow reads its Jozu credentials from GitHub secrets.

### Run

Step 1, pull the model from Jozu Hub:

```bash
./login_kit.sh
./pull_model.sh
```

Step 2, deploy locally with Docker Compose (pulls the model if needed):

```bash
./test-local.sh
```

Step 3 (optional), deploy the model directly as a Kubernetes pod:

```bash
./deploy-model-pod.sh
kubectl exec -it text-classification-model-basic -- /bin/bash
```

Step 4 (optional), full Kubernetes deployment:

```bash
cd kubernetes
./deploy.sh
```

Step 5 (optional), run inference with Argo Workflows:

```bash
kubectl apply -f argo/workflow-template.yaml -n argo
kubectl apply -f argo/public-workflow-template.yaml -n argo

# Original templates (need authentication)
./argo/submit-workflow.sh single text "Your text to classify"
./argo/submit-workflow.sh batch file argo/sample-inputs.json

# Public templates (no authentication)
./argo/submit-public-workflow.sh single text "Your text to classify"
./argo/submit-public-workflow.sh batch file argo/sample-inputs.json
```

## How it works

```text
models/        Kitfile, Dockerfile, inference_server.py, train_model.py, model.pkl
web-ui/        Dockerfile, nginx.conf, html/
kubernetes/    model-deployment.yaml, web-ui-deployment.yaml, model-pod.yaml, workflow-rbac.yaml, deploy.sh
argo/          workflow-template.yaml, public-workflow-template.yaml, submit-*.sh, sample-inputs.json
docs/          DEPLOYMENT.md, END_TO_END_GUIDE.md, MODEL_INTERACTION_GUIDE.md, DEMONSTRATION_LOG.md
.github/workflows/model-deploy.yml   Package, push and deploy pipeline
```

Helper scripts: `setup-argo-workflows.sh` installs Argo, `setup-jozu-auth.sh` configures Jozu Hub authentication, `troubleshoot-image-pull.sh` diagnoses image pull problems and `cleanup.sh` tidies the project directory. The `docs/` folder has a deployment guide, an end-to-end walkthrough with real commands and a guide for interacting with the model pod.

## Resources

- [Jozu documentation](https://jozu.com/docs): Jozu Hub guides.
- [Jozu](https://jozu.com): Product site.
- [KitOps documentation](https://kitops.org/docs/overview/): ModelKit and Kitfile reference.
- [Argo Workflows](https://argoproj.github.io/workflows/): Workflow engine docs.

<br />

---

<div align="center">

<a href="https://studio1hq.com">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/Studio1HQ/website/main/brand/studio1-logo-on-dark.svg" />
    <img src="https://raw.githubusercontent.com/Studio1HQ/website/main/brand/studio1-logo-on-light.svg" alt="Studio1" width="160" />
  </picture>
</a>

Built by **[Studio1](https://studio1hq.com)**, the technical content and DevRel partner for devtool teams. Made with [Jozu](https://jozu.com).<br />
Browse more open-source examples at [github.com/Studio1HQ](https://github.com/Studio1HQ).

[![Website](https://img.shields.io/badge/studio1hq.com-0b0807?style=for-the-badge&logo=googlechrome&logoColor=white)](https://studio1hq.com)
[![Book a call](https://img.shields.io/badge/Book_a_strategy_call-f97316?style=for-the-badge&logo=googlecalendar&logoColor=white)](https://cal.com/studio1/collab)
[![X](https://img.shields.io/badge/%40Studio1HQ-141414?style=for-the-badge&logo=x&logoColor=white)](https://x.com/Studio1HQ)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-0a66c2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/company/studio1hq/)

<sub><a href="https://studio1hq.com">studio1hq.com</a> · Technical content, docs, video and DevRel for devtools</sub>

</div>
