#!/bin/bash

sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4
sudo apt install -y python3 python3-pip
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
docker version
sleep 2

VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version
sleep 1

sudo groupadd docker
sudo usermod -aG docker $USER

sudo rm -rf /usr/local/go
curl -L https://go.dev/dl/go1.22.4.linux-amd64.tar.gz | sudo tar -xzf - -C /usr/local
echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> $HOME/.bash_profile
echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> $HOME/.bash_profile
source ~/.bash_profile
go version
sleep 2

git clone https://github.com/allora-network/allora-chain.git
cd allora-chain && make all
allorad version

echo "You can use your keplr seed-phrase to recover your wallet or create a new one"
PS3='Would you like to create a new wallet (option 1) or recover an existing one (option 2)? '
wallet_options=("Create new wallet" "Recover existing wallet")
select wallet_opt in "${wallet_options[@]}"
do
    case $wallet_opt in
        "Create new wallet")
            WALLET_INFO=$(allorad keys add testkey)
            echo "Wallet created successfully. Here are the details:"
            echo "$WALLET_INFO"
            break
            ;;
        "Recover existing wallet")
            allorad keys add testkey --recover
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

echo "Get uAllo faucet: https://faucet.testnet-1.testnet.allora.network/"
read -p "After obtaining the faucet, enter 0 to continue: " continue_opt
if [ "$continue_opt" == "0" ]; then
    cd $HOME && git clone https://github.com/allora-network/basic-coin-prediction-node
    cd basic-coin-prediction-node

    mkdir workers
    mkdir workers/worker-1 workers/worker-2 head-data

    sudo chmod -R 777 workers/worker-1
    sudo chmod -R 777 workers/worker-2
    sudo chmod -R 777 head-data

    sudo docker run -it --entrypoint=bash -v ./head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
    sudo docker run -it --entrypoint=bash -v ./workers/worker-1:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
    sudo docker run -it --entrypoint=bash -v ./workers/worker-2:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"

    echo -e "\033[31mPlease copy the content below:\033[0m"
    cat head-data/keys/identity
    sleep 4
    read -p "Did you copy the content? (Y/N): " copied
    if [ "$copied" == "Y" ]; then
        rm -rf docker-compose.yml
        read -p "Enter WALLET_SEED_PHRASE: " WALLET_SEED_PHRASE
        read -p "Enter head-id: " head_id

        cat << EOF > docker-compose.yml
version: '3'

services:
  inference:
    container_name: inference
    build:
      context: .
    command: python -u /app/app.py
    ports:
      - "8000:8000"
    networks:
      eth-model-local:
        aliases:
          - inference
        ipv4_address: 172.22.0.4
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/inference/ETH"]
      interval: 10s
      timeout: 10s
      retries: 12
    volumes:
      - ./inference-data:/app/data
  
  updater:
    container_name: updater
    build: .
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
    command: >
      sh -c "
      while true; do
        python -u /app/update_app.py;
        sleep 24h;
      done
      "
    depends_on:
      inference:
        condition: service_healthy
    networks:
      eth-model-local:
        aliases:
          - updater
        ipv4_address: 172.22.0.5
  
  head:
    container_name: head
    image: alloranetwork/allora-inference-base-head:latest
    environment:
      - HOME=/data
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=head --peer-db=/data/peerdb --function-db=/data/function-db  \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9010 --rest-api=:6000 \
          --boot-nodes=/dns/head-0-p2p.testnet-1.testnet.allora.network/tcp/32130/p2p/12D3KooWLBhsSucVVcyVCaM9pvK8E7tWBM9L19s7XQHqqejyqgEC,/dns/head-1-p2p.testnet-1.testnet.allora.network/tcp/32131/p2p/12D3KooWEUNWg7YHeeCtH88ju63RBfY5hbdv9hpv84ffEZpbJszt,/dns/head-2-p2p.testnet-1.testnet.allora.network/tcp/32132/p2p/12D3KooWATfUSo95wtZseHbogpckuFeSvpL4yks6XtvrjVHcCCXk
    ports:
      - "6000:6000"
    volumes:
      - ./head-data:/data
    working_dir: /data
    networks:
      eth-model-local:
        aliases:
          - head
        ipv4_address: 172.22.0.100

  worker-1:
    container_name: worker-1
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9011 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-1-worker --allora-chain-worker-mode=worker \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network \
          --allora-chain-key-name=worker-1 \
          --allora-chain-topic-id=1
    volumes:
      - ./workers/worker-1:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker1
        ipv4_address: 172.22.0.12

  worker-2:
    container_name: worker-2
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9013 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-2-worker --allora-chain-worker-mode=worker \
          --allora-chain-restore-mnemonic='$WALLET_SEED_PHRASE' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network \
          --allora-chain-key-name=worker-2 \
          --allora-chain-topic-id=2
    volumes:
      - ./workers/worker-2:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker1
        ipv4_address: 172.22.0.13
  
