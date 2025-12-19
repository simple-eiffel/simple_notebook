# simple_notebook

Interactive Eiffel notebook environment - execute Eiffel code cells with shared state.

## Overview

simple_notebook provides a Jupyter-like experience for Eiffel. Write code in cells, execute them, and see results. Variables declared as `shared` persist across cells.

## Quick Start

```eiffel
local
    nb: SIMPLE_NOTEBOOK
do
    create nb.make
    nb.add_cell ("shared x: INTEGER%Nx := 42")
    nb.add_cell ("print (x * 2)")
    nb.execute_all
    print (nb.output)  -- prints "84"
end
```

One-liner execution:

```eiffel
result := nb.run ("print (%"Hello, Eiffel!%")")
```

## Features

- **Code cells**: Execute Eiffel code snippets
- **Markdown cells**: Documentation alongside code
- **Shared variables**: `shared x: INTEGER` persists across cells
- **Variable tracking**: Monitor state changes (new/modified/removed)
- **Error mapping**: Compilation errors traced back to originating cell and line
- **JSON persistence**: Save/load notebooks

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

### Variable Declaration

```eiffel
-- Shared variable (persists across cells)
shared x: INTEGER
x := 42

-- Local variable (cell-scoped)
y: STRING
y := "hello"
```

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for detailed design documentation.

## Testing

103 tests covering all components:

```bash
# Run via EiffelStudio test runner
# Or use custom runner:
./EIFGENs/simple_notebook_tests/W_code/simple_notebook.exe
```

## Phase Status

- **Phase 1**: Core engine (COMPLETE - 103 tests passing)
- **Phase 2**: CLI/REPL interface (planned)
- **Phase 3**: Performance optimization (planned)
- **Phase 4**: Documentation (planned)

## License

MIT License - See LICENSE file
