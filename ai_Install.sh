#!/bin/bash
clear
script_dir="$(dirname "$(readlink -f "$0")")"

# Function to calculate the center position
center_text() {
    local text="$1"
    local width=$(tput cols)
    local padding=$(( (width - ${#text}) / 2 ))
    ((padding < 0)) && padding=0
    printf "%*s%s\n" "$padding" '' "$text"
}

# Function to safely remove a directory
safely_remove_directory() {
    if [ -d "$1" ]; then
        echo "Removing directory: $1"
        rm -rf "$1"
    else
        echo "Directory not found: $1"
    fi
}

# Function to create a symbolic link
create_symbolic_link() {
    ln -sf "$1" "$2"
    echo "Created symbolic link: $2"
}

pre_launch() {
    echo "performing pre-checks"
    # check for spaces in path
    if [[ "$(pwd)" =~ " " ]]; then echo This script can not be installed under a path with spaces. && exit; fi

    # check if running as root
    can_run_as_root=0
    while getopts "f" flag; do
        case ${flag} in
            f) can_run_as_root=1;;
            *) break;;
        esac
    done
    if [[ $EUID -eq 0 || $can_run_as_root -eq 1 ]]; then
        echo "ERROR: This script must not be launched as root or with sudo, aborting..."
        exit 1
    else
        echo "Running on $(whoami) user"
    fi

    # check if miniconda is installed
    ! "$CONDA_ROOT_PREFIX/bin/conda" --version &>/dev/null && echo "conda detected" || {
        echo "conda not detected, aborting..."
        exit 1
    }

    # Define common paths
    STABLE_DIFFUSION_WEBUI="/home/$(whoami)/stable-diffusion-webui"
    FORGE="/home/$(whoami)/stable-diffusion-webui-forge"
    COMFYUI="/home/$(whoami)/ComfyUI"
    TASKWEAVER="/home/$(whoami)/TaskWeaver"
    HOME="/home/$(whoami)"
    OOBABOOGA="/home/$(whoami)/text-generation-webui"
    PYTHON_VER="python=3.10"
    PYTHON="python3.10"
    ROCM="rocm6.0.2"
    GFX="gfx1030"
    TORCH="pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.0"

    # Get latest onnxruntime rocm wheels
    echo "checking for latest onnxruntime rocm wheels"
    ONNX_URL="https://download.onnxruntime.ai/onnxruntime_nightly_rocm60.html"
    latest_onnx_wheel=$(wget -qO- ${ONNX_URL} | grep -oP 'onnxruntime.*?cp310-cp310-manylinux_2_28_x86_64.whl' | tail -n 1)
    onnxruntime_rocm="pip install --pre https://download.onnxruntime.ai/$latest_onnx_wheel"

    # Get latest miopen kdb
    echo "checking for latest miopen kdb files"
    url_kdb="https://repo.radeon.com/rocm/apt/6.0.2/pool/main/m/miopen-hip-gfx1030kdb/"
    latest_kdb=$(wget -qO- ${url_kdb} | grep -oP 'miopen.*?deb' | tail -n 1)
    miopen_url="https://repo.radeon.com/rocm/apt/6.0.2/pool/main/m/miopen-hip-gfx1030kdb/$latest_kdb"
    kdb_folder="${latest_kdb%.deb}"
    if [ -d "$(pwd)/$kdb_folder" ]; then
        MIOPEN_KDB="$(pwd)/$kdb_folder/opt/rocm-6.0.2/share/miopen/db/gfx1030.kdb"
        KDB_MOVE="$ROCM/lib/$PYTHON/site-packages/torch/share/miopen/db/gfx1030.kdb"
    else
        wget "$miopen_url"
        rm -rf miopen*amd64
        dpkg-deb -xv "$latest_kdb" "$(pwd)/$kdb_folder"
        MIOPEN_KDB="$(pwd)/$kdb_folder/opt/rocm-6.0.2/share/miopen/db/gfx1030.kdb"
        KDB_MOVE="$ROCM/lib/$PYTHON/site-packages/torch/share/miopen/db/gfx1030.kdb"
        rm -rf "$latest_kdb"
    fi
}
clear

instal_automatic1111() {
    clear
    echo "Starting Automatic1111 Instalation"
    pre_launch
    safely_remove_directory "$STABLE_DIFFUSION_WEBUI"
    cd "$HOME"|| return
    git clone --recursive https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$STABLE_DIFFUSION_WEBUI"
    conda_env_name="automatic1111"
    eval "$(conda shell.zsh hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv "$STABLE_DIFFUSION_WEBUI"/"$ROCM"
    source "$STABLE_DIFFUSION_WEBUI/$ROCM/bin/activate"
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd "$STABLE_DIFFUSION_WEBUI" || return
    pip install --upgrade pip wheel
    eval "$TORCH"
    eval "$onnxruntime_rocm"
    pip install insightface
    pip install -r requirements.txt
    #sd-webui-animatediff extension
    git clone --recursive https://github.com/continue-revolution/sd-webui-animatediff.git "$STABLE_DIFFUSION_WEBUI/extensions/sd-webui-animatediff"
    #sd-webui-controlnet extension
    git clone --recursive https://github.com/Mikubill/sd-webui-controlnet.git "$STABLE_DIFFUSION_WEBUI/extensions/sd-webui-controlnet"
    cd "$STABLE_DIFFUSION_WEBUI/extensions/sd-webui-controlnet" || return
    pip install -r requirements.txt
    create_symbolic_link "$MIOPEN_KDB" "$STABLE_DIFFUSION_WEBUI/$KDB_MOVE"
    cd "$script_dir"
    cp -rf "$(pwd)/launch_auto.sh" "$STABLE_DIFFUSION_WEBUI/launch_auto.sh"
    chmod +x "$STABLE_DIFFUSION_WEBUI/launch_auto.sh"
    echo "successfully installed Automatic1111"
    echo "you can launch Automatic1111 with launch_auto.sh"
}

install_forge(){
    clear
    echo "Starting Forge Instalation"
    pre_launch
    safely_remove_directory "$FORGE"
    cd "$HOME" || return
    git clone --recursive https://github.com/lllyasviel/stable-diffusion-webui-forge.git "$FORGE"
    conda_env_name="forge"
    eval "$(conda shell.zsh hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv "$FORGE"/"$ROCM"
    source "$FORGE/$ROCM/bin/activate"
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd "$FORGE" || return
    pip install --upgrade pip wheel
    eval "$TORCH"
    eval "$onnxruntime_rocm"
    pip install insightface
    pip install -r requirements.txt
    #sd-forge-animatediff extension
    git clone --recursive https://github.com/continue-revolution/sd-forge-animatediff.git "$FORGE/extensions/sd-forge-animatediff"
    create_symbolic_link "$MIOPEN_KDB" "$FORGE/$KDB_MOVE"
    cd "$script_dir"
    cp -rf "$(pwd)/launch_forge.sh" "$FORGE/launch_forge.sh"
    chmod +x "$FORGE/launch_forge.sh"
    echo "successfully installed Forge"
    echo "you can launch Forge with launch_forge.sh"
}

install_comfyui() {
    clear
    echo "Starting ComfyUI Instalation"
    pre_launch
    safely_remove_directory "$COMFYUI"
    cd "$HOME" || return
    git clone --recursive https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI"
    conda_env_name="comfy"
    eval "$(conda shell.zsh hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv "$COMFYUI"/"$ROCM"
    source "$COMFYUI/$ROCM/bin/activate"
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd "$COMFYUI" || return
    pip install --upgrade pip wheel
    eval "$TORCH"
    eval "$onnxruntime_rocm"
    pip install insightface
    pip install -r requirements.txt
    #comfyui-reactor-node custom nodes
    git clone --recursive https://github.com/Gourieff/comfyui-reactor-node.git "$COMFYUI/custom_nodes/comfyui-reactor-node"
    cd "$COMFYUI/custom_nodes/comfyui-reactor-node" || return
    pip install -r requirements.txt
    #ComfyUI-Advanced-ControlNet custom node
    git clone --recursive https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git "$COMFYUI/custom_nodes/ComfyUI-Advanced-ControlNet"
    cd "$COMFYUI/custom_nodes/ComfyUI-Advanced-ControlNet" || return
    pip install -r requirements.txt
    #ComfyUI-AnimateDiff-Evolved custom node
    git clone --recursive https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git "$COMFYUI/custom_nodes/ComfyUI-AnimateDiff-Evolved"
    #comfyui_controlnet_aux custom node
    git clone --recursive https://github.com/Fannovel16/comfyui_controlnet_aux.git "$COMFYUI/custom_nodes/comfyui_controlnet_aux"
    cd "$COMFYUI/custom_nodes/comfyui_controlnet_aux" || return
    pip install -r requirements.txt
    #ComfyUI_FizzNodes custom node
    git clone --recursive https://github.com/FizzleDorf/ComfyUI_FizzNodes.git "$COMFYUI/custom_nodes/ComfyUI_FizzNodes"
    cd "$COMFYUI/custom_nodes/ComfyUI_FizzNodes" || return
    pip install -r requirements.txt
    #ComfyUI_IPAdapter_plus custom node
    git clone --recursive https://github.com/cubiq/ComfyUI_IPAdapter_plus.git "$COMFYUI/custom_nodes/ComfyUI_IPAdapter_plus"
    #ComfyUI-Manager custom node
    git clone --recursive https://github.com/ltdrdata/ComfyUI-Manager.git "$COMFYUI/custom_nodes/ComfyUI-Manager"
    cd "$COMFYUI/custom_nodes/ComfyUI-Manager" || return
    pip install -r requirements.txt
    #ComfyUI_UltimateSDUpscale custom node
    git clone --recursive https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git "$COMFYUI/custom_nodes/ComfyUI_UltimateSDUpscale"
    #ComfyUI-VideoHelperSuite custom node
    git clone --recursive https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git "$COMFYUI/custom_nodes/ComfyUI-VideoHelperSuite"
    cd "$COMFYUI/custom_nodes/ComfyUI-VideoHelperSuite" || return
    pip install -r requirements.txt
    #efficiency-nodes-comfyui custom node
    git clone --recursive https://github.com/jags111/efficiency-nodes-comfyui.git "$COMFYUI/custom_nodes/efficiency-nodes-comfyui"
    cd "$COMFYUI/custom_nodes/efficiency-nodes-comfyui" || return
    pip install -r requirements.txt
    #SeargeSDXL custom node
    git clone --recursive https://github.com/SeargeDP/SeargeSDXL.git "$COMFYUI/custom_nodes/SeargeSDXL"
    #ComfyUI-Custom-Scripts custom node
    git clone --recursive https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git "$COMFYUI/custom_nodes/ComfyUI-Custom-Scripts"
    #image-resize-comfyui node
    git clone --recursive https://github.com/palant/image-resize-comfyui.git "$COMFYUI/custom_nodes/image-resize-comfyui"
    #ComfyUI-PhotoMaker-Plus node
    git clone --recursive https://github.com/shiimizu/ComfyUI-PhotoMaker-Plus.git "$COMFYUI/custom_nodes/ComfyUI-PhotoMaker-Plus"
    create_symbolic_link "$MIOPEN_KDB" "$COMFYUI/$KDB_MOVE"
    cd "$script_dir"
    cp -rf "$(pwd)/launch_comfyui.sh" "$COMFYUI/launch_comfyui.sh"
    chmod +x "$COMFYUI/launch_comfyui.sh"
    echo "successfully installed ComfyUI"
    echo "you can launch ComfyUI with launch_comfyui.sh"
}

install_taskweaver() {
    clear
    echo "Starting TaskWeaver Instalation"
    pre_launch
    safely_remove_directory "$TASKWEAVER"
    cd "$HOME" || return
    PYTHON_VER="python=3.11"
    git clone --recursive https://github.com/microsoft/TaskWeaver.git "$TASKWEAVER"
    conda_env_name="taskweaver"
    eval "$(conda shell.zsh hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv "$TASKWEAVER/TW"
    source "$TASKWEAVER/TW/bin/activate"
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd "$TASKWEAVER" || return
    pip install --upgrade pip wheel
    pip install -r requirements.txt
    pip install chainlit==1.0.100
    cd "$script_dir"
    cp -rf "$(pwd)/launch_taskweaver.sh" "/$TASKWEAVER/launch_taskweaver.sh"
    chmod +x "$TASKWEAVER/launch_taskweaver.sh"
    echo "successfully installed TaskWeaver"
    echo "you can launch TaskWeaver with launch_taskweaver.sh"
}

install_ollama() {
    clear
    echo "Starting Ollama Instalation"
    pre_launch
    cd "$HOME" || return
    latest_release=$(curl -sSL https://api.github.com/repos/ollama/ollama/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)
    version=${latest_release}
    download_url="https://github.com/ollama/ollama/releases/download/$version/ollama-linux-amd64"
    destination_file="ollama-$version"
    if [[ -e "$destination_file" ]]; then
        rm ollama-*
        echo "Downloading Ollama $version..."
        wget --show-progress -O "$destination_file" "$download_url"
        chmod +x "$destination_file"
        echo "Downloaded $destination_file"
    fi
    echo "successfully installed $destination_file"
    echo "you can launch Ollama with ./$destination_file serve"
}

install_oobabooga(){
    clear
    echo "Starting Oobabooga Instalation"
    pre_launch
    safely_remove_directory "$OOBABOOGA"
    cd "$HOME" || return
    git clone --recursive https://github.com/oobabooga/text-generation-webui.git "$OOBABOOGA"
    conda_env_name="textgen"
    eval "$(conda shell.zsh hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv "$OOBABOOGA/$ROCM"
    source "$OOBABOOGA/$ROCM/bin/activate"
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd "$OOBABOOGA" || return
    pip install --upgrade pip wheel
    eval "$TORCH"
    cp requirements_amd.txt requirements_custom.txt
    sed -i '/# llama-cpp-python (CPU only, AVX2)/,$d' "$OOBABOOGA/requirements_custom.txt"
    pip install -r requirements_custom.txt
    rm requirements_custom.txt
    # AutoGPTQ
    git clone --recursive https://github.com/PanQiWei/AutoGPTQ.git "$OOBABOOGA/repo/AutoGPTQ"
    cd "$OOBABOOGA/repo/AutoGPTQ" || return
    git clean -fd
    make clean
    python setup.py clean
    pip install numpy gekko pandas
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    # GPTQ-for-LLaMa
    git clone --recursive https://github.com/jllllll/GPTQ-for-LLaMa-CUDA.git "$OOBABOOGA/repo/GPTQ-for-LLaMa-CUDA"
    cd "$OOBABOOGA/repo/GPTQ-for-LLaMa-CUDA" || return
    git clean -fd
    make clean
    python setup.py clean
    pip install -r requirements.txt
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    # ExLlamaV2
    git clone --recursive https://github.com/turboderp/exllamav2.git "$OOBABOOGA/repo/exllamav2"
    cd "$OOBABOOGA/repo/exllamav2" || return
    git clean -fd
    make clean
    python setup.py clean
    pip install -r requirements.txt
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    # llama-cpp
    git clone --recurse https://github.com/abetlen/llama-cpp-python.git "$OOBABOOGA/repo/llama-cpp-python"
    cd "$OOBABOOGA/repo/llama-cpp-python"
    pip install --upgrade pip
    CC='/opt/rocm/llvm/bin/clang' CXX='/opt/rocm/llvm/bin/clang++' CFLAGS='-fPIC' CXXFLAGS='-fPIC' CMAKE_PREFIX_PATH='/opt/rocm' ROCM_PATH="/opt/rocm" HIP_PATH="/opt/rocm" CMAKE_ARGS="-GNinja -DLLAMA_HIPBLAS=ON -DLLAMA_AVX2=on -DGPU_TARGETS=$GFX" pip install --no-cache-dir -e .[all]
    # bitsandbytes
    git clone --recursive --single-branch --branch rocm_enabled https://github.com/ROCm/bitsandbytes.git "$OOBABOOGA/repo/bitsandbytes"
    cd "$OOBABOOGA/repo/bitsandbytes" || return
    git clean -fd
    make clean
    python setup.py clean
    pip install -r requirements.txt
    ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" make hip
    ROCM_VERSION=6.0 ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    # AutoAWQ
    git clone --recursive https://github.com/casper-hansen/AutoAWQ.git "$OOBABOOGA/repo/AutoAWQ"
    cd "$OOBABOOGA/repo/AutoAWQ" || return
    ROCM_VERSION=6.0 ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    cd "$OOBABOOGA" || return
    create_symbolic_link "$MIOPEN_KDB" "$OOBABOOGA/$KDB_MOVE"
    cd "$script_dir"
    cp -rf "$(pwd)/launch_oobabooga.sh" "/$OOBABOOGA/launch_oobabooga.sh"
    chmod +x "$OOBABOOGA/launch_oobabooga.sh"
    echo "successfully installed oobabooga"
    echo "you can launch oobabooga with launch_oobabooga.sh"
}

main() {
    delimiter="################################################################"
    center_text "${delimiter}"
    center_text "__________                 _____               _____       .___ "
    center_text "\______   \ ____   ____   /     \             /  _  \      |   |"
    center_text " |    |  _//  _ \ /  _ \ /  \ /  \   ______  /  /_\  \     |   |"
    center_text " |    |   (  <_> |  <_> )    Y    \ /_____/ /    |    \    |   |"
    center_text " |______  /\____/ \____/\____|__  /         \____|__  / /\ |___|"
    center_text "        \/                      \/                  \/  \/      "
    center_text "${delimiter}"
    # Display menu
    echo "----------------------------"
    echo "Choose an option to install:"
    echo "----------------------------"
    echo "1. Automatic1111"
    echo "2. Forge"
    echo "3. ComfyUI"
    echo "4. TaskWeaver"
    echo "5. Ollama"
    echo "6. Oobabooga"
    echo "----------------------------"

    # Read user input
    read -p "Enter the option number: " choice

    # Choose action based on user input
    case "$choice" in
    1)
        instal_automatic1111
        ;;
    2)
        install_forge
        ;;
    3)
        install_comfyui
        ;;
    4)
        install_taskweaver
        ;;
    5)
        install_ollama
        ;;
    6)
        install_oobabooga
        ;;
    *)
        clear
        echo "Invalid option: $choice"
        exit 1
        ;;
    esac
}

# Execute the main function
main
