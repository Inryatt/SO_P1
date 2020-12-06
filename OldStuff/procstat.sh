#!/bin/bash

PIDtmp=($(ls /proc/ -v | grep '[0-9]' ))

#echo  "${PIDtmp[@]}"
#echo "Len= ${#PIDtmp[@]}"
for ((i=0;i<${#PIDtmp[@]};i++));do
#	echo "i= $i"
#	echo  ${PIDtmp[i]}
	PIDarr[${PIDtmp[i]}]=${PIDtmp[i]};
done

#for l in "${PIDarr[@]}";do
#	echo PIDarr[$l]=$l
#done

#echo ${#PIDarr[@]}
#Temos dois arrays: PIDarr com os indices iguais ao PID e PIDtmp com indices seguidos entre 1 e o numero de PIDs existentes.

if [[ "${PIDarr[$1]}" -ne "$1" ]]; then

	echo "Esse PID não existe :( "	
	
else
	readarray -t info < <(cat /proc/"$1"/status)
	#info=($(cat /proc/$1/status))
	vmsize=${info[17]}
	teste=${vmsize//[^0-9]/}
	
	echo $teste
fi 


