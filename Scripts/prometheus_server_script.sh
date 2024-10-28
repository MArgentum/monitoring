#!/bin/bash

# prometheus

sudo apt-get update
sudo apt-get install -y prometheus

sudo chown -R prometheus:prometheus /etc/prometheus/prometheus.yml /var/lib/prometheus /etc/prometheus

sudo bash -c 'cat > /etc/prometheus/prometheus.yml <<EOF
global:
  scrape_interval:     2s # Set the scrape interval to every 10 seconds. Default is every 1 minute.

alerting:
  alertmanagers:
    - static_configs:
      - targets: ["localhost:9093"]

rule_files:
  - /etc/alert-rules/alert.rules.yml

scrape_configs:
  - job_name:  "prometheus"
    static_configs:
      - targets: ["localhost:9090"]

  - job_name:  "local_node_exporter"
    static_configs:
      - targets:  ["localhost:9100"]  # если node_exporter установлен локально на той же машине

  - job_name:  "grafana_node_exporter"
    static_configs:
      - targets:  ["10.130.0.11:9100"]
EOF'



# хранить данные 5 дней

sudo bash -c 'cat > /etc/default/prometheus <<EOF
ARGS="--config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus --storage.tsdb.retention.time=5d --web.console.templates=/etc/prometheus/consoles --web.console.libraries=/etc/prometheus/console_libraries"
EOF'


sudo systemctl daemon-reload
sudo systemctl restart prometheus
sudo systemctl enable prometheus
sudo systemctl status prometheus

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
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
sudo systemctl status node_exporter





# alertmanager

wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
sudo tar xvfz alertmanager-0.27.0.linux-amd64.tar.gz
sudo rm -rf alertmanager-0.27.0.linux-amd64.tar.gz

sudo mkdir /etc/alertmanager
sudo mkdir -p /var/lib/alertmanager
sudo mkdir /etc/alert-rules/

sudo mv ./alertmanager-0.27.0.linux-amd64/alertmanager /usr/bin/


sudo bash -c "cat > /etc/alertmanager/alertmanager.yml << EOF
route:
  group_by: ['severity']
  group_wait: 1s
  group_interval: 1s
  repeat_interval: 10s
  receiver: 'telegram-alert-bot'

receivers:
  - name: 'telegram-alert-bot'
    telegram_configs:
      - send_resolved: true
        bot_token: "7613253333:AAH_mhsvqRiF_d_YeguNS5W-Vz8W4LbR3s4"
        chat_id: 896890026
        message: |
          [{{ .Status | toUpper }}] {{ .CommonAnnotations.summary }}
          Details:
          {{ range .Alerts }}
            - alertname: {{ .Labels.alertname }}
            - instance: {{ .Labels.instance }}
            - severity: {{ .Labels.severity }}
            - description: {{ .Annotations.description }}
          {{ end }}
EOF"


sudo bash -c 'cat > /etc/systemd/system/alertmanager.service << EOF
[Unit]
Description=Prometheus Alert-Manager
After=network.target

[Service]
User=alertmanager
Group=alertmanager
Type=simple
Restart=on-failure
ExecStart=/usr/bin/alertmanager --config.file=/etc/alertmanager/alertmanager.yml --storage.path=/var/lib/alertmanager

[Install]
WantedBy=multi-user.target
EOF'

sudo bash -c 'cat > /etc/alert-rules/alert.rules.yml << EOF
groups:

#- name: test.rules
#  rules:
#  - alert: TestAlert
#    expr: vector(1)  # Эта метрика всегда возвращает 1, так что алерт всегда будет срабатывать
#    for: 1s
#    labels:
#      severity: critical
#    annotations:
#      summary: "Test alert for Telegram integration"
#      description: "This is a test alert to verify the Telegram integration."

- name: alert.rules
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 10s
    labels:
      severity: critical
      instance: "{{ $labels.instance }}"
    annotations:
      summary: "Endpoint {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minute."

  - alert: HostHighCpuLoad
    expr: (1 - avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5s]))) * 100 > 75
    for: 0s
    labels:
      severity: warning
      alertname: HostHighCpuLoad
      instance: "{{ $labels.instance }}"
    annotations:
      summary: "Host high CPU load (instance {{ $labels.instance }})"
      description: "CPU load is > 75%\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"

  - alert: HostOutOfMemory
    expr: node_memory_MemAvailable / node_memory_MemTotal * 100 < 25
    for: 20s
    labels:
      severity: warning
      instance: "{{ $labels.instance }}"
    annotations:
      summary: "Host out of memory (instance {{ $labels.instance }})"
      description: "Node memory is filling up (< 25% left)\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"

  - alert: HostOutOfDiskSpace
    expr: (node_filesystem_avail{mountpoint="/"}  * 100) / node_filesystem_size{mountpoint="/"} < 50
    for: 0s
    labels:
      severity: warning
      instance: "{{ $labels.instance }}"
    annotations:
      summary: "Host out of disk space (instance {{ $labels.instance }})"
      description: "Disk is almost full (< 50% left)\n  VALUE = {{ $value }}\n  LABELS: {{ $labels }}"
EOF'

sudo useradd -rs /bin/false alertmanager

sudo chown -R alertmanager:alertmanager /usr/bin/alertmanager
sudo chown -R alertmanager:alertmanager /etc/alertmanager/alertmanager.yml
sudo chown -R alertmanager:alertmanager /var/lib/alertmanager
sudo chown -R prometheus:prometheus /etc/alert-rules


sudo systemctl daemon-reload
sudo systemctl enable alertmanager
sudo systemctl start alertmanager
sudo systemctl status alertmanager









# nginx

sudo systemctl disable apache2 && sudo systemctl stop apache2

sudo apt-get update && sudo apt-get install -y nginx

sudo rm -rf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

sudo bash -c 'cat > /etc/nginx/sites-available/devops-study.conf << EOF
server {
    listen 80;
    server_name prometheus-matvey.devops-study.ru;

    location / {
        proxy_pass http://localhost:9090;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        auth_basic "Restricted area";
        auth_basic_user_file /etc/nginx/auth.basic;
    }
}

server {
    listen 80;
    server_name alerts-matvey.devops-study.ru;

    location / {
        proxy_pass http://localhost:9093;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;

        auth_basic "Restricted area";
        auth_basic_user_file /etc/nginx/auth.basic;
    }
}

server {
    listen 80;
    server_name grafana-matvey.devops-study.ru;

    location / {
        proxy_pass http://10.130.0.11:3000;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF'


sudo apt install apache2-utils -y
sudo htpasswd -cb /etc/nginx/auth.basic admin 3785adm


sudo ln -s /etc/nginx/sites-available/devops-study.conf /etc/nginx/sites-enabled/


sudo systemctl reload nginx
sudo systemctl restart nginx



# SSL сертификаты

sudo apt update
sudo apt install snapd -y

sudo snap install --classic certbot

sudo ln -s /snap/bin/certbot /usr/bin/certbot

sudo certbot --nginx -m matvevait5686@gmail.com --agree-tos --no-eff-email -d prometheus-matvey.devops-study.ru,grafana-matvey.devops-study.ru,alerts-matvey.devops-study.ru --non-interactive

sudo certbot renew --dry-run
sudo systemctl reload nginx
