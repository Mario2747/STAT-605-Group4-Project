#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: ./process_data.sh <STATE> <YEAR>"
  exit 1
fi

STATE=$1
YEAR=$2


INPUT_FOLDER="./${STATE}-${YEAR}"

if [ ! -d "$INPUT_FOLDER" ]; then
  echo "Error: Folder $INPUT_FOLDER does not exist."
  exit 1
fi

Rscript process_data_fast1.R "$INPUT_FOLDER" "${STATE}-${YEAR}_merge.csv"

echo "Processing completed for $STATE in $YEAR."
