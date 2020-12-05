#!/bin/bash

sortCol=2
sortRev=""		# "-r" para reverse, "" para normal
numericSort=""	# "-n" para sort numérico, "" para alfabético
tableMax=-1

#############  get PIDs  #############

pids=($(ls /proc/ -v | grep '[0-9]'))

for ((el = 0; el < ${#pids[@]}; el++)); do
	# verficar se a informação do processo pode ser lida
	if [[ $(cat /proc/${pids[$el]}/status 2>/dev/null | grep VmSize | awk '{print $2}') != "" ]]\
    && [[ $(cat /proc/${pids[$el]}/status 2>/dev/null | grep VmRSS | awk '{print $2}') != " " ]]\
    && [[ $(cat /proc/${pids[$el]}/io 2>/dev/null | grep wchar | awk '{print $2}') != " " ]]\
    && [[ $(cat /proc/${pids[$el]}/io 2>/dev/null | grep rchar | awk '{print $2}') != " " ]]\
    && [[ $"/proc/${pids[$el]}/status" != " " ]]\
    && [[ -f "/proc/$el/comm" ]]\
    && [[ -f "/proc/$el/io" ]]\
    && [[ -f "/proc/$el/status" ]]; then				# these 3 are redundant (i think?)
		:
	else
		toUnset+=($el)
	fi
done

for el in ${toUnset[@]}; do
	unset -v 'pids[$el]'
done

unset toUnset

# this might not be necessary with the current sorting method
#To fix array indexes              			IMPORTANT!  gotta be repeated everytime after pids is altered! :( blame bash and its dumb arrays
for el in ${pids[@]}; do
	tmp_pids+=($el)
done
unset pids

for el in ${tmp_pids[@]}; do
	pids+=($el)
done

unset tmp_pids


#############  process options given  #############

while getopts "c:s:e:u:p:wmtdr" options; do

	case "${options}" in
	c)
		#WIP -- filtrar o nome DOS PROCESSOS (COMM) por REGEX
		toUnset=()
		filter_regex="$OPTARG"
		#echo "DEBUG: $filter_regex = filterregex"
		for ((el = 0; el < ${#pids[@]}; el++)); do
			#echo " DEBUG  el= $el , pid=${pids[$el]} , comm= $(cat /proc/${pids[$el]}/comm 2>/dev/null)"
			if ! [[ $(cat /proc/${pids[$el]}/comm 2>/dev/null) =~ $filter_regex ]]; then
				#echo "DEBUG: REMOVED $(cat /proc/${pids[$el]}/comm 2>/dev/null) "
				toUnset+=($el)
			fi
		done

		#echo to unset ${toUnset[@]}
		for el in ${toUnset[@]}; do
			#echo unsetted $el
			unset -v 'pids[$el]'
		done
		unset toUnset
		#To fix array indexes              			IMPORTANT!
		for el in ${pids[@]}; do
			tmp_pids+=($el)
		done
		unset pids

		for el in ${tmp_pids[@]}; do
			pids+=($el)
		done

		unset tmp_pids
		;;

	s)
		#WIP -- Filtrar Data Mínima
		MIN_DATE_t=$OPTARG

		MAX_DATE=$(date -d $MIN_DATE_t +%s)
		echo "Opção s ainda não implementada - WIP"
		#if [[ ${OPTARG} ]] check date is formatted right and if theres a max date, its inferior to it
		;;

	e)
		#WIP -- filtrar Data Máxima
		MAX_DATE=$OPTARG
		echo "Opção e ainda não implementada - WIP"
		#if [[ ${OPTARG} ]] check date is formatted right and if theres a min date, its superior to it
		;;

	u)
		#WIP -- filtrar por nome de utilizador   --- this ain't workin :(

		toUnset=()
		filterUser="$OPTARG"

		for ((el = 0; el < ${#pids[@]}; el++)); do

			#	echo $(ps -p ${pids[$el]} -o user= ) user to find is $filterUser
			if [[ "$(ps -p ${pids[$el]} -o user= 2>/dev/null)" != "$filterUser" ]]; then
				toUnset+=($el)
			fi
		done

		for el in ${toUnset[@]}; do
			unset -v 'pids[$el]'
		done

		unset toUnset

		#To fix array indexes              			IMPORTANT!
		for el in ${pids[@]}; do
			tmp_pids+=($el)
		done
		unset pids

		for el in ${tmp_pids[@]}; do
			pids+=($el)
		done

		unset tmp_pids
		;;

	p)
		# limit number of processes displayed on table
		regexNum="^[0-9]+$"
		if [[ "$OPTARG" =~ $regexNum ]]; then
			tableMax=$OPTARG
		else
			echo "Error: O número de processos é inválido"
			exit 1
		fi
		;;

	w)
		# sort on RATEW
		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=9
		numericSort="-n"
		;;

	m)
		# sort on MEM
		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=4
		numericSort="-n"
		;;

	t)
		# sort on RSS
		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=5
		numericSort="-n"
		;;

	d)
		# sort on RATER
		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=8
		numericSort="-n"
		;;

	r)
		# reverse sort order
		sortRev="-r"
		;;

	:)

		echo "Erro- ${options} has missing argument!"
		exit 1
		;;

	*)
		echo "ERRO-Opção Inválida;" #REPLACE WITH STDERR? OR EQUIV EM BASH
		exit 1
		;;
	esac
