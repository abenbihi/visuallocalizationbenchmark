#!/bin/sh

if [ "$#" -ne 1 ]; then
  echo "Error: wrong number of arguments."
  echo "1. xp_dir"
  exit 1
fi

xp_dir="$1"
if [ -d "$xp_dir" ]; then
  while true; do
    read -p ""$xp_dir" already exists. Do you want to overwrite it (y/n) ?" yn
    case $yn in
      [Yy]* ) 
        rm -rf "$xp_dir"; 
        mkdir -p "$xp_dir"; 
        break;;
      [Nn]* ) exit;;
      * ) * echo "Please answer yes or no.";;
    esac
  done
else
  mkdir -p "$xp_dir"; 
fi
