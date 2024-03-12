#!/bin/bash
clear
ROCM="rocm6.0.2"
STABLE_DIFFUSION_WEBUI="/home/$(whoami)/stable-diffusion-webui"
GFX="gfx1030"
TORCH="pip install --upgrade --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.0"

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
center_text "_  _   _ _____ ___  __  __   _ _____ ___ ___ _ _ _ _ "
center_text "/_\| | | |_   _/ _ \|  \/  | /_\_   _|_ _/ __/ / / / |"
center_text "/ _ \ |_| | | || (_) | |\/| |/ _ \| |  | | (__| | | | |"
center_text "/_/ \_\___/  |_| \___/|_|  |_/_/ \_\_| |___\___|_|_|_|_|"
center_text "${delimiter}"
echo "-----------------"
echo "Choose an option:"
echo "-----------------"
echo "1. Run (default)"
echo "2. Update & Run"
echo "-----------------"
# Read user input
for ((i = 5; i >= 1; i--)); do
    echo -ne "\rEnter the option number ($i seconds): "
    read -t 1 choice
    if [[ $? -eq 0 ]]; then
        break
    fi
done
if [[ -z "$choice" ]]; then
    choice=1
fi
# Choose action based on user input
case "$choice" in
1)
    clear
    # conda activate
    eval "$(conda shell.zsh hook)"
    conda activate automatic1111
    center_text "${delimiter}"
    center_text "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    # activating python venv
    source $STABLE_DIFFUSION_WEBUI/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    center_text "Activated python virtual environment: $venv_name123"
    pyth=$(python --version)
    center_text "$pyth"
    center_text "${delimiter}"
    # start webui
    echo "Starting WebUI"
    python launch.py $@
    ;;
2)
    clear
    # update
    echo "updating Automatic1111"
    git pull
    # Updating git repos
    folder_path="$(pwd)/extensions"
    # Loop through each subfolder in the specified folder
    for repo in "$folder_path"/*; do
        if [ -d "$repo" ]; then
            # Check if the subfolder is a Git repository
            if [ -d "$repo/.git" ] || [ -f "$repo/.git" ]; then
                # Enter the repository and perform git pull
                cd "$repo" || exit
                echo "Updating $(basename "$repo")"
                git pull
                cd - >/dev/null 2>&1 || exit
            else
                echo "Skipping non-Git repository: $(basename "$repo")"
            fi
        fi
    done
    # conda activate
    eval "$(conda shell.zsh hook)"
    conda activate automatic1111
    center_text "${delimiter}"
    center_text "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    # activating python venv
    source $STABLE_DIFFUSION_WEBUI/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    center_text "Activated python virtual environment: $venv_name123"
    pyth=$(python --version)
    center_text "$pyth"
    center_text "${delimiter}"
    # Get latest torch rocm wheels
    eval "$TORCH"
    # Get latest onnxruntime rocm wheels
    echo "checking for latest onnxruntime rocm wheels"
    ONNX_URL="https://download.onnxruntime.ai/onnxruntime_nightly_rocm60.html"
    latest_onnx_wheel=$(wget -qO- ${ONNX_URL} | grep -oP 'onnxruntime.*?cp310-cp310-manylinux_2_28_x86_64.whl' | tail -n 1)
    onnxruntime_rocm="pip install --upgrade --pre https://download.onnxruntime.ai/$latest_onnx_wheel"
    eval "$onnxruntime_rocm"
    pip install --upgrade -r requirements.txt
    # start webui
    echo "Starting WebUI"
    python launch.py $@
    ;;
*)
    echo "Invalid option: $choice"
    exit 1
    ;;
esac
