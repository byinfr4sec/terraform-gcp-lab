#!/bin/bash
# ============================================================
# Lab: Deploy a static site with Caddy V2 on Google Cloud Run
# Automação: executa exatamente as tasks do lab (1..7)
# Autor: Rapha "infr4SeC" Pereira
# Nota: só pede PROJECT_ID e REGION (obrigatórios). Nada mais.
# ============================================================

# Não usar set -e: queremos coletar status de cada task e relatar ao final.
# Cada task grava status em uma variável (OK/FAIL) e logs mínimos.
TASK1_STATUS="PENDING"
TASK2_STATUS="PENDING"
TASK3_STATUS="PENDING"
TASK4_STATUS="PENDING"
TASK5_STATUS="PENDING"
TASK6_STATUS="PENDING"
TASK7_STATUS="PENDING"

LOG_DIR="./caddy_lab_logs_$(date +%s)"
mkdir -p "$LOG_DIR"

# Helpers de logging/estado
log()   { printf "%s\n" "$*" | tee -a "$LOG_DIR/run.log"; }
ok()    { printf "✅ %s\n" "$*" | tee -a "$LOG_DIR/run.log"; }
err()   { printf "❌ %s\n" "$*" | tee -a "$LOG_DIR/run.log"; }
save_out(){ printf "%s\n" "$1" > "$2"; }

echo
log "=============================================="
log "Caddy on Cloud Run - Auto Lab Runner"
log "=============================================="
echo

# --- Solicita PROJECT_ID e REGION ---
read -p "👉 Digite o PROJECT_ID (fornecido pelo lab): " PROJECT_ID
read -p "👉 Digite a REGION para Cloud Run / Artifact Registry (ex: us-central1): " REGION

# validação básica
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ]; then
  err "PROJECT_ID e REGION são obrigatórios. Abortando."
  exit 1
fi

log "Project: $PROJECT_ID"
log "Region:  $REGION"

# ---------------------------
# Task 1: Set up environment
# ---------------------------
log ""
log ">> Task 1: Configurar ambiente (gcloud project, run region, habilitar APIs)"

# set project
gcloud config set project "$PROJECT_ID" 2>&1 | tee -a "$LOG_DIR/task1_gcloud_config.log"
gcloud config set run/region "$REGION" 2>&1 | tee -a "$LOG_DIR/task1_gcloud_config.log"

# Enable APIs
gcloud services enable run.googleapis.com artifactregistry.googleapis.com cloudbuild.googleapis.com --project="$PROJECT_ID" 2>&1 | tee -a "$LOG_DIR/task1_enable_apis.log"
if gcloud services list --enabled --project="$PROJECT_ID" | grep -E "run.googleapis.com|artifactregistry.googleapis.com|cloudbuild.googleapis.com" >/dev/null 2>&1; then
  TASK1_STATUS="OK"
  ok "Task 1 concluída: ambiente configurado e APIs habilitadas."
else
  TASK1_STATUS="FAIL"
  err "Task 1 falhou: verifique logs em $LOG_DIR/task1_enable_apis.log"
fi

# ---------------------------
# Task 2: Create Artifact Registry repo
# ---------------------------
log ""
log ">> Task 2: Criar repositório Artifact Registry (caddy-repo)"

# create repo (if exists, ignore)
ARTIFACT_REPO_NAME="caddy-repo"
gcloud artifacts repositories create "$ARTIFACT_REPO_NAME" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Docker repository for Caddy images" \
  --project="$PROJECT_ID" 2>&1 | tee -a "$LOG_DIR/task2_create_repo.log" || true

# verify
if gcloud artifacts repositories list --project="$PROJECT_ID" --location="$REGION" --format="value(name)" 2>/dev/null | grep -q "^$ARTIFACT_REPO_NAME$"; then
  TASK2_STATUS="OK"
  ok "Task 2 concluída: repositório Artifact Registry '$ARTIFACT_REPO_NAME' existe em $REGION."
else
  TASK2_STATUS="FAIL"
  err "Task 2 falhou: repositório não criado. Ver logs: $LOG_DIR/task2_create_repo.log"
fi

# ---------------------------
# Task 3: Create static website + Caddyfile
# ---------------------------
log ""
log ">> Task 3: Criar index.html e Caddyfile"

WORKDIR="./caddy_static_site"
mkdir -p "$WORKDIR"
cat > "$WORKDIR/index.html" <<'HTML'
<html>
<head>
  <title>My Static Website</title>
</head>
<body>
  <div>Hello from Caddy on Cloud Run!</div>
  <p>This website is served by Caddy running in a Docker container on Google Cloud Run.</p>
</body>
</html>
HTML

cat > "$WORKDIR/Caddyfile" <<'CADDY'
:8080
root * /usr/share/caddy
file_server
CADDY

# verify files
if [ -f "$WORKDIR/index.html" ] && [ -f "$WORKDIR/Caddyfile" ]; then
  TASK3_STATUS="OK"
  ok "Task 3 concluída: index.html e Caddyfile criados em $WORKDIR"
else
  TASK3_STATUS="FAIL"
  err "Task 3 falhou: arquivos não encontrados em $WORKDIR"
fi

# ---------------------------
# Task 4: Create Dockerfile
# ---------------------------
log ""
log ">> Task 4: Criar Dockerfile para Caddy"

cat > "$WORKDIR/Dockerfile" <<'DOCKER'
FROM caddy:2-alpine

WORKDIR /usr/share/caddy

COPY index.html .
COPY Caddyfile /etc/caddy/Caddyfile
DOCKER

if [ -f "$WORKDIR/Dockerfile" ]; then
  TASK4_STATUS="OK"
  ok "Task 4 concluída: Dockerfile criado."
