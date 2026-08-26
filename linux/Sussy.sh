#!/usr/bin/env bash

set -u

SCRIPT_PATH="$(readlink -f "$0")"

EXTENSION="sls"
MIME_TYPE="application/x-sls-archive"
DESKTOP_ID="sussy-sls.desktop"

LOCAL_SHARE="${XDG_DATA_HOME:-$HOME/.local/share}"
MIME_APPS_DIR="$LOCAL_SHARE/applications"
MIME_PACKAGES_DIR="$LOCAL_SHARE/mime/packages"

DESKTOP_FILE="$MIME_APPS_DIR/$DESKTOP_ID"
MIME_XML="$MIME_PACKAGES_DIR/sussy-sls.xml"

mkdir -p "$MIME_APPS_DIR"
mkdir -p "$MIME_PACKAGES_DIR"


pause() {
    echo
    read -r -p "Нажмите Enter для продолжения"
}


select_folder() {
    local result=""

    if command -v zenity >/dev/null 2>&1; then
        result="$(zenity \
            --file-selection \
            --directory \
            --title="Выберите папку" \
            2>/dev/null || true)"
    else
        echo
        read -r -p "Введите путь к папке: " result
    fi

    if [[ -n "$result" ]]; then
        printf '%s\n' "$result"
    fi
}


select_sls_file() {
    local result=""

    if command -v zenity >/dev/null 2>&1; then
        result="$(zenity \
            --file-selection \
            --title="Выберите SLS-архив" \
            --file-filter="SLS архив (*.sls) | *.sls" \
            --file-filter="Все файлы | *" \
            2>/dev/null || true)"
    else
        echo
        read -r -p "Введите путь к SLS-файлу: " result
    fi

    if [[ -n "$result" ]]; then
        printf '%s\n' "$result"
    fi
}


show_header() {
    clear

    echo "===================================="
    echo "             SLS ARCHIVIZER"
    echo "===================================="
    echo
}

archive_folder() {

    echo "Если вы не видите меню выбора папки,"
    echo "проверьте, не находится ли окно выбора позади других окон."
    echo

    local source_folder
    source_folder="$(select_folder)"

    if [[ -z "$source_folder" ]]; then
        echo
        echo "Папка не выбрана."
        return
    fi

    if [[ ! -d "$source_folder" ]]; then
        echo
        echo "Ошибка: папка не существует."
        return
    fi

    source_folder="$(cd "$source_folder" && pwd -P)"

    local parent_folder
    local folder_name
    local sls_file

    parent_folder="$(dirname "$source_folder")"
    folder_name="$(basename "$source_folder")"

    sls_file="$parent_folder/$folder_name.sls"

    if [[ -e "$sls_file" ]]; then
        rm -f -- "$sls_file"
    fi

    echo
    echo "===================================="
    echo "             АРХИВАЦИЯ"
    echo "===================================="
    echo

    echo "Источник:"
    echo -e "\033[33m$source_folder\033[0m"
    echo

    if ! command -v zip >/dev/null 2>&1; then
        echo "Ошибка: программа zip не установлена."
        echo
        echo "Установите её:"
        echo "  Debian/Ubuntu: sudo apt install zip"
        echo "  Fedora:        sudo dnf install zip"
        echo "  Arch:          sudo pacman -S zip"
        return
    fi

    echo "Подготовка..."

    
    
    cd "$parent_folder" || {
        echo "Не удалось перейти в родительскую папку."
        return
    }

    local files
    files="$(find "$folder_name" -type f -print0 2>/dev/null | tr '\0' '\n')"

    local total_files
    total_files="$(printf '%s\n' "$files" | grep -c . || true)"

    echo "Файлов: $total_files"
    echo

    if [[ "$total_files" -eq 0 ]]; then

        if ! zip -q -r -- "$sls_file" "$folder_name" >/dev/null 2>&1; then
            echo "Ошибка создания архива."
            rm -f -- "$sls_file"
            return
        fi

        echo
        echo -e "\033[32mГотово!\033[0m"
        echo
        echo "SLS-архив:"
        echo -e "\033[32m$sls_file\033[0m"

        return
    fi

    
    
    local current=0

    rm -f -- "$sls_file"

    if ! zip -q -r \
        -- "$sls_file" "$folder_name" >/dev/null 2>&1; then

        echo
        echo -e "\033[31mОшибка при архивации.\033[0m"
        rm -f -- "$sls_file"
        return
    fi

    
    
    current="$total_files"

    printf '\rАрхивация: 100%%\n'

    echo
    echo -e "\033[32mГотово!\033[0m"
    echo
    echo "SLS-архив:"
    echo -e "\033[32m$sls_file\033[0m"
}

