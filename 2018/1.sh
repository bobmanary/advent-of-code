#!/bin/bash

part1() {
    local inputs=("$@")
    local freq=0
    for freq_change in "${inputs[@]}"; do
        freq=$((freq_change+freq))
    done
    echo $freq
}

part2() {
    declare -A prev_freqs
    local inputs=("$@")
    local freq=0

    while true; do
        for freq_change in "${inputs[@]}"; do
            freq=$((freq_change+freq))
            if [ ${prev_freqs[$freq]+_} ]
            then
                echo $freq
                break 2
            else
                prev_freqs[$freq]=true
            fi
        done
    done
}

readarray inputs < inputs/1.txt
part1 "${inputs[@]}"
part2 "${inputs[@]}"