else
  TASK4_STATUS="FAIL"
  err "Task 4 falhou: Dockerfile não criado."
fi

# ---------------------------
# Task 5: Build and Push Docker Image to Artifact Registry
# ---------------------------
log ""
log ">> Task 5: Build & Push Docker image to Artifact Registry"

IMAGE_HOST="${REGION}-docker.pkg.dev"
IMAGE_REPO="${IMAGE_HOST}/${PROJECT_ID}/${ARTIFACT_REPO_NAME}"
IMAGE_NAME="${IMAGE_REPO}/caddy-static:latest"

log "Authenticating Docker to Artifact Registry..."
gcloud auth configure-docker "${IMAGE_HOST}" --quiet 2>&1 | tee -a "$LOG_DIR/task5_docker_auth.log" || true

log "Building Docker image..."
docker build -t "$IMAGE_NAME" "$WORKDIR" 2>&1 | tee -a "$LOG_DIR/task5_docker_build.log"
BUILD_RC=${PIPESTATUS[0]}

if [ $BUILD_RC -ne 0 ]; then
  TASK5_STATUS="FAIL"
  err "Task 5 falhou na build do Docker. Veja $LOG_DIR/task5_docker_build.log"
else
  log "Tagging & pushing image: $IMAGE_NAME"
  docker push "$IMAGE_NAME" 2>&1 | tee -a "$LOG_DIR/task5_docker_push.log"
  PUSH_RC=${PIPESTATUS[0]}
  if [ $PUSH_RC -ne 0 ]; then
    TASK5_STATUS="FAIL"
    err "Task 5 falhou no push do Docker. Ver logs: $LOG_DIR/task5_docker_push.log"
  else
    TASK5_STATUS="OK"
    ok "Task 5 concluída: imagem enviada para Artifact Registry: $IMAGE_NAME"
  fi
fi

# ---------------------------
# Task 6: Deploy to Cloud Run
# ---------------------------
log ""
log ">> Task 6: Deploy to Cloud Run (service: caddy-static) - allow unauthenticated"

DEPLOY_CMD="gcloud run deploy caddy-static --image=${IMAGE_NAME} --platform=managed --region=${REGION} --allow-unauthenticated --project=${PROJECT_ID} --quiet"
log "Executando: $DEPLOY_CMD"
$DEPLOY_CMD 2>&1 | tee -a "$LOG_DIR/task6_deploy.log"
DEPLOY_RC=${PIPESTATUS[0]}

if [ $DEPLOY_RC -ne 0 ]; then
  TASK6_STATUS="FAIL"
  err "Task 6 falhou: deploy para Cloud Run não concluído. Ver $LOG_DIR/task6_deploy.log"
else
  TASK6_STATUS="OK"
  ok "Task 6 concluída: serviço Cloud Run 'caddy-static' implantado."
fi

# Capture service URL
if [ "$TASK6_STATUS" = "OK" ]; then
  SERVICE_URL=$(gcloud run services describe caddy-static --platform managed --region "$REGION" --project="$PROJECT_ID" --format='value(status.url)' 2>/dev/null)
  save_out "$SERVICE_URL" "$LOG_DIR/service_url.txt"
  log "Service URL: $SERVICE_URL"
fi

# ---------------------------
# Task 7: Access the website (validate)
# ---------------------------
log ""
log ">> Task 7: Acessar URL e validar conteúdo"

if [ -n "$SERVICE_URL" ]; then
  # wait a bit for service readiness
  log "Aguardando 5s para o serviço ficar pronto..."
  sleep 5
  HTTP_OUTPUT=$(curl -sS "$SERVICE_URL" || true)
  save_out "$HTTP_OUTPUT" "$LOG_DIR/task7_curl_output.html"
  if echo "$HTTP_OUTPUT" | grep -q "Hello from Caddy on Cloud Run"; then
    TASK7_STATUS="OK"
    ok "Task 7 concluída: conteúdo válido servido pela URL."
  else
    TASK7_STATUS="FAIL"
    err "Task 7 falhou: conteúdo esperado não encontrado na URL. Veja $LOG_DIR/task7_curl_output.html"
  fi
else
  TASK7_STATUS="FAIL"
  err "Task 7 falhou: Service URL não disponível."
fi

# ---------------------------
# Final Report
# ---------------------------
echo
log "=============================================="
log "FINAL REPORT - Tasks status"
log "=============================================="
printf "Task 1 (setup + APIs)........: %s\n" "$TASK1_STATUS" | tee -a "$LOG_DIR/final_report.txt"
printf "Task 2 (artifact repo)......: %s\n" "$TASK2_STATUS" | tee -a "$LOG_DIR/final_report.txt"
printf "Task 3 (site + Caddyfile)...: %s\n" "$TASK3_STATUS" | tee -a "$LOG_DIR/final_report.txt"
printf "Task 4 (Dockerfile).........: %s\n" "$TASK4_STATUS" | tee -a "$LOG_DIR/final_report.txt"
printf "Task 5 (build & push image)..: %s\n" "$TASK5_STATUS" | tee -a "$LOG_DIR/final_report.txt"
printf "Task 6 (deploy Cloud Run)....: %s\n" "$TASK6_STATUS" | tee -a "$LOG_DIR/final_report.txt"
printf "Task 7 (validate site)......: %s\n" "$TASK7_STATUS" | tee -a "$LOG_DIR/final_report.txt"
log "----------------------------------------------"

# show service url if ok
if [ "$TASK7_STATUS" = "OK" ]; then
  log "Your site is live at: $SERVICE_URL"
  log "You can open it in browser to manually verify."
else
  log "If any task FAILED, check logs in: $LOG_DIR"
fi

log "Run logs saved in directory: $LOG_DIR"
log "=============================================="
echo
