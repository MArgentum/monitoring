# Все конфигурационные файлы лежат в директории Configs

# Все скрипты лежат в директории Scripts

# Trees.txt - описание структуры дерева файлов на серверах




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

### Установить Grafana
- Подключиться к ВМ по ssh - `ssh matvey@84.252.134.54`
- Скачать, назначить права и выполнить скрипт
	- `wget https://raw.githubusercontent.com/matvey-k/monitoring/main/Scripts/grafana_server_script.sh`
	- `chmod +x grafana_server_script.sh`
	- `sudo bash grafana_server_script.sh`
	- 