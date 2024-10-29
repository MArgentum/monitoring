# Monitoring

### Структура проекта
- Configs - конфигурационные файлы
- Scripts - скрипты
  - prometheus скрипты нерабочие
  - grafana скрипт рабочие
- Trees.txt - описание структуры дерева файлов на серверах
- README.md - этот файл
- monitoring_promserv_1.0.0.deb - пакет для установки на сервер Prometheus



### Далее - инструкции...




# Инструкция по настройке Grafana-server

### Создать ВМ
- Создать вм с настройками:
- Дистрибутив - Debian 12
- Зона доступности - ru-central1-d
- hdd - 10гб
- Вычислительные ресурсы
	- Гарантированная доля vCPU - 20%
	- Дополнительно - Прерываемая
- Сетевые настройки
	- Подсеть - default / default-ru-central1-d
	- Публичный адрес - Список
		- IP-адрес - 84.252.134.54
	- Внутренний IPv4-адрес - Вручную
		- Ввести - 10.130.0.11
- Доступ
	- SSH-ключ
		- Логин - matvey
		- SSH-ключ - matvey
- Имя - grafana-server

### Установить и настроить Grafana
1. Подключиться к ВМ по ssh - `ssh matvey@84.252.134.54`
2. Скачать, назначить права и выполнить скрипт:
   1. `wget https://raw.githubusercontent.com/matvey-k/monitoring/main/Scripts/grafana_server_script.sh`
   2. `chmod +x grafana_server_script.sh`
   3. `sudo bash grafana_server_script.sh`
3. Проверить, что Grafana доступен по адресу http://<публичный-IP-адрес-grafana-сервера>:3000
4. Войти в Grafana с помощью логина и пароля - admin / admin
5. В Cennections подключить Prometheus с адреса http://<локальный-IP-адрес-prometheus-сервера>:9090
6. Добавить Dashboard с ID - 1860


# Инструкция по настройке Prometheus-server



1. `sudo apt-get update && sudo apt-get install -y wget nginx prometheus && sudo apt-get --fix-broken install -y`
2. Скачать пакет: `wget https://raw.githubusercontent.com/matvey-k/monitoring/monitoring_promserv_1.0.0.deb`
3. Установить пакет: `sudo dpkg -i monitoring_promserv_1.0.0.deb`
3. Перезагрузить сервер: `sudo reboot`

# Проверить ip во всех конфигах