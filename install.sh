#!/bin/bash

# Install Packages
sudo apt update && sudo apt upgrade -y

sudo apt install ca-certificates zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev curl git wget make jq build-essential pkg-config lsb-release libssl-dev libreadline-dev libffi-dev gcc screen unzip lz4 -y

# Install Python3
sudo apt install python3 -y
python3 --version

sudo apt install python3-pip -y
pip3 --version

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io -y
docker --version

# Install Docker-Compose
VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)

sudo curl -L "https://github.com/docker/compose/releases/download/$VER/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# Docker permission to the user
sudo groupadd docker
sudo usermod -aG docker $USER

# Clone the repository
git clone https://github.com/DanielOneSinger/basic-coin-prediction-node.git
cd basic-coin-prediction-node || exit


# Prompt for wallet name and seed phrase
read -p "Enter your wallet name: " wallet_name
read -p "Enter your seed phrase: " seed_phrase

# Update config.json with wallet name and seed phrase
jq --arg wallet "$wallet_name" --arg seed "$seed_phrase" \
'.wallet.addressKeyName = $wallet | .wallet.addressRestoreMnemonic = $seed' config.json > config.tmp.json && mv config.tmp.json config.json

# Make init.config executable and run it
chmod +x init.config
./init.config

# Start Docker containers and build
docker compose up --build -d

echo "开始重启worker容器，确保可以加入topic"
for i in {1..3}
do
    echo "执行第 $i 次重启"
    docker restart worker    
    sleep 5
done

# Output completion message
echo "Your worker node have been started. To check logs, run:"
echo "docker logs -f worker"