done

shift $((OPTIND -1))	# remover argumentos opcionais processados, o argumento de tempo passa a ser $1

#############  validate given time argument  #############

if [[ $# -ne 1 ]]; then		# tem de haver exatamente 1 argumento não opcional
	echo "Missing Arguments--Include the time interval"  # trocar isto por um usage?
	exit 1
fi

s=$1
#echo .$s. is  s
regexNum="^[0-9]+$"
if [[ "$s" =~ $regexNum ]]; then
	:
else
	echo "Error: O intervalo de tempo é inválido"
	exit 1
fi


#############  get info on processes  #############

for el in ${pids[@]}; do
	comm[$el]=$(cat /proc/$el/comm 2>/dev/null)
	user[$el]=$(ps -aux | awk '{print $1 " " $2} ' 2>/dev/null | grep -w $el | awk '{print $1}')
	vmsize[$el]=$(cat /proc/$el/status 2>/dev/null | grep VmSize | awk '{print $2}')
	rss[$el]=$(cat /proc/$el/status 2>/dev/null | grep VmRSS | awk '{print $2}')
	datestart[$el]=$(ps -p $el -o lstart | tail -1 | cut -c 5-25)
	readb[$el]=$(cat /proc/$el/io 2>/dev/null | grep rchar | awk '{print $2}')
	writeb[$el]=$(cat /proc/$el/io 2>/dev/null | grep wchar | awk '{print $2}')
done

sleep $s

for el in ${pids[@]}; do
	newread=$(cat /proc/$el/io 2>/dev/null | grep rchar | awk '{print $2}')
	newwrite=$(cat /proc/$el/io 2>/dev/null | grep wchar | awk '{print $2}')

	# usar a funcionalidade 'herestring (<<<)' para dar comandos ao bc
	# scale corresponde ao numero de casas decimais

	rater[$el]=$(bc <<<"scale=2;( $newread - ${readb[$el]})/$s") 
	ratew[$el]=$(bc <<<"scale=2;( $newwrite - ${writeb[$el]})/$s")
done

#############  format data, sort and print table  #############

if [[ $tableMax -eq -1 ]]; then
	tableMax=${#pids[@]}
fi

printf "%8s | %16s | %10s | %10s | %15s | %15s | %15s | %15s | %15s | %20s \n" \
	"PID" "COMM" "USER" "MEM" "RSS" "READB" "WRITEB" "RATER" "RATEW" "DATE"

# formatar a informação de cada processo em linhas e dar pipe para o sort
for ((line = 0; line < ${#pids[@]}; line++)); do
	el=${pids[$line]}
	printf "%8s | %-16s | %-10s | %10s | %15s | %15s | %15s | %15s | %15s | %-20s \n" \
		$el "${comm[$el]}" ${user[$el]} ${vmsize[$el]} ${rss[$el]} ${readb[$el]} ${writeb[$el]} ${rater[$el]} ${ratew[$el]} "${datestart[$el]}"
done | sort -t "|" -k $sortCol,$sortCol $numericSort $sortRev | head -n $tableMax
# -t: separador de colunas para o sort
# -k: coluna por qual é feito o sort
# de seguida é feito o pipe do sort para o comando head, que com a opção -n limita o número de linhas de output
