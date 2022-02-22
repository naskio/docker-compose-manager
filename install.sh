#!/bin/bash

##########################################################
########## Docker Compose Manager Installation  ##########
##########################################################


########## Parsing args ##########
VERSION="$1"
if [[ -z "$VERSION" || $1 == "--debug" ]]
then
  VERSION="multi" # default version
fi

DEBUG="false"
if [[ $1 == "--debug" || $2 == "--debug" ]]
then
  DEBUG="true"
else
  DEBUG="false"
fi
########## Parsing args ##########
echo "Version: $VERSION"
echo "Debug: $DEBUG"

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


########## Installing dependencies ##########
case $VERSION in
  "dialog" | "multi")
    echo "Installing Docker Compose Manager - $VERSION ..."
    echo "Installing dependencies ..."
    # check if dialog is installed using which
    dialog_exists=$(which dialog)
    if [ -z "$dialog_exists" ]
    then
      if [ $PLATFORM == "Linux" ]
      then
        echo "Installing dialog on Linux ..."
        apt-get update -y
        apt-get install -y dialog
      fi
      if [ $PLATFORM == "Mac" ]
      then
        echo "Installing dialog on MacOS ..."
        brew update
        brew install dialog
      fi
    else
      echo "dialog is already installed."
    fi
    ;;
  "arrow-keys" | "arrow-keys-v2" | "ps3")
    echo "Installing Docker Compose Manager - $VERSION ..."
    ;;
  *)
    echo "- Invalid option '$VERSION'. Should be: 'dialog', 'multi', 'ps3', 'arrow-keys' or 'arrow-keys-v2'."
    exit 1
    ;;
esac
########## Installing dependencies ##########


########## Installing the script ##########
echo "creating docker-compose-manager directory ..."
mkdir -p /usr/local/lib/docker-compose-manager/
if [ $DEBUG == "true" ]
then
  echo "copying files ..."
  cp ./docker-compose-manager.$VERSION.sh /usr/local/lib/docker-compose-manager/docker-compose-manager.sh
else
  echo "downloading files ..."
  curl -sSL https://raw.githubusercontent.com/naskio/docker-compose-manager/main/docker-compose-manager.$VERSION.sh > /usr/local/lib/docker-compose-manager/docker-compose-manager.sh
fi
echo "adding executable permissions ..."
chmod +x /usr/local/lib/docker-compose-manager/docker-compose-manager.sh
echo "creating symbolic link ..."
ln -s -f /usr/local/lib/docker-compose-manager/docker-compose-manager.sh /usr/local/bin/dcm
echo "Installation done."
########## Installing the script ##########