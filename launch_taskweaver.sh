#!/bin/bash

# update
echo "updating TaskWeaver"
git pull
# Function to calculate the center position
center_text() {
    local text="$1"
    local width=$(tput cols)
    local padding=$(( (width - ${#text}) / 2 ))
    ((padding < 0)) && padding=0
    printf "%*s%s\n" "$padding" '' "$text"
}
# Display menu
delimiter="################################################################"
center_text "${delimiter}"
center_text "  _____ _   ___ _  ____      _____   ___   _____ ___ "
center_text " |_   _/_\ / __| |/ /\ \    / / __| /_\ \ / / __| _ \ "
center_text "   | |/ _ \\__ \ ' <  \ \/\/ /| _| / _ \ V /| _||   /"
center_text "   |_/_/ \_\___/_|\_\  \_/\_/ |___/_/ \_\_/ |___|_|_\ "
center_text "                                                     "
center_text "${delimiter}"
# activate conda
eval "$(conda shell.zsh hook)"
conda activate taskweaver
center_text "${delimiter}"
center_text "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
# activate python venv
source /home/$(whoami)/TaskWeaver/TW/bin/activate
venv_name123=$(basename "$VIRTUAL_ENV")
center_text "Activated python virtual environment: $venv_name123"
pyth=$(python --version)
center_text "$pyth"
center_text "${delimiter}"

# start webui
echo "Starting WebUI"
cd playground/UI/
chainlit run app.py
