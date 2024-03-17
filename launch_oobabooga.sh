#!/bin/bash
clear
ROCM="rocm6.0.2"
OOBABOOGA="/home/$(whoami)/text-generation-webui"
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
center_text "_____ _____  _______ ___ ___ _  _ "
center_text "|_   _| __\ \/ /_   _/ __| __| \|"
center_text "| | | _| >  <  | || (_ | _|| .\`|"
center_text "|_| |___/_/\_\ |_| \___|___|_|\_|"
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
    # conda activate
    eval "$(conda shell.zsh hook)"
    conda activate textgen
    center_text "${delimiter}"
    center_text "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    # activating python venv
    source $OOBABOOGA/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    center_text "Activated python virtual environment: $venv_name123"
    pyth=$(python --version)
    center_text "$pyth"
    center_text "${delimiter}"
    # start webui
    echo "Starting WebUI"
    python server.py $@ --auto-launch
    ;;
2)
    clear
    # update
    echo "updating oobabooga"
    git pull
    # Updating git repos
    folder_path="$OOBABOOGA/repo"
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
    conda activate textgen
    center_text "${delimiter}"
    center_text "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    # activating python venv
    source $OOBABOOGA/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    center_text "Activated python virtual environment: $venv_name123"
    pyth=$(python --version)
    center_text "$pyth"
    center_text "${delimiter}"
    # Get latest torch
    eval "$TORCH"
    # AutoGPTQ update
    cd "$OOBABOOGA/repo/AutoGPTQ"
    git clean -fd
    make clean
    python setup.py clean
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --upgrade --no-cache-dir .
    # GPTQ-for-LLaMa update
    cd "$OOBABOOGA/repo/GPTQ-for-LLaMa-CUDA"
    git clean -fd
    make clean
    python setup.py clean
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --upgrade --no-cache-dir .
    # ExLlamaV2 update
    cd "$OOBABOOGA/repo/exllamav2"
    git clean -fd
    make clean
    python setup.py clean
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --upgrade --no-cache-dir .
    # llama-cpp update
    cd "$OOBABOOGA/repo/llama-cpp-python"
    CC='/opt/rocm/llvm/bin/clang' CXX='/opt/rocm/llvm/bin/clang++' CFLAGS='-fPIC' CXXFLAGS='-fPIC' CMAKE_PREFIX_PATH='/opt/rocm' ROCM_PATH="/opt/rocm" HIP_PATH="/opt/rocm" CMAKE_ARGS="-GNinja -DLLAMA_HIPBLAS=ON -DLLAMA_AVX2=on -DGPU_TARGETS="$GFX"" pip install --upgrade --force-reinstall --no-cache-dir -e .[all]
    # bitsandbytes update
    cd "$OOBABOOGA/repo/bitsandbytes"
    git clean -fd
    make clean
    python setup.py clean
    ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" make hip
    ROCM_VERSION=6.0 ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --upgrade --no-cache-dir .
    # AutoAWQ
    cd "$OOBABOOGA/repo/AutoAWQ"
    ROCM_VERSION=6.0 ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --upgrade --no-cache-dir .
    cd $OOBABOOGA
    cp requirements_amd.txt requirements_custom.txt
    sed -i '/# llama-cpp-python (CPU only, AVX2)/,$d' "$OOBABOOGA/requirements_custom.txt"
    pip install -r requirements_custom.txt
    rm requirements_custom.txt
    # start webui
    echo "Starting WebUI"
    python server.py $@ --auto-launch
    ;;
*)
    echo "Invalid option: $choice"
    exit 1
    ;;
esac
