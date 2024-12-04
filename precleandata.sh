#!/bin/bash

base_folder="./"
years=("2021" "2022" "2023")

for year in "${years[@]}"; do
  year_outer_folder_path="${base_folder}${year}"
  year_folder_path="${year_outer_folder_path}/${year}"

  
  for state_folder in "$year_folder_path"/*; do
    if [ -d "$state_folder" ]; then
      
      for item in "$state_folder"/*; do
        
        if [ -f "$item" ] && [[ "$item" != *.csv ]]; then
          rm "$item"
          echo "Deleted: $item"
        fi

        
        if [ -d "$item" ]; then
          for sub_item in "$item"/*; do
            
            if [ -f "$sub_item" ] && [[ "$sub_item" == *.csv ]]; then
              mv "$sub_item" "$state_folder/"
              echo "Moved: $sub_item to $state_folder"
            else
              rm "$sub_item"
              echo "Deleted: $sub_item"
            fi
          done
         
          rmdir "$item"
          echo "Deleted folder: $item"
        fi
      done

      # check and rename
      base_name=$(basename "$state_folder")
      if [[ "$base_name" != *-$year ]]; then
        new_folder_name="${base_name}-${year}"
        mv "$state_folder" "$year_folder_path/$new_folder_name"
        echo "Renamed: $state_folder to $new_folder_name"
      fi
    fi
  done
done

echo "Data cleaning and renaming completed."
