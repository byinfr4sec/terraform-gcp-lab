#!/bin/bash
# =====================================================================
# Google Cloud Arcade - Level 3: Scalable Deployments and Delivery
# Lab: Terraform Essentials - Service Account
# Autor: Rapha "infr4SeC" Pereira
# Objetivo: Automatizar 100% o laboratório de criação de Service Account via Terraform
# =====================================================================

echo "☁️ Iniciando laboratório: Terraform Essentials - Service Account"
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

# === [ Etapa 3: Habilitar APIs necessárias ] ===============================
echo "🔓 Habilitando a API do IAM..."
gcloud services enable iam.googleapis.com
echo "✅ IAM API habilitada!"
echo ""

# === [ Etapa 4: Criar bucket remoto para o Terraform State ] ===============
STATE_BUCKET="${PROJECT_ID}-tf-state"

echo "🪣 Criando bucket remoto para o Terraform state..."
gcloud storage buckets create gs://$STATE_BUCKET --project=$PROJECT_ID --location=$REGION --uniform-bucket-level-access

echo "🔄 Ativando versionamento no bucket..."
gsutil versioning set on gs://$STATE_BUCKET
echo "✅ Bucket de estado remoto criado: gs://$STATE_BUCKET"
echo ""

# === [ Etapa 5: Criar estrutura Terraform ] ================================
echo "📁 Criando diretório e arquivos Terraform..."
mkdir -p terraform-service-account
cd terraform-service-account

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
  project = var.project_id
  region  = var.region
}

resource "google_service_account" "default" {
  account_id   = "terraform-sa"
  display_name = "Terraform Service Account"
}
EOF

# variables.tf
cat > variables.tf <<EOF
variable "project_id" {
  type        = string
  description = "The GCP project ID"
  default     = "${PROJECT_ID}"
}

variable "region" {
  type        = string
  description = "The GCP region"
  default     = "${REGION}"
}
EOF

echo "✅ Arquivos main.tf e variables.tf criados com sucesso!"
echo ""

# === [ Etapa 6: Inicialização e aplicação do Terraform ] ===================
echo "🚀 Inicializando Terraform..."
terraform init

echo ""
echo "🧩 Gerando plano de execução..."
terraform plan

echo ""
echo "✅ Aplicando configuração para criar o Service Account..."
terraform apply -auto-approve

# === [ Etapa 7: Verificação do recurso criado ] ============================
echo ""
echo "🔍 Verificando se o Service Account foi criado corretamente..."
gcloud iam service-accounts list --project=$PROJECT_ID

echo ""
echo "🎉 Service Account criado com sucesso!"
echo "==========================================================================="

# === [ Etapa 8: Dica de limpeza dos recursos ] =============================
echo ""
echo "🧠 Para destruir os recursos e evitar custos, execute:"
echo "    terraform destroy -auto-approve"
echo ""
echo "💾 Seus arquivos Terraform estão em: terraform-service-account/"
echo "==========================================================================="
echo "✨ Laboratório finalizado com sucesso — by Rapha 'infr4SeC' Pereira ✨"
