# 🏠 House Price Predictor – An MLOps Learning Project

Welcome to the **House Price Predictor** project. An end-to-end, real-world MLOps learning use case. The goal is to practice building and operationalizing a complete ML pipeline from raw data to deployable models.
You’ll move through data preprocessing, feature engineering, experimentation, and model tracking with MLflow, with the option to explore interactively in Jupyter all using industry-standard tooling and workflows.

---
## 🧰 Tech Stack & Tools

- **Language & Runtime:** Python 3.11, UV (env/packaging)
- **Modeling:** scikit-learn / XGBoost (interchangeable via `configs/model_config.yaml`)
- **Tracking:** MLflow (local Docker in CI; UI on :5555 locally)
- **API:** FastAPI + Uvicorn (pydantic validation, OpenAPI at `/docs`)
- **UI:** Streamlit (talks to FastAPI via `API_URL`)
- **Containers:** Docker (or Podman), Docker Compose
- **Orchestration:** Kubernetes (manifests in `deployment/kubernetes/`), Kustomize
- **GitOps:** Argo CD (watches the manifests branch)
- **Autoscaling:** KEDA ScaledObject (Prometheus/other trigger → HPA)
- **Observability:** Prometheus Operator (ServiceMonitor), Grafana dashboards
- **CI/CD:** GitHub Actions → build/test → DockerHub

## 🧪 Model Card (Summary)

- **Intended Use:** Educational regression model for single-property price estimation demo.
- **Training Data:** `data/raw/house_data.csv` → cleaned + engineered features in `data/processed/`.
- **Algorithm:** (e.g.) XGBoost / RandomForest (select via `configs/model_config.yaml`).
- **Metrics:** RMSE, MAE, R² on hold-out split; tracked in MLflow (run URL in UI).
- **Limitations:** Not suitable for real-world appraisal; dataset bias; no macroeconomic factors.
- **Ethical Considerations:** Avoid use in lending/underwriting decisions; explain predictions as demo only.
---
## Sequence (request/response path):
```mermaid
sequenceDiagram
  autonumber
  participant U as User (Browser)
  participant ST as Streamlit UI
  participant FA as FastAPI (Model Service)
  participant M as Model + Preprocessor

  U->>ST: Enter features, click "Predict"
  ST->>FA: POST /predict (JSON)
  FA->>M: transform(features) + predict()
  M-->>FA: y_hat (price)
  FA-->>ST: 200 OK (prediction JSON)
  ST-->>U: Render predicted price & charts
```
---

## Flowchart (CI → Image → Argo CD → Kubernetes runtime):
```mermaid
flowchart LR
  subgraph Repo["GitHub Repository"]
    code[Repo: code + configs]
  end

  subgraph CI["GitHub Actions: MLOps Pipeline"]
    dp[data-processing]
    mt[model-training]
    bp[build-and-publish]
  end

  subgraph Registry["DockerHub Registry"]
    image[Image: house-price-model]
  end

  subgraph CD["Argo CD (GitOps)"]
    manifests[Manifests in repo]
    argo[Argo CD Application]
  end

  subgraph Cluster["Kubernetes Cluster"]
    subgraph AppNS["Namespace: app"]
      faD[Deployment: fastapi]
      faS[Service: fastapi]
      keda[KEDA ScaledObject]
      stD[Deployment: streamlit]
      stS[Service: streamlit]
      ing[Ingress or LoadBalancer]
      model[Model + Preprocessor]
    end
    subgraph MonNS["Namespace: monitoring"]
      sm[ServiceMonitor: fastapi]
      prom[Prometheus]
      graf[Grafana]
    end
  end

  code --> dp
  dp --> mt
  mt --> bp
  bp --> image

  code -. watches .- manifests
  manifests --> argo
  argo --> faD

  image --> faD

  faD --> faS
  stD --> stS
  faS --> ing
  stS --> ing
  keda -. scales .- faD

  sm --> prom
  prom --> graf
  faS -. metrics .- sm

  user[User]
  curlClient[curl or SDK]
  ui[Streamlit App]

  user --> ui
  ui --> faS
  curlClient --> faS
  faS --> model
  model --> faS
  faS --> ui
```
---

## 📸 Live Screenshots

> From a real deployment (Github Actions ↔︎ Argo CD ↔︎ Kubernetes). Click any image to view full size.
### GitHub Actions — MLOps Pipeline Run
<p align="center">
  <a href="docs/assets/gh-actions-run.png">
    <img src="docs/assets/gh-actions-run.png"
         alt="GitHub Actions run for 'MLOps Pipeline' showing data-processing, model-training, and build-and-publish all green"
         width="850">
  </a>
