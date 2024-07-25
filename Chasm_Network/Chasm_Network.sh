#!/bin/bash

echo "Get Groq API Key : https://console.groq.com/keys"
echo "Get Openrouter API key : https://openrouter.ai/settings/keys"
read -p "Press Enter to continue..."

sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

cd ~
touch .env

read -p "Enter SCOUT_NAME: " SCOUT_NAME
read -p "Enter SCOUT_UID: " SCOUT_UID
read -p "Enter WEBHOOK_API_KEY: " WEBHOOK_API_KEY
echo -e "\033[32mEnter WEBHOOK_URL (e.g., http://x.x.x.x:3001/): \033[0m"
read -p "" WEBHOOK_URL
read -p "Enter GROQ_API_KEY: " GROQ_API_KEY
read -p "Enter OPENROUTER_API_KEY: " OPENROUTER_API_KEY
read -p "Enter OPENAI_API_KEY (optional): " OPENAI_API_KEY

cat << EOF > .env
PORT=3001
LOGGER_LEVEL=debug

ORCHESTRATOR_URL=https://orchestrator.chasm.net
SCOUT_NAME=$SCOUT_NAME
SCOUT_UID=$SCOUT_UID
WEBHOOK_API_KEY=$WEBHOOK_API_KEY
WEBHOOK_URL=$WEBHOOK_URL

PROVIDERS=groq,openrouter
MODEL=gemma2-9b-it
GROQ_API_KEY=$GROQ_API_KEY
OPENROUTER_API_KEY=$OPENROUTER_API_KEY
OPENAI_API_KEY=$OPENAI_API_KEY

NODE_ENV=production
EOF

echo -e "\033[34mFile .env created successfully.\033[0m"
sleep 2

sudo ufw allow 3001
docker pull johnsonchasm/chasm-scout
docker run -d --restart=always --env-file ./.env -p 3001:3001 --name scout johnsonchasm/chasm-scout

if curl -s localhost:3001 | grep -q "OK"; then
    echo -e "\033[33mOperation completed successfully.\033[0m"
fi
sleep 2

source ./.env
curl -X POST \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer $WEBHOOK_API_KEY" \
     -d '{"body":"{\"model\":\"gemma-7b-it\",\"messages\":[{\"role\":\"system\",\"content\":\"You are a helpful assistant.\"}]}"}' \
     $WEBHOOK_URL

docker logs scout
sleep 4

echo "Node successfully started."
