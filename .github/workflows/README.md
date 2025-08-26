## ⚙️ CI/CD — GitHub Actions Pipeline

This pipeline automates data processing, feature engineering, model training (with MLflow), and container build/publish.

### Triggers
- **Manual:** `workflow_dispatch` with inputs
  - `run_all` (default `true`)
  - `run_data_processing`, `run_model_training`, `run_build_and_publish` (selective runs)
- **Release:** on `release: created` for `main` with tags `v*.*.*`

### Jobs Overview

| Job                | Purpose                                                     | Key Steps (high level)                                                                 | Outputs / Artifacts                         |
|--------------------|-------------------------------------------------------------|----------------------------------------------------------------------------------------|---------------------------------------------|
| `data-processing`  | Clean data + engineer features                              | Setup Python → install deps → run `run_processing.py` and `engineer.py`               | `processed-data` (featured CSV), `preprocessor` (pickle) |
| `model-training`   | Train and log model; ephemeral MLflow server in CI          | Download artifacts → run MLflow in Docker (SQLite backend) → train via `train_model.py` | `trained-model` (model dir incl. pickle(s)) |
| `build-and-publish`| Build, health-check, and publish FastAPI image to DockerHub | Build with commit tag → run container + `/health` probe → push `:shortSHA` and `:latest` | Image in DockerHub                          |

### Required Repository Variables / Secrets

| Name                 | Type       | Used In              | Notes                                                |
|----------------------|------------|----------------------|------------------------------------------------------|
| `DOCKERHUB_USERNAME` | **Variable** | build-and-publish     | Your DockerHub username                              |
| `DOCKERHUB_TOKEN`    | **Secret**   | docker login & push   | Personal access token or password                    |

### What the pipeline actually does

1. **Data step**
   - Upgrades `pip`, installs `requirements.txt`.
   - Runs:
     ```bash
     python src/data/run_processing.py --input data/raw/house_data.csv --output data/processed/cleaned_house_data.csv
     python src/features/engineer.py --input data/processed/cleaned_house_data.csv --output data/processed/featured_house_data.csv --preprocessor models/trained/preprocessor.pkl
     ```
   - Uploads artifacts: `featured_house_data.csv`, `preprocessor.pkl`.

2. **Training step**
   - Downloads processed artifacts.
   - Starts MLflow in Docker on `:5000` with SQLite backend.
   - Trains model:
     ```bash
     python src/models/train_model.py \
       --config configs/model_config.yaml \
       --data data/processed/featured_house_data.csv \
       --models-dir models \
       --mlflow-tracking-uri http://localhost:5000
     ```
   - Uploads `models/` as `trained-model` artifact.
   - Stops/removes MLflow container.

3. **Build & publish**
   - Downloads `trained-model` and `preprocessor` artifacts into `models/`.
   - Builds the FastAPI image from root `Dockerfile`:
     - Tags: `docker.io/${DOCKERHUB_USERNAME}/house-price-model:<shortSHA>` and `:latest`.
   - Boots the container, waits for `http://localhost:8000/health` to pass, prints last logs.
   - Pushes both tags to DockerHub.

### Manual Run (Examples)

Run everything:
```bash
gh workflow run "MLOps Pipeline" -f run_all=true
