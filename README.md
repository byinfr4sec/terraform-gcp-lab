## 🚀 **GCP Labs Automation – Terraform, Secret Manager & Cloud Run (Caddy V2)**

### 📘 **Descrição Geral**

Este repositório contém scripts Shell automatizados para execução **completa e validada** de três laboratórios oficiais do **Google Cloud Skills Boost**.
Cada script executa **somente o que o lab pede** — nada a mais, nada a menos — automatizando todas as tarefas e verificando o sucesso de cada etapa.

Os scripts foram desenvolvidos para serem executados **diretamente no Google Cloud Shell**, e solicitam **apenas as variáveis obrigatórias** (como `PROJECT_ID`, `REGION` e `ZONE`), conforme os requisitos de cada laboratório.

---

### 🧩 **Laboratórios Incluídos**

#### **1️⃣ Terraform Essentials: Service Account**

> Cria uma Service Account usando o Terraform e armazena o state file em um bucket GCS.

**Principais etapas automatizadas:**

* Configuração do projeto, região e zona
* Habilitação da API `iam.googleapis.com`
* Criação de bucket remoto para o state (`gs://<PROJECT_ID>-tf-state`)
* Criação dos arquivos `main.tf` e `variables.tf`
* Inicialização (`terraform init`) e aplicação (`terraform apply`)
* Validação automática da criação da Service Account
* Destruição dos recursos (`terraform destroy`)

**Techs utilizadas:**
`Terraform`, `Google Cloud IAM`, `Google Cloud Storage`, `gcloud CLI`

---

#### **2️⃣ Developer Essentials: Creating Secrets with Secret Manager**

> Criação, armazenamento e leitura de segredos com o Secret Manager.

**Principais etapas automatizadas:**

* Habilitação da API `secretmanager.googleapis.com`
* Criação do segredo `my-secret`
* Adição de versão com valor `super-secret-password`
* Recuperação e exibição do segredo
* Armazenamento em variável de ambiente `MY_SECRET`
* Validação do valor retornado

**Techs utilizadas:**
`Secret Manager`, `gcloud CLI`, `bash scripting`

---

#### **3️⃣ Deploy a Static Site with Caddy V2 on Cloud Run**

> Cria, empacota e implanta um site estático com o Caddy no Cloud Run.

**Principais etapas automatizadas:**

* Configuração de projeto e região
* Habilitação das APIs:

  * `run.googleapis.com`
  * `artifactregistry.googleapis.com`
  * `cloudbuild.googleapis.com`
* Criação do repositório `caddy-repo` no Artifact Registry
* Criação dos arquivos:

  * `index.html`
  * `Caddyfile`
  * `Dockerfile`
* Build e push da imagem para o Artifact Registry
* Deploy automático no Cloud Run com `--allow-unauthenticated`
* Validação do serviço e exibição do URL público

**Techs utilizadas:**
`Cloud Run`, `Artifact Registry`, `Caddy V2`, `Docker`, `Cloud Build`, `gcloud CLI`

---

### ⚙️ **Como Executar os Scripts**

Execute no **Cloud Shell**:

```bash
curl -LO https://raw.githubusercontent.com/byinfr4sec/gcp-labs-automation/main/terraform_firestore_lab.sh
sudo chmod +x terraform_firestore_lab.sh
./terraform_firestore_lab.sh
```

Substitua o nome do script conforme o laboratório desejado:

* `terraform_service_account_lab.sh`
* `secret_manager_lab.sh`
* `cloud_run_caddy_lab.sh`

Cada script:

* Solicita `PROJECT_ID`, `REGION` e `ZONE` (quando necessário)
* Executa automaticamente todas as tarefas do lab
* Exibe logs coloridos e mensagens de validação final

---

### ✅ **Validação Automática**

Cada script realiza verificações automáticas no final, confirmando se todas as tarefas foram concluídas com sucesso — exatamente conforme o guia do laboratório.
Em caso de erro, o script exibe mensagens claras e sugestões para correção.

---

### 💡 **Requisitos**

* **Google Cloud Shell** (já vem com `gcloud`, `terraform`, `docker` e `bash`)
* Permissões de `Editor` no projeto
* Projeto ativo e APIs habilitáveis

---

### 🧠 **Aprendizados**

Esses laboratórios permitem compreender:

* Infraestrutura como código com Terraform
* Armazenamento seguro de segredos no GCP
* Deploy de containers no Cloud Run
* Integração entre Cloud Build, Artifact Registry e serviços gerenciados

---

### 👨‍💻 **Autor & Créditos**

Desenvolvido e automatizado por **ByInfr4Sec**
📎 *GCP Labs Automation Series – 2025 Edition*
📧 Contato: [https://github.com/byinfr4sec](https://github.com/byinfr4sec)

---

### 🏁 **Licença**

Este projeto é distribuído sob a licença **MIT**, permitindo uso, modificação e redistribuição livremente, desde que os créditos originais sejam mantidos.

---