safe_extract_path() {

    local destination="$1"
    local archive_path="$2"

    
    archive_path="${archive_path

    
    if [[ "$archive_path" == ".." ||
          "$archive_path" == ../* ||
          "$archive_path" == */../* ||
          "$archive_path" == */.. ]]; then

        return 1
    fi

    local full_path
    full_path="$(realpath -m -- "$destination/$archive_path")"

    local full_destination
    full_destination="$(realpath -m -- "$destination")"

    case "$full_path" in
        "$full_destination"/*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

extract_sls() {

    local input_file="${1:-}"

    if [[ -n "$input_file" ]]; then

        local sls_file="$input_file"

        if [[ ! -f "$sls_file" ]]; then
            echo
            echo -e "\033[31mФайл не найден:\033[0m"
            echo "$sls_file"
            return
        fi

    else

        local sls_file
        sls_file="$(select_sls_file)"

        if [[ -z "$sls_file" ]]; then
            echo
            echo "Файл не выбран."
            return
        fi

        if [[ ! -f "$sls_file" ]]; then
            echo
            echo "Файл не найден."
            return
        fi
    fi

    local destination_folder
    destination_folder="$(select_folder)"

    if [[ -z "$destination_folder" ]]; then
        echo
        echo "Папка назначения не выбрана."
        return
    fi

    if [[ ! -d "$destination_folder" ]]; then
        echo
        echo "Ошибка: папка назначения не существует."
        return
    fi

    destination_folder="$(cd "$destination_folder" && pwd -P)"
    sls_file="$(readlink -f "$sls_file")"

    echo
    echo "===================================="
    echo "            РАСПАКОВКА"
    echo "===================================="
    echo

    echo "Архив:"
    echo -e "\033[33m$sls_file\033[0m"
    echo

    echo "Назначение:"
    echo -e "\033[33m$destination_folder\033[0m"
    echo

    if ! command -v unzip >/dev/null 2>&1; then
        echo "Ошибка: программа unzip не установлена."
        echo
        echo "Установите её:"
        echo "  Debian/Ubuntu: sudo apt install unzip"
        echo "  Fedora:        sudo dnf install unzip"
        echo "  Arch:          sudo pacman -S unzip"
        return
    fi

    
    local bad_path=""
    local entry

    while IFS= read -r entry; do

        [[ -z "$entry" ]] && continue

        
        if ! safe_extract_path "$destination_folder" "$entry"; then
            bad_path="$entry"
            break
        fi

    done < <(unzip -Z1 -- "$sls_file" 2>/dev/null)

    if [[ -n "$bad_path" ]]; then
        echo
        echo -e "\033[31mОшибка безопасности!\033[0m"
        echo
        echo "Обнаружен недопустимый путь в архиве:"
        echo -e "\033[31m$bad_path\033[0m"
        return
    fi

    echo "Проверка архива пройдена."
    echo
    echo "Распаковка..."

    if ! unzip -o \
        -- "$sls_file" \
        -d "$destination_folder"; then

        echo
        echo -e "\033[31mОшибка при распаковке.\033[0m"
        return
    fi

    echo
    echo -e "\033[32mГотово!\033[0m"
    echo
    echo "Файлы распакованы в:"
    echo -e "\033[32m$destination_folder\033[0m"
}

test_sls_association() {

    if [[ -f "$DESKTOP_FILE" ]] &&
       grep -q '^MimeType=.*x-sls-archive' "$DESKTOP_FILE" 2>/dev/null; then

        return 0
    fi

    return 1
}


register_association() {

    local is_associated=1

    if test_sls_association; then
        is_associated=0
    fi

    echo
    echo "===================================="
    echo "          SLS ASSOCIATION"
    echo "===================================="
    echo

    echo -e "\033[33mОТКАЗ ОТ ОТВЕТСТВЕННОСТИ\033[0m"
    echo

    echo -e "\033[33mТЕХНИКА БЕЗОПАСНОСТИ:\033[0m"
    echo

    echo -e "\033[31mНе перемещайте этот скрипт после создания ассоциации.\033[0m"
    echo
    echo "Если нужно переместить файл,"
    echo "сначала удалите ассоциацию."
    echo
    echo -e "\033[33mПосле перемещения старое правило может перестать работать.\033[0m"
    echo

    if [[ "$is_associated" -eq 0 ]]; then

        echo -n "Ассоциация: "
        echo -e "\033[32mВКЛЮЧЕНА\033[0m"
        echo

        read -r -p "Убрать ассоциацию .sls? (Y/N) " answer

        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            echo
            echo "Отмена."
            return
        fi

        rm -f -- "$DESKTOP_FILE"
        rm -f -- "$MIME_XML"

        update-desktop-database "$MIME_APPS_DIR" >/dev/null 2>&1 || true

        if command -v update-mime-database >/dev/null 2>&1; then
            update-mime-database "$LOCAL_SHARE/mime" >/dev/null 2>&1 || true
        fi

        echo
        echo -e "\033[32mАссоциация .sls удалена!\033[0m"

    else

        echo -n "Ассоциация: "
        echo -e "\033[33mВЫКЛЮЧЕНА\033[0m"
        echo

        read -r -p "Сделать ассоциацию .sls? (Y/N) " answer

        if [[ ! "$answer" =~ ^[Yy]$ ]]; then
            echo
            echo "Отмена."
            return
        fi

        if [[ ! -f "$SCRIPT_PATH" ]]; then
            echo
            echo -e "\033[31mОШИБКА!\033[0m"
            echo
            echo "Не найден:"
            echo -e "\033[33m$SCRIPT_PATH\033[0m"
            return
        fi

        
        
        

        cat > "$MIME_XML" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
    <mime-type type="$MIME_TYPE">
        <comment>SLS Archive</comment>
        <glob pattern="*.$EXTENSION"/>
    </mime-type>
</mime-info>
EOF

        
        
        

        cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=SLS Archivizer
Comment=SLS Archive Manager
Exec=$SCRIPT_PATH %f
Icon=package-x-generic
Terminal=true
MimeType=$MIME_TYPE;
NoDisplay=false
Categories=Utility;Archiving;
EOF

        chmod +x "$DESKTOP_FILE"

        
        
        

        if command -v update-mime-database >/dev/null 2>&1; then
            update-mime-database "$LOCAL_SHARE/mime" >/dev/null 2>&1 || true
        fi

        if command -v update-desktop-database >/dev/null 2>&1; then
            update-desktop-database "$MIME_APPS_DIR" >/dev/null 2>&1 || true
        fi

        
        if command -v xdg-mime >/dev/null 2>&1; then
            xdg-mime default "$DESKTOP_ID" "$MIME_TYPE" >/dev/null 2>&1 || true
        fi

        echo
        echo -e "\033[32mАссоциация .sls создана!\033[0m"
        echo
        echo "SLS-файлы будут открываться через:"
        echo -e "\033[32m$SCRIPT_PATH\033[0m"
        echo
        echo -e "\033[36mАдминистратор НЕ требуется.\033[0m"
    fi

    pause
}






if [[ $

    input_file="$1"

    if [[ -f "$input_file" &&
          "${input_file

        show_header

        extract_sls "$input_file"

        echo
        read -r -p "Нажмите Enter для выхода"

        exit 0
    fi
fi


while true; do

    show_header

    if test_sls_association; then
        association="ВКЛЮЧЕНА"
    else
        association="ВЫКЛЮЧЕНА"
    fi

    echo "1 - Архивация"
    echo "2 - Деархивация"
    echo "3 - Сделать/Убрать ассоциацию"
    echo -n "Ассоциация: "
    echo "$association"
    echo "0 - Выход"
    echo

    read -r -p "Введите число: " choice

    case "$choice" in

        1)
            archive_folder
            pause
            ;;

        2)
            extract_sls
            pause
            ;;

        3)
            register_association
            ;;

        0)
            echo
            echo "Выход..."
            exit 0
            ;;

        *)
            echo
            echo -e "\033[31mНеверный выбор. Введите 1, 2, 3 или 0.\033[0m"
            sleep 1
            ;;

    esac

done
