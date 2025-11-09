#!/bin/bash
# ============================================================
# Terraform Essentials: VPC and Subnet - Google Cloud Lab
# Automação criada por: Rapha "infr4SeC" Pereira
# ============================================================
# Este script automatiza o laboratório do Qwiklabs:
# "Terraform Essentials: VPC and Subnet"
# ============================================================

# ✅ Pré-requisitos:
# - Executar dentro do Cloud Shell do Google Cloud
# - Projeto ativo no Qwiklabs com permissões adequadas
# ============================================================

echo "🚀 Iniciando configuração do ambiente Terraform + GCP..."

# === VARIÁVEIS DE CONFIGURAÇÃO ===
PROJECT_ID=$(gcloud config get-value project)
REGION="us-central1"
ZONE="us-central1-a"
BUCKET_NAME="${PROJECT_ID}-terraform-state"

echo "📦 Projeto ativo: $PROJECT_ID"
echo "🌎 Região: $REGION | Zona: $ZONE"

# === CONFIGURA GCP ===
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# === CRIA BUCKET PARA STATE DO TERRAFORM ===
echo "🪣 Criando bucket para armazenar o state remoto do Terraform..."
gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --location=us \
  --uniform-bucket-level-access || echo "⚠️ Bucket já existe, prosseguindo..."

# === HABILITA APIs NECESSÁRIAS ===
echo "⚙️ Ativando API Cloud Resource Manager..."
gcloud services enable cloudresourcemanager.googleapis.com --project="${PROJECT_ID}"

# === CRIA DIRETÓRIO DO PROJETO ===
mkdir -p terraform-vpc && cd terraform-vpc

# === ARQUIVO PRINCIPAL DO TERRAFORM ===
cat > main.tf <<EOF
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.0"
    }
  }
  backend "gcs" {
    bucket = "${BUCKET_NAME}"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = "${PROJECT_ID}"
  region  = "${REGION}"
}

# Cria rede VPC customizada
resource "google_compute_network" "vpc_network" {
  name                    = "custom-vpc-network"
  auto_create_subnetworks = false
}

# Cria sub-rede dentro da VPC
resource "google_compute_subnetwork" "subnet_us" {
  name            = "subnet-us"
  ip_cidr_range   = "10.10.1.0/24"
  region          = "${REGION}"
  network         = google_compute_network.vpc_network.id
}

# Regra de firewall para SSH
resource "google_compute_firewall" "allow_ssh" {
  name    = "allow-ssh"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  source_ranges = ["0.0.0.0/0"]
}

# Regra de firewall para ICMP
resource "google_compute_firewall" "allow_icmp" {
  name    = "allow-icmp"
  network = google_compute_network.vpc_network.name
  allow {
    protocol = "icmp"
  }
  source_ranges = ["0.0.0.0/0"]
}
EOF

# === VARIÁVEIS DO TERRAFORM ===
cat > variables.tf <<EOF
variable "project_id" {
  type        = string
  description = "O ID do projeto Google Cloud"
  default     = "${PROJECT_ID}"
}

variable "region" {
  type        = string
  description = "Região onde os recursos serão criados"
  default     = "${REGION}"
}
EOF

# === OUTPUTS ===
cat > outputs.tf <<EOF
output "network_name" {
  value       = google_compute_network.vpc_network.name
  description = "Nome da VPC criada"
}

output "subnet_name" {
  value       = google_compute_subnetwork.subnet_us.name
  description = "Nome da Subnet criada"
}
EOF

# === INICIALIZA, PLANEJA E APLICA CONFIGURAÇÕES ===
echo "🔧 Inicializando Terraform..."
terraform init

echo "🧩 Verificando plano de execução..."
terraform plan

echo "🚀 Aplicando configurações..."
terraform apply --auto-approve

# === RESULTADOS ===
echo "✅ Recursos criados com sucesso!"
terraform output

# === INSTRUÇÕES DE VALIDAÇÃO ===
echo ""
echo "🔍 Validação manual (no Console GCP):"
echo "1️⃣ Acesse: VPC Network → VPC networks → confirme 'custom-vpc-network'"
echo "2️⃣ Acesse: Subnets → confirme 'subnet-us'"
echo "3️⃣ Acesse: Firewall rules → confirme 'allow-ssh' e 'allow-icmp'"
echo ""

# === LIMPEZA OPCIONAL ===
echo "🧹 Para remover os recursos e evitar custos, execute:"
echo "terraform destroy --auto-approve"
echo ""
echo "🧱 Lab Terraform VPC & Subnet concluído com sucesso!"