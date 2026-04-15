#!/usr/bin/env bash

## Run this script from the main folder of the workshop materials.
# Create a virtual enviroment for the workshop and activate it
python3 -m venv Workshop_AutoM3
source Workshop_AutoM3/bin/activate

# Install the dependencies
pip install -r requirements.txt
