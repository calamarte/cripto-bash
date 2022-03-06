#!/bin/bash

# Author: Jose Navarro (calamarte)
# Tuto https://youtu.be/_OpD54Q9hZc?t=1643
# Required: html2text

#Colors
greenColor="\e[0;32m\033[1m"
endColor="\033[0m\e[0m"
redColor="\e[0;31m\033[1m"
blueColor="\e[0;34m\033[1m"
yellowColor="\e[0;33m\033[1m"
purpleColor="\e[0;35m\033[1m"
turquoiseColor="\e[0;36m\033[1m"
grayColor="\e[0;37m\033[1m"

trap ctrl_c INT

function ctrl_c() {
    echo -e "\n${redColor}[!] Exit...\n${endColor}"

    tput cnorm; exit 1
}

lang="en"
trans_all_url="https://www.blockchain.com/$lang/btc/unconfirmed-transactions"
trans_url="https://www.blockchain.com/$lang/btc/tx"
address_url="https://www.blockchain.com/$lang/btc/address"

function usage() {
    echo -e "\n${redColor}[!] Usage${endColor}"

    for i in {1..80}; do echo -ne "${redColor}-"; done; echo -ne "${endColor}"
    
    echo -e "\n\n\t${grayColor}[-e]${endColor}${yellowColor} Exploration mode${endColor}"
    echo -e "\t\t${purpleColor}unconfirmed ${endColor}${yellowColor}List unconfirmed transactions${endColor}"
    echo -e "\t\t${purpleColor}inspect     ${endColor}${yellowColor}Inspect transaction hash${endColor}"
    echo -e "\t\t${purpleColor}address     ${endColor}${yellowColor}Inspect transaction address${endColor}"
    echo -e "\n\t${grayColor}[-h]${endColor}${yellowColor} Show this help panel"
    echo -e "\n"

    tput cnorm; exit 1
}

function get_unconfirmed() {
    touch ut.tmp

    while [ $(cat ut.tmp | wc -l) == 0 ]; do
        curl -s "$trans_all_url" | 
        html2text                |  
        grep "Hash" -A 2         |   
        grep -E -o '\[\w+\]'     |   
        tr -d '[]' > ut.tmp                
    done

    cat ut.tmp
}

while getopts "e:h:" arg; do
    case $arg in
        e) mode=$OPTARG;;
        h) usage;;
    esac
done

tput civis

case $mode in
    unconfirmed) get_unconfirmed;;
    inspect) echo $mode;;
    address) echo $mode;;
    *) usage;;
esac

tput cnorm
