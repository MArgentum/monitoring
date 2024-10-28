#!/bin/bash

# grafana

sudo apt-get update

sudo apt-get install -y apt-transport-https software-properties-common wget libfontconfig1 musl adduser

wget https://dl.grafana.com/oss/release/grafana_11.2.2_amd64.deb

sudo dpkg -i grafana_11.2.2_amd64.deb

sudo apt install -f


sudo rm -rf grafana_11.2.2_amd64.deb

sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

sudo iptables -A INPUT -p tcp -m multiport --dports 3000,9100 -s 10.130.0.0/24 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 3000,9100 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 3000,9100 -j DROP

sudo sudo DEBIAN_FRONTEND=noninteractive IPTABLES_PERSISTENT_SAVE=yes apt-get install -y iptables-persistent

sudo netfilter-persistent save


# node_exporter

wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
sudo tar xvfz node_exporter-1.8.2.linux-amd64.tar.gz
sudo mv ./node_exporter-1.8.2.linux-amd64/node_exporter /usr/bin/

sudo rm -rf node_exporter-1.8.2.linux-amd64 node_exporter-1.8.2.linux-amd64.tar.gz

sudo useradd -rs /bin/false node_exporter
sudo chown -R  node_exporter:node_exporter /usr/bin/node_exporter

sudo bash -c 'cat > /etc/systemd/system/node_exporter.service << EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
ExecStart=/usr/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF'


sudo systemctl daemon-reload
sudo systemctl enable grafana-server
sudo systemctl start grafana-server
sudo systemctl enable node_exporter
sudo systemctl start node_exporter