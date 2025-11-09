#!/bin/bash
# =========================================================
# Developer Essentials: Creating Secrets with Secret Manager
# Automação completa by infr4Sec (Rapha Pereira)
# =========================================================

set -e  # Fail fast: se qualquer comando falhar, o script para imediatamente

# ---- Entrada obrigatória ----
echo "🔧 Digite o PROJECT_ID do seu ambiente Qwiklabs:"
read PROJECT_ID

# ---- Task 1: Enable Secret Manager API ----
echo "🧩 [1/4] Habilitando a API do Secret Manager..."
gcloud services enable secretmanager.googleapis.com --project="$PROJECT_ID"

# Verificação
if gcloud services list --enabled --project="$PROJECT_ID" | grep -q "secretmanager.googleapis.com"; then
  echo "✅ Secret Manager API habilitada com sucesso!"
else
  echo "❌ Falha ao habilitar a API do Secret Manager!"
  exit 1
fi

# ---- Task 2: Create a Secret ----
echo "🔐 [2/4] Criando o segredo 'my-secret'..."
gcloud secrets create my-secret --project="$PROJECT_ID" --replication-policy="automatic"

# Verificação
if gcloud secrets list --project="$PROJECT_ID" | grep -q "my-secret"; then
  echo "✅ Segredo 'my-secret' criado com sucesso!"
else
  echo "❌ Falha ao criar o segredo!"
  exit 1
fi

# ---- Task 3: Add a Secret Version ----
echo "🧾 [3/4] Adicionando uma versão com valor do segredo..."
echo -n "super-secret-password" | gcloud secrets versions add my-secret --data-file=- --project="$PROJECT_ID"

# Verificação
if gcloud secrets versions list my-secret --project="$PROJECT_ID" | grep -q "enabled"; then
  echo "✅ Versão do segredo adicionada com sucesso!"
else
  echo "❌ Falha ao adicionar versão do segredo!"
  exit 1
fi

# ---- Task 4: Access the Secret Value ----
echo "🔍 [4/4] Acessando o valor do segredo..."
SECRET_VALUE=$(gcloud secrets versions access latest --secret=my-secret --project="$PROJECT_ID")

# Verificação
if [[ "$SECRET_VALUE" == "super-secret-password" ]]; then
  echo "✅ Valor do segredo recuperado corretamente!"
else
  echo "❌ Falha ao acessar o valor do segredo!"
  exit 1
fi

# Teste variável de ambiente
export MY_SECRET="$SECRET_VALUE"

if [[ "$MY_SECRET" == "super-secret-password" ]]; then
  echo "✅ Variável de ambiente MY_SECRET configurada corretamente!"
else
  echo "❌ Falha ao configurar variável de ambiente!"
  exit 1
fi

# ---- Finalização ----
echo ""
echo "🎉 Todas as tarefas foram concluídas com sucesso!"
echo "-----------------------------------------------------"
echo "✅ API habilitada"
echo "✅ Segredo criado"
echo "✅ Versão adicionada"
echo "✅ Valor acessado e validado"
echo "-----------------------------------------------------"
echo "Lab concluído com sucesso — Developer Essentials: Creating Secrets with Secret Manager"
echo "by Rapha 'infr4Sec' Pereira 🛡️"
