#!/bin/bash

# Проверка наличия аргумента (доменного имени)
if [ "$#" -ne 1 ]; then
    echo "Использование: $0 <доменное имя>"
    exit 1
fi

DOMAIN=$1

echo "Настройка для домена: $DOMAIN"

# Создание директории для Xray
mkdir -p /etc/xray

# Установка Certbot и плагина для Nginx
apt -y install certbot python3-certbot-nginx

# Остановка и отключение Nginx
systemctl stop nginx && systemctl disable nginx

# Получение сертификатов Let's Encrypt с автоматическим указанием почты и согласия
certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email info@quantech.live --no-eff-email

# Копирование сертификатов в директорию Xray
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/xray/cert.crt
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/xray/privkey.key

# Установка Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install

# Удаление стандартного конфигурационного файла Xray
cd /usr/local/etc/xray && rm -f config.json

# Загрузка конфигурационного файла Xray
curl -o config.json https://raw.githubusercontent.com/ivanstepachev/config/main/config.json

# Настройка прав доступа к сертификатам
chmod 644 /etc/xray/cert.crt
chmod 644 /etc/xray/privkey.key

# Создавние файлов логгирования
mkdir -p /var/log/Xray/ && touch /var/log/Xray/access.log && touch /var/log/Xray/error.log

# Создание доступа для Xray к файлам логгирования
chown -R nobody:nogroup /var/log/Xray/

# Настройка прав доступа файлам логгирования для записи
chmod 0664 /var/log/Xray/access.log && chmod 0664 /var/log/Xray/error.log

# Удаление стандартного конфигурационного файла sysctl
cd /etc && rm -f sysctl.conf

# Скачивание оптимизированного конфига сетевых настроек
curl -o /etc/sysctl.conf https://raw.githubusercontent.com/ivanstepachev/config/main/sysctl.conf

# Внесение изменений в настройки
sysctl -p

# Включение и запуск Xray
systemctl enable xray && systemctl start xray

# Первое выключение
systemctl stop xray

# Повторное включение
systemctl start xray

echo "Настройка Xray завершена для домена: $DOMAIN"
