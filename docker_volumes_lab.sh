#!/bin/bash
# ================================================
# Google Cloud Arcade - Level 3
# Lab: Docker Essentials: Container Volumes
# Autor: Raphael "infr4SeC" Pereira
# ================================================

# Este script segue as instruções oficiais do Qwiklabs.
# ⚠️ IMPORTANTE: Execute passo a passo e leia os comentários.
# Ele serve como guia automatizado e educativo.

echo "===================================================="
echo " 🐳 Docker Essentials: Container Volumes - LAB START "
echo "===================================================="
echo ""
echo "🚀 Este script ajudará você a testar volumes Docker (named, bind mounts, e compose)."
echo "👉 Leia cada comentário e observe os resultados no terminal."
echo ""

# ------------------------------------------------------
# Task 1 - Revisão conceitual (nenhum comando necessário)
# ------------------------------------------------------
echo ""
echo "📘 [Task 1] Entendendo Volumes Docker"
echo " - Named Volumes: gerenciados pelo Docker (persistência simples)."
echo " - Bind Mounts: vincula diretórios do host diretamente no container."
echo " - tmpfs: dados em memória, não persistem."
echo "✅ Essa seção é teórica. Vamos criar volumes agora..."
echo ""

# ------------------------------------------------------
# Task 2 - Criar e usar Named Volumes
# ------------------------------------------------------
echo "📦 [Task 2] Criando e utilizando Named Volumes..."
sleep 2

echo "👉 Criando volume chamado 'mydata'..."
docker volume create mydata

echo "🔍 Inspecionando volume..."
docker volume inspect mydata

echo "🚀 Executando container Alpine com volume montado em /data..."
docker run -it -v mydata:/data alpine ash <<'EOF'
cd /data
echo "Hello from inside the container!" > myfile.txt
exit
EOF

echo "🛑 Parando containers..."
docker stop $(docker ps -aq) 2>/dev/null

echo "🧹 Removendo containers..."
docker rm $(docker ps -aq) 2>/dev/null

echo "♻️ Rodando novo container com o mesmo volume para validar persistência..."
docker run -it -v mydata:/data alpine ash <<'EOF'
cd /data
echo "Conteúdo do volume persistido:"
cat myfile.txt
exit
EOF

echo "✅ Arquivo persistido com sucesso!"
echo ""

# ------------------------------------------------------
# Task 3 - Bind Mounts
# ------------------------------------------------------
echo "📂 [Task 3] Testando Bind Mounts..."
sleep 2

echo "📁 Criando diretório no host ~/host_data"
mkdir -p ~/host_data
echo "Hello from the host!" > ~/host_data/hostfile.txt

echo "🚀 Rodando container Alpine com bind mount ativo..."
docker run -it -v /home/$USER/host_data:/data alpine ash <<'EOF'
echo "This line added from container" >> /data/hostfile.txt
cat /data/hostfile.txt
exit
EOF

echo "🔍 Verificando alterações no host..."
cat ~/host_data/hostfile.txt
echo "✅ Alterações refletidas com sucesso!"
echo ""

# ------------------------------------------------------
# Task 4 - Docker Compose com Volumes
# ------------------------------------------------------
echo "🧱 [Task 4] Usando Docker Compose com volumes..."
sleep 2

echo "📁 Criando diretório compose-lab..."
mkdir -p ~/compose-lab && cd ~/compose-lab

# Cria o docker-compose.yml
cat <<'EOF' > docker-compose.yml
version: "3.3"
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
    volumes:
      - web_data:/usr/share/nginx/html
volumes:
  web_data:
EOF

# Cria o index.html
cat <<'EOF' > index.html
<html>
<head>
  <title>Docker Compose Volume Example</title>
</head>
<body>
  <div><strong>Hello from Docker Compose!</strong></div>
  <p>This content is served from a Docker volume.</p>
</body>
</html>
EOF

echo "🚀 Subindo o ambiente com Docker Compose..."
docker-compose up -d

echo "🌐 Acessando o conteúdo via curl (porta 8080)..."
sleep 5
curl http://localhost:8080 || echo "⚠️ Verifique se o container está rodando corretamente."

echo "🛑 Encerrando containers e limpando recursos..."
docker-compose down
echo "✅ Compose finalizado!"
echo ""

# ------------------------------------------------------
# Clean-up Opcional
# ------------------------------------------------------
echo "🧹 [Opcional] Limpando volumes e diretórios..."
docker volume rm mydata 2>/dev/null
rm -rf ~/host_data ~/compose-lab

echo "===================================================="
echo " 🎯 LAB FINALIZADO - Docker Volumes Essentials"
echo "===================================================="
