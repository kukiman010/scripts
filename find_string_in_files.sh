#!/bin/bash

search_string=$1
start_path=$2

if [[ -z $search_string ]]; then
    echo "Error! Not find string"
    echo ""
    echo "Examples script:"
    echo "./find_string_in_files.sh pam_tally            - find in local directory"
    echo "./find_string_in_files.sh 'ALL : ALL' /etc     - find in /etc directory "
    exit 1
fi


if [[ -z $start_path ]]; then
    current_dir=$(pwd)
    start_path=$(printf "%q" "$current_dir")
fi

function search_file 
{
    if [[ -f "$1" ]]; then
    search_string_in_file "$1" 
    elif [[ -d "$1" ]]; then
        for item in "$1"/*; do
            search_file "$item"
        done
    fi
}

search_string_in_file() 
{
    local path="$1"
    local line_num=0
    local found=false

    # Построчное чтение файла
    while IFS= read -r line; do
        ((line_num++))

        # Проверка наличия строки в текущей строке
        if [[ $line == *"$search_string"* ]]; then
            if [[ $found == false ]]; then
		        echo ""
                echo -e "\nФайл: $path"
                found=true
            fi
            echo "  Строка $line_num: $line"
        fi
    done < "$path"
}

search_file "$start_path"
