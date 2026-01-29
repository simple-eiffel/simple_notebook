<p align="center">
  <img src="https://raw.githubusercontent.com/simple-eiffel/.github/main/profile/assets/logo.svg" alt="simple_ library logo" width="400">
</p>

# simple_notebook

**[Documentation](https://simple-eiffel.github.io/simple_notebook/)** | **[GitHub](https://github.com/simple-eiffel/simple_notebook)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Eiffel](https://img.shields.io/badge/Eiffel-25.02-blue.svg)](https://www.eiffel.org/)
[![Design by Contract](https://img.shields.io/badge/DbC-enforced-orange.svg)]()

Interactive Eiffel notebook environment - execute code cells with persistent state, streaming compiler output, and DBC trace logging.

Part of the [Simple Eiffel](https://github.com/simple-eiffel) ecosystem.

## Status

**Alpha 34** - 80 tests passing, Phase 5 complete (multi-class with multiple inheritance)

## Overview

**simple_notebook** provides a Jupyter-like REPL experience for Eiffel. Write code in cells, execute them, and see results immediately. Uses natural Eiffel syntax - no special keywords. Features real-time streaming compiler output, automatic EiffelStudio detection, and session logging with DBC traces.

**New in Alpha 34:** Define multiple classes with full multiple inheritance support - a unique feature for an Eiffel REPL.

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
Eiffel Notebook 1.0.0-alpha.34
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

## Multi-Class with Multiple Inheritance

Define complete Eiffel classes with full DBC support and multiple inheritance:

```
e[1]> -class CAR
class CAR
feature
    drive do print ("Driving on road%N") end
end
...
e[1] Output:

e[2]> -class BOAT
class BOAT
feature
    sail do print ("Sailing on water%N") end
end
...
e[2] Output:

e[3]> -class CAR_BOAT
class CAR_BOAT
inherit
    CAR
    BOAT
feature
    amphibious_mode do
        print ("Entering water...%N")
        sail
        print ("Back on land...%N")
        drive
    end
end
...
e[3] Output:

e[4]> v: CAR_BOAT
...
e[4] Output:

e[5]> create v
...
e[5] Output:

e[6]> v.amphibious_mode
...
e[6] Output:
Entering water...
Sailing on water
Back on land...
Driving on road
```

### Editing Existing Classes

Use `-class NAME` to edit a class you already defined:

```
e[7]> -class CAR
Editing class CAR (cell 1):
class CAR
feature
    drive do print ("Driving on road%N") end
end

Type complete new class (starts with 'class CAR'):
class CAR
feature
    drive do print ("Vroom! Driving on road%N") end
    honk do print ("Beep beep!%N") end
end
...
Class CAR updated in cell 1.
```


### Opening in EiffelStudio

After running cells, you can open the generated workspace directly in EiffelStudio:

1. Run some cells in the notebook to create a working session
2. Navigate to the workspace directory shown at startup (typically `~/.eiffel_notebook/workspace/`)
3. Open the `.ecf` file in EiffelStudio
4. Browse, debug, or modify your code with full IDE features

This is great for:
- Debugging complex code with breakpoints
- Exploring generated class structure
- Experimenting with modifications before updating cells

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
| `-class NAME` | Create or edit class NAME |
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
| `x: INTEGER` | Attribute | Added to accumulated class |
| `f (a: INTEGER) do ... end` | Routine | Added to accumulated class |
| `x := 42` | Instruction | Executed in `execute_cell_N` |
| `x * 2` | Expression | Evaluated and result printed |
| `class FOO ... end` | Class | Written to separate .e file |

## Features

- **Natural Eiffel syntax**: No special keywords - write normal Eiffel
- **Attribute persistence**: Attributes declared in any cell persist across cells
- **Routine definitions**: Define routines with full DBC contracts
- **Multi-class support**: Define complete classes with `-class NAME`
- **Multiple inheritance**: Full Eiffel inheritance including MI
- **Class editing**: Edit existing classes with `-class NAME`
- **Variable tracking**: Monitor state changes (new/modified/removed)
- **Error mapping**: Compilation errors traced back to originating cell and line
- **JSON persistence**: Save/load notebooks
- **Melt mode**: 10-30x faster execution after initial compile
- **Session persistence**: Save/restore notebook sessions
- **Silent compile**: Clean output by default (use `-compile verbose` for details)

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

## Installation

### Windows

Download and run the installer: `eiffel_notebook_setup_1.0.0-alpha.34.exe`

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
- **Phase 4**: Enhanced UX (COMPLETE) - variable tracking, session persistence, command history, melt mode (10-30x faster)
- **Phase 5**: Multi-class support (COMPLETE) - define CAR, BOAT, CAR_BOAT with multiple inheritance, edit existing classes
- **Phase 6**: Web interface (PLANNED) - browser-based notebook UI

## Acknowledgments

- **Eric Bezault** (Gobo Eiffel): Cell classification design using natural Eiffel syntax
- **Javier Velilla**: Original project idea

## Getting Help

- **Documentation**: https://simple-eiffel.github.io/simple_notebook
- **Issues**: https://github.com/simple-eiffel/simple_notebook/issues

## License

MIT License
