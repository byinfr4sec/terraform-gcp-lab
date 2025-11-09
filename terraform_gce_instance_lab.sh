#!/bin/bash
# =====================================================================
# Google Cloud Arcade - Level 3: Infrastructure as Code
# Lab: Terraform Essentials - Google Compute Engine Instance
# Autor: Rapha "infr4SeC" Pereira
# Objetivo: Automatizar 100% o laboratório GCE Instance via Terraform
# =====================================================================

echo "☁️ Iniciando laboratório: Terraform Essentials - Google Compute Engine Instance"
echo "==========================================================================="

# === [ Etapa 1: Coleta de informações ] =====================================
echo ""
read -p "👉 Digite o ID do seu projeto GCP (ex: qwiklabs-gcp-xxxxxx): " PROJECT_ID
read -p "🌍 Digite a REGIÃO (ex: us-central1): " REGION
read -p "📍 Digite a ZONA (ex: us-central1-a): " ZONE
echo ""

# === [ Etapa 2: Configuração inicial do projeto ] ============================
echo "⚙️ Configurando o projeto no gcloud..."
gcloud config set project $PROJECT_ID

echo "✅ Projeto configurado: $PROJECT_ID"
echo ""

# === [ Etapa 3: Criação do bucket remoto para o estado Terraform ] ==========
BUCKET_NAME="${PROJECT_ID}-tf-state"
echo "🪣 Criando bucket remoto para armazenar o estado do Terraform..."
gsutil mb -l $REGION gs://$BUCKET_NAME

echo "🔄 Habilitando versionamento no bucket..."
gsutil versioning set on gs://$BUCKET_NAME
echo "✅ Bucket criado e versionamento ativado: gs://$BUCKET_NAME"
echo ""

# === [ Etapa 4: Criação dos arquivos Terraform ] ============================
echo "📄 Gerando arquivos Terraform..."
mkdir -p terraform-gce-instance
cd terraform-gce-instance

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

resource "google_compute_instance" "default" {
  name         = "terraform-instance"
  machine_type = "e2-micro"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    subnetwork = "default"
    access_config {}
  }
}
EOF

# variables.tf
cat > variables.tf <<EOF
variable "project_id" {
  type        = string
  description = "ID do projeto Google Cloud"
  default     = "${PROJECT_ID}"
}

variable "region" {
  type        = string
  description = "Região de deploy"
  default     = "${REGION}"
}

variable "zone" {
  type        = string
  description = "Zona de deploy"
  default     = "${ZONE}"
}
EOF

echo "✅ Arquivos Terraform criados com sucesso!"
echo ""

# === [ Etapa 5: Inicialização do Terraform ] ================================
echo "🚀 Inicializando Terraform..."
terraform init

# === [ Etapa 6: Planejamento da infraestrutura ] ============================
echo ""
echo "🧩 Gerando plano de execução..."
terraform plan

# === [ Etapa 7: Aplicação da infraestrutura ] ===============================
echo ""
echo "✅ Aplicando a configuração Terraform para criar a instância GCE..."
terraform apply -auto-approve

# === [ Etapa 8: Verificação da instância criada ] ===========================
echo ""
echo "🔍 Verificando se a instância foi criada com sucesso..."
gcloud compute instances list --project $PROJECT_ID

echo ""
echo "🎉 Instância Compute Engine criada com sucesso!"
echo "==========================================================================="

# === [ Etapa 9: Instruções finais ] =========================================
echo ""
echo "🧠 Dica: Para destruir os recursos ao final do lab, execute:"
echo "    terraform destroy -auto-approve"
echo ""
echo "💾 Seus arquivos Terraform estão salvos em: terraform-gce-instance/"
echo "==========================================================================="
echo "✨ Laboratório finalizado com sucesso — by Rapha 'infr4SeC' Pereira ✨"
