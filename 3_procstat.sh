#!/bin/bash

sortOpt=0

if [[ $# -lt 1 ]]; then
	echo "Missing Arguments--Include at least the time interval"
	exit 1
fi

s=${@: -1}
#echo .$s. is  s
regexNum="^[0-9]+$"
if [[ "$s" =~ $regexNum ]]; then

	echo
else
	echo "Error: Missing Arguments -O intervalo de tempo têm de ser o último argumento."
	exit 1
fi

echo "${options}"
#echo "intervalo em segundos: $s"
while getopts "c:s:e:u:wmtdr" options; do
	case "${options}" in
	c)
		#WIP -- filtrar o nome DOS PROCESSOS (COMM) por REGEX

		if [[ $# -lt 3 ]]; then
			echo "Error-Missing Argument! Pass an regex after -c !"
		else
			fiter_regex=$OPTARG
			echo "Opção c ainda não implementada - WIP"

		fi

		;;

	s)
		#WIP -- Filtrar Data Mínima
		if [[ $# -lt 3 ]]; then
			echo "Error-Missing Argument! Pass the minimum date after -c !"
		else
			MIN_DATE=$OPTARG
			echo "Opção s ainda não implementada - WIP"
			#if [[ ${OPTARG} ]] check date is formatted right and if theres a max date, its inferior to it
		fi
		;;

	e)
		#WIP -- filtrar Data Máxima
		if [[ $# -lt 3 ]]; then
			echo "Error-Missing Argument! Pass the maximum date after -c !"
		else
			MAX_DATE=$OPTARG
			echo "Opção e ainda não implementada - WIP"
			#if [[ ${OPTARG} ]] check date is formatted right and if theres a min date, its superior to it
		fi
		;;

	u)
		#WIP -- filtrar por nome de utilizador

		if [[ $# -lt 3 ]]; then
			echo "Error-Missing Argument! Pass an username after -c !"
		else
			NAME=$OPTARG
			echo "Opção u ainda não implementada - WIP"
			#if [[ ${OPTARG} ]] check if user exists
		fi
		;;

	w)
		echo "w pressed"
		if [[ $sortOpt == 0 ]]; then
			sortOpt=1
			#WIP -- sort on MEMup
			echo "Sort Opção w ainda não implementada - WIP"
		else
			echo "Error-Use apenas uma das seguintes opções: m t d w"
			exit 1
		fi
		;;

	m)
		echo "m pressed"

		if [[ $sortOpt == 0 ]]; then
			sortOpt=1
			#WIP -- sort on RATE
			echo "Sort Opção m ainda não implementada - WIP"
		else
			echo "Error-Use apenas uma das seguintes opções: m t d w"
			exit 1
		fi

		;;

	t)
		echo "t pressed"
		if [[ $sortOpt == 0 ]]; then
			sortOpt=1
			#WIP -- sort on RSSup
			echo "Sort Opção m ainda não implementada - WIP"
		else
			echo "Error-Use apenas uma das seguintes opções: m t d w"
			exit 1
		fi
		;;

	d)
		echo "d pressed"

		if [[ $sortOpt == 0 ]]; then
			sortOpt=1
			#WIP -- sort on RATERup
			echo "Sort Opção m ainda não implementada - WIP"
		else
			echo "Error-Use apenas uma das seguintes opções: m t d w"
			exit 1
		fi
		;;

	r)
		echo "t pressed"
		if [[ $sortOpt == 1 ]]; then
			#WIP -- REVERSE SORT
			echo "Opção c ainda não implementada - WIP"
		else
			echo "Error-Tem de usar uma opção destas opções também: m t d w"
			exit 1
		fi
		;;

	:)

		echo "Erro- ${OPTARG} has missing argument!"
		exit 1
		;;

	*)
		echo "ERRO-Opção Inválida;" #REPLACE WITH STDERR? OR EQUIV EM BASH
		exit 1
		;;
	esac
done

#what to do if only time is passed to procstat
if [[ $# == 1 ]]; then
	#pids=($(ps -au | awk '{ print $2 } ' | tail +2)	)

	PIDtmp=($(ls /proc/ -v | grep '[0-9]'))
	

	for el in ${PIDtmp[@]}; do
		#pids[$el]=$el
		#if [[ ]]
		if [[ -f "/proc/$el/comm" ]] && [[ -f "/proc/$el/io" ]] && [[ -f "/proc/$el/status" ]] && [[ $(/proc/$el/status) != " " ]]; then
			pids[$el]=$el
			comm[$el]=$(cat /proc/$el/comm)
			user[$el]=$(ps -aux|awk '{print $1 " " $2} '  | grep -w $el | awk '{print $1}')
			vmsize[$el]=$(cat /proc/$el/status | grep VmSize | awk '{print $2}')
			rss[$el]=$(cat /proc/$el/status | grep VmRSS | awk '{print $2}')
			readb[$el]=$(cat /proc/$el/io | grep rchar | awk '{print $2}')
			writeb[$el]=$(cat /proc/$el/io | grep wchar | awk '{print $2}')
		fi
	done

	sleep $s

	for el in ${pids[@]}; do
		newread=$(cat /proc/$el/io | grep rchar | awk '{print $2}')
		newwrite=$(cat /proc/$el/io | grep wchar | awk '{print $2}')
		
		# usar a funcionalidade 'herestring (<<<)' para dar comandos ao bc
		# scale corresponde ao numero de casas decimais
		rater[$el]=$(bc <<< "scale=2;($newread - ${readb[$el]})/$s")
		ratew[$el]=$(bc <<< "scale=2;($newwrite - ${writeb[$el]})/$s")
	done

	#echo ${pids[@]}
	#pids=($(ps -e | awk '{print $1}' | tail +1)) get pids from ps - works well
	#echo "pids= ${pids[@]}"
	#exit 0
	#echo should be equal ${#PIDarr[@]} ${#comm[@]}

	for el in ${pids[@]}; do
		echo ${pids[$el]} ${comm[$el]} ${user[$el]} ${vmsize[$el]} ${rss[$el]} ${readb[$el]} ${writeb[$el]} ${rater[$el]} ${ratew[$el]}
	done 
fi

#for el in ${pids[@]}; do
#	if [[ -f "/proc/$el/comm" ]]; then
#		cat /proc/$el/comm
#	fi
#
#done
