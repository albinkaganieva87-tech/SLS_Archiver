#!/bin/bash


SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

EXTENSION=".sls"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

check_dependencies() {

    if ! command -v zip >/dev/null 2>&1; then
        echo
        echo -e "${RED}Ошибка: zip не найден.${RESET}"
        echo
        echo "На macOS zip обычно уже установлен."
        echo
        exit 1
    fi

    if ! command -v unzip >/dev/null 2>&1; then
        echo
        echo -e "${RED}Ошибка: unzip не найден.${RESET}"
        echo
        exit 1
    fi
}

select_folder() {

    local result

    
    result="$(osascript <<'APPLESCRIPT'
set selectedFolder to choose folder with prompt "Выберите папку"

POSIX path of selectedFolder
APPLESCRIPT
)"

    if [[ $? -ne 0 || -z "$result" ]]; then
        return 1
    fi

    
    result="$(printf '%s' "$result" | sed 's/[[:space:]]*$//')"

    printf '%s\n' "$result"
}

select_sls_file() {

    local result

    result="$(osascript <<'APPLESCRIPT'
set selectedFile to choose file with prompt "Выберите SLS-архив" of type {"sls"}

POSIX path of selectedFile
APPLESCRIPT
)"

    if [[ $? -ne 0 || -z "$result" ]]; then
        return 1
    fi

    result="$(printf '%s' "$result" | sed 's/[[:space:]]*$//')"

    printf '%s\n' "$result"
}

archive_folder() {

    echo
    echo -e "${RED}Если вы не видите меню выбора папки, проверьте другие окна.${RESET}"
    echo

    local source_folder

    if ! source_folder="$(select_folder)"; then

        echo
        echo -e "${YELLOW}Папка не выбрана.${RESET}"

        return
    fi

    if [[ ! -d "$source_folder" ]]; then

        echo
        echo -e "${RED}Ошибка: папка не существует.${RESET}"

        return
    fi


    
    source_folder="${source_folder%/}"


    local parent_folder
    local folder_name
    local sls_file

    parent_folder="$(dirname "$source_folder")"
    folder_name="$(basename "$source_folder")"

    sls_file="$parent_folder/$folder_name.sls"


    if [[ -f "$sls_file" ]]; then
        rm -f -- "$sls_file"
    fi


    echo
    echo "===================================="
    echo "             АРХИВАЦИЯ"
    echo "===================================="
    echo

    echo "Источник:"
    echo -e "${YELLOW}$source_folder${RESET}"
    echo


    local files
    files="$(find "$source_folder" -type f 2>/dev/null)"

    local total_files
    total_files="$(printf '%s\n' "$files" | grep -c . || true)"

    echo "Файлов: $total_files"
    echo


    
    
    cd "$parent_folder" || {

        echo
        echo -e "${RED}Ошибка перехода в папку.${RESET}"

        return
    }


    if ! zip -r -q "$sls_file" "$folder_name"; then

        echo
        echo -e "${RED}Ошибка при архивации.${RESET}"

        rm -f -- "$sls_file"

        return
    fi


    echo -ne "\rАрхивация: 100%"

    echo
    echo
    echo -e "${GREEN}Готово!${RESET}"
    echo

    echo "SLS-архив:"
    echo -e "${GREEN}$sls_file${RESET}"
}

check_safe_path() {

    local destination="$1"
    local archive_path="$2"

    
    archive_path="${archive_path


    
    case "$archive_path" in

        "..")
            return 1
            ;;

        ../*)
            return 1
            ;;

        */../*)
            return 1
            ;;

        */..)
            return 1
            ;;

    esac


    local destination_real
    local target_real

    destination_real="$(cd "$destination" && pwd -P)"

    target_real="$(python3 - "$destination_real" "$archive_path" <<'PY'
import os
import sys

destination = sys.argv[1]
archive_path = sys.argv[2]

print(os.path.realpath(os.path.join(destination, archive_path)))
PY
)"


    case "$target_real" in

        "$destination_real"/*)
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
            echo -e "${RED}Файл не найден:${RESET}"
            echo "$sls_file"

            return
        fi

    else

        local sls_file

        if ! sls_file="$(select_sls_file)"; then

            echo
            echo -e "${YELLOW}Файл не выбран.${RESET}"

            return
        fi

    fi


    local destination_folder

    if ! destination_folder="$(select_folder)"; then

        echo
        echo -e "${YELLOW}Папка назначения не выбрана.${RESET}"

        return
    fi


    if [[ ! -d "$destination_folder" ]]; then

        echo
        echo -e "${RED}Папка назначения не существует.${RESET}"

        return
    fi


    destination_folder="${destination_folder%/}"


    echo
    echo "===================================="
    echo "            РАСПАКОВКА"
    echo "===================================="
    echo

    echo "Архив:"
    echo -e "${YELLOW}$sls_file${RESET}"
    echo

    echo "Назначение:"
    echo -e "${YELLOW}$destination_folder${RESET}"
    echo


    
    
    

    echo "Проверка архива..."

    local entry
    local bad_path=""

    while IFS= read -r entry; do

        [[ -z "$entry" ]] && continue

        if ! check_safe_path "$destination_folder" "$entry"; then

            bad_path="$entry"

            break
        fi

    done < <(unzip -Z1 "$sls_file" 2>/dev/null)


    if [[ -n "$bad_path" ]]; then

        echo
        echo -e "${RED}Ошибка безопасности!${RESET}"
        echo

        echo "Обнаружен недопустимый путь в архиве:"
        echo -e "${RED}$bad_path${RESET}"

        return
    fi


    echo "Проверка пройдена."
    echo
    echo "Распаковка..."


    if ! unzip -o "$sls_file" -d "$destination_folder"; then

        echo
        echo -e "${RED}Ошибка при распаковке.${RESET}"

        return
    fi


    echo
    echo -e "${GREEN}Готово!${RESET}"
    echo

    echo "Файлы распакованы в:"
    echo -e "${GREEN}$destination_folder${RESET}"
}






check_dependencies






if [[ $

    input_file="$1"


    if [[ -f "$input_file" &&
          "${input_file

        clear


        echo "===================================="
        echo "             SLS ARCHIVIZER"
        echo "===================================="
        echo


        extract_sls "$input_file"


        echo
        read -r -p "Нажмите Enter для выхода"

        exit 0
    fi
fi






while true; do

    clear


    echo "===================================="
    echo "             SLS ARCHIVIZER"
    echo "===================================="
    echo

    echo "1 - Архивация"
    echo "2 - Деархивация"
    echo "3 - Выход"
    echo


    read -r -p "Введите число: " choice


    case "$choice" in

        1)

            archive_folder

            echo
            read -r -p "Нажмите Enter для продолжения"

            ;;


        2)

            extract_sls

            echo
            read -r -p "Нажмите Enter для продолжения"

            ;;


        3)

            echo
            echo -e "${CYAN}Выход...${RESET}"

            exit 0

            ;;


        *)

            echo
            echo -e "${RED}Неверный выбор. Введите 1, 2 или 3.${RESET}"

            sleep 1

            ;;

    esac

done
