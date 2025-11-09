#!/bin/bash
# ============================================================
# Google Cloud Arcade - Level 3
# Lab: Docker Essentials - Container Volumes
# Autor: Raphael "infr4SeC" Pereira
# Versão: Auto-Checker Edition (v3)
# ============================================================

echo "===================================================="
echo " 🐳 Docker Essentials: Container Volumes - Auto Checker "
echo "===================================================="
echo ""
echo "👋 Olá! Este script segue passo a passo o lab oficial."
echo "   Ele vai verificar automaticamente se cada etapa foi feita corretamente."
echo ""

# ------------------------------------------------------
# Task 1 - Overview
# ------------------------------------------------------
echo "📘 [Task 1] Conceitos revisados — nenhuma ação necessária."
sleep 2

# ------------------------------------------------------
# Task 2 - Named Volumes
# ------------------------------------------------------
echo ""
echo "📦 [Task 2] Criando Named Volume..."
docker volume create mydata >/dev/null 2>&1

if docker volume inspect mydata >/dev/null 2>&1; then
  echo "✅ Volume 'mydata' criado com sucesso!"
else
  echo "❌ Falha ao criar o volume 'mydata'."
  exit 1
fi

echo ""
echo "🚀 Agora execute manualmente o container:"
echo "------------------------------------------------"
echo "docker run -it -v mydata:/data alpine ash"
echo "Dentro do container, digite:"
echo "  cd /data"
echo "  echo 'Hello from inside the container!' > myfile.txt"
echo "  exit"
echo "------------------------------------------------"
read -p "👉 Pressione [ENTER] após concluir manualmente essa etapa..."

# Parar e limpar containers antigos
docker stop $(docker ps -aq) >/dev/null 2>&1
docker rm $(docker ps -aq) >/dev/null 2>&1

# Rodar novamente e verificar persistência
echo ""
echo "♻️ Agora execute novamente o container e verifique:"
echo "------------------------------------------------"
echo "docker run -it -v mydata:/data alpine ash"
echo "Dentro do container, digite:"
echo "  cd /data"
echo "  ls -l"
echo "  cat myfile.txt"
echo "  exit"
echo "------------------------------------------------"
read -p "👉 Pressione [ENTER] após verificar o conteúdo persistido..."

# Auto-check: testar se o volume contém o arquivo
VOLUME_PATH=$(docker volume inspect mydata -f '{{ .Mountpoint }}')
if [ -f "$VOLUME_PATH/myfile.txt" ]; then
  echo "✅ Verificação OK: arquivo 'myfile.txt' existe dentro do volume!"
else
  echo "⚠️ Aviso: arquivo 'myfile.txt' não encontrado dentro do volume."
  echo "   Certifique-se de tê-lo criado dentro do container."
fi

# ------------------------------------------------------
# Task 3 - Bind Mounts
# ------------------------------------------------------
echo ""
echo "📂 [Task 3] Criando Bind Mount..."
mkdir -p ~/host_data
echo "Hello from the host!" > ~/host_data/hostfile.txt

echo "🚀 Execute manualmente o container:"
echo "------------------------------------------------"
echo "docker run -it -v ~/host_data:/data alpine ash"
echo "Dentro dele, digite:"
echo "  echo 'This line added from container' >> /data/hostfile.txt"
echo "  cat /data/hostfile.txt"
echo "  exit"
echo "------------------------------------------------"
read -p "👉 Pressione [ENTER] após concluir essa etapa..."

# Auto-check: verificar se o arquivo foi modificado
if grep -q "This line added from container" ~/host_data/hostfile.txt; then
  echo "✅ Verificação OK: alterações do container refletidas no host!"
else
  echo "⚠️ Falha: o arquivo não contém a linha esperada."
  echo "   Revise a etapa 3 e repita a modificação dentro do container."
fi

# ------------------------------------------------------
# Task 4 - Docker Compose Volumes
# ------------------------------------------------------
echo ""
echo "🧱 [Task 4] Criando Docker Compose com volume..."
mkdir -p ~/compose-lab && cd ~/compose-lab

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

docker-compose up -d >/dev/null 2>&1
sleep 5

echo "🌐 Testando acesso com curl..."
OUTPUT=$(curl -s http://localhost:8080)
if echo "$OUTPUT" | grep -q "Hello from Docker Compose"; then
  echo "✅ Verificação OK: conteúdo do site foi servido corretamente!"
else
  echo "⚠️ Falha: o conteúdo não corresponde ao esperado."
  echo "   Verifique se o container nginx está rodando corretamente."
fi

docker-compose down >/dev/null 2>&1

# ------------------------------------------------------
# Cleanup
# ------------------------------------------------------
echo ""
echo "🧹 Limpando recursos temporários..."
docker volume rm mydata >/dev/null 2>&1
rm -rf ~/host_data ~/compose-lab

echo ""
echo "===================================================="
echo " 🎯 Auto-Checker Finalizado com sucesso!"
echo " ✅ Se todas as etapas acima estiverem OK,"
echo "    o Qwiklabs deve marcar o lab como CONCLUÍDO."
echo "===================================================="
