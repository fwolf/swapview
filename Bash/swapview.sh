#!/bin/bash

function filesize(){
    size=$1
    if [[ $1 -le 1100 ]] ; then
        echo "${size}B"
        return
    fi
    arr=($(bc -l <<EOF
left=$size;
unit=-1;
while(left>1100 && unit<3){
    left /= 1024
    unit += 1
}
left
unit
EOF
))
    left=${arr[0]}
    unit=${arr[1]}
    units="KMGT"
    printf "%.1f%siB\n" "$left" "${units:$unit:1}"
}

function getSwap(){
    sumfile=/tmp/sum$RAMDOM
    > $sumfile
    cd /proc
    (for pid in [0-9]*; do
        command=$(tr '\0' ' ' </proc/$pid/cmdline 2>/dev/null)
        len=$((${#command}-1))
        if [[ "${command:$len:1}"x = " "x ]]; then
            command="${command:0:$len}"
        fi
        [[ $? -ne 0 ]] && continue

        swap=$(
            awk '
                BEGIN  { total = 0 }
                /Swap/ { total += $2 }
                END    { print total }
            ' /proc/$pid/smaps 2>/dev/null
        )
        [[ $? -ne 0 ]] && continue

        if (( swap > 0 )); then
            fs=$(filesize $((swap*1024)))
            echo $swap >>$sumfile
            printf "%5s %9s %s\n" "$pid" "$fs" "$command"
        fi
    done) | sort -k2 -h
    total=$(filesize $(( $(paste -sd+ <$sumfile | bc) *1024)))
    printf "Total: %8s\n" $total
    rm $sumfile
}

printf "%5s %9s %s\n" PID SWAP COMMAND
getSwap
