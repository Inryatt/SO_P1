#!/bin/bash

readarray -t  pid do< <(ps -au | awk '{print $2}')
n_max=$(( ${#pid[@]}*10 ))
echo $n_max is n_max

for ((i=10;i<$n_max;i+=10));do
	mainArray[$i]=${pid[$(( $i/10 ))]}
	echo mainArr= ${mainArray[$i]}
	echo i= $i pid=  ${pid[$i]}	
done

#printf "%-20b" "COMM" "NAME" "TESTE" 
#printf "%-20s" "${PIDs[@]}" 

echo ${mainArray[@]}

#(ps -a -o comm)



