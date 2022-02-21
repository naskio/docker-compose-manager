#!/bin/bash
##########################################################
########## Docker Compose Manager, using arrow keys ######
##########################################################


########## Parsing arguments ##########
ROOT_DIR="$1"

# set default value for root directory
if [ -z "$ROOT_DIR" ]; then
  # ROOT_DIR="$HOME"
  ROOT_DIR=$(pwd)
fi
########## Parsing arguments ##########


########## Setup Vars ##########
CURRENT_DIR=$(pwd)
ROOT_DIR=$(realpath $ROOT_DIR)
########## Setup Vars ##########


########## Getting the platform ##########
PLATFORM=""
UNAME_OUT="$(uname -s)"
case "$UNAME_OUT" in
    Linux*)     PLATFORM=Linux;;
    Darwin*)    PLATFORM=Mac;;
    CYGWIN*)    PLATFORM=Cygwin;;
    MINGW*)     PLATFORM=MinGw;;
    *)          PLATFORM="UNKNOWN:${UNAME_OUT}"
esac
########## Getting the platform ##########


########## Getting stacks ##########
array=()
init_array() {
  tmp_array=()
  # get docker-compose.yml files
  if [ "$PLATFORM" = "Mac" ]
  then
    while IFS=  read -r -d $'\n'; do
    tmp_array+=("$REPLY")
    done < <(find -E $ROOT_DIR -type f -regex .*/docker-compose.ya?ml | sort -u)
  elif [ "$PLATFORM" = "Linux" ]
  then
    while IFS=  read -r -d $'\n'; do
    tmp_array+=("$REPLY")
    done < <(find $ROOT_DIR -type f -regex .*/docker-compose.ya?ml | sort -u)
  fi

  # map file to parent dir
  for i in "${tmp_array[@]}"
  do
    parent=$(dirname $i)
    array+=("$(realpath $parent)")
  done
}
init_array
########## Getting stacks ##########


########## Get stack status ##########
get_stack_status() {
  second_line=$(cd "$1"; docker-compose ps --services)
  if [[ "$second_line" =~ ^[[:space:]] || -z "$second_line" || $second_line == "" ]]
  then
    running_services=""
    stack_status="down"
  else
    stack_status="up"
    running_services=$(echo "$second_line" | tr '\n\r' ' ')
  fi
}
########## Get stack status ##########


########## User Interface ##########
function print_menu()
{
	local header_text="$1"
	shift
	local selected_item="$1"
	shift
	local menu_items=($@)
	local menu_size="${#menu_items[@]}"

  echo "----- Welcome to Docker Compose Manager -----"
  echo "$header_text"
	for (( i = 0; i < $menu_size; ++i ))
	do
		if [ "$i" = "$selected_item" ]
		then
			echo "$i ---> ${menu_items[i]}"
		else
			echo "$i -    ${menu_items[i]}"
		fi
	done
}

function run_menu()
{
	local header_text="$1"
	shift

	local selected_item="$1"
	shift

	local menu_items=($@)
	local menu_size="${#menu_items[@]}"
	local menu_limit=$((menu_size - 1))

	clear
	print_menu "$header_text" "$selected_item" "${menu_items[@]}"

	while read -rsn1 input
	do
		case "$input"
		in
			$'\x1B')  # ESC ASCII code (https://dirask.com/posts/ASCII-Table-pJ3Y0j)
				read -rsn1 -t 0.1 input
				if [ "$input" = "[" ]  # occurs before arrow code
				then
					read -rsn1 -t 0.1 input
					case "$input"
					in
						A)  # Up Arrow
							if [ "$selected_item" -ge 1 ]
							then
								selected_item=$((selected_item - 1))
								clear
								print_menu "$header_text" "$selected_item" "${menu_items[@]}"
							else
							  selected_item=$menu_limit
							  clear
							  print_menu "$header_text" "$selected_item" "${menu_items[@]}"
							fi
							;;
						B)  # Down Arrow
							if [ "$selected_item" -lt "$menu_limit" ]
							then
								selected_item=$((selected_item + 1))
								clear
								print_menu "$header_text" "$selected_item" "${menu_items[@]}"
              else # selected_item = menu_limit
                selected_item=0
                clear
                print_menu "$header_text" "$selected_item" "${menu_items[@]}"
							fi
							;;
					esac
				fi
				read -rsn5 -t 0.1  # flushing stdin
				;;
			"")  # Enter key
				return "$selected_item"
				;;
		esac
	done
}
########## User Interface ##########


########## Get stack ##########
SELECTED_FOLDER=""
select_folder(){
  tmp_array=("${array[@]}")
  tmp_array+=("Quit")
  SELECTED_STACK_INDEX=0
  MENU_HEADER1="=> Select the stack: "
  run_menu "$MENU_HEADER1" "$SELECTED_STACK_INDEX" "${tmp_array[@]}"
  SELECTED_FOLDER="${tmp_array[$?]}"
  clear
  if [ "$SELECTED_FOLDER" = "Quit" ]  # Quit
  then
    clear
    exit 0
  fi
}
select_folder
########## Get stack ##########


########## Get operation ##########
SELECTED_OPERATION=""
select_operation(){
  # get 2nd header
  MENU_HEADER2="=> Select the operation: "
  MENU_HEADER2="$MENU_HEADER2 Stack '$(basename $1)'"
  stack_status=""
  running_services=""
  get_stack_status "$1"
  MENU_HEADER2="$MENU_HEADER2 | Status '$stack_status'"
  if [ "$stack_status" == "up" ]
  then
    MENU_HEADER2="$MENU_HEADER2 | running services: $running_services"
  fi
  MENU_HEADER2="$MENU_HEADER2 | located at '$1'"

  # select operation
  operations=("up" "down" "restart" "upgrade" "resync" "Quit")
  SELECTED_OPERATION_INDEX=0
  run_menu "$MENU_HEADER2" "$SELECTED_OPERATION_INDEX" "${operations[@]}"
  SELECTED_OPERATION="${operations[$?]}"
  clear
  if [ "$SELECTED_OPERATION" = "Quit" ]  # Quit
  then
    clear
    exit 0
  fi
}
select_operation $SELECTED_FOLDER
########## Get operation ##########


########## Commands ##########
run_docker_compose_operation () {
  clear
  echo "----- Stack '$(basename $1)' -----"
  echo "- status: $stack_status"
  if [ "$stack_status" == "up" ]
  then
    echo "- running services: $running_services"
  fi
  echo "- located at: $1"
  echo "- running command '$2' at '$1'..."
  case $2 in
    "resync") cd $1; docker-compose down && git pull && docker-compose up -d ;cd $CURRENT_DIR;exit;;
    "upgrade") cd $1; docker-compose down && docker-compose pull && docker-compose up -d ;cd $CURRENT_DIR;exit;;
    "restart") cd $1 && docker-compose down && docker-compose up -d ;cd $CURRENT_DIR;exit;;
    "up") cd $1; docker-compose up -d ;cd $CURRENT_DIR;exit;;
    "down") cd $1; docker-compose down ;cd $CURRENT_DIR;exit;;
    "Quit") exit;;
    *) echo "Invalid options operation '$2' at folder '$1'.";exit;;
  esac
}
########## Commands ##########


########## Main ##########
case $SELECTED_FOLDER in
  "Quit")
    exit
    ;;
  *)
    run_docker_compose_operation $SELECTED_FOLDER $SELECTED_OPERATION
    exit
    ;;
esac
########## Main ##########