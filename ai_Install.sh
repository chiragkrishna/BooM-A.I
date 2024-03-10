#!/bin/bash
clear
# Function to calculate the center position
center_text() {
    local text="$1"
    local width=$(tput cols)
    local padding=$((($width - ${#text}) / 2))
    printf "%*s%s\n" $padding '' "$text"
}

# Function to safely remove a directory
check_directory() {
    if [ -d "$1" ]; then
        echo "Detected directory: $1"
        exit 1
    else
        echo "Directory not found: $1"
    fi
}

check_file() {
    if [ -e "$1" ]; then
        echo "Detected file: $1"
        exit 1
    else
        echo "file not found: $1"
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
if [[ $(id -u) -eq 0 && can_run_as_root -eq 0 ]]
then
    echo "ERROR: This script must not be launched as root, aborting..."
    exit 1
else
    echo "Running on $(whoami) user"
fi

# check if miniconda is installed
! "$CONDA_ROOT_PREFIX/bin/conda" --version &>/dev/null && echo "conda detected" || { echo "miniconda not detected, aborting..."; exit 1; }

# Define common paths
STABLE_DIFFUSION_WEBUI="/home/$(whoami)/stable-diffusion-webui"
COMFYUI="/home/$(whoami)/ComfyUI"
TEXTGEN="/home/$(whoami)/text-generation-webui"
HOME="/home/$(whoami)"
OOBABOOGA="/home/$(whoami)/text-generation-webui"
TORCH="pip install --pre torch torchvision torchaudio --index-url https://download.pytorch.org/whl/nightly/rocm6.0"
PYTHON_VER="python=3.10"
PYTHON="python3.10"
ROCM="rocm6.0"
GFX="gfx1030"

# Get latest onnxruntime rocm wheels
echo "checking for latest onnxruntime rocm wheels"
url="https://download.onnxruntime.ai/onnxruntime_nightly_rocm60.html"
latest_wheel=$(wget -qO- ${url} | grep -oP 'onnxruntime.*?cp310-cp310-manylinux_2_28_x86_64.whl' | tail -n 1)
onnxruntime_rocm="pip install https://download.onnxruntime.ai/$latest_wheel"

# Get latest miopen kdb
echo "checking for latest miopen kdb files"
url_kdb="https://repo.radeon.com/rocm/apt/6.0.2/pool/main/m/miopen-hip-"$GFX"kdb/"
latest_kdb=$(wget -qO- ${url_kdb} | grep -oP 'miopen.*?deb' | tail -n 1)
miopen_url="https://repo.radeon.com/rocm/apt/6.0.2/pool/main/m/miopen-hip-"$GFX"kdb/$latest_kdb"
kdb_folder="${latest_kdb%.deb}"
if [ -d "$(pwd)/$kdb_folder" ]; then
    MIOPEN_KDB="$(pwd)/$kdb_folder/opt/rocm-6.0.2/share/miopen/db/"$GFX".kdb"
    KDB_MOVE="$ROCM/lib/$PYTHON/site-packages/torch/share/miopen/db/"$GFX".kdb"
else
    wget $miopen_url
    rm -rf $(pwd)/miopen*amd64
    dpkg-deb -xv $latest_kdb $(pwd)/$kdb_folder
    MIOPEN_KDB="$(pwd)/$kdb_folder/opt/rocm-6.0.2/share/miopen/db/"$GFX".kdb"
    KDB_MOVE="$ROCM/lib/$PYTHON/site-packages/torch/share/miopen/db/"$GFX".kdb"
    rm -rf $latest_kdb
fi
}

clear
delimiter="################################################################"
center_text "${delimiter}"
center_text "__________                 _____               _____       .___ ";
center_text "\______   \ ____   ____   /     \             /  _  \      |   |";
center_text " |    |  _//  _ \ /  _ \ /  \ /  \   ______  /  /_\  \     |   |";
center_text " |    |   (  <_> |  <_> )    Y    \ /_____/ /    |    \    |   |";
center_text " |______  /\____/ \____/\____|__  /         \____|__  / /\ |___|";
center_text "        \/                      \/                  \/  \/      ";
center_text "${delimiter}"
# Display menu
echo "----------------------------"
echo "Choose an option to install:"
echo "----------------------------"
echo "1. Automatic1111"
echo "2. ComfyUI"
echo "3. Ollama"
echo "4. Oobabooga"
echo "----------------------------"

# Read user input
read -p "Enter the option number: " choice

# Choose action based on user input
case "$choice" in
1)
    # Automatic1111
    pre_launch
    clear
    check_directory "$STABLE_DIFFUSION_WEBUI"
    cd $HOME
    git clone --recurse-submodules -j8 https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$STABLE_DIFFUSION_WEBUI"
    conda_env_name="automatic1111"
    eval "$(conda shell.bash hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv $STABLE_DIFFUSION_WEBUI/$ROCM
    source $STABLE_DIFFUSION_WEBUI/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd "$STABLE_DIFFUSION_WEBUI"
    pip install --upgrade pip wheel
    sleep 1
    eval "$TORCH"
    sleep 1
    eval "$onnxruntime_rocm"
    pip install insightface
    sleep 1
    pip install -r requirements.txt
    sleep 1
    #sd-webui-animatediff extension
    git clone --recurse-submodules -j8 https://github.com/continue-revolution/sd-webui-animatediff.git "$STABLE_DIFFUSION_WEBUI/extensions/sd-webui-animatediff"
    #sd-webui-controlnet extension
    git clone --recurse-submodules -j8 https://github.com/Mikubill/sd-webui-controlnet.git "$STABLE_DIFFUSION_WEBUI/extensions/sd-webui-controlnet"
    cd "$STABLE_DIFFUSION_WEBUI/extensions/sd-webui-controlnet"
    pip install -r requirements.txt
    sleep 1
    cp -rf $MIOPEN_KDB "$STABLE_DIFFUSION_WEBUI/$KDB_MOVE"
    cp -rf $(pwd)/launch_auto.sh "$STABLE_DIFFUSION_WEBUI/launch_auto.sh"
    chmod +x "$STABLE_DIFFUSION_WEBUI/launch_auto.sh"
    echo "successfully installed Automatic1111: $STABLE_DIFFUSION_WEBUI"
    echo "you can launch Automatic1111 with launch_auto.sh"
    ;;
2)
    # ComfyUI
    pre_launch
    clear
    check_directory "$COMFYUI"
    cd $HOME
    git clone --recurse-submodules -j8 https://github.com/comfyanonymous/ComfyUI.git "$COMFYUI"
    conda_env_name="comfy"
    eval "$(conda shell.bash hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv $COMFYUI/$ROCM
    source $COMFYUI/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd "$COMFYUI"
    pip install --upgrade pip wheel
    sleep 1
    eval "$TORCH"
    sleep 1
    eval "$onnxruntime_rocm"
    sleep 1
    pip install -r requirements.txt
    sleep 1
    #comfyui-reactor-node custom nodes
    git clone --recurse-submodules -j8 https://github.com/Gourieff/comfyui-reactor-node.git $COMFYUI/custom_nodes/comfyui-reactor-node
    cd $COMFYUI/custom_nodes/comfyui-reactor-node
    pip install -r requirements.txt
    #ComfyUI-Advanced-ControlNet custom nodes
    git clone --recurse-submodules -j8 https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git $COMFYUI/custom_nodes/ComfyUI-Advanced-ControlNet
    cd $COMFYUI/custom_nodes/ComfyUI-Advanced-ControlNet
    pip install -r requirements.txt
    #ComfyUI-AnimateDiff-Evolved custom nodes
    git clone --recurse-submodules -j8 https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved.git $COMFYUI/custom_nodes/ComfyUI-AnimateDiff-Evolved
    #comfyui_controlnet_aux custom nodes
    git clone --recurse-submodules -j8 https://github.com/Fannovel16/comfyui_controlnet_aux.git $COMFYUI/custom_nodes/comfyui_controlnet_aux
    cd $COMFYUI/custom_nodes/comfyui_controlnet_aux
    pip install -r requirements.txt
    #ComfyUI_FizzNodes custom nodes
    git clone --recurse-submodules -j8 https://github.com/FizzleDorf/ComfyUI_FizzNodes.git $COMFYUI/custom_nodes/ComfyUI_FizzNodes
    cd $COMFYUI/custom_nodes/ComfyUI_FizzNodes
    pip install -r requirements.txt
    #ComfyUI_IPAdapter_plus custom nodes
    git clone --recurse-submodules -j8 https://github.com/cubiq/ComfyUI_IPAdapter_plus.git $COMFYUI/custom_nodes/ComfyUI_IPAdapter_plus
    #ComfyUI-Manager custom nodes
    git clone --recurse-submodules -j8 https://github.com/ltdrdata/ComfyUI-Manager.git $COMFYUI/custom_nodes/ComfyUI-Manager
    cd $COMFYUI/custom_nodes/ComfyUI-Manager
    pip install -r requirements.txt
    #ComfyUI_UltimateSDUpscale custom nodes
    git clone --recurse-submodules -j8 https://github.com/ssitu/ComfyUI_UltimateSDUpscale.git $COMFYUI/custom_nodes/ComfyUI_UltimateSDUpscale
    #ComfyUI-VideoHelperSuite custom nodes
    git clone --recurse-submodules -j8 https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git $COMFYUI/custom_nodes/ComfyUI-VideoHelperSuite
    cd $COMFYUI/custom_nodes/ComfyUI-VideoHelperSuite
    pip install -r requirements.txt
    #efficiency-nodes-comfyui custom nodes
    git clone --recurse-submodules -j8 https://github.com/jags111/efficiency-nodes-comfyui.git $COMFYUI/custom_nodes/efficiency-nodes-comfyui
    cd $COMFYUI/custom_nodes/efficiency-nodes-comfyui
    pip install -r requirements.txt
    #SeargeSDXL custom nodes
    git clone --recurse-submodules -j8 https://github.com/SeargeDP/SeargeSDXL.git $COMFYUI/custom_nodes/SeargeSDXL
    #ComfyUI-Custom-Scripts custom nodes
    git clone --recurse-submodules -j8  https://github.com/pythongosssss/ComfyUI-Custom-Scripts.git $COMFYUI/custom_nodes/ComfyUI-Custom-Scripts
    cp -rf $MIOPEN_KDB "$COMFYUI/$KDB_MOVE"
    cp -rf $(pwd)/launch_comfyui.sh "$COMFYUI/launch_comfyui.sh"
    chmod +x "$COMFYUI/launch_comfyui.sh"
    echo "successfully installed ComfyUI: $COMFYUI"
    echo "you can launch ComfyUI with launch_comfyui.sh"
    ;;
3)
    #Ollama
    pre_launch
    clear
    cd $HOME
    latest_release=$(curl -sSL https://api.github.com/repos/ollama/ollama/releases/latest | grep '"tag_name"' | cut -d '"' -f 4)
    version=${latest_release}
    download_url="https://github.com/ollama/ollama/releases/download/$version/ollama-linux-amd64"
    destination_file="ollama-$version"
    if [[ -e "$destination_file" ]]; then
      check_file ollama
      echo "Downloading Ollama $version..."
      wget --show-progress -O "$destination_file" "$download_url"
      chmod +x "$destination_file"
      echo "Downloaded $destination_file"
    fi
    echo "successfully installed Ollama: $HOME/$destination_file"
    echo "you can launch Ollama with ./$destination_file serve"
    ;;
4)
    # oobabooga
    pre_launch
    clear
    check_directory "$OOBABOOGA"
    cd $HOME
    PYTHON_VER="python=3.11"
    PYTHON="python3.11"
    KDB_MOVE="$ROCM/lib/$PYTHON/site-packages/torch/share/miopen/db/"$GFX".kdb"
    git clone --recurse-submodules -j8 https://github.com/oobabooga/text-generation-webui.git "$OOBABOOGA"
    conda_env_name="textgen"
    eval "$(conda shell.bash hook)"
    if conda env list | grep -q "$conda_env_name"; then
        echo "Conda environment '$conda_env_name' already exists."
    else
        conda create --name "$conda_env_name" $PYTHON_VER -y
        echo "Conda environment '$conda_env_name' created."
    fi
    conda activate $conda_env_name
    echo "################################################################"
    echo "Activated conda virtual environment: $CONDA_DEFAULT_ENV"
    python -m venv $OOBABOOGA/$ROCM
    source $OOBABOOGA/$ROCM/bin/activate
    venv_name123=$(basename "$VIRTUAL_ENV")
    echo "Activated python virtual environment: $venv_name123"
    python --version
    echo "################################################################"
    cd $OOBABOOGA
    pip install --upgrade pip wheel
    sleep 1
    eval "$TORCH"
    sleep 1
    sed -i '/# llama-cpp-python (CPU only, AVX2)/,$d' "$OOBABOOGA/requirements_amd.txt"
    pip install -r requirements_amd.txt
    sleep 1
    # AutoGPTQ
    git clone --recurse-submodules -j8 https://github.com/PanQiWei/AutoGPTQ.git $OOBABOOGA/repo/AutoGPTQ
    cd $OOBABOOGA/repo/AutoGPTQ
    git clean -fd; make clean; python setup.py clean
    pip install numpy gekko pandas
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    cd $OOBABOOGA
    # GPTQ-for-LLaMa
    git clone --recurse-submodules -j8 https://github.com/jllllll/GPTQ-for-LLaMa-CUDA.git $OOBABOOGA/repo/GPTQ-for-LLaMa-CUDA
    cd $OOBABOOGA/repo/GPTQ-for-LLaMa-CUDA
    git clean -fd; make clean; python setup.py clean
    pip install -r requirements.txt
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    cd $OOBABOOGA
    # ExLlamaV2
    git clone --recurse-submodules -j8 https://github.com/turboderp/exllamav2.git $OOBABOOGA/repo/exllamav2
    cd $OOBABOOGA/repo/exllamav2
    git clean -fd; make clean; python setup.py clean
    pip install -r requirements.txt
    ROCM_VERSION=6.0 PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    cd $OOBABOOGA
    # llama-cpp
    CC='/opt/rocm/llvm/bin/clang' CXX='/opt/rocm/llvm/bin/clang++' CFLAGS='-fPIC' CXXFLAGS='-fPIC' CMAKE_PREFIX_PATH='/opt/rocm' ROCM_PATH="/opt/rocm" HIP_PATH="/opt/rocm" CMAKE_ARGS="-GNinja -DLLAMA_HIPBLAS=ON -DLLAMA_AVX2=on -DGPU_TARGETS="$GFX"" pip install --no-cache-dir llama-cpp-python
    # bitsandbytes
    git clone --recurse-submodules -j8 --single-branch --branch rocm_enabled https://github.com/ROCm/bitsandbytes.git $OOBABOOGA/repo/bitsandbytes
    cd $OOBABOOGA/repo/bitsandbytes
    git clean -fd; make clean; python setup.py clean
    pip install -r requirements.txt
    ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" make hip
    ROCM_VERSION=6.0 ROCM_HOME=/opt/rocm ROCM_TARGET="$GFX" PYTORCH_ROCM_ARCH="$GFX" MAX_JOBS=6 pip install --no-cache-dir .
    cd $OOBABOOGA
    cp -rf $MIOPEN_KDB "$OOBABOOGA/$KDB_MOVE"
    cp -rf $(pwd)/launch_oobabooga.sh /$OOBABOOGA/launch_oobabooga.sh
    chmod +x "$OOBABOOGA/launch_oobabooga.sh"
    echo "successfully installed oobabooga: "$OOBABOOGA"
    echo "you can launch oobabooga with launch_oobabooga.sh"
    ;;
*)
    clear
    echo "Invalid option: $choice"
    exit 1
    ;;
esac
