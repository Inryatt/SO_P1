#!/bin/bash

# Projeto 1 de SO
# NMec 97880: Camila Fonseca
# NMec 97606: Diogo Monteiro

############ Inicialização de variáveis ###############
sortCol=2
sortRev=""		# "-r" para reverse, "" para normal
numericSort=""	# "-n" para sort numérico, "" para alfabético
tableMax=-1
regexNum="^[0-9]+$"

############# verificação da existencia do s  ######################
#Está logo ao início para dar feedback instantâneo ao utilizador em caso de erro.

if [[ $# -lt 1 ]]; then		# tem de haver pelo menos 1 argumento
	# o script nunca pode ser corrido sem qualquer argumento.
	echo "ERRO: Falta o intervalo de tempo. Usage: ./procstat.sh <optional filter/sort flags> <timeInterval>"  
	exit 1
fi

s=${@: -1}	#Definimos s como o último argumento passado ao programa.

#Verificação de que se o último argumento é um número, e maior do que 0.
if [[ "$s" =~ $regexNum ]] && [[ "$s" -gt 0 ]] ; then
	:
else
	echo "ERRO: O intervalo de tempo é inválido"
	exit 1
fi

#############  get PIDs  #############

pids=($(ls /proc/ -v | grep '[0-9]'))

for ((el = 0; el < ${#pids[@]}; el++)); do
	# verficar se a informação do processo pode ser lida, caso contrário,
	# descarta-se já os PIDs que não queremos para não ser necessário 
	# efetuar tantos acessos desnecessários aos ficheiros mais tarde
	if [[ $(cat /proc/${pids[$el]}/status 2>/dev/null) != "" ]] \
		&& [[ $(cat /proc/${pids[$el]}/io 2>/dev/null) != "" ]] ; then			
		:
	else
		toUnset+=($el)
	fi
done

#Ao remover elementos, temos agora 'falhas' no array que contém os PIDs
#Para resolver isto, copiamos o array para um temporário, e de volta
#de maneira que os elementos do array ficam todos sequenciais.
for el in ${toUnset[@]}; do
	unset -v 'pids[$el]'
done
unset toUnset

for el in ${pids[@]}; do
	tmp_pids+=($el)
done
unset pids

for el in ${tmp_pids[@]}; do
	pids+=($el)
done
unset tmp_pids


#############  process options given  #############

while getopts "c:s:e:u:p:wmtdrh" options; do

	case "${options}" in

	c)	#Filtrar COMM por regex 

		# Todos as opções de sort funcionam desta maneira. São recolhidos os elementos
		# do array de PIDs que não verificam a condição definida, e depois são removidos do
		# array. Mais tarde, quando se guarda a informação relativa a cada processo, já não se 
		# recolhe aquela relativa aos removidos, poupando assim tempo e acessos aos ficheiros 
		# no disco.

		toUnset=()
		filterRegex="$OPTARG"

		for ((el = 0; el < ${#pids[@]}; el++)); do
			if ! [[ $(cat /proc/${pids[$el]}/comm 2>/dev/null) =~ $filterRegex ]]; then
				toUnset+=($el)
			fi
		done

		for el in ${toUnset[@]}; do
			unset -v 'pids[$el]'
		done
		unset toUnset

		for el in ${pids[@]}; do
			tmp_pids+=($el)
		done
		unset pids

		for el in ${tmp_pids[@]}; do
			pids+=($el)
		done
		unset tmp_pids

		# Em caso de não haver qualquer match no regex inserido, é apresentada
		# uma mensagem de erro, e o script é abortado.
		if [[ ${#pids[@]} == 0 ]]; then
			echo "Nenhum processo válido encontrado que corresponda ao regex inserido."
			echo "Verifique o argumento introduzido e tente de novo."
			exit 1
		fi
		;;

	s)	# Filtrar Data Mínima

		# Verifica-se se a data passada está num formato aceite pelo bash (GNU date)
		if ! [[ $(date -d "$OPTARG") ]]; then
			echo "Data inválida, por favor insira uma data no formato de GNU date"
			echo "Um dos formatos aceites é  <hora>:<minutos>:<segundos>"
			echo "Por exemplo, 15:44:12."
			exit 1
		fi

		# Converte-se a data passada para formato Unix time, que é o número de segundos
		# passados desde 1970-01-01, e permite-nos comparar datas muito facilmente.
		MIN_DATE=$(date "+%s" -d "$OPTARG")
		
		for ((el = 0; el < ${#pids[@]}; el++)); do
			tmp_date=$(ps -p ${pids[$el]} -o lstart | tail -1 | cut -c 5-25) 

			#Converte-se também a data de ínicio do processo para Unix time.
			tmp_date=$(date "+%s" -d "$tmp_date")

			#Comparamos as duas datas, que estão dadas em segundos.
			if  [[ $tmp_date -lt $MIN_DATE ]]; then
				toUnset+=($el)
			fi
		done	

		#Quaisquer processos (PIDs) que não passem na condição desejada são descartados
		for el in ${toUnset[@]}; do
			unset -v 'pids[$el]'
		done
		unset toUnset

		for el in ${pids[@]}; do
			tmp_pids+=($el)
		done
		unset pids

		for el in ${tmp_pids[@]}; do
			pids+=($el)
		done
		unset tmp_pids
		;;

	e)	# Filtrar Data Máxima

		# Verifica-se se a data passada está num formato aceite pelo bash (GNU date)
		if ! [[ $(date -d "$OPTARG") ]]; then
			echo "Data inválida, por favor insira uma data no formato de GNU date"
			echo "Um dos formatos aceites é  <hora>:<minutos>:<segundos>"
			echo "Por exemplo, 15:44:12."
			exit 1
		fi

		# Converte-se a data passada para formato Unix time, que é o número de segundos
		# passados desde 1970-01-01, e permite-nos comparar datas muito facilmente.
		MAX_DATE=$(date "+%s" -d "$OPTARG")
		
		for ((el = 0; el < ${#pids[@]}; el++)); do
			tmp_date=$(ps -p ${pids[$el]} -o lstart | tail -1 | cut -c 5-25)

			#Converte-se também a data de ínicio do processo para Unix time.
			tmp_date=$(date "+%s" -d "$tmp_date")

			#Comparamos as duas datas, que estão dadas em segundos.
			if  [[ $tmp_date -gt $MAX_DATE ]] ; then
				toUnset+=($el)
			fi
		done	
		
		#Quaisquer processos (PIDs) que não passem na condição desejada são descartados
		for el in ${toUnset[@]}; do
			unset -v 'pids[$el]'
		done
		unset toUnset

		for el in ${pids[@]}; do
			tmp_pids+=($el)
		done
		unset pids

		for el in ${tmp_pids[@]}; do
			pids+=($el)
		done
		unset tmp_pids
		;;

	u)	#Filtrar por Username

		toUnset=()
		filterUser="$OPTARG"

		for ((el = 0; el < ${#pids[@]}; el++)); do
			if [[ "$(ps -p ${pids[$el]} -o user= 2>/dev/null)" != "$filterUser" ]]; then
				toUnset+=($el)
			fi
		done

		for el in ${toUnset[@]}; do
			unset -v 'pids[$el]'
		done
		unset toUnset

		for el in ${pids[@]}; do
			tmp_pids+=($el)
		done
		unset pids

		for el in ${tmp_pids[@]}; do
			pids+=($el)
		done
		unset tmp_pids

		# Em caso de não haver qualquer processo correspondente ao utilizador inserido,
		# é apresentada uma mensagem de erro, e o script é abortado.
		if [[ ${#pids[@]} == 0 ]]; then
			echo "Nenhum processo válido encontrado para o utilizador inserido."
			echo "Verifique o argumento introduzido e tente de novo."
			exit 1
		fi
		;;

	p)	# Limita número de processos apresentados na tabela final.
		
		if [[ "$OPTARG" =~ $regexNum ]] && [[ "$OPTARG" -gt 0 ]]; then
			tableMax=$OPTARG
		else
			echo "Erro: O número de processos é inválido"
			exit 1
		fi
		;;

	w)	# Ordenar por valor de RATEW (Crescente)
		
		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=9
		numericSort="-n"
		;;

	m)	# Ordenar por valor de MEM (Crescente)

		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=4
		numericSort="-n"
		;;

	t)	# Ordenar por valor de RSS (Crescente)

		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=5
		numericSort="-n"
		;;

	d)	# Ordenar por valor de RATER (Crescente)
		
		if [[ $sortCol -ne 2 ]]; then
			echo "WARNING - mais que uma opção de sort foi dada, apenas a última será considerada"
		fi
		sortCol=8
		numericSort="-n"
		;;

	r)	# Inverter a ordem de sort (Passa a Decrescente)

		sortRev="-r"
		;;

	:)

		echo "Erro- ${options} requires an optional argument!"
		exit 1
		;;

	*)
		echo "ERRO-Opção Inválida;"
		exit 1
		;;
	esac
done

shift $((OPTIND -1))	# remover argumentos opcionais processados, o argumento de tempo passa a ser $1

############ Check if there's any processes left to display ##########

if [[ ${#pids[@]} == 0 ]]; then
	echo "Nenhum processo encontrado que corresponda aos critérios pedidos."
	echo "Verifique as opções selecionadas e tente de novo."
	exit 1
fi

#############  re-validate given time argument  #############

#isto é para evitar casos como ./procstat.sh -p 5, em que 5 é considerado o argumento de -p e o intervalo de tempo
if [[ $# -lt 1 ]]; then		# se não existem argumentos, então afinal não foi dado intervalo de tempo
	echo "ERRO: Falta o intervalo de tempo. Usage: ./procstat.sh <optional filter/sort flags> <timeInterval>"  
	exit 1
fi


#############  Ir buscar a informação de cada processo  #############

for el in ${pids[@]}; do
	comm[$el]=$(cat /proc/$el/comm 2>/dev/null)
	user[$el]=$(ps -aux | awk '{print $1 " " $2} ' 2>/dev/null | grep -w $el | awk '{print $1}')
	vmsize[$el]=$(cat /proc/$el/status 2>/dev/null | grep VmSize | awk '{print $2}')
	rss[$el]=$(cat /proc/$el/status 2>/dev/null | grep VmRSS | awk '{print $2}')
	datestart[$el]=$(ps -p $el -o lstart | tail -1 | cut -c 5-25)
	readb[$el]=$(cat /proc/$el/io 2>/dev/null | grep rchar | awk '{print $2}')
	writeb[$el]=$(cat /proc/$el/io 2>/dev/null | grep wchar | awk '{print $2}')
done

sleep $s	# Este sleep corresponde ao intervalo de tempo inserido pelo utilizador
		# para calcular RATER e RATEW

for ((el=0; el < ${#pids[@]}; el++)); do
	newread=$(cat /proc/${pids[$el]}/io 2>/dev/null | grep rchar | awk '{print $2}')
	newwrite=$(cat /proc/${pids[$el]}/io 2>/dev/null | grep wchar | awk '{print $2}')

	# usar a funcionalidade 'herestring (<<<)' para dar comandos ao bc
	# scale corresponde ao número de casas decimais

	rater[${pids[$el]}]=$(bc <<<"scale=2;( $newread - ${readb[${pids[$el]}]})/$s") 
	ratew[${pids[$el]}]=$(bc <<<"scale=2;( $newwrite - ${writeb[${pids[$el]}]})/$s")

	# remover processos cujo rater ou ratew seja negativo
	# (isto acontece quando um processo termina a meia da execução de procstat)
	if [[ $(bc <<<"${ratew[${pids[$el]}]} < 0") -eq 1 ]] || [[ $(bc <<<"${rater[${pids[$el]}]} < 0") -eq 1 ]]; then
		toUnset+=($el)
	fi
done

for bad_el in ${toUnset[@]}; do
	unset -v 'pids[$bad_el]'
done
unset toUnset

for bad_el in ${pids[@]}; do
	tmp_pids+=($bad_el)
done
unset pids

for bad_el in ${tmp_pids[@]}; do
	pids+=($bad_el)
done
unset tmp_pids

#############  Formatar data, ordenar, e imprimir tabela  #############

if [[ $tableMax -eq -1 ]]; then
	tableMax=${#pids[@]}
fi

printf "%8s | %-16s | %-10s | %10s | %15s | %15s | %15s | %15s | %15s | %20s \n" \
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
exit 0
