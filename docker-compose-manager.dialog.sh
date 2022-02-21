#!/bin/bash
##########################################################
########## Docker Compose Manager, dialog        #########
########## Tested on: macOS, Linux               #########
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


########## Getting stacks as string ##########
array_string=""
for i in "${!array[@]}"; do
#    array_string+="$((i + 1)) ${array[$i]} off " # multiple selection
    array_string+="$((i + 1)) ${array[$i]} " # single selection
done
########## Getting stacks as string ##########

########## Operations as string ##########
operations=("up" "down" "restart" "upgrade" "resync")
operations_string=""
for i in "${!operations[@]}"; do
    operations_string+="$((i + 1)) ${operations[$i]} " # single selection
done
########## Operations as string ##########


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


########## Get stack ##########
SELECTED_FOLDER=""
select_folder(){
  # get stack
  TMP_FILE=$(mktemp)
  dialog --ok-label "NEXT" --cancel-label "QUIT" --menu "Select the stack:" 0 0 0 $array_string 2>$TMP_FILE
  stack_index=$(cat $TMP_FILE) # index of stack
  rm $TMP_FILE
  #  clear
  if [ $stack_index ]
  then
      SELECTED_FOLDER=${array[$((stack_index - 1))]}
  else # No stack selected
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
  MENU_HEADER2="Select the operation: "
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

  TMP_FILE=$(mktemp)
  dialog --ok-label "RUN" --cancel-label "QUIT" --menu "$MENU_HEADER2" 0 0 0 $operations_string 2>$TMP_FILE
  operation_index=$(cat $TMP_FILE) # index of stack
  rm $TMP_FILE
  #  clear
  if [ $operation_index ]
  then
      SELECTED_OPERATION=${operations[$((operation_index - 1))]}
  else # No operation selected
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
    clear
    exit
    ;;
  *)
    run_docker_compose_operation $SELECTED_FOLDER $SELECTED_OPERATION
    exit
    ;;
esac
########## Main ##########