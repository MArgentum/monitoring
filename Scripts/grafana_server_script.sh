#!/bin/bash

# Определение переменных
GRAFANA_VERSION="11.2.2" #11.2.2 - stable
NODE_EXPORTER_VERSION="1.8.2" #1.8.2 - stable
ALLOWED_NETWORK="10.130.0.0/24" #10.130.0.0/24 - default
MONITORING_DIR="$HOME/monitoring"

# Создание директории для мониторинга
mkdir -p $MONITORING_DIR

# Обновление репозиториев и установка зависимостей
sudo apt-get update && sudo apt-get install -y apt-transport-https software-properties-common wget libfontconfig1 musl adduser

# Скачивание и установка Grafana с проверкой целостности
cd $MONITORING_DIR
if [ ! -f grafana_${GRAFANA_VERSION}_amd64.deb ]; then
    wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb
    wget https://dl.grafana.com/oss/release/grafana_${GRAFANA_VERSION}_amd64.deb.sha256
    sha256sum -c grafana_${GRAFANA_VERSION}_amd64.deb.sha256
    if [ $? -ne 0 ]; then
        echo "Ошибка проверки контрольной суммы Grafana. Установка прервана."
        exit 1
    fi
fi

sudo dpkg -i grafana_${GRAFANA_VERSION}_amd64.deb
sudo apt install -f
rm -rf grafana_${GRAFANA_VERSION}_amd64.deb grafana_${GRAFANA_VERSION}_amd64.deb.sha256

# Настройка iptables
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 3000,9100 -s $ALLOWED_NETWORK -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 3000,9100 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 3000,9100 -j DROP

# Установка iptables-persistent для сохранения правил
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent

# Сохранение iptables правил
sudo netfilter-persistent save

# Скачивание и установка Node Exporter
cd $MONITORING_DIR
if [ ! -f node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz ]; then
    wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
fi

tar xvfz node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz
mv ./node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter $MONITORING_DIR/
rm -rf node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64 node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz

# Создание пользователя node_exporter, если не существует
if id "node_exporter" &>/dev/null; then
    echo "Пользователь node_exporter уже существует"
else
    sudo useradd -rs /bin/false node_exporter
fi

sudo chown -R node_exporter:node_exporter $MONITORING_DIR/node_exporter

# Создание службы для Node Exporter
sudo bash -c 'cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=$MONITORING_DIR/node_exporter

[Install]
WantedBy=multi-user.target
EOF'

# Запуск и включение служб Grafana и Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable --now grafana-server
sudo systemctl enable --now node_exporter
