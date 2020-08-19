#/bin/bash
#INFO
#----------------------------------------------------------------
# Coded by jjavieralv
# version 4.0
# git reference: https://github.com/Telefonica/smartwifi_devops_scripts/blob/master/bajas_date.sh
# Explanation: This script is designed to remove lines which date is out parameters
#----------------------------------------------------------------
#SETTING UP GLOBAL VARIABLES 
#First field must be below $FIRST_BELOW days
FIRST_BELOW=30
#Second field must be upper $SECOND_UPPER days
SECOND_UPPER=60
INPUT_FILE="$1"

#INDIVIDUAL FUNCTIONS
function red_messages() {
  #crittical and error messages
  echo -e "\n\033[31m$1\e[0m\n"
}

function green_messages() {
  #starting functions and OK messages
  echo -e "\n\033[32m$1\e[0m\n"
}

function magenta_messages(){
  #what part which is executting
  echo -e "\n\e[45m$1\e[0m\n"
}

function process_file(){
	green_messages "Processing file $1"
	gawk  -v firstdias="$FIRST_BELOW" -v seconddias="$SECOND_UPPER" -v current=$(date +%s) -F '<#>' '{
	first=substr($7,0,10);
	split(first,a,"/");
	firstabs = mktime(sprintf("%d %d %d 0 0 0 0",a[3],a[2],a[1]));
	firstabs = (current - firstabs)/86400;
	if (firstabs > firstdias)
		print $0;
	else
		second=substr($8,0,10);
		split(second,b,"/");
		secondabs = mktime(sprintf("%d %d %d 0 0 0 0",b[3],b[2],b[1]));
		secondabs = (current - secondabs)/86400;
		if(secondabs < seconddias)
			print $0;
	}' "$INPUT_FILE" >"$OUTPUT_FILE"
}

function remove_empty_lines(){
	green_messages "Deleting empty lines of $INPUT_FILE"
	sed '/^$/d' "$INPUT_FILE">tmp;mv tmp "$INPUT_FILE"
	green_messages "Empty lines deleted"
}


#STRUCTURAL FUNCTIONS
function prepare_values(){
	#check if input file exists
	green_messages " Selected file:  $INPUT_FILE"
	if test -f "$INPUT_FILE"; then
		green_messages "  File exists"
		OUTPUT_FILE="OUTPUT_$INPUT_FILE"
		rm "$OUTPUT_FILE"
	else
		red_messages "  File NOT exists. Exit"
		exit
	fi
}



#UNIQUE MAIN FUNCTION
function main(){
	prepare_values
	remove_empty_lines 
	process_file
	green_messages "File processed :)"
}

main
