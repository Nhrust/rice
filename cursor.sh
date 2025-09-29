#!/bin/bash
timeout=3

# Функция: запустить evtest для устройства
start_evtest() {
    dev=$1
    if [[ -c "$dev" ]]; then
        evtest --grab "$dev" | while read -r line; do
            if [[ $line == *"EV_REL"* || $line == *"EV_KEY"* ]]; then
                hyprctl keyword cursor:inactive_timeout $timeout
            fi
        done &
        echo $!  # выводим PID
    fi
}

# Запустить на всех существующих мышах/тачпадах
for dev in $(libinput list-devices | awk '/Kernel:/{d=$2} /Capabilities:/{if($2~/pointer|touch/)print d}'); do
    start_evtest "$dev"
done

# Слушать udev и добавлять новые устройства при подключении
udevadm monitor --udev --subsystem-match=input | while read -r line; do
    if [[ "$line" =~ add.*event ]]; then
        newdev=$(echo "$line" | grep -o 'event[0-9]\+')
        [[ -n "$newdev" ]] && start_evtest "/dev/input/$newdev"
    fi
done