networks:
  eth-model-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/24

volumes:
  inference-data:
  workers:
  head-data:
EOF

        docker compose up -d --build

        cd $HOME && cd basic-coin-prediction-node

        echo "You must have Success: register node Tx Hash in workers 1 & 2 logs Success: register node Tx Hash:=82BF67E2E1247B226B8C5CFCF3E4F41076909ADABF3852C468D087D94BD9FC3B"
        echo "If the above condition is met, congratulations, both your workers are functioning correctly."

        # Check Worker node:
        # Check topic 1:
        network_height=$(curl -s -X 'GET' 'https://allora-rpc.testnet-1.testnet.allora.network/abci_info?' -H 'accept: application/json' | jq -r .result.response.last_block_height) && \
        curl --location 'http://localhost:6000/api/v1/functions/execute' --header 'Content-Type: application/json' --data '{
            "function_id": "bafybeigpiwl3o73zvvl6dxdqu7zqcub5mhg65jiky2xqb4rdhfmikswzqm",
            "method": "allora-inference-function.wasm",
            "parameters": null,
            "topic": "allora-topic-1-worker",
            "config": {
                "env_vars": [
                    {
                        "name": "BLS_REQUEST_PATH",
                        "value": "/api"
                    },
                    {
                        "name": "ALLORA_ARG_PARAMS",
                        "value": "ETH"
                    },
                    {
                        "name": "ALLORA_BLOCK_HEIGHT_CURRENT",
                        "value": "'"${network_height}"'"
                    }
                ],
                "number_of_nodes": -1,
                "timeout": 2
            }
        }' | jq

        # Check topic 2:
        network_height=$(curl -s -X 'GET' 'https://allora-rpc.testnet-1.testnet.allora.network/abci_info?' -H 'accept: application/json' | jq -r .result.response.last_block_height) && \
        curl --location 'http://localhost:6000/api/v1/functions/execute' --header 'Content-Type: application/json' --data '{
            "function_id": "bafybeigpiwl3o73zvvl6dxdqu7zqcub5mhg65jiky2xqb4rdhfmikswzqm",
            "method": "allora-inference-function.wasm",
            "parameters": null,
            "topic": "allora-topic-2-worker",
            "config": {
                "env_vars": [
                    {
                        "name": "BLS_REQUEST_PATH",
                        "value": "/api"
                    },
                    {
                        "name": "ALLORA_ARG_PARAMS",
                        "value": "ETH"
                    },
                    {
                        "name": "ALLORA_BLOCK_HEIGHT_CURRENT",
                        "value": "'"${network_height}"'"
                    }
                ],
                "number_of_nodes": -1,
                "timeout": 2
            }
        }' | jq

        echo "Response: you will get code: 200 if everything is fine"
        echo "All tasks completed successfully. Join the Telegram channel: https://t.me/xOneiros"
    fi
fi
