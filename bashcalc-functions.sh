#!/bin/bash
calc (){
    local v=$1
    #echo "recieving ${v}" 1>&2
    if [ ${#v} -eq 0 ]; then
	echo "Invalid input" 1>&2
        return 1
    fi
    if [[ $v == *'%'* ]]; then
	    cm="bc -l .bcrc"
    else 
	    cm="bc -l"
    fi
    local result=$(echo "$v" | $cm)
    local unsigned=${result#"-"}
    test $unsigned == $result
    local signed=$?
    local first_letter=${unsigned: 0: 1}
    if [ "$first_letter" == "." ] ; then
        result="0$unsigned"
	if [ "${signed}" ]; then
		result="-$result"
	fi
    fi
    #echo "$result" 1>&2    
    echo $result
}


sine (){
    echo $(calc "s($1)")
}

cos (){
    echo $(calc "c($1)")
}

float_lt (){
    echo $(calc "$1<$2")
}

float_lte (){
    echo $(calc "$1<=$2")
}

float_eq (){
    echo $(calc "$1==$2")
}

