#!/bin/bash

if [ ! -e $1 ]; then 
    echo " "
    echo "*** File $1 DOES NOT EXITS ***"
    echo " "

else 
    ./dasm.Darwin.x86 $1 -o${1%.*}.out
    echo " "
    echo "COMPLETED: ${1%.*}.out in Directory "
    echo "---"

fi 


