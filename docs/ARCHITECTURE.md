# simple_notebook Architecture

## Execution Model

simple_notebook uses **accumulated class generation**: all cells up to the target cell are combined into a single Eiffel class where each cell becomes an `execute_cell_N` feature called in sequence.

```
Cell 1: shared x: INTEGER      →  feature x: INTEGER
        x := 42                    execute_cell_1 do x := 42 end

Cell 2: print (x * 2)          →  execute_cell_2 do print (x * 2) end

                               →  execute_all do
                                      execute_cell_1
                                      execute_cell_2
                                  end
```

Shared variables become class attributes, allowing state to persist across cells. The generated class is compiled with ec.exe and the resulting executable is run to capture output.

## Component Architecture

```
SIMPLE_NOTEBOOK (facade)
    └── NOTEBOOK_ENGINE (orchestrator)
            ├── NOTEBOOK_CONFIG (settings: compiler path, workspace, timeout)
            ├── NOTEBOOK (data model)
            │       └── NOTEBOOK_CELL[] (code, output, status)
            ├── ACCUMULATED_CLASS_GENERATOR (code → Eiffel class)
            │       └── LINE_MAPPING (generated line → cell:line)
            ├── CELL_EXECUTOR (compile & run)
            │       ├── COMPILATION_RESULT
            │       ├── EXECUTION_RESULT
            │       └── COMPILER_ERROR_PARSER
            ├── VARIABLE_TRACKER (state management)
            │       ├── VARIABLE_INFO
            │       └── VARIABLE_CHANGE
            └── NOTEBOOK_STORAGE (JSON persistence)
```

## Component Responsibilities

### SIMPLE_NOTEBOOK (Facade)

Clean, minimal API for clients. Delegates all work to NOTEBOOK_ENGINE.

```eiffel
create nb.make
nb.add_cell ("shared x: INTEGER%Nx := 42")
nb.execute_all
print (nb.output)
```

Clients never interact with internal components directly.

### NOTEBOOK_ENGINE (Orchestrator)

Coordinates all notebook operations:

- **Session management**: new, open, save, dirty tracking
- **Cell CRUD**: add/update/remove code and markdown cells
- **Execution**: invokes code generator → executor → output capture
- **Variable tracking**: monitors shared variable changes
- **Error mapping**: translates generated-class line numbers to cell:line

### NOTEBOOK_CONFIG

Runtime configuration:

| Setting | Default | Description |
|---------|---------|-------------|
| `eiffel_compiler` | auto-detected | Path to ec.exe |
| `workspace_dir` | temp | Where generated files go |
| `timeout_seconds` | 30 | Execution timeout |
| `library_paths` | [] | Additional ECF libraries |

Auto-detection via `CONFIG_DETECTOR` checks:
1. `$ISE_EIFFEL` environment variable
2. Common installation paths
3. PATH search

### NOTEBOOK / NOTEBOOK_CELL

Data model for notebook structure:

```eiffel
NOTEBOOK
    name: STRING
    cells: ARRAYED_LIST [NOTEBOOK_CELL]

NOTEBOOK_CELL
    id: STRING           -- "cell_001"
    cell_type: INTEGER   -- code or markdown
    code: STRING         -- source code
    output: STRING       -- execution result
    status: INTEGER      -- idle/running/success/error
    order: INTEGER       -- execution order
```

JSON serialization for persistence.

### ACCUMULATED_CLASS_GENERATOR

Transforms notebook cells into compilable Eiffel class:

1. Collects `shared` variable declarations → class attributes
2. Extracts local declarations → feature locals
3. Generates `execute_cell_N` feature for each cell
4. Maintains LINE_MAPPING for error tracing
5. Generates ECF configuration file

Output example:
```eiffel
class ACCUMULATED_SESSION_20251219_103549
inherit ANY redefine default_create end
create make, default_create

feature -- Shared Variables
    x: INTEGER

feature -- Execution
    execute_all
        do
            execute_cell_1
            execute_cell_2
        end

    execute_cell_1
        do
            x := 42
        end

    execute_cell_2
        do
            print (x * 2)
        end
end
```

### LINE_MAPPING

Maps generated class line numbers back to original cells:

```
Generated line 45 → cell_001, line 3
Generated line 52 → cell_002, line 1
```

Essential for meaningful error messages. When ec.exe reports "Error at line 45", we translate to "Error in cell_001, line 3".

### CELL_EXECUTOR

Compiles and runs generated code:

1. Writes generated .e file and .ecf to workspace
2. Deletes old executable (prevents Windows linker lock)
3. Invokes: `ec.exe -batch -clean -config notebook.ecf -target notebook_session -c_compile`
4. **Checks if exe exists** (ec.exe returns 0 even on errors!)
5. Runs executable, captures stdout
6. Returns EXECUTION_RESULT with output or errors

