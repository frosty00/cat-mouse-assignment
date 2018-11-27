#!/usr/local/bin/bash
# Cat & Mouse Framework
# CS9E - Assignment 4.2

# Framework by Jeremy Huddleston <jeremyhu@cs.berkeley.edu>

# Source the file containing your calculator functions:
. bashcalc-functions.sh

# Todo: write tests!
if [ "${BASH_VERSION:0:1}" -lt 4 ]; then
	echo "Please upgrade to bash 4 or higher to use this script" 1>&2
	exit 1
fi

#set -x
> statelog

function check_argno () {
	local n=$1
	local args=$2
	log "$n args recieved: $args"
	set -- $args
	if (( $# != $n )); then
		log "wrong number of args supplied"
	fi
}

function log () {
	local string="$1"
	if (( ${DEBUG} == 1 )); then
		printf "${string}\n\r" 1>&2
	fi

}

# angle_between <A> <B> <C>
# Returns true (exit code 0) if angle B is between angles A and C and false otherwise
function angle_between {
	log "finding angle between $(echo "$@")"	
	local A=$1
	local B=$2
	local C=$3
	check_argno 3 "$(echo "$@")"

	# ADD CODE HERE FOR PART 1
	local C_A=$(cos "$(calc "$C - $A")")
	local B_A=$(cos "$(calc "$B - $A")")
	local C_B=$(cos "$(calc "$C - $B")")
	local gtCB=$(calc "$C_B > $C_A")
	local gtBA=$(calc "$B_A > $C_A")
	# bitwise 'and' then 'not'
	return $((!(${gtCB} & ${gtBA})))
}


function caught_mouse {
	log "caught mouse called with $(echo "$@")"
	local old_cat_angle=$1
	local new_cat_angle=$2
	local mouse_angle=$3
	local cat_radius=$4
	check_argno 4 "$(echo "$@")" 

	angle_between ${old_cat_angle} ${mouse_angle} ${new_cat_angle}
	local between_exit_code=$?
	local is_at_base="$(calc "${cat_radius} == 1")"
	[[ ${between_exit_code} -eq 0 && ${is_at_base} -eq 1 ]]
}

### Simulation Functions ###
# Variables for the state
RUNNING=0
GIVEUP=1
CAUGHT=2

DEBUG=0

# CONSTANTS
PI="3.1415926"
TAU=$(calc "$PI * 2")



# does_cat_see_mouse <cat angle> <cat radius> <mouse angle>
#
# Returns true (exit code 0) if the cat can see the mouse, false otherwise.
#
# The cat sees the mouse if
# (cat radius) * cos (cat angle - mouse angle)
# is at least 1.0.
function does_cat_see_mouse {
	log "does cat see mouse recieved $(echo "$@")"
	local cat_angle=$1
	local cat_radius=$2
	local mouse_angle=$3
	check_argno 3 "$(echo "$@")"

	# ADD CODE HERE FOR PART 1
	local cos_diff=$(cos "$(calc "${cat_angle} - ${mouse_angle}")")
	local total=$(calc "${cos_diff} * ${cat_radius}")
	local can_see_mouse=$(calc "${total#-} >= 1")
	log "cat can see mouse ${can_see_mouse}"
	test "${can_see_mouse}" -eq 1
}	

# next_step <current state> <current step #> <cat angle> <cat radius> <mouse angle> <max steps>
# returns string output similar to the input, but for the next step:
# <state at next step> <next step #> <cat angle> <cat radius> <mouse angle> <max steps>
#
# exit code of this function (return value) should be the state at the next step.  This allows for easy
# integration into a while loop.
function next_step {
	log "next step recieved $(echo "$@")"
	local state=$1
	local -i step=$2
	local old_cat_angle=$3
	local cat_radius=$4
	local old_mouse_angle=$5
	local -i max_steps=$6

	check_argno 6 "$(echo "$@")" 

	echo "Step: ${step}" 1>&2

	# First, make sure we are still running
	if (( ${state} != ${RUNNING} )) ; then
		echo ${state} ${step} ${old_cat_angle} ${cat_radius} ${old_mouse_angle} ${max_steps}
		return ${state}
	fi

	# ADD CODE HERE FOR PART 2

	# Move the cat first
	does_cat_see_mouse ${old_cat_angle} ${cat_radius} ${old_mouse_angle}
	if [[ $? -eq 0 && ${cat_radius} -gt 1 ]] ; then
		# Move the cat in if it's not at the statue and it can see the mouse
		(( cat_radius-- ))
	        cat_radius="$(( ${cat_radius} > 1 ? ${cat_radius} : 1 ))"
		new_cat_angle="${old_cat_angle}"
	else
		# Move the cat around if it's at the statue or it can't see the mouse
		# Check if the cat caught the mouse
		new_cat_angle=$(calc "${old_cat_angle} + (1.25 / ${cat_radius})")
		if caught_mouse ${old_cat_angle} ${new_cat_angle} ${old_mouse_angle} ${cat_radius}; then
			state=${CAUGHT}
			new_mouse_angle="${old_mouse_angle}"
		fi
	fi

	# Now move the mouse if it wasn't caught
	if (( ${state} == ${RUNNING} )); then
		# Move the mouse
		local angle_change=$(calc "${PI} / 6") 
		new_mouse_angle=$(calc "${old_mouse_angle} + ${angle_change}")
		new_cat_angle=$(calc "${new_cat_angle} % ${TAU}")
		new_mouse_angle=$(calc "${new_mouse_angle} % ${TAU}")
	fi
	# Give up if we're at the last step and haven't caught the mouse
	if (( ${step} == ${max_steps} )); then
		state=${GIVEUP}
	fi

	(( step++ ))


	echo "${state} ${step} ${new_cat_angle} ${cat_radius} ${new_mouse_angle} ${max_steps}"
	return ${state}
}

### Main Script ###

# ADD CODE HERE FOR PART 3
function print_dict {
	local -n dict=$1
	for key in "${!dict[@]}"
	do 
		echo "${key} - ${dict[${key}]}"
       	done
}

function get_values {
	local -n keys=$1
	local -n dict=$2
	for key in "${keys[@]}"
	do
		printf "${dict[${key}]} "
	done
}


function transform {
	echo "$1" | sed 's/\(.\+\) \(.\+\) \(.\+\) \(.\+\) \(.\+\) \(.\+\)/state=\1 steps=\2 cat_angle=\3 cat_radius=\4 mouse_angle=\5 max_steps=\6/'
}

function wrap {
	# initialise variables
	local old_cat_angle=$(calc "${PI} / 2")
	declare -A defaults
	defaults=( [state]=${RUNNING}  [step]=0 [cat_angle]="${old_cat_angle}" [cat_radius]=5 [mouse_angle]=0 [max_steps]=30 )
	declare -a order
	order=( state step cat_angle cat_radius mouse_angle max_steps )
	local len=${#defaults[@]}
	echo -e "The current settings are:\n$(print_dict defaults)"
	echo "Please select the value you would like to change:"
	select option in "${!defaults[@]}" "DEBUG" "continue"; do
		# case matching doesn't accept variable 
		match=$(echo "${!defaults[@]}" | sed 's/ /\n/g' | grep -e "^$option$")
		echo "$match" "$option"
		case ${option} in
			"$match")  
				echo "Select a value for ${option}:"
				read value
				echo "Setting ${option} to ${value}" 
				defaults[${option}]=${value}
				;;
			"continue") 
				break
				;;
			"DEBUG")
				DEBUG=1
				;;
			*)
				echo "Invalid input - ${option}, please try again (select 1-$((${len}+1)))"
				;;
		esac
	done
	
	current_state=$(get_values order defaults)
	while (( $? == ${RUNNING} ))
	do
		transform "${current_state}" 
		current_state=$(next_step ${current_state})
	done >> statelog
	transform "${current_state}" >> statelog
}

