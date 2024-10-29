#!/bin/bash

# Файлы которые нужно создать:
# /etc/prometheus/prometheus.yml
# /etc/default/prometheus
# /etc/systemd/system/node_exporter.service
# /etc/alertmanager/alertmanager.yml
# /etc/systemd/system/alertmanager.service
# /etc/alert-rules/alert.rules.yml
# /etc/nginx/sites-available/devops-study.conf

# prometheus

sudo apt-get update
sudo apt-get install -y prometheus

sudo chown -R prometheus:prometheus /etc/prometheus/prometheus.yml /var/lib/prometheus /etc/prometheus

# iptables

sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

sudo iptables -A INPUT -p tcp -m multiport --dports 9090,9093,9100 -s 10.130.0.0/24 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 9090,9093,9100 -s 127.0.0.1 -j ACCEPT
sudo iptables -A INPUT -p tcp -m multiport --dports 9090,9093,9100 -j DROP

sudo apt-get install -y iptables-persistent
sudo netfilter-persistent save

# node_exporter

wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
sudo tar xvfz node_exporter-1.8.2.linux-amd64.tar.gz
sudo mv ./node_exporter-1.8.2.linux-amd64/node_exporter /usr/bin/

sudo rm -rf node_exporter-1.8.2.linux-amd64 node_exporter-1.8.2.linux-amd64.tar.gz

sudo useradd -rs /bin/false node_exporter
sudo chown -R  node_exporter:node_exporter /usr/bin/node_exporter

# alertmanager

wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
sudo tar xvfz alertmanager-0.27.0.linux-amd64.tar.gz
sudo rm -rf alertmanager-0.27.0.linux-amd64.tar.gz

sudo mkdir /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager
sudo mkdir /etc/alert-rules/

sudo mv ./alertmanager-0.27.0.linux-amd64/alertmanager /usr/bin/

sudo useradd -rs /bin/false alertmanager

sudo chown -R alertmanager:alertmanager /usr/bin/alertmanager
sudo chown -R alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager
sudo chown -R prometheus:prometheus /etc/alert-rules

# nginx

sudo systemctl disable apache2 && sudo systemctl stop apache2

sudo apt-get update && sudo apt-get install -y nginx

sudo rm -rf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

sudo apt install apache2-utils -y
sudo htpasswd -cb /etc/nginx/auth.basic admin 3785adm

sudo ln -s /etc/nginx/sites-available/devops-study.conf /etc/nginx/sites-enabled/

# SSL сертификаты

sudo apt update
sudo apt install snapd -y

sudo snap install --classic certbot

sudo ln -s /snap/bin/certbot /usr/bin/certbot

sudo certbot --nginx -m matvevait5686@gmail.com --agree-tos --no-eff-email -d prometheus-matvey.devops-study.ru,grafana-matvey.devops-study.ru,alerts-matvey.devops-study.ru --non-interactive

sudo certbot renew --dry-run

# Выполнение всех команд systemctl в конце
sudo systemctl daemon-reload

sudo systemctl enable prometheus
sudo systemctl restart prometheus

sudo systemctl enable nginx
sudo systemctl restart nginx

sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl restart node_exporter

sudo systemctl enable alertmanager
sudo systemctl start alertmanager
sudo systemctl restart alertmanager
