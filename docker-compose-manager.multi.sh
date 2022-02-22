#!/bin/bash
##########################################################
########## Docker Compose Manager, dialog        #########
########## run the same command on multi stacks  #########
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


########## Get array stack status ##########
array_stack_status=()
array_running_services=()
get_array_stack_status() {
  for st in "${array[@]}" ; do
    second_line=$(cd "$st"; docker-compose ps --services) # add 2>/dev/null to disable WARNING
    if [[ "$second_line" =~ ^[[:space:]] || -z "$second_line" || $second_line == "" ]]
    then
      running_services=""
      stack_status="down"
    else
      stack_status="up"
      running_services=$(echo "$second_line" | tr '\n\r' ' ')
    fi
    array_stack_status+=("$stack_status")
    array_running_services+=("$running_services")
  done
}
get_array_stack_status
########## Get array stack status ##########


########## Getting stacks as string ##########
array_string=""
for i in "${!array[@]}"; do
    array_string+="$((i + 1)) (${array_stack_status[$i]})->${array[$i]} off " # multiple selection
done
########## Getting stacks as string ##########


########## Operations as string ##########
operations=("up" "down" "restart" "upgrade" "resync")
operations_string=""
for i in "${!operations[@]}"; do
    operations_string+="$((i + 1)) ${operations[$i]} " # single selection
done
########## Operations as string ##########


########## Get operation ##########
SELECTED_OPERATION=""
select_operation(){
  TMP_FILE=$(mktemp)
  dialog --ok-label "NEXT" --cancel-label "QUIT" --menu "Select the operation: " 0 0 0 $operations_string 2>$TMP_FILE
  operation_index=$(cat $TMP_FILE)
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
select_operation
########## Get operation ##########


########## Get stacks ##########
SELECTED_FOLDER_INDEXES=()
SELECTED_FOLDERS=()
select_folder(){
  # get stack
  TMP_FILE=$(mktemp)
  if [ -z "$array" ]
  then
    echo "No stacks detected"
    exit
  fi
  dialog --ok-label "RUN" --cancel-label "QUIT" --checklist "Select stacks (selected: '$SELECTED_OPERATION'):" 0 0 0 $array_string 2>$TMP_FILE
  stack_indexes=$(cat $TMP_FILE)
  rm $TMP_FILE
  # clear
  if [[ -z $stack_indexes ]]
  then
    clear
    exit 0
  else
    stack_indexes=( "$stack_indexes" ) # convert string to array of indexes
    for i in $stack_indexes; do
      stack=${array[$((i - 1))]}
      SELECTED_FOLDERS+=("$stack")
      SELECTED_FOLDER_INDEXES+=($((i - 1)))
    done
  fi
}
select_folder
########## Get stacks ##########


########## Commands ##########
run_docker_compose_operation () {
  echo "----- Stack '$(basename $1)' -----"
  echo "- status: $3"
  if [ "$3" == "up" ]
  then
    echo "- running services: $4"
  fi
  echo "- located at: $1"
  echo "- running command '$2' at '$1'..."
  case $2 in
    "resync")
      cd $1; docker-compose down && git pull && docker-compose up -d ;cd $CURRENT_DIR;
      ;;
    "upgrade")
      cd $1; docker-compose down && docker-compose pull && docker-compose up -d ;cd $CURRENT_DIR;
      ;;
    "restart")
      cd $1 && docker-compose down && docker-compose up -d ;cd $CURRENT_DIR;
      ;;
    "up")
      cd $1; docker-compose up -d ;cd $CURRENT_DIR;
      ;;
    "down")
      cd $1; docker-compose down ;cd $CURRENT_DIR;
      ;;
    "Quit")
      exit;
      ;;
    *)
      echo "ERROR: Invalid options operation '$2' at folder '$1'.";
      ;;
  esac
}
########## Commands ##########


########## Main ##########
if (( ${#SELECTED_FOLDERS[@]} != 0 )); then
  clear
  for i in ${SELECTED_FOLDER_INDEXES[*]} ; do
    run_docker_compose_operation "${array[$i]}" "$SELECTED_OPERATION" "${array_stack_status[$i]}" "${array_running_services[$i]}"
  done
  exit
else # No stacks selected.
  clear
  exit 0
fi
########## Main ##########