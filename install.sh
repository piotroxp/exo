#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

# 1) Create a local venv (prefer 3.12 if available)
PY=python3
if command -v python3.12 &>/dev/null; then
  echo "Python 3.12 is installed, proceeding with python3.12..."
  PY=python3.12
else
  echo "The recommended Python is 3.12, but using: $($PY --version)"
fi

$PY -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate

# 2) Modern build tools
python -m pip install -U pip setuptools wheel

# 3) Install exo in editable mode (no build isolation to respect the venv)
#    editable_mode=compat keeps the legacy `setup.py develop` behavior stable
pip install -e . --no-build-isolation --config-settings editable_mode=compat

# 4) Create a launcher that:
#    - prevents transformers from importing torch at import-time
#    - ensures tinygrad can dlopen the REAL libgcc_s.so.1 (not conda's linker script)
cat > exo-run << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Use venv python
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/.venv/bin/activate"

# Stop transformers from importing torch (exo uses tinygrad)
export TRANSFORMERS_NO_TORCH=1

# Find real libgcc_s.so.1 and prefer its directory on LD_LIBRARY_PATH
REAL_LIBGCC=""
if command -v ldconfig >/dev/null 2>&1; then
  REAL_LIBGCC="$(ldconfig -p | awk '/libgcc_s\.so\.1/{print $4; exit}')"
fi
# Fallback for common Debian/Ubuntu path
if [[ -z "${REAL_LIBGCC}" && -e /lib/x86_64-linux-gnu/libgcc_s.so.1 ]]; then
  REAL_LIBGCC=/lib/x86_64-linux-gnu/libgcc_s.so.1
fi
if [[ -n "${REAL_LIBGCC}" ]]; then
  export LD_LIBRARY_PATH="$(dirname "$REAL_LIBGCC"):${LD_LIBRARY_PATH:-}"
fi

# Run exo
exec exo "$@"
EOF

chmod +x exo-run

echo
echo "✅ Installed. Use:  ./exo-run"
echo
