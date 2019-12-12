#/bin/bash
clear
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'
IP=$(curl -s4 api.ipify.org)
PORT=3234
CONF_DIR=~/.grandmastercoin
COINKEY=MN

cd ~
mkdir -p $CONF_DIR
echo && echo && echo -e "${GREEN}"
echo " "
echo " "
echo "This script will install and configure your grandmastercoin masternode"
echo " "
echo " "
echo && echo && echo -e "${NC}"

echo "Do you want to install all needed dependencies (no if you did it before)? [y/n]"
read DOSETUP

if [[ $DOSETUP =~ "y" ]] ; then
  sudo apt-get update
  sudo apt-get -y upgrade
  sudo apt-get -y dist-upgrade
  sudo apt-get install -y nano htop git
  sudo apt-get install -y software-properties-common
  sudo apt-get install -y build-essential libtool autotools-dev pkg-config libssl-dev
  sudo apt-get install -y libboost-all-dev
  sudo apt-get install -y libevent-dev
  sudo apt-get install -y libminiupnpc-dev
  sudo apt-get install -y autoconf
  sudo apt-get install -y automake unzip
  sudo add-apt-repository  -y  ppa:bitcoin/bitcoin
  sudo apt-get update
  sudo apt-get install -y libdb4.8-dev libdb4.8++-dev

  cd /var
  sudo touch swap.img
  sudo chmod 600 swap.img
  sudo dd if=/dev/zero of=/var/swap.img bs=1024k count=2000
  sudo mkswap /var/swap.img
  sudo swapon /var/swap.img
  sudo free
  sudo echo "/var/swap.img none swap sw 0 0" >> /etc/fstab
  cd

  wget https://github.com/globalmovementclub/globalmovementclub/releases/download/v0.7.6.2/grandmastercoin-0.7.6.2-cli-linux.tar.gz
  tar -zxvf grandmastercoin-0.7.6.2-cli-linux*.tar.gz
  chmod 755 grandmastercoin*
  mv grandmastercoin* /usr/local/bin/

  sudo apt-get install -y ufw
  sudo ufw allow ssh/tcp
  sudo ufw limit ssh/tcp
  sudo ufw logging on
  sudo ufw allow $PORT/tcp
  echo "y" | sudo ufw enable
  sudo ufw status
fi

function create_key() {
  clear
  echo -e "Enter your ${GREEN}grandmastercoin masternode private key${NC}. Leave it blank to generate a new ${GREEN}masternode private key${NC} for you:"
  read -e COINKEY
  if [[ -z "$COINKEY" ]]; then
    echo -e "Configuring, please wait..."
    /usr/local/bin/grandmastercoind -daemon
    sleep 60
    if [ -z "$(ps axo cmd:100 | grep grandmastercoind)" ]; then
      echo -e "${GREEN}grandmastercoin server couldn not start. Check /var/log/syslog for errors.${$NC}"
      exit 1
    fi
    COINKEY=$(/usr/local/bin/grandmastercoin-cli masternode genkey)
    if [ "$?" -gt "0" ]; then
      echo -e "${GREEN}Wallet not fully loaded. Let us wait and try again to generate the private key${NC}"
      sleep 60
      COINKEY=$(/usr/local/bin/grandmastercoin-cli masternode genkey)
    fi
    /usr/local/bin/grandmastercoin-cli stop
    sleep 10
  fi
}  

function create_conf() {
  echo "rpcuser=U"`shuf -i 10000000-99999999 -n 1` >> grandmastercoin.conf_TEMP
  echo "rpcpassword=P"`shuf -i 10000000-99999999 -n 1` >> grandmastercoin.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> grandmastercoin.conf_TEMP
  echo "rpcport=41412" >> grandmastercoin.conf_TEMP
  echo "listen=1" >> grandmastercoin.conf_TEMP
  echo "server=1" >> grandmastercoin.conf_TEMP
  echo "daemon=1" >> grandmastercoin.conf_TEMP
  echo "logtimestamps=1" >> grandmastercoin.conf_TEMP
  echo "maxconnections=256" >> grandmastercoin.conf_TEMP
  echo "masternode=1" >> grandmastercoin.conf_TEMP
  echo "externalip=$IP:$PORT" >> grandmastercoin.conf_TEMP
  echo "port=$PORT" >> grandmastercoin.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> grandmastercoin.conf_TEMP
  echo "masternodeprivkey=$COINKEY" >> grandmastercoin.conf_TEMP
  mv grandmastercoin.conf_TEMP $CONF_DIR/grandmastercoin.conf
}

function create_tmp() {
  echo "rpcuser=tu"`shuf -i 100000-10000000 -n 1` >> grandmastercoin.conf_TEMP
  echo "rpcpassword=tp"`shuf -i 100000-10000000 -n 1` >> grandmastercoin.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> grandmastercoin.conf_TEMP
  echo "listen=1" >> grandmastercoin.conf_TEMP
  echo "server=1" >> grandmastercoin.conf_TEMP
  echo "daemon=1" >> grandmastercoin.conf_TEMP
  mv grandmastercoin.conf_TEMP $CONF_DIR/grandmastercoin.conf
  
  
}

create_tmp
create_key
create_conf
sleep 3
clear
/usr/local/bin/grandmastercoind -daemon -reindex
echo ""
echo -e " "
echo -e "grandmastercoin masternode is up and running listening on port ${GREEN}$PORT${NC}."
echo -e "Configuration file is: ${GREEN}grandmastercoin.conf${NC}"
echo -e "Start: ${GREEN}grandmastercoind${NC}"
echo -e "Stop: ${GREEN}grandmastercoin-cli stop${NC}"
echo -e "VPS_IP:PORT ${GREEN}$IP:$PORT${NC}"
echo -e "MASTERNODE PRIVATEKEY is: ${GREEN}$COINKEY${NC}"
echo -e "Please check ${GREEN}$COIN_NAME${NC} daemon is running with the following command: ${GREEN}grandmastercoin-cli getinfo${NC}"
echo -e "Use ${GREEN}grandmastercoin-cli masternode status${NC} to check your MN."
if [[ -n $SENTINEL_REPO  ]]; then
echo -e "${GREEN}Sentinel${NC} is installed in ${GREEN}/root/.grandmastercoin/sentinel${NC}"
echo -e "Sentinel logs is: ${GREEN}/root/.grandmastercoin/sentinel.log${NC}"
fi
echo -e " "
