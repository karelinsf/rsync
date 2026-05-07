#!/bin/bash

SOURCE_DIR=$HOME/
REMOTE_HOST="vagrant@192.168.26.10"
REMOTE_DIR="/tmp/backup"
BACKUP_PREFIX="netology"
MAX_BACKUPS=5

# Проверяем создана ли директория на удаленном сервере в которую будут записаны бэкапы, если нет, то создаем
ssh "$REMOTE_HOST" "test -d $REMOTE_DIR/ || mkdir -p $REMOTE_DIR "

# Функция для создания инкрементного бэкапа.
# В rsync указываем в качестве референсной директории - предыдущий бэкап на удаленном сервере.
# Создаём очередной бэкап c датой и временем в имени, Проверяем были ли созданы бэкапы до этого.
# Если папка пустая, то создаём первый (без опции -link-dest)
create_backup() {
  new_backup_name="${BACKUP_PREFIX}_$(date +%Y-%m-%d_%H:%M:%S)"
  if ssh "$REMOTE_HOST" "ls -d $REMOTE_DIR/${BACKUP_PREFIX}*" >/dev/null 2>&1 ; then 
      latest_backup=$(ssh "$REMOTE_HOST" "ls $REMOTE_DIR/ | grep $BACKUP_PREFIX | tail -1")
      rsync -a --link-dest="$REMOTE_DIR/$latest_backup" --delete  "$SOURCE_DIR/" "$REMOTE_HOST:$REMOTE_DIR/$new_backup_name"
  else
      rsync -a --delete  "$SOURCE_DIR/" "$REMOTE_HOST:$REMOTE_DIR/$new_backup_name"
  fi
}

# Функция для удаления самого старого бэкапа при количестве бэкапов более MAX_BACKUPS
delete_oldest_backup() {
  oldest_backup=$(ssh "$REMOTE_HOST" "ls -r $REMOTE_DIR/ | grep $BACKUP_PREFIX | tail -1")
  ssh "$REMOTE_HOST" "rm -rf $REMOTE_DIR/$oldest_backup"
}
if [[ "$1" == "-run" ]]; then
    # Подсчитываем количество бэкапов, если их больше MAX_BACKUPS, то удаляем самый старый бэкап и пишем следующий
    num_backups=$(ssh "$REMOTE_HOST" "find $REMOTE_DIR -mindepth 1 -maxdepth 1 -name '$BACKUP_PREFIX*' -type d | grep -v '^$' | wc -l")
    if [ "$num_backups" -ge "$MAX_BACKUPS" ]; then
        delete_oldest_backup
        num_backups=$(( num_backups - 1 ))
        echo "Удалён старый бэкап $oldest_backup"
    fi
    create_backup
    num_backups=$(( num_backups + 1 ))
    echo "Создан очередной бэкап $new_backup_name. Общее количество бэкапов - $num_backups"

elif [[ "$1" == "-list" ]]; then
    backups_list=$(ssh "$REMOTE_HOST" "ls $REMOTE_DIR/ | grep $BACKUP_PREFIX ")
    echo "Доступные бэкапы:"
    echo "$backups_list" | awk '{print NR,$0}'
    echo "Выберите бэкап для восстановления:"
    read -p "Введите номер бэкапа для восстановления (0 для выхода): " selected_number
    if [[ ! "$selected_number" =~ ^[0-9]+$ || -z "$selected_number" ||  "$selected_number" -lt 0  ||  "$selected_number" -gt  "$MAX_BACKUPS" ]]; then
        echo "Некорректное значение"
        exit 1
    elif [[ "$selected_number" -eq 0 ]]; then
        echo "Выход"
        exit 0
    fi
    selected_backup=$(echo "$backups_list" | awk -v num="$selected_number" 'NR==num {print}')
    echo "Вы выбрали бэкап: $selected_backup"
    read -p "Наберите yes для подтверждения: " user_verify
    if [[ "$user_verify" == "yes" || "$user_verify" == "YES" ]]; then
        echo "Начато восстановления бэкапа"
        rsync -a --delete "$REMOTE_HOST:$REMOTE_DIR/$selected_backup/" "$SOURCE_DIR"
    else
        echo "Выход"
        exit 0
    fi
else
    echo "Укажите оацию -list или -run"
    exit 1
fi