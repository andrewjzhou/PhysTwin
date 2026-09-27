#!/usr/bin/env bash
# uv-based installation (alternative to the conda scripts in this folder).
#
# Creates ./.venv with Python 3.10, torch 2.4.0+cu121, PyTorch3D and all CUDA
# extensions (diff-gaussian-rasterization, simple-knn, fused-ssim, gsplat).
#
# Requires: uv (https://docs.astral.sh/uv/), a CUDA toolkit with nvcc, a C++ compiler.
# Usage:    bash ./env_install/uv_install.sh
set -euo pipefail

cd "$(dirname "$0")/.."

# GPU architectures to compile the CUDA extensions for.
# 8.6 = RTX 30xx, 8.9 = RTX 40xx, 12.0 = RTX 50xx. See https://developer.nvidia.com/cuda-gpus
export TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-8.9+PTX}"
export CUDA_HOME="${CUDA_HOME:-/usr/local/cuda}"
export PATH="$CUDA_HOME/bin:$PATH"

if ! command -v nvcc >/dev/null 2>&1; then
    echo "error: nvcc not found. Set CUDA_HOME to your CUDA toolkit (e.g. /usr/local/cuda-12.1)." >&2
    exit 1
fi

# The CUDA extensions build without isolation, i.e. directly against whatever is in
# .venv, so torch and setuptools have to be there before the first sync.
echo "==> [1/2] Seeding .venv with the build toolchain (torch 2.4.0+cu121)"
uv venv --python 3.10
uv pip install setuptools wheel ninja
uv pip install torch==2.4.0 --index-url https://download.pytorch.org/whl/cu121

echo "==> [2/2] Installing everything (TORCH_CUDA_ARCH_LIST=$TORCH_CUDA_ARCH_LIST)"
echo "    Compiling the CUDA extensions takes several minutes on the first run."
uv sync

echo
echo "Done. Run things with:  uv run python interactive_playground.py --n_ctrl_parts 2 --case_name double_stretch_sloth"
echo "Or activate the venv:   source .venv/bin/activate"
