# BooM-A.I

# Script details

This script can auto install the following along with custom extentions/nodes.
- [Automatic1111](https://github.com/AUTOMATIC1111/stable-diffusion-webui)
    - [sd-webui-animatediff](https://github.com/continue-revolution/sd-webui-animatediff)
    - [sd-webui-controlnet](https://github.com/Mikubill/sd-webui-controlnet)
- [ComfyUI](https://github.com/comfyanonymous/ComfyUI)
    - [comfyui-reactor-node](https://github.com/Gourieff/comfyui-reactor-node)
    - [ComfyUI-Advanced-ControlNet](https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet)
    - [ComfyUI-AnimateDiff-Evolved](https://github.com/Kosinkadink/ComfyUI-AnimateDiff-Evolved)
    - [comfyui_controlnet_aux](https://github.com/Fannovel16/comfyui_controlnet_aux)
    - [ComfyUI_FizzNodes](https://github.com/FizzleDorf/ComfyUI_FizzNodes)
    - [ComfyUI_IPAdapter_plus](https://github.com/cubiq/ComfyUI_IPAdapter_plus)
    - [ComfyUI-Manager](https://github.com/ltdrdata/ComfyUI-Manager)
    - [ComfyUI_UltimateSDUpscale](https://github.com/ssitu/ComfyUI_UltimateSDUpscale)
    - [ComfyUI-VideoHelperSuite](https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite)
    - [efficiency-nodes-comfyui](https://github.com/jags111/efficiency-nodes-comfyui)
    - [SeargeSDXL](https://github.com/SeargeDP/SeargeSDXL)
    - [ComfyUI-Custom-Scripts](https://github.com/pythongosssss/ComfyUI-Custom-Scripts)
- [Ollama](https://github.com/ollama/ollama)
- [Oobabooga](https://github.com/oobabooga/text-generation-webui)

# pre requisite

- Debian x86_64 based distros
- Miniconda
- Python
- GCC
- ROCM-6.0.2
- GIT
- AMD GPU
  (gfx1030 gfx1100 gfx1101 gfx1102 gfx900 gfx906 gfx908 gfx90a gfx940 gfx941 gfx942)

# Install the dependencies

```bash
sudo apt install wget git python3 python3-venv libgl1 libglib2.0-0 libstdc++-12-dev
sudo apt install --no-install-recommends google-perftools
```
# make sure you change GFX according to your GPU
