#!/bin/bash
# ============================================================================
# Google Cloud Arcade - Level 3: Scalable Deployments and Delivery
# Lab: Terraform Essentials - Firewall Policy
# Autor: Rapha "infr4SeC" Pereira
# Descrição: Automação completa da criação de uma Firewall Rule via Terraform.
# ============================================================================

echo "🔥 Iniciando laboratório: Terraform Essentials - Firewall Policy"
echo "==========================================================================="

# === [ Etapa 1: Entrada de variáveis básicas ] ==============================
echo ""
read -p "👉 Digite o ID do seu projeto GCP (ex: qwiklabs-gcp-xxxxxx): " PROJECT_ID
read -p "🌍 Digite a REGIÃO (ex: us-central1): " REGION
read -p "📍 Digite a ZONA (ex: us-central1-a): " ZONE
echo ""

# === [ Etapa 2: Configuração do ambiente do Cloud SDK ] =====================
echo "⚙️ Configurando o projeto e região padrão..."
gcloud config set project $PROJECT_ID
gcloud config set compute/region $REGION
gcloud config set compute/zone $ZONE
echo "✅ Configuração do gcloud concluída!"
echo ""

# === [ Etapa 3: Criar bucket remoto para Terraform state ] ==================
STATE_BUCKET="${PROJECT_ID}-tf-state"

echo "🪣 Criando bucket remoto para armazenar o Terraform state..."
gcloud storage buckets create gs://$STATE_BUCKET --project=$PROJECT_ID --location=$REGION --uniform-bucket-level-access

echo "🔁 Habilitando versionamento no bucket..."
gsutil versioning set on gs://$STATE_BUCKET

echo "✅ Bucket criado e versionamento ativado!"
echo ""

# === [ Etapa 4: Estrutura Terraform ] =======================================
echo "📁 Criando diretório e arquivos Terraform..."
mkdir -p terraform-firewall
cd terraform-firewall

# firewall.tf
cat > firewall.tf <<EOF
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh-from-anywhere"
  network = "default"
  project = "${PROJECT_ID}"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh-allowed"]
}
EOF

# variables.tf
cat > variables.tf <<EOF
variable "project_id" {
  type        = string
  description = "The GCP project ID"
  default     = "${PROJECT_ID}"
}

variable "bucket_name" {
  type        = string
  description = "The Terraform backend bucket name"
  default     = "${STATE_BUCKET}"
}

variable "region" {
  type        = string
  description = "The GCP region"
  default     = "${REGION}"
}
EOF

# outputs.tf
cat > outputs.tf <<EOF
output "firewall_name" {
  value = google_compute_firewall.allow_ssh.name
}
EOF

# main.tf (configuração base do Terraform e backend)
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }

  backend "gcs" {
    bucket = "${STATE_BUCKET}"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
EOF

echo "✅ Arquivos Terraform criados com sucesso!"
echo ""

# === [ Etapa 5: Inicializar e aplicar Terraform ] ===========================
echo "🚀 Inicializando o Terraform..."
terraform init

echo ""
echo "🧩 Gerando plano de execução..."
terraform plan

echo ""
echo "⚡ Aplicando configuração e criando firewall rule..."
terraform apply -auto-approve

echo ""
echo "🔍 Verificando se o firewall foi criado..."
gcloud compute firewall-rules list --filter="name=allow-ssh-from-anywhere" --project=$PROJECT_ID

echo ""
echo "✅ Firewall rule criada com sucesso!"
echo "==========================================================================="

# === [ Etapa 6: Dica de limpeza ] ==========================================
echo ""
echo "🧠 Para remover os recursos e evitar custos, execute:"
echo "    terraform destroy -auto-approve"
echo ""
echo "💾 Seus arquivos Terraform estão em: terraform-firewall/"
echo "==========================================================================="
echo "✨ Laboratório concluído com sucesso — by Rapha 'infr4SeC' Pereira ✨"
