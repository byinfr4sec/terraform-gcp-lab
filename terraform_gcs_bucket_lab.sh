#!/bin/bash
# =====================================================================
# Google Cloud Arcade - Level 3: Infrastructure as Code
# Lab: Terraform Essentials - Google Cloud Storage Bucket
# Autor: Rapha "infr4SeC" Pereira
# Objetivo: Automatizar 100% o laboratório de criação de bucket via Terraform
# =====================================================================

echo "☁️ Iniciando laboratório: Terraform Essentials - Google Cloud Storage Bucket"
echo "==========================================================================="

# === [ Etapa 1: Coleta de informações ] =====================================
echo ""
read -p "👉 Digite o ID do seu projeto GCP (ex: qwiklabs-gcp-xxxxxx): " PROJECT_ID
read -p "🌍 Digite a REGIÃO (ex: us-central1): " REGION
read -p "📍 Digite a ZONA (ex: us-central1-a): " ZONE
echo ""

# === [ Etapa 2: Configuração do ambiente Cloud SDK ] =======================
echo "⚙️ Configurando o ambiente do gcloud..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo "✅ Projeto, região e zona configurados!"
echo ""

# === [ Etapa 3: Criação do bucket remoto do Terraform State ] ==============
STATE_BUCKET="${PROJECT_ID}-tf-state"

echo "🪣 Criando bucket para armazenar o estado remoto do Terraform..."
gcloud storage buckets create gs://$STATE_BUCKET --project=$PROJECT_ID --location=$REGION --uniform-bucket-level-access

echo "🔄 Ativando versionamento no bucket..."
gsutil versioning set on gs://$STATE_BUCKET
echo "✅ Bucket de estado remoto configurado: gs://$STATE_BUCKET"
echo ""

# === [ Etapa 4: Criação dos arquivos Terraform ] ===========================
echo "📁 Criando diretório e arquivos Terraform..."
mkdir -p terraform-gcs
cd terraform-gcs

# main.tf
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket = "${PROJECT_ID}-tf-state"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "${PROJECT_ID}"
  region  = "${REGION}"
}

resource "google_storage_bucket" "default" {
  name          = "${PROJECT_ID}-my-terraform-bucket"
  location      = "${REGION}"
  force_destroy = true

  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}
EOF

echo "✅ Arquivo main.tf criado com sucesso!"
echo ""

# === [ Etapa 5: Inicialização e aplicação do Terraform ] ===================
echo "🚀 Inicializando Terraform..."
terraform init

echo ""
echo "🧩 Gerando plano de execução..."
terraform plan

echo ""
echo "✅ Aplicando configuração para criar o bucket..."
terraform apply -auto-approve

# === [ Etapa 6: Verificação do bucket criado ] =============================
echo ""
echo "🔍 Verificando se o bucket foi criado corretamente..."
gsutil ls gs://${PROJECT_ID}-my-terraform-bucket

echo ""
echo "🎉 Bucket criado com sucesso!"
echo "==========================================================================="

# === [ Etapa 7: Dica de limpeza dos recursos ] =============================
echo ""
echo "🧠 Para destruir os recursos e evitar custos, execute:"
echo "    terraform destroy -auto-approve"
echo ""
echo "💾 Seus arquivos Terraform estão em: terraform-gcs/"
echo "==========================================================================="
echo "✨ Laboratório finalizado com sucesso — by Rapha 'infr4SeC' Pereira ✨"
