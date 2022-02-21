#!/bin/bash
##########################################################
########## Docker Compose Manager, arrow-keys V2 #########
########## Tested on: macOS, Linux                  ######
##########################################################


########## Parsing arguments ##########
ROOT_DIR="$1"

# set default value for root directory
if [ -z "$ROOT_DIR" ]; then
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
function select_option {
    # little helpers for terminal print control and key input
    ESC=$( printf "\033")
    cursor_blink_on()  { printf "$ESC[?25h"; }
    cursor_blink_off() { printf "$ESC[?25l"; }
    cursor_to()        { printf "$ESC[$1;${2:-1}H"; }
    print_option()     { printf "   $1 "; }
    print_selected()   { printf "  $ESC[7m $1 $ESC[27m"; }
    get_cursor_row()   { IFS=';' read -sdR -p $'\E[6n' ROW COL; echo ${ROW#*[}; }
    key_input()        { read -s -n3 key 2>/dev/null >&2
                         if [[ $key = $ESC[A ]]; then echo up;    fi
                         if [[ $key = $ESC[B ]]; then echo down;  fi
                         if [[ $key = ""     ]]; then echo enter; fi; }
    # initially print empty new lines (scroll down if at bottom of screen)
    for opt; do printf "\n"; done
    # determine current screen position for overwriting the options
    local lastrow=`get_cursor_row`
    local startrow=$(($lastrow - $#))
    # ensure cursor and input echoing back on upon a ctrl+c during read -s
    trap "cursor_blink_on; stty echo; printf '\n'; exit" 2
    cursor_blink_off
    local selected=0
    while true; do
        # print options by overwriting the last lines
        local idx=0
        for opt; do
            cursor_to $(($startrow + $idx))
            if [ $idx -eq $selected ]; then
                print_selected "$opt"
            else
                print_option "$opt"
            fi
            ((idx++))
        done
        # user key control
        case `key_input` in
            enter) break;;
            up)    ((selected--));
                   if [ $selected -lt 0 ]; then selected=$(($# - 1)); fi;;
            down)  ((selected++));
                   if [ $selected -ge $# ]; then selected=0; fi;;
        esac
    done
    # cursor position back to normal
    cursor_to $lastrow
    printf "\n"
    cursor_blink_on
    return $selected
}

function select_opt {
    select_option "$@" 1>&2
    local result=$?
    echo $result
    return $result
}

########## User Interface ##########


########## Commands ##########
run_docker_compose_operation () {
  clear
  echo "----- Stack '$(basename $1)' -----"
  stack_status=""
  running_services=""
  get_stack_status "$1"
  echo "- status: $stack_status"
  if [ "$stack_status" == "up" ]
  then
    echo "- running services: $running_services"
  fi
  echo "- located at: $1"
  echo "Select the operation: "

  local options=("up" "down" "restart" "resync" "upgrade" "Quit")
  select_option "${options[@]}"
  local choice=$?
  local operation="${options[$choice]}"

  if [ "$operation" != "Quit" ]
  then
    echo "- running command '$operation' at '$1'..."
  fi
  case $operation in
      "resync") cd $1; docker-compose down && git pull && docker-compose up -d ;cd $CURRENT_DIR;exit;;
      "upgrade") cd $1; docker-compose down && docker-compose pull && docker-compose up -d ;cd $CURRENT_DIR;exit;;
      "restart") cd $1 && docker-compose down && docker-compose up -d ;cd $CURRENT_DIR;exit;;
      "up") cd $1; docker-compose up -d ;cd $CURRENT_DIR;exit;;
      "down") cd $1; docker-compose down ;cd $CURRENT_DIR;exit;;
      "Quit") clear;exit;;
      *) echo "Invalid options. operation '$REPLY' at folder '$1'.";exit;;
  esac
}
########## Commands ##########


########## Main ##########
clear
echo "----- Welcome to Docker Compose Manager -----"
echo "- Current directory: $CURRENT_DIR"
echo "- Looking for docker-compose.ya?ml files in: $ROOT_DIR ..."
echo "---------------------------------------------"
echo "Select the stack: "
options=("${array[@]}" "Quit")
select_option "${options[@]}"
choice=$?
stack="${options[$choice]}"
case $stack in
  "Quit")
    clear
    exit
    ;;
  *)
    run_docker_compose_operation $stack
    exit
    ;;
esac
########## Main ##########