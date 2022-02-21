#!/bin/bash
##########################################################
########## Docker Compose Manager, based on PS3 ##########
########## Tested on: macOS, Linux              ##########
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
  PS3="Select the operation: "
  select operation in up down restart resync upgrade Quit; do
    if [ "$operation" != "Quit" ]
    then
      echo "- running command '$operation' at '$1'..."
    fi
    case $operation in
        "resync") cd $1; docker-compose down && git pull && docker-compose up -d ;cd $CURRENT_DIR;break;;
        "upgrade") cd $1; docker-compose down && docker-compose pull && docker-compose up -d ;cd $CURRENT_DIR;break;;
        "restart") cd $1 && docker-compose down && docker-compose up -d ;cd $CURRENT_DIR;break;;
        "up") cd $1; docker-compose up -d ;cd $CURRENT_DIR;break;;
        "down") cd $1; docker-compose down ;cd $CURRENT_DIR;break;;
        "Quit") clear;break;;
        *) echo "Invalid options. operation '$REPLY' at folder '$1'.";break;;
    esac
  done
}
########## Commands ##########


########## Main ##########
clear
echo "----- Welcome to Docker Compose Manager -----"
echo "- Current directory: $CURRENT_DIR"
echo "- Looking for docker-compose.ya?ml files in: $ROOT_DIR ..."
echo "---------------------------------------------"
PS3="Select the stack: "
select stack in "${array[@]}" "Quit"; do
  case $stack in
      "Quit") clear;break;;
      *) run_docker_compose_operation $stack;break;;
  esac
done
########## Main ##########