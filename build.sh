#\!/bin/bash
# Build Eiffel Notebook from source

set -e

echo "Building Eiffel Notebook..."
echo ""

# Check for ec
if \! command -v ec &> /dev/null; then
    if [ -n "$ISE_EIFFEL" ]; then
        export PATH="$ISE_EIFFEL/studio/spec/linux-x86-64/bin:$PATH"
    fi
fi

if \! command -v ec &> /dev/null; then
    echo "ERROR: EiffelStudio compiler (ec) not found\!"
    echo "Install EiffelStudio or set ISE_EIFFEL environment variable."
    exit 1
fi

echo "Compiler: $(which ec)"
echo ""

# Compile C code for simple_process
echo "Compiling C code..."
if [ -n "$SIMPLE_EIFFEL" ]; then
    PROC_CLIB="$SIMPLE_EIFFEL/simple_process/Clib"
    if [ -f "$PROC_CLIB/simple_process.c" ]; then
        cd "$PROC_CLIB"
        gcc -c -fPIC -I. simple_process.c -o simple_process.o
        echo "  Created simple_process.o"
        cd - > /dev/null
    fi
fi

echo ""
echo "Compiling Eiffel Notebook..."
ec -batch -config simple_notebook.ecf -target notebook_cli -c_compile

echo ""
echo "Build complete\!"
echo "Binary: ./EIFGENs/notebook_cli/W_code/eiffel_notebook"

