#!/bin/bash

# Check we have terraform files before proceeding
COUNT=$(ls -1 *.tf 2>/dev/null | wc -l)

if [ $COUNT -eq 0 ]
then
  echo "No terraform files found.  Exiting..."
  exit 1
fi

FALSE=0
TRUE=1
REMOVE_DOTFILE=$FALSE

while getopts ":y?" opt; do
  case $opt in
    y) REMOVE_DOTFILE=$TRUE;;
    \?) ;;
  esac
done
   
DOT_FILE=$(date +%s).dot
SVG_FILE=${PWD##*/}.svg

echo "Writing terraform graph to ${DOT_FILE}.  Please wait..."
terraform graph > $DOT_FILE
echo "Writing SVG to ${SVG_FILE}.  Please wait..."
dot ${DOT_FILE} -Tsvg -o ${SVG_FILE}

if [ $REMOVE_DOTFILE -eq $FALSE ]
then
  while true; do
    read -n 1 -p "Do you wish to remove ${DOT_FILE} (y/n)?  " RESPONSE
    case $RESPONSE in
      [Yy]) rm ${DOT_FILE}; break;;
      [Nn]) break;;
      *) echo -e "\nPlease answer y or n.";;
    esac
  done
  echo ""
else
  rm ${DOT_FILE}
fi

exit 0
