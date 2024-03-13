#!/bin/bash
clear
ROCM="rocm6.0.2"
COMFYUI="/home/$(whoami)/ComfyUI"
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
center_text "___ ___  __  __ _____   ___   _ ___ "
center_text "/ __/ _ \|  \/  | __\ \ / / | | |_ _|"
center_text "| (_| (_) | |\/| | _| \ V /| |_| || | "
center_text "\___\___/|_|  |_|_|   |_|  \___/|___|"
center_text "${delimiter}"
# Display menu
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
    # activate conda
    eval "$(conda shell.zsh hook)"
    conda activate comfy
    center_text "${delimiter}"
    center_text "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    # activate python venv
    source $COMFYUI/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    center_text "Activated python virtual environment: $venv_name123"
    pyth=$(python --version)
    center_text "$pyth"
    center_text "${delimiter}"
    # start webui
    echo "Starting WebUI"
    python main.py $@ --auto-launch
    ;;
2)
    clear
    # update
    echo "updating ComfyUI"
    git pull
    # Updating git repos
    folder_path="$COMFYUI/custom_nodes"
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
    # activate conda
    eval "$(conda shell.zsh hook)"
    conda activate comfy
    center_text "${delimiter}"
    center_text "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    # activate python venv
    source $COMFYUI/$ROCM/bin/activate
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
    #comfyui-reactor-node custom nodes
    cd "$COMFYUI/custom_nodes/comfyui-reactor-node" || return
    pip install --upgrade -r requirements.txt
    #ComfyUI-Advanced-ControlNet custom node
    cd "$COMFYUI/custom_nodes/ComfyUI-Advanced-ControlNet" || return
    pip install --upgrade -r requirements.txt
    #comfyui_controlnet_aux custom node
    cd "$COMFYUI/custom_nodes/comfyui_controlnet_aux" || return
    pip install --upgrade -r requirements.txt
    #ComfyUI_FizzNodes custom node
    cd "$COMFYUI/custom_nodes/ComfyUI_FizzNodes" || return
    pip install --upgrade -r requirements.txt
    #ComfyUI-Manager custom node
    cd "$COMFYUI/custom_nodes/ComfyUI-Manager" || return
    pip install --upgrade -r requirements.txt
    #ComfyUI-VideoHelperSuite custom node
    git clone --recursive https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git "$COMFYUI/custom_nodes/ComfyUI-VideoHelperSuite"
    cd "$COMFYUI/custom_nodes/ComfyUI-VideoHelperSuite" || return
    pip install --upgrade -r requirements.txt
    #efficiency-nodes-comfyui custom node
    cd "$COMFYUI/custom_nodes/efficiency-nodes-comfyui" || return
    pip install --upgrade -r requirements.txt
    cd "$COMFYUI" || return
    pip install --upgrade -r requirements.txt
    # start webui
    echo "Starting WebUI"
    python main.py $@ --auto-launch
    ;;
*)
    echo "Invalid option: $choice"
    exit 1
    ;;
esac
