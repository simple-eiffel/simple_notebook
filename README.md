# simple_notebook

Interactive Eiffel notebook environment - execute Eiffel code cells with persistent state.

## Overview

simple_notebook provides a Jupyter-like experience for Eiffel. Write code in cells, execute them, and see results. Uses natural Eiffel syntax - no special keywords.

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

## Requirements

- EiffelStudio 25.02 or later
- Environment variable `$SIMPLE_NOTEBOOK` pointing to this directory

## ECF Configuration

```xml
<library name="simple_notebook" location="$SIMPLE_NOTEBOOK/simple_notebook.ecf"/>
```

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

- **Phase 1**: Core engine (COMPLETE)
- **Phase 2**: Cell classification + Eric Bezault's design (IN PROGRESS)
- **Phase 3**: CLI/REPL interface (planned)
- **Phase 4**: Performance optimization (planned)

## Acknowledgments

Design feedback from Eric Bezault (Gobo) - natural Eiffel syntax approach.

## License

MIT License - See LICENSE file
