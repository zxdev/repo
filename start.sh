#! /bin/sh

rm -fr .git
git init

if [[ "$1" ]]; then 
  echo "initializing go.mod"
  rm go.mod
  go mod init $1
fi

rm start.sh
