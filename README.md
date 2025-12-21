<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/claude_eiffel_op_docs/main/artwork/LOGO.png" alt="simple_ library logo" width="400">
</p>

# simple_notebook

**[Documentation](https://simple-eiffel.github.io/simple_notebook/)** | **[GitHub](https://github.com/simple-eiffel/simple_notebook)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Interactive Eiffel notebook environment - execute code cells with persistent state, streaming compiler output, and DBC trace logging.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Alpha** - 80 tests passing, Phase 2 complete (session persistence, command history)

## Overview

**simple_notebook** provides a Jupyter-like REPL experience for Eiffel. Write code in cells, execute them, and see results immediately. Uses natural Eiffel syntax - no special keywords. Features real-time streaming compiler output, automatic EiffelStudio detection, and session logging with DBC traces.

## Quick Start

```eiffel
local
    nb: SIMPLE_NOTEBOOK
do
    create nb.make
    nb.add_cell ("x: INTEGER")           -- attribute: persists across cells
    nb.add_cell ("x := 42")              -- instruction: executed
    nb.add_cell ("x * 2")                -- expression: printed
    nb.execute_all
    print (nb.output)  -- prints "84"
end
```

One-liner execution:

```eiffel
result := nb.run ("print (%"Hello, Eiffel!%")")
```

## Interactive CLI

Run `eiffel_notebook` for an interactive REPL session:

```
Eiffel Notebook 1.0.0-alpha.21
Type Eiffel code to execute. Type -help for commands.

e[1]> name: STRING := "World"
...
e[1] Output:

e[2]> print ("Hello, " + name + "!")
...
e[2] Output:
Hello, World!

e[3]> x: INTEGER := 21
...
e[3] Output:

e[4]> x * 2
...
e[4] Output:
42

e[5]> -compile verbose
Compile mode: verbose (shows streaming compiler output)

e[5]> -quit
Goodbye!
```

### CLI Commands

| Command | Description |
|---------|-------------|
| `-help` | Show help |
| `-quit` | Exit |
| `-clear` | Clear all cells |
| `-cells` | List all cells |
| `-vars` | Show tracked variables |
| `-run` | Re-execute all cells |
| `-compile verbose/silent` | Toggle compiler output streaming |
| `-class` | Show generated Eiffel class |
| `-debug` | Show cell classifications |
| `-save [name]` | Save notebook / Save As |
| `-open <name>` | Open notebook |
| `-new` | Start fresh notebook |
| `-notebooks` | List saved notebooks |
| `-history [N]` | Show last N commands |
| `!N` | Re-execute cell N |
| `!!` | Re-execute last cell |

## Cell Classification

Cells are automatically classified by their content:

| Content | Classification | Action |
|---------|----------------|--------|
| `x: INTEGER` | Attribute | Added to cumulative class |
| `f (a: INTEGER) do ... end` | Routine | Added to cumulative class |
| `x := 42` | Instruction | Executed in `execute_cell_N` |
| `x * 2` | Expression | Evaluated and result printed |
| `class FOO ... end` | Class | Generated as separate class file |

## Features

- **Natural Eiffel syntax**: No special keywords - write normal Eiffel
- **Attribute persistence**: Attributes declared in any cell persist across cells
- **Routine definitions**: Define routines with full DBC contracts
- **Class definitions**: Define auxiliary classes within notebooks
- **Variable tracking**: Monitor state changes (new/modified/removed)
- **Error mapping**: Compilation errors traced back to originating cell and line
- **JSON persistence**: Save/load notebooks

## Examples

### Attributes and Instructions

```eiffel
-- Cell 1: Declare an attribute
x: INTEGER

-- Cell 2: Assign a value
x := 42

-- Cell 3: Print result (expression)
x * 2
```

Output: `84`

### Routines with Contracts

```eiffel
-- Cell 1: Define a routine with DBC
double (n: INTEGER): INTEGER
    require
        n_positive: n > 0
    do
        Result := n * 2
    ensure
        doubled: Result = n * 2
    end

-- Cell 2: Use the routine
double (21)
```

Output: `42`

### Local Variables

```eiffel
-- Cell 1: Routine with local
compute: INTEGER
    local
        temp: INTEGER
    do
        temp := 10
        Result := temp * 4
    end

-- Cell 2: Call it
compute
```

Output: `40`

### Class Definitions

```eiffel
-- Cell 1: Define a class
class POINT
create
    make
feature
    x, y: INTEGER
    make (a_x, a_y: INTEGER)
        do
            x := a_x
            y := a_y
        end
    distance: REAL_64
        do
            Result := {MATH}.sqrt ((x * x + y * y).to_double)
        end
end

-- Cell 2: Use the class
my_point: POINT
use_point: REAL_64
    local
        p: POINT
    do
        create p.make (3, 4)
        Result := p.distance
    end

-- Cell 3: Show result
use_point
```

Output: `5.0`

## Installation

### Windows

Download and run the installer: `eiffel_notebook_setup_1.0.0-alpha.22.exe`

The installer:
- Installs the interactive CLI to `C:\Program Files\EiffelNotebook`
- Adds to system PATH
- Auto-detects EiffelStudio location

### Linux (Ubuntu/Debian) and WSL2

**Prerequisites:**

1. Install build tools:
```bash
sudo apt update
sudo apt install build-essential gcc make
```

2. Install EiffelStudio:
```bash
# Download from https://www.eiffel.com/eiffelstudio/download/
# Extract to ~/Eiffel_25.02 (or your preferred location)
tar -xzf EiffelStudio-25.02-linux-x86-64.tar.gz -C ~/
```

3. **Set environment variables** (add to `~/.bashrc` for persistence):
```bash
# EiffelStudio configuration (REQUIRED)
export ISE_EIFFEL=$HOME/Eiffel_25.02
export ISE_PLATFORM=linux-x86-64
export ISE_LIBRARY=$ISE_EIFFEL
export PATH=$ISE_EIFFEL/studio/spec/$ISE_PLATFORM/bin:$PATH

# Simple Eiffel ecosystem
export SIMPLE_EIFFEL=$HOME/simple_eiffel
```

> **Important:** `ISE_LIBRARY` must be set or compilation will fail with `eif_langinfo.h: No such file or directory`.

**Build from source:**

```bash
# Clone the Simple Eiffel ecosystem
mkdir -p ~/simple_eiffel && cd ~/simple_eiffel
git clone https://github.com/simple-eiffel/simple_notebook
git clone https://github.com/simple-eiffel/simple_process
git clone https://github.com/simple-eiffel/simple_json
git clone https://github.com/simple-eiffel/simple_file
git clone https://github.com/simple-eiffel/simple_datetime
git clone https://github.com/simple-eiffel/simple_testing

# Compile C code for simple_process (cross-platform support)
cd simple_process/Clib
gcc -c -fPIC -I. simple_process.c -o simple_process.o
cd ../..

# Build Eiffel Notebook
cd simple_notebook
ec -batch -config simple_notebook.ecf -target notebook_cli -c_compile

# Run
./EIFGENs/notebook_cli/W_code/simple_notebook
```

### WSL2 (Windows Subsystem for Linux)

WSL2 works identically to native Linux. Follow the Linux instructions above inside your WSL2 Ubuntu instance.

**Quick setup for WSL2:**
```bash
# In WSL2 Ubuntu terminal
export ISE_EIFFEL=$HOME/Eiffel_25.02
export ISE_PLATFORM=linux-x86-64
export ISE_LIBRARY=$ISE_EIFFEL
export PATH=$ISE_EIFFEL/studio/spec/$ISE_PLATFORM/bin:$PATH
export SIMPLE_EIFFEL=$HOME/simple_eiffel

# Run notebook
~/simple_eiffel/simple_notebook/EIFGENs/notebook_cli/W_code/simple_notebook
```


### Library Usage

1. Set the ecosystem environment variable (one-time setup for all simple_* libraries):
```bash
# Windows
set SIMPLE_EIFFEL=D:\prod

# Linux/macOS
export SIMPLE_EIFFEL=/path/to/simple-eiffel
```

2. Add to ECF:
```xml
<library name="simple_notebook" location="$SIMPLE_EIFFEL/simple_notebook/simple_notebook.ecf"/>
```

## Requirements

- EiffelStudio 25.02 or later
- Windows, Linux (Ubuntu 20.04+), or macOS

## Dependencies

- simple_process (async process execution with streaming)
- simple_json (notebook persistence)
- simple_file (file operations)
- simple_datetime (timing and timestamps)
- simple_testing (test framework)

## API

### SIMPLE_NOTEBOOK (Facade)

| Feature | Description |
|---------|-------------|
| `make` | Create with default configuration |
| `make_with_config (cfg)` | Create with custom configuration |
| `add_cell (code): STRING` | Add code cell, returns cell ID |
| `add_markdown (content): STRING` | Add markdown cell |
| `execute (id)` | Execute specific cell |
| `execute_all` | Execute all cells in order |
| `run (code): STRING` | Quick: add + execute + return output |
| `output: STRING` | Combined output from all cells |
| `variables: LIST` | All tracked variables |
| `save_as (path)` | Save notebook to file |
| `open (path)` | Load notebook from file |

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed design documentation.

## Testing

```bash
./EIFGENs/simple_notebook_tests/W_code/simple_notebook.exe
```

## Phase Status

- **Phase 1**: Core engine (COMPLETE) - 80 tests passing
- **Phase 2**: Cell classification + Eric Bezault design (COMPLETE)
- **Phase 3**: CLI/REPL interface (COMPLETE) - alpha.21 released
- **Phase 4**: Enhanced UX (COMPLETE) - variable change markers, session persistence, command history
- **Phase 5**: Web interface (planned) - browser-based notebook UI

## Acknowledgments

- **Eric Bezault** (Gobo Eiffel): Cell classification design using natural Eiffel syntax
- **Javier Velilla**: Original project idea

## Getting Help

- **Documentation**: https://simple-eiffel.github.io/simple_notebook
- **Issues**: https://github.com/simple-eiffel/simple_notebook/issues

## License

MIT License
