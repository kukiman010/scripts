#!/bin/bash

VERSION="1.0"
BRANCH="openssl-3.3"
DIR_BUILD="build_openssl"
CLEAN="true"
# https://www.ssltrust.com.au/help/setup-guides/compile-openssl-from-source
# https://habr.com/ru/articles/678698/


run_command() 
{
    "$@"
    local status=$?

    if [ $status -ne 0 ]; then
	local red='\033[0;31m'
	local nc='\033[0m'
	echo -e "${red}Error: команда '$*' завершилась с ошибкой (код: $status).${nc}"
	exit $status
    fi
}


clone()
{
    if [[ -d "./openssl/.git" ]]; then
        echo ""
    else
	run_command git clone --branch $BRANCH https://github.com/openssl/openssl.git
    fi

#    sudo chmod -R 777 ./openssl
    chmod +x ./openssl/Configure
    chmod +x ./openssl/config
}

build_for_windows()
{
    cd ./openssl
    mkdir ./openssl_for_windows
    
    if [ "$CLEAN" == "true" ]; then
	echo "clean!!!"
	make clean
    fi

    run_command ./Configure --cross-compile-prefix=x86_64-w64-mingw32- mingw64 --prefix=$DIR_BUILD

    run_command make -j8
    run_command sudo make install

    sudo chown 777 -R $DIR_BUILD
    cd ..
}

build_for_linux()
{
    cd ./openssl

    if [ "$CLEAN" == "true" ]; then
	echo "clean!!!"
	make clean
    fi
    run_command ./config --release -O3 no-shared no-ssl3 no-comp no-dgram no-stdio no-srp no-gost no-cast no-bf no-ripemd no-mdc2 no-dsa no-dh no-sctp no-whirlpool --prefix=/tmp/$DIR_BUILD

    run_command make -j8
    run_command sudo make install
#    sudo chown 777 -R $DIR_BUILD
    cd ..
}

make_windows_dir()
{
    mkdir -p ./C:

# Основные пути
    src_dir="./openssl/$DIR_BUILD"
    dest_dir="C:/Program Files"
    common_ssl_dir="$dest_dir/Common Files/SSL"

# Создаем структуру каталогов в назначении
    mkdir -p "$dest_dir/Common Files/SSL/certs"
    mkdir -p "$dest_dir/Common Files/SSL/misc"
    mkdir -p "$dest_dir/Common Files/SSL/private"
    mkdir -p "$dest_dir/OpenSSL/bin"
    mkdir -p "$dest_dir/OpenSSL/include/openssl"
    mkdir -p "$dest_dir/OpenSSL/lib/engines-1_1"
    mkdir -p "$dest_dir/OpenSSL/lib/pkgconfig"
    mkdir -p "$dest_dir/OpenSSL/share"

# Перемещаем файлы
    cp "$src_dir/bin/"* 			"$dest_dir/OpenSSL/bin/"
    cp "$src_dir/include/openssl/"* 		"$dest_dir/OpenSSL/include/openssl/"
    cp "$src_dir/lib64/lib"* 			"$dest_dir/OpenSSL/lib/"
    cp "$src_dir/lib64/engines-3/"* 		"$dest_dir/OpenSSL/lib/engines-1_1/"
    cp "$src_dir/lib64/pkgconfig/"* 		"$dest_dir/OpenSSL/lib/pkgconfig/"
    cp "$src_dir/ssl/certs/"* 			"$common_ssl_dir/certs/"
    cp "$src_dir/ssl/misc/"* 			"$common_ssl_dir/misc/"
    cp "$src_dir/ssl/private/"* 		"$common_ssl_dir/private/"
    cp -R "$src_dir/share/"* 			"$dest_dir/OpenSSL/share/"
    cp "$src_dir/../apps/openssl.cnf" 		"$common_ssl_dir/"
    cp "$src_dir/../apps/ct_log_list.cnf"	"$common_ssl_dir/"


# Перемещаем конфигурационные файлы
    for config_file in ct_log_list.cnf ct_log_list.cnf.dist openssl.cnf openssl.cnf.dist; do
      if [[ -f "$src_dir/ssl/$config_file" ]]; then
	cp "$src_dir/ssl/$config_file" "$common_ssl_dir/"
      fi
    done

    run_command zip -r ./openssl_for_windows.zip ./C:
    rm -R ./C:
    rm -R ./openssl/openssl_for_windows
}

make_linux_dir()
{
    run_command tar -cf ./openssl_for_linux.tar /tmp/$DIR_BUILD
    rm -R /tmp/$DIR_BUILD
}

info()
{
    echo "Build openssl $BRANCH"
    echo "Version sripts: $VERSION"
    echo ""
    echo "-w                Build for windows"
    echo "-l                Build for linux"
    echo "-nc               No clean make"

    if [ "$CLEAN" == "true" ]; then
	echo "clear!!!"
    fi
}


if [ "$2" == "-nc" ]; then
    CLEAN="false"
fi


if [ "$1" == "-w" ]; then
    clone
    build_for_windows
    make_windows_dir
    echo -e "\033[0;32mdone \033[0m"
elif [ "$1" == "-l" ]; then
    clone
    build_for_linux
    make_linux_dir
    echo -e "\033[0;32mdone \033[0m"
elif [ "$1" == "-h" ]; then
    info
else 
    info
fi

exit 0;