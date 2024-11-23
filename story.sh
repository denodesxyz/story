#!/bin/bash

RED="\e[31m"
NOCOLOR="\e[0m"

install_node() {
local snap_type="$1"

cd $HOME

apt update
apt upgrade -y
apt install jq curl wget lz4 -y

if ! command -v go >/dev/null 2>&1; then
    wget https://go.dev/dl/go1.23.3.linux-amd64.tar.gz
    tar -C /usr/local -xzf go1.23.3.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.profile
    source $HOME/.profile
fi

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest

wget -O /usr/local/bin/story-geth https://github.com/piplabs/story-geth/releases/download/v0.10.1/geth-linux-amd64
wget -O /usr/local/bin/story https://github.com/piplabs/story/releases/download/v0.12.1/story-linux-amd64
chmod +x /usr/local/bin/story-geth
chmod +x /usr/local/bin/story

if [ ! $MONIKER ]; then
    read -p "Enter validator name: " MONIKER
fi

echo "export MONIKER=$MONIKER" >> $HOME/.bash_profile
source $HOME/.bash_profile

story init --network odyssey --moniker "$MONIKER"

sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.story/story/config/config.toml
sed -i -e "s/^indexer *=.*/indexer = \"null\"/" $HOME/.story/story/config/config.toml

echo "export DAEMON_NAME=story" >> $HOME/.bash_profile
echo "export DAEMON_HOME=$HOME/.story/story" >> $HOME/.bash_profile
echo "export DAEMON_RESTART_AFTER_UPGRADE=true" >> $HOME/.bash_profile
echo "export UNSAFE_SKIP_BACKUP=true" >> $HOME/.bash_profile
source $HOME/.bash_profile

cosmovisor init /usr/local/bin/story

sudo tee /etc/systemd/system/story-gethd.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=$USER
#WorkingDirectory=$HOME/.story
ExecStart=/usr/local/bin/story-geth --odyssey --syncmode full --metrics --metrics.addr=0.0.0.0 --metrics.port 6060
Restart=always
RestartSec=1
StartLimitInterval=0
LimitNOFILE=65536
LimitNPROC=65536

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/storyd.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/.story
Environment="DAEMON_NAME=story"
Environment="DAEMON_HOME=$HOME/.story/story"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="UNSAFE_SKIP_BACKUP=true"
ExecStart=$(which cosmovisor) run run
Restart=always
RestartSec=1
StartLimitInterval=0
LimitNOFILE=65536
LimitNPROC=65536

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable story-gethd storyd

if [[ "$snap_type" == "full" ]]; then
    SNAPSHOT_URL=$(curl -s https://story-odyssey-snap.denodes.xyz/snapshots_story.json | jq -c 'max_by(.height) | .url' | sed 's/"//g')
else
    SNAPSHOT_URL=$(curl -s https://story-odyssey-snap.denodes.xyz/snapshots_story_pruned.json | jq -c 'max_by(.height) | .url' | sed 's/"//g')
fi

cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/story/priv_validator_state.json.backup
rm -rf $HOME/.story/story/data
curl $SNAPSHOT_URL | lz4 -dc - | tar -xf - -C $HOME/.story/story
mv $HOME/.story/story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json
SNAPSHOT_URL=$(curl -s https://story-odyssey-snap.denodes.xyz/snapshots_geth.json | jq -c 'max_by(.height) | .url' | sed 's/"//g')
rm -rf $HOME/.story/geth/odyssey/geth/chaindata
mkdir -p $HOME/.story/geth/odyssey/geth
curl $SNAPSHOT_URL | lz4 -dc - | tar -xf - -C $HOME/.story/geth/odyssey/geth

systemctl start story-gethd storyd

ufw allow 30303/tcp
ufw allow 26656/tcp
}

while true
do

curl -s https://api.denodes.xyz/logo.sh | bash && sleep 1
echo ""
echo "Welcome to the Story One-Liner Script! 🛠

Our goal is to simplify the process of running a Story node.
With this script, you can effortlessly select additional options right from your terminal. 
"
echo ""

PS3=$'\nPlease select an option from the list provided: '

options=(
"Run a Full Node"
"Run a Pruned Node"
"Exit"
)
COLUMNS=1
select opt in "${options[@]}"
do
case $opt in

"Run a Full Node")
install_node "full"
exit
;;

"Run a Pruned Node")
install_node "pruned"
exit
;;

"Exit")
exit 8
;;

*) echo "invalid option $REPLY";;
esac
done
done
