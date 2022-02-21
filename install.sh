#!/bin/bash

##########################################################
########## Docker Compose Manager Installation  ##########
##########################################################


########## Parsing args ##########
VERSION="$1"
if [[ -z "$VERSION" || $1 == "--debug" ]]
then
  VERSION="arrow-keys"
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
  "dialog")
    echo "Installing Docker Compose Manager - $VERSION ..."
    echo "Installing dependencies ..."
    if [ $PLATFORM=="Linux" ]; then
      sudo apt-get update -y
      sudo apt-get install -y dialog
    fi
    if [ $PLATFORM=="Mac" ]; then
      brew update
      brew install dialog
    fi
    ;;
  "arrow-keys")
    echo "Installing Docker Compose Manager - $VERSION ..."
    ;;
  "ps3")
    echo "Installing Docker Compose Manager - $VERSION ..."
    ;;
  *)
    echo "- Invalid option '$VERSION'. Should be: 'dialog', 'ps3' or 'arrow-keys'."
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
ln -s -f /usr/local/lib/docker-compose-manager/docker-compose-manager.sh /usr/local/bin/dcmanager
echo "Installation done."
########## Installing the script ##########