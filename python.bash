#!/usr/bin/env bash
set -euo pipefail

# On windows, there is no python3 executable
if [[ "$OSTYPE" == "msys" ]]; then
    function python3 {
        python "$@"
    }

    function pip3 {
        pip "$@"
    }

    export -f python3
    export -f pip3
    export activate_path="Scripts/activate"
else
    export activate_path="bin/activate"
fi
