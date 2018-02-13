#!/bin/bash
#vars
nameLog=`date | md5sum | awk '{print $1}'`
nameHost="google.com"
pathInstall="/usr/local/bin/"


if [[ ! -z $@ ]]; then
    nameHost=$@
fi

if [ -z `dpkg -l | grep -o nmap` ]; then
    echo "Сейчас будет установлена утилита nmap"
    sleep 5
    sudo apt-get install nmap -y
fi

if [ -z `which chost` ]; then
    echo "Сейчас будет установлена утилита chost"
    sleep 5
    sudo cp $BASH_SOURCE $pathInstall
    sudo ln -s $pathInstall/$BASH_SOURCE $pathInstall/chost
    echo "Теперь проверить хост google.com можно командой 'sudo chost google.com'"
    sleep 5
fi

function ifRoot()
{
    if [[ $EUID -ne 0 ]]; then
        echo "Нужно запустить скрипт от root"
        exit 1
    fi
}
function timer()
{
    while sleep 1; do
        echo -n '* ' >&2
    done
    echo -e "\n"
}
function ssh_test()
{
    for sshTest in $@; do
        if [[ -z `dpkg -l | grep -wo nmap` ]]; then sudo apt-get install nmap -y  ; fi
        ssh_tst=`sudo nmap -O $sshTest | grep ssh | awk -F "/" '{print $1}'`
        if [[ -z $ssh_tst ]];
        then echo -e "\n\033[31mssh не доступен\033[0m"; else
        echo -e "\n\033[33mПредпологается что ssh доступен по порту : \033[0m \033[32m $ssh_tst \033[0m"; fi
        echo "####################################################################"
    done
}

function ssTestTimer()
{
    timer &
    timer_ID=$!
    ssh_test $@
    sudo kill -9 $timer_ID
}
function pingHosts()
{
    for pingHost in $@; do
        echo -n -e "\033[33mПингуется ли хост  $pingHost ? : \033[0m "
        ping $1 -c 3 > /dev/null
        if [ $? -ne "0" ]; then
            echo -e "\033[31mХост не пингуется\033[0m "
        else
            echo -e "\033[32m Хост пингуется \033[0m"
        fi
        ssTestTimer $pingHost
    done
}

function resolvHosts()
{
    for hosts in $@; do
        echo -n -e  "\033[33mРезолвится ли хост $hosts ? : \033[0m"
        host $hosts > /tmp/$nameLog
        if [ $? -ne "0" ]; then
            echo -e "\033[31mПри попытке разрезолвить хост , возникли проблемы ! \033[0m"
        else
            echo -e "\033[32m Да \033[0m"
            ipt=`cat /tmp/$nameLog | grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"`
            if [[ -z $ipt ]] ; then
                echo -e "\033[31mЧто то пошло не так \033[0m"
            else
                pingHosts $ipt
            fi
        fi
    done
}
ifRoot
resolvHosts  $nameHost
