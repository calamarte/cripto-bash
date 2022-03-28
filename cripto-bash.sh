#!/bin/bash

# Author: Jose Navarro (calamarte)
# Tuto https://youtu.be/_OpD54Q9hZc?t=3969
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

    tput cnorm; rm -r $tmp; exit 1
}

lang="en"
trans_all_url="https://www.blockchain.com/$lang/btc/unconfirmed-transactions"
trans_url="https://www.blockchain.com/$lang/btc/tx"
address_url="https://www.blockchain.com/$lang/btc/address"
tmp=$(mktemp -d)

function usage() {
    echo -e "\n${redColor}[!] Usage${endColor}"

    for i in {1..80}; do echo -ne "${redColor}-"; done; echo -ne "${endColor}"
    
    echo -e "\n\n\t${grayColor}[-e]${endColor}${yellowColor} Exploration mode${endColor}"
    echo -e "\t\t${purpleColor}unconfirmed ${endColor}${yellowColor}List unconfirmed transactions${endColor}"
    echo -e "\t\t${purpleColor}inspect     ${endColor}${yellowColor}Inspect transaction hash${endColor}"
    echo -e "\t\t${purpleColor}address     ${endColor}${yellowColor}Inspect transaction address${endColor}"
    echo -e "\n\t${grayColor}[-h]${endColor}${yellowColor} Show this help panel"
    echo -e "\n"

    tput cnorm; rm -r $tmp; exit 1
}

function get_unconfirmed() {
    touch $tmp/ut.tmp

    while ! [[ -s $tmp/ut.tmp ]]; do
        curl -s $trans_all_url |
        html2text              |
        sed -r '/^\s*$/d' > $tmp/ut.tmp
    done

    hashes=$(
        cat $tmp/ut.tmp      |
        grep "Hash" -A 2     |   
        grep -E -o '\[\w+\]' |   
        tr -d '[]'                 
    ) 


    > $tmp/ut.table
    for hash in $hashes; do
        block=$(grep $hash -A 6 $tmp/ut.tmp)
        echo $block | awk -v h=$hash '{print h" "$3" "$6" "$NF}' >> $tmp/ut.table
    done

    total=$(
        cat $tmp/ut.table |
        awk '{print $NF}' |
        tr -d '$,'        |
        paste -s -d +     |
        bc
    )

    echo $total | awk '{print "Total -- -- $"$1}' >> $tmp/ut.table

    echo -ne "${yellowColor}"
    cat $tmp/ut.table | column -o " | " -t -N 'Hash,Time,Amount(BTC),Amount($)' 
    echo -ne "${endColor}"
}

function inspect_transaction() {
    touch $tmp/tr.tmp

    while ! [[ -s $tmp/tr.tmp ]]; do
        curl -s $trans_url/$1  |
        html2text > $tmp/tr.tmp
    done

    fromToHashs=$(
        grep -E 'From|To' -A 2 $tmp/tr.tmp |
        grep -E -o '\[\w+\]'               |
        tr -d '[]' 
    )
    
    totals=$(
        grep -E 'Total (Input|Output)' -A 2 $tmp/tr.tmp   |
        grep "BTC" | tr ' ' '-'
    )

    outNumber=$(grep 'Outputs' -A 500 $tmp/tr.tmp | grep 'Address' | wc -l)
    inNumber=$(grep 'Inputs' -A 500 $tmp/tr.tmp | grep 'Address' | echo "$(wc -l) - $outNumber" | bc)

    grep 'Outputs' -A $((21 * $outNumber)) $tmp/tr.tmp |
    grep 'Address' -A 6                                |
    grep -E -o '(\[\w+\]|.*BTC$)'                      |
    tr -d '[]'                                         |
    sed 's/ BTC/-BTC/g'                                |
    awk 'NR%2 {printf "%s ",$0;next;}1' > $tmp/tr-outputs.tmp
    
    grep 'Inputs' -A $((21 * $inNumber)) $tmp/tr.tmp     |
    grep 'Address' -A 6                 |
    grep -E -o '(\[\w+\]|.*BTC$)'       |
    tr -d '[]'                          |
    awk 'NR%2 {printf "%s ",$0;next;}1' |
    sed 's/ BTC/-BTC/g' > $tmp/tr-inputs.tmp

    echo "$fromToHashs $totals" | tr '\n' ' ' > $tmp/tr.table

    echo -ne "${yellowColor}"
    cat $tmp/tr.table | column -o " | " -t -N 'From,To,Total Input,Total Output' 
    echo -ne "${endColor}"

    echo -e '\n'
    
    echo -ne "${blueColor}"
    cat $tmp/tr-inputs.tmp | column -o " | " -t -N 'Address,Amount (BTC)' 
    echo -ne "${endColor}"
    
    echo -e '\n'
    
    echo -ne "${greenColor}"
    cat $tmp/tr-outputs.tmp | column -o " | " -t -N 'Address,Amount (BTC)' 
    echo -ne "${endColor}"
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
    inspect) inspect_transaction ${@:(-1)};;
    address) echo $mode;;
    *) usage;;
esac

rm -r $tmp

tput cnorm
