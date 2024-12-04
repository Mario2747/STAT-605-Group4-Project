#!/bin/bash

wget -O 2021.zip "https://www.dropbox.com/scl/fi/aonflekymr3hrykonuet1/2021.zip?rlkey=ilr40suqetnl6p03t83ucv07c&st=nqa4d4zf&dl=0"
wget -O 2022.zip "https://www.dropbox.com/scl/fi/ktckcrs5cvs59eyln20vp/2022.zip?rlkey=h5epq22m3qrfw381hj6nliemt&st=r103hzzx&dl=0"
wget -O 2023.zip "https://www.dropbox.com/scl/fi/xeks8n26h2wdcek8kjgcf/2023.zip?rlkey=o5owknpkeaet83qutw51ypso7&st=zpgo3o1m&dl=0"

for year in 2021 2022 2023; do
    unzip -o "$year.zip" -d "$year"
done

echo "Data download and extraction completed."