### COMPILER_ERROR_PARSER

Parses ec.exe output for error codes:

```
VEEN: unknown identifier 'x'
VJAR: type mismatch
```

Extracts error code, message, line number, class name. Works with LINE_MAPPING to produce cell-relative errors.

### VARIABLE_TRACKER

Tracks variables across executions:

```eiffel
VARIABLE_INFO
    name: STRING         -- "x"
    type_name: STRING    -- "INTEGER"
    is_shared: BOOLEAN   -- True for cross-cell
    cell_id: STRING      -- defining cell
    value: detachable ANY

VARIABLE_CHANGE
    variable: VARIABLE_INFO
    change_type: INTEGER  -- new/modified/removed
    old_value, new_value: detachable ANY
```

Enables:
- Variable inspector in UI
- Change detection between executions
- Dependency analysis

### NOTEBOOK_STORAGE

JSON persistence:

```json
{
  "name": "my_notebook",
  "cells": [
    {
      "id": "cell_001",
      "type": "code",
      "code": "shared x: INTEGER\nx := 42",
      "output": "",
      "status": 0
    }
  ]
}
```

## Design Principles

### Separation of Concerns

Each component has one job:
- Engine doesn't know how to parse errors
- Executor doesn't know about variables
- Generator doesn't know about file I/O

### Testability

103 tests verify each layer independently:
- Code generation tests don't need the compiler
- Executor tests don't need the full engine
- Parser tests use synthetic input

### DBC Contracts

All public features have contracts:

```eiffel
add_cell (a_code: STRING): STRING
    require
        code_not_void: a_code /= Void
    ensure
        cell_added: cell_count = old cell_count + 1
        is_dirty: is_dirty
        result_not_empty: not Result.is_empty
```

### Extensibility

Adding features doesn't require rewriting core logic:
- New output formats: extend EXECUTION_RESULT
- New cell types: extend NOTEBOOK_CELL
- New variable types: extend VARIABLE_INFO

## Key Implementation Details

### ec.exe Exit Code Quirk

EiffelStudio's ec.exe returns exit code 0 even when compilation fails with errors. The executor checks if the executable file was actually created:

```eiffel
if l_exe_file.exists then
    -- Compilation succeeded
else
    -- Compilation failed - parse errors from output
```

### Windows Linker Lock

On Windows, the linker cannot overwrite a locked executable. The executor deletes the old exe before compiling:

```eiffel
if l_old_exe.exists then
    l_old_exe.delete.do_nothing
end
```

### Workspace Isolation

Each notebook execution uses `-clean` flag to delete EIFGENs and force fresh compile. This prevents stale artifacts from previous runs affecting current execution.

## Phase 1 Deliverables

| Component | Status | Tests |
|-----------|--------|-------|
| NOTEBOOK_CONFIG | Complete | 10 |
| CONFIG_DETECTOR | Complete | 3 |
| NOTEBOOK | Complete | 15 |
| NOTEBOOK_CELL | Complete | 12 |
| NOTEBOOK_STORAGE | Complete | 6 |
| ACCUMULATED_CLASS_GENERATOR | Complete | 14 |
| LINE_MAPPING | Complete | 8 |
| CELL_EXECUTOR | Complete | 12 |
| COMPILATION_RESULT | Complete | 4 |
| EXECUTION_RESULT | Complete | 4 |
| COMPILER_ERROR_PARSER | Complete | 3 |
| VARIABLE_TRACKER | Complete | 18 |
| NOTEBOOK_ENGINE | Complete | 15 |
| SIMPLE_NOTEBOOK | Complete | 6 |
| **Total** | **Complete** | **103** |

## Foundation for Phase 2

Phase 1 is the **execution core**. Everything that follows builds on it:

| Phase 2 Feature | Depends On |
|-----------------|------------|
| REPL/CLI interface | `SIMPLE_NOTEBOOK.run()`, `add_cell()`, `execute()` |
| Incremental execution | `LINE_MAPPING`, cell ordering, variable tracking |
| Error highlighting | `COMPILER_ERROR.cell_id`, `cell_line`, error mapping |
| LSP integration | `NOTEBOOK_ENGINE` for execution, `VARIABLE_TRACKER` for completions |
| Web/GUI frontend | `SIMPLE_NOTEBOOK` facade as backend API |

The engine is a **black box that takes cells in and produces output + errors + variable state out**. Phase 2 wraps this with user interfaces; Phase 3 optimizes it; Phase 4 documents it. But the core contract is set.
