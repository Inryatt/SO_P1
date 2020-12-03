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

pids=($(ls /proc/ -v | grep '[0-9]'))

for (( el=0; el<${#pids[@]}; el++ )); do
	echo el= $el
	echo pid= ${pids[$el]}				
done

#echo "intervalo em segundos: $s"
while getopts "c:s:e:u:wmtdr" options; do
	
	case "${options}" in
	c)
		#WIP -- filtrar o nome DOS PROCESSOS (COMM) por REGEX
		
		if [[ $OPTARG == $s ]]; then #IMPORTANTE! ISTO FOI A MELHOR MANEIRA QUE DESCOBRI DE FAZER COM QUE ./PROCSTAT -C 3 DESSE ERRO POR NAO PASSAR PROPER ARGUMENTO AO -C!!
			echo "Error-Missing Argument! Pass an regex after -c !"
			exit 1
		else
			toUnset=()
			filter_regex="$OPTARG"
			#echo "DEBUG: $filter_regex = filterregex" 
			for (( el=0; el<${#pids[@]}; el++ )); do

				#echo " DEBUG  el= $el , pid=${pids[$el]} , comm= $(cat /proc/${pids[$el]}/comm 2>/dev/null)"	
				if ! [[ $(cat /proc/${pids[$el]}/comm 2>/dev/null) =~ $filter_regex ]];then
					#echo "DEBUG: REMOVED $(cat /proc/${pids[$el]}/comm 2>/dev/null) "
					toUnset+=($el)
				
				
				#else
				#echo  $(cat /proc/${pids[$el]}/comm 2>/dev/null) got through!!===========================================

				fi
			done

			#echo to unset ${toUnset[@]}
			for el in ${toUnset[@]}; do
				#echo unsetted $el
				unset -v 'pids[$el]'
			done
			unset toUnset
			#echo pids= ${pids[@]}
			#echo "Opção c ainda não implementada - WIP" eyy it done
			shift $((OPTIND-1)) #not sure if very needed
		fi

		;;

	s)
		#WIP -- Filtrar Data Mínima
		if [[ $# -lt 3 ]]; then
			echo "Error-Missing Argument! Pass the minimum date after -s !"
			exit 1
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


	#pids=($(ps -au | awk '{ print $2 } ' | tail +2)	)



	for el in ${pids[@]}; do
	if [[ -f "/proc/$el/comm"  ]] && [[ -f "/proc/$el/io" ]] && [[ -f "/proc/$el/status" ]] && [[ $"/proc/$el/status" != " " ]]; then
		comm[$el]=$(cat /proc/$el/comm 2>/dev/null)
		user[$el]=$(ps -aux | awk '{print $1 " " $2} ' 2>/dev/null | grep -w $el | awk '{print $1}')
		vmsize[$el]=$(cat /proc/$el/status 2>/dev/null | grep VmSize | awk '{print $2}')
		rss[$el]=$(cat /proc/$el/status 2>/dev/null | grep VmRSS | awk '{print $2}')
		readb[$el]=$(cat /proc/$el/io 2>/dev/null | grep rchar | awk '{print $2}')
		writeb[$el]=$(cat /proc/$el/io 2>/dev/null | grep wchar | awk '{print $2}')
	fi
	done

	sleep $s

	for el in ${pids[@]}; do
		newread=$(cat /proc/$el/io 2>/dev/null | grep rchar | awk '{print $2}')
		newwrite=$(cat /proc/$el/io 2>/dev/null | grep wchar | awk '{print $2}')

		# usar a funcionalidade 'herestring (<<<)' para dar comandos ao bc
		# scale corresponde ao numero de casas decimais

		rater[$el]=$(bc <<<"scale=2;( $newread - ${readb[$el]})/$s") #! SYNTAX ERROR HERE IDK WHAT THIS DOES SO CANT FIX

		ratew[$el]=$(bc <<<"scale=2;( $newwrite - ${writeb[$el]})/$s")
	done

	#echo ${pids[@]}
	#pids=($(ps -e | awk '{print $1}' | tail +1)) get pids from ps - works well
	#echo "pids= ${pids[@]}"
	#exit 0
	#echo should be equal ${#PIDarr[@]} ${#comm[@]}

	for el in ${pids[@]}; do
		echo $el ${comm[$el]} ${user[$el]} ${vmsize[$el]} ${rss[$el]} ${readb[$el]} ${writeb[$el]} ${rater[$el]} ${ratew[$el]}
	done
#
#	echo debugging: ${pids[@]} 
#	for el in ${pids[@]}; do
#		echo $el
#	done

#for el in ${pids[@]}; do
#	if [[ -f "/proc/$el/comm" ]]; then
#		cat /proc/$el/comm
#	fi
#
#done
