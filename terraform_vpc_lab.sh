#!/bin/bash
# ============================================================
# Terraform Essentials: VPC and Subnet - Google Cloud Lab
# Automação criada por: Rapha "infr4SeC" Pereira
# ============================================================

echo "🚀 Iniciando configuração do ambiente Terraform + GCP..."
echo ""

# === INPUTS DO USUÁRIO ===
read -p "👉 Digite o PROJECT_ID fornecido pelo lab: " PROJECT_ID
read -p "🌎 Digite a REGION (ex: us-central1): " REGION
read -p "🗺️  Digite a ZONE (ex: us-central1-a): " ZONE

# === VALIDAÇÃO SIMPLES ===
if [ -z "$PROJECT_ID" ] || [ -z "$REGION" ] || [ -z "$ZONE" ]; then
  echo "❌ Erro: Todos os campos (PROJECT_ID, REGION, ZONE) são obrigatórios."
  exit 1
fi

BUCKET_NAME="${PROJECT_ID}-terraform-state"

echo ""
echo "📦 Projeto: $PROJECT_ID"
echo "🌍 Região: $REGION"
echo "🧭 Zona: $ZONE"
echo ""

# === CONFIGURA GCP ===
gcloud config set project "$PROJECT_ID"
gcloud config set compute/region "$REGION"
gcloud config set compute/zone "$ZONE"

# === CRIA BUCKET PARA STATE DO TERRAFORM ===
echo "🪣 Criando bucket remoto para o Terraform state..."
gcloud storage buckets create "gs://${BUCKET_NAME}" \
  --project="${PROJECT_ID}" \
  --location="${REGION}" \
  --uniform-bucket-level-access || echo "⚠️ Bucket já existe, prosseguindo..."

# === HABILITA APIs NECESSÁRIAS ===
echo "⚙️ Ativando Cloud Resource Manager API..."
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

# === EXECUÇÃO DO TERRAFORM ===
echo ""
echo "🔧 Inicializando Terraform..."
terraform init

echo ""
echo "🧩 Gerando plano de execução..."
terraform plan

echo ""
echo "🚀 Aplicando configurações..."
terraform apply --auto-approve

# === RESULTADOS ===
echo ""
echo "✅ Recursos criados com sucesso!"
terraform output

# === INSTRUÇÕES FINAIS ===
echo ""
echo "🔍 Validação manual no Console GCP:"
echo "  → VPC network → confirmar 'custom-vpc-network'"
echo "  → Subnets → confirmar 'subnet-us'"
echo "  → Firewall → confirmar 'allow-ssh' e 'allow-icmp'"
echo ""
echo "🧹 Para limpar o ambiente após o teste, execute:"
echo "terraform destroy --auto-approve"
echo ""
echo "🧱 Lab Terraform VPC & Subnet finalizado!"