</p>
<sub>End-to-end CI proof: data → train (ephemeral MLflow) → build/test → publish image.</sub>

### Argo CD — Application Topology
<p align="center">
  <a href="docs/assets/argocd-app-tree.png">
    <img src="docs/assets/argocd-app-tree.png" alt="Argo CD application tree showing Deployments, Services, HPA/ScaledObject, and Pods for model (FastAPI) and Streamlit" width="850">
  </a>
</p>
<sub>GitOps view of the app: FastAPI (model), Streamlit UI, KEDA ScaledObject, Services, and ReplicaSets/Pods. Health and sync status shown.</sub>

### Streamlit — Prediction UI
<p align="center">
  <a href="docs/assets/streamlit-ui.png">
    <img src="docs/assets/streamlit-ui.png" alt="Streamlit interface with inputs (sqft, bedrooms, bathrooms, location, year built) and prediction results panel" width="850">
  </a>
</p>
<sub>Frontend for manual testing and demos. Calls FastAPI at <code>/predict</code> and renders price, confidence, range, and top factors.</sub>

### Grafana — API Observability
<p align="center">
  <a href="docs/assets/grafana-observability.png">
    <img src="docs/assets/grafana-observability.png" alt="Grafana dashboard showing request rate per endpoint, 95th percentile latency, error rate, and request size for /health and /predict" width="850">
  </a>
</p>
<sub>Dash panels include Request Rate (per endpoint), p95 Latency, Error Rate, and Request Size. Useful for SLIs/SLOs and autoscaling signals.</sub>


## 📦 Project Structure

```
house-price-predictor/
├── configs
│ └── model_config.yaml        # YAML configuration for model training (hyperparameters, paths, etc.)
├── data
│ ├── processed                # Cleaned & feature-ready datasets
│ │ ├── cleaned_house_data.csv    # Preprocessed raw dataset
│ │ ├── data_scientists_features.csv     # Custom feature set for experimentation
│ │ ├── featured_house_data.csv   # Final dataset with engineered features
│ │ └── README.md              # Notes on processed datasets
│ └── raw
│ └── house_data.csv           # Original raw housing dataset
├── deployment
│ ├── kubernetes               # K8s manifests for deploying API + Streamlit
│ │ ├── fastapi-scaledobject.yaml # KEDA autoscaling for FastAPI
│ │ ├── kustomization.yaml     # Kustomize entrypoint for managing manifests
│ │ ├── model-deploy.yaml      # Model (FastAPI) Deployment
│ │ ├── model-svc.yaml         # Service exposing FastAPI
│ │ ├── README.md # Deployment usage notes
│ │ ├── streamlit-deploy.yaml  # Streamlit Deployment
│ │ └── streamlit-svc.yaml     # Service exposing Streamlit UI
│ ├── mlflow
│ │ └── docker-compose.yaml    # Local MLflow + backend store setup
│ └── monitoring
│ ├── graph-dashb.json # Grafana/Prometheus dashboard config
│ ├── load_test.sh     # Script for load-testing API endpoints
│ ├── predict.json     # Sample prediction payload for testing
│ └── servicemonitor.yaml      # Prometheus ServiceMonitor for metrics scraping
├── Dockerfile         # Root Dockerfile for FastAPI inference service
├── LICENSE            # License for open-source usage
├── models
│ └── trained          # Stored model artifacts
│ ├── house_price_model.pkl         # Trained regression model
│ ├── preprocessor.pkl # Data preprocessing pipeline
│ └── README.md # Documentation of trained models
├── notebooks          # Jupyter notebooks for exploration & experimentation
│ ├── 00_data_engineering.ipynb           # Data ingestion & cleaning
│ ├── 01_exploratory_data_analysis.ipynb  # Exploratory Data Analysis (EDA)
│ ├── 02_feature_engineering.ipynb  # Feature selection & engineering
│ └── 03_experimentation.ipynb      # Model experimentation & MLflow tracking
├── README.md          # Project documentation (you’re here)
├── requirements.txt   # Python dependencies
├── src
│ ├── api              # FastAPI inference service
│ │ ├── inference.py   # Model inference logic
│ │ ├── main.py        # FastAPI entrypoint
│ │ ├── README.md      # API documentation
│ │ ├── requirements.txt      # API-specific dependencies
│ │ ├── schemas.py     # Pydantic schemas for request/response validation
│ │ └── utils.py       # Helper utilities for API
│ ├── data
│ │ └── run_processing.py     # Data preprocessing script
│ ├── features
│ │ └── engineer.py    # Feature engineering script
│ └── models
│ └── train_model.py   # Model training & evaluation script
└── streamlit_app      # Streamlit UI for user interaction
├── app.py             # Streamlit app entrypoint
├── Dockerfile         # Container definition for Streamlit
├── README.md          # Streamlit app documentation
└── requirements.txt   # Streamlit dependencies
```

---

## 🛠️ Setting up Learning/Development Environment

Install the following tools:

- [Python 3.11](https://www.python.org/downloads/)
- [Git](https://git-scm.com/)
- [Visual Studio Code](https://code.visualstudio.com/) or your preferred editor
- [UV – Python package and environment manager](https://github.com/astral-sh/uv)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) **or** [Podman Desktop](https://podman-desktop.io/)

---

## 🚀 Preparing Your Environment

1. **Fork this repo** on GitHub.

2. **Clone your forked copy:**

   ```bash
   git clone https://github.com/mafike/house-price-predictor.git
   cd house-price-predictor
   ```

3. **Setup Python Virtual Environment using UV:**

   ```bash
   uv venv --python python3.11
   source .venv/bin/activate
   ```

4. **Install dependencies:**

   ```bash
   uv pip install -r requirements.txt
   ```

---

## 📊 Setup MLflow for Experiment Tracking

Start MLflow locally to track experiments and model runs:

```bash
cd deployment/mlflow
docker compose -f mlflow-docker-compose.yml up -d
docker compose ps
```

> 🐧 **Using Podman?** Use this instead:

```bash
podman compose -f mlflow-docker-compose.yml up -d
podman compose ps
```

Access the MLflow UI at [http://localhost:5555](http://localhost:5555)

---

## 📒 Using JupyterLab (Optional)

If you prefer an interactive experience, launch JupyterLab with:

```bash
uv python -m jupyterlab
# or
python -m jupyterlab
```

---

## 🔁 Model Workflow

### 🧹 Step 1: Data Processing

Clean and preprocess the raw housing dataset:

```bash
python src/data/run_processing.py   --input data/raw/house_data.csv   --output data/processed/cleaned_house_data.csv
```

---

### 🧠 Step 2: Feature Engineering

Apply transformations and generate features:

```bash
python src/features/engineer.py   --input data/processed/cleaned_house_data.csv   --output data/processed/featured_house_data.csv   --preprocessor models/trained/preprocessor.pkl
```

---

### 📈 Step 3: Modeling & Experimentation

Train your model and log everything to MLflow:

```bash
python src/models/train_model.py   --config configs/model_config.yaml   --data data/processed/featured_house_data.csv   --models-dir models   --mlflow-tracking-uri http://localhost:5555
```

---


## Building FastAPI and Streamlit 

The code for both the apps are available in `src/api` and `streamlit_app` already. To build and launch these apps 

  * Add a  `Dockerfile` in the root of the source code for building FastAPI  
  * Add `streamlit_app/Dockerfile` to package and build the Streamlit app  
  * Add `docker-compose.yaml` in the root path to launch both these apps. be sure to provide `API_URL=http://fastapi:8000` in the streamlit app's environment. 


Once you have launched both the apps, you should be able to access streamlit web ui and make predictions. 

You could also test predictions with FastAPI directly using 

```
curl -X POST "http://localhost:8000/predict" \
-H "Content-Type: application/json" \
-d '{
  "sqft": 1500,
  "bedrooms": 3,
  "bathrooms": 2,
  "location": "suburban",
  "year_built": 2000,
  "condition": fair
}'

```

Be sure to replace `http://localhost:8000/predict` with actual endpoint based on where its running. 

## 🧯 Troubleshooting

- **Streamlit cannot hit API:** Wrong `API_URL`. Use `http://fastapi:8000` in Kubernetes.
- **Ingress 502/504:** Service/port mismatch; probe `/health`; check readinessProbe.
- **No metrics in Grafana:** ServiceMonitor label selector doesn’t match Service labels; verify `release`/`app` labels.
- **KEDA not scaling:** Trigger query returns 0; check Prometheus target is “up”; adjust cooldownPeriod/minReplicas.
- **CI image push fails:** Missing `DOCKERHUB_TOKEN` or wrong `DOCKERHUB_USERNAME` repo permissions.
- **Container crash loop:** Missing `MODEL_PATH`/`PREPROCESSOR_PATH` or corrupted artifact.


## 🎯 Key Learning Outcomes
* Applying MLOps best practices in a structured project
* Using MLflow to track experiments, metrics, and models
* Packaging and deploying ML services with FastAPI + Streamlit
* Leveraging Docker Compose for reproducible environments
* Demonstrating how raw data becomes a production-ready ML application

## Attribution

This project stands on the shoulders of learning materials by **Gourav Shah** (MLOps Bootcamp).  
It preserves the teaching intent and reframes it as a deployable reference—same ideas, production discipline.  
All adaptations and mistakes are mine.


