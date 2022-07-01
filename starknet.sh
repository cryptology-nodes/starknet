#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
  echo ''
else
  sudo apt install curl -y < "/dev/null"
fi
sleep 1 && curl -s https://raw.githubusercontent.com/cryptology-nodes/main/main/logo.sh |  bash && sleep 2
echo "==================================================="
sleep 2
sudo apt update -y && sudo apt install curl git tmux python3 python3-venv python3-dev build-essential libgmp-dev pkg-config libssl-dev -y
sudo curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env
rustup update stable --force
cd $HOME
rm -rf pathfinder
git clone -b v0.2.1-alpha https://github.com/eqlabs/pathfinder.git
cd pathfinder/py
python3 -m venv .venv
source .venv/bin/activate
PIP_REQUIRE_VIRTUALENV=true pip install --upgrade pip
PIP_REQUIRE_VIRTUALENV=true pip install -r requirements-dev.txt
pytest
cargo build --release --bin pathfinder
sleep 2
source $HOME/.bash_profile
mv ~/pathfinder/target/release/pathfinder /usr/local/bin/

echo "[Unit]
Description=StarkNet
After=network.target

[Service]
User=$USER
Type=simple
WorkingDirectory=$HOME/pathfinder/py
ExecStart=/bin/bash -c \"source $HOME/pathfinder/py/.venv/bin/activate && /usr/local/bin/pathfinder --http-rpc=\"0.0.0.0:9545\" --ethereum.url $ALCHEMY\"
Restart=on-failure
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target" > $HOME/starknetd.service
mv $HOME/starknetd.service /etc/systemd/system/
sudo systemctl restart systemd-journald
sudo systemctl daemon-reload
sudo systemctl enable starknetd
sudo systemctl restart starknetd
echo "==================================================="
echo -e '\n\e[42mПеревірити статус ноди:\e[0m\n' && sleep 1
if [[ `service starknetd status | grep active` =~ "running" ]]; then
  echo -e "Ваша StarkNet нода \e[32mустановлена и работает\e[39m!"
else
  echo -e "Ваша StarkNet нода \e[31mбыла установлена неправильно\e[39m, попробуйте переустановить ноду"
fi
