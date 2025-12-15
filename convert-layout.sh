#!/usr/bin/env bash
# =============================================================
# Скрипт для конвертации раскладки выделенного текста в Ubuntu 24 + Wayland
# Использование:
#   - Настроить горячую клавишу в системе для запуска у меня win+space:
#       /путь/до/скрипта/convert-layout.sh cl
#   - Выделить текст
#   - Нажать сочетание клавиш для запуска скрипта
#   - Текст конвертируется и вставляется обратно
#   - Смена раскладки выполняется автоматически
# =============================================================

USERNAME="md"          # Имя пользователя для прав на сокет ydotool
KEY_CHG="ctrl+shift"   # Горячие клавиши для смены раскладки через ydotool

# -------------------------------------------------------------
# Функция cl - конвертация выделенного текста
# -------------------------------------------------------------
cl() {
    # Сохраняем текущий буфер обмена
    TMP=$(wl-paste)

    # Берём текст из PRIMARY буфера (выделенный текст)
    TEXT=$(wl-paste --primary)
    [ -z "$TEXT" ] && exit 0

    # Конвертация раскладки с помощью sed
    RESULT=$(echo "$TEXT" | sed "y/abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ[]{};':\",.\/<>?@#\$^&\`~фисвуапршолдьтщзйкыегмцчняФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯхъХЪжэЖЭбюБЮ№ёЁ/фисвуапршолдьтщзйкыегмцчняФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯхъХЪжэЖЭбю.БЮ,\"№;:?ёЁabcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ[]{};':\",.<>#\`~/")

    # Кладём результат в буфер обмена
    echo -n "$RESULT" | wl-copy

    # Вставляем обратно через ydotool Ctrl+V
    ydotool key ctrl+v
    sleep 0.05

    # Переключаем раскладку
    ydotool key $KEY_CHG

    # Восстанавливаем исходный буфер обмена
    echo -n "$TMP" | wl-copy
}

# -------------------------------------------------------------
# Функция i - установка зависимостей и демона ydotool
# -------------------------------------------------------------
i() {
    # Установка необходимых пакетов
    sudo apt install -y wl-clipboard wtype ydotool ydotoold

    # Создание systemd unit для ydotoold
    sudo bash -c "cat <<EOF > /etc/systemd/system/ydotoold.service
[Unit]
Description=ydotool daemon for simulating keyboard/mouse input
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/ydotoold
ExecStartPost=/bin/chown $USERNAME /tmp/.ydotool_socket
Restart=on-failure
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF"

    # Перезагрузка systemd и запуск демона
    sudo systemctl daemon-reload
    sudo systemctl enable --now ydotoold
    sudo systemctl start ydotoold.service
}

# -------------------------------------------------------------
# Основной блок: вызов функции по аргументу
# -------------------------------------------------------------
if [ -z "$1" ]; then
    echo "Использование:"
    echo "  $0 cl - конвертация выделенного текста"
    echo "  $0 i  - установка зависимостей и демона"
    exit 1
fi

fn="$1"
shift

# Проверяем, существует ли функция
if declare -f "$fn" > /dev/null; then
    "$fn" "$@"
else
    echo "Функция '$fn' не найдена"
    exit 1
fi