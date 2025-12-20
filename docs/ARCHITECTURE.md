# simple_notebook Architecture

## Execution Model

simple_notebook uses **accumulated class generation** with **smart cell classification**: cells are analyzed to determine their type, then combined into a single Eiffel class for compilation.

### Cell Classification (Eric Bezault Design)

Cells are classified by their content using natural Eiffel syntax:

| Cell Content | Classification | Generated As |
|--------------|----------------|--------------|
| `x: INTEGER` | Attribute | Class attribute |
| `f (a: INTEGER) do ... end` | Routine | Class feature |
| `x := 42` | Instruction | Body of `execute_cell_N` |
| `x * 2` | Expression | `print (x * 2)` in `execute_cell_N` |
| `class FOO ... end` | Class | Separate class file |

### Example Transformation

```
Cell 1: x: INTEGER             →  feature x: INTEGER

Cell 2: double (n: INTEGER): INTEGER
            require n > 0      →  feature double (n: INTEGER): INTEGER
            do Result := n * 2 end        require n > 0
                                          do Result := n * 2 end

Cell 3: x := 21                →  execute_cell_3 do x := 21 end

Cell 4: double (x)             →  execute_cell_4 do print (double (x)) end

                               →  execute_all do
                                      execute_cell_3
                                      execute_cell_4
                                  end
```

Note: Attribute and routine cells don't generate `execute_cell_N` features - they become class members directly. Only instruction and expression cells generate execution features.

## Component Architecture

```
SIMPLE_NOTEBOOK (facade)
    └── NOTEBOOK_ENGINE (orchestrator)
            ├── NOTEBOOK_CONFIG (settings: compiler path, workspace, timeout)
            ├── NOTEBOOK (data model)
            │       └── NOTEBOOK_CELL[] (code, output, status, classification)
            ├── CELL_CLASSIFIER (NEW: determines cell type)
            │       └── Classification: attribute | routine | instruction | expression | class
            ├── ACCUMULATED_CLASS_GENERATOR (code → Eiffel class)
            │       ├── LINE_MAPPING (generated line → cell:line)
            │       └── USER_CLASS_GENERATOR (for class-type cells)
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
nb.add_cell ("x: INTEGER")      -- attribute
nb.add_cell ("x := 42")         -- instruction
nb.add_cell ("x * 2")           -- expression (auto-printed)
nb.execute_all
print (nb.output)  -- "84"
```

Clients never interact with internal components directly.

### CELL_CLASSIFIER (NEW)

Analyzes cell content to determine its type. Uses Eiffel syntax patterns:

```eiffel
CELL_CLASSIFIER
    classify (code: STRING): INTEGER
        -- Returns: Class_attribute, Class_routine, Executable_instruction,
        --          Executable_expression, User_class

    is_attribute (code: STRING): BOOLEAN
        -- Pattern: identifier : TYPE
        -- Example: "x: INTEGER", "name: STRING"

    is_routine (code: STRING): BOOLEAN
        -- Pattern: name [(args)] [: TYPE] [require...] do ... end
        -- Example: "f do print (42) end", "double (n: INTEGER): INTEGER do..."

    is_class (code: STRING): BOOLEAN
        -- Pattern: class NAME ... end
        -- Example: "class POINT create make feature ... end"

    is_expression (code: STRING): BOOLEAN
        -- Pattern: evaluable expression (identifier, call, operator expr)
        -- Example: "x", "x + 1", "my_routine (arg)"

    is_instruction (code: STRING): BOOLEAN
        -- Pattern: assignment, procedure call with side effects
        -- Example: "x := 42", "print (x)", "create obj.make"
```

Classification rules (in order):
1. Starts with `class ` → User class
2. Contains ` do ` or ` external ` with balanced structure → Routine
3. Matches `identifier: TYPE` (no `:=`) → Attribute
4. Contains `:=` or starts with `create ` or known command → Instruction
5. Otherwise → Expression

### NOTEBOOK_ENGINE (Orchestrator)

Coordinates all notebook operations:

- **Session management**: new, open, save, dirty tracking
- **Cell CRUD**: add/update/remove code and markdown cells
- **Classification**: uses CELL_CLASSIFIER on each cell
- **Execution**: invokes code generator → executor → output capture
- **Variable tracking**: monitors attribute changes
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
    id: STRING              -- "cell_001"
    cell_type: STRING       -- "code" or "markdown"
    code: STRING            -- source code
    output: STRING          -- execution result
    status: STRING          -- idle/running/success/error
    order: INTEGER          -- execution order
    classification: INTEGER -- attribute/routine/instruction/expression/class (NEW)
```

JSON serialization for persistence.

### ACCUMULATED_CLASS_GENERATOR

Transforms notebook cells into compilable Eiffel class using classification:

1. **Attribute cells** → class attributes
2. **Routine cells** → class features (verbatim)
3. **Instruction cells** → body of `execute_cell_N`
4. **Expression cells** → `print (expr)` in `execute_cell_N`
5. **Class cells** → separate .e files via USER_CLASS_GENERATOR
6. Maintains LINE_MAPPING for error tracing
7. Generates ECF configuration file

Output example:
```eiffel
class ACCUMULATED_SESSION_20251219_103549
inherit ANY redefine default_create end
create make, default_create

feature -- Attributes (from cells)
    x: INTEGER
    name: STRING

feature -- Routines (from cells)
    double (n: INTEGER): INTEGER
        require
            n_positive: n > 0
        do
            Result := n * 2
        ensure
            doubled: Result = n * 2
        end

feature -- Execution
    execute_all
        do
            execute_cell_3
            execute_cell_4
        end

    execute_cell_3
        do
            x := 21
        end

    execute_cell_4
        do
            print (double (x))  -- expression cell: auto-print
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

1. Writes generated .e file(s) and .ecf to workspace
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

Tracks attributes across executions:

```eiffel
VARIABLE_INFO
    name: STRING         -- "x"
    type_name: STRING    -- "INTEGER"
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
      "code": "x: INTEGER",
      "classification": "attribute",
      "output": "",
      "status": "idle"
    },
    {
      "id": "cell_002",
      "type": "code",
      "code": "x := 42",
      "classification": "instruction",
      "output": "",
      "status": "success"
    }
  ]
}
```

## Design Principles

### Natural Eiffel Syntax (Eric Bezault)

No special keywords like `shared`. Users write standard Eiffel:
- Attributes look like attributes
- Routines look like routines
- Instructions look like instructions
- Expressions just work

The system infers intent from syntax.

### Separation of Concerns

Each component has one job:
- Classifier doesn't know about execution
- Engine doesn't know how to parse errors
- Executor doesn't know about variables
- Generator doesn't know about file I/O

### Testability

Tests verify each layer independently:
- Classification tests use synthetic input
- Code generation tests don't need the compiler
- Executor tests don't need the full engine
- Parser tests use synthetic error output

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
- New cell types: extend CELL_CLASSIFIER
- New output formats: extend EXECUTION_RESULT
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

## Phase 2 Deliverables (Eric Bezault Design)

| Component | Status | Description |
|-----------|--------|-------------|
| CELL_CLASSIFIER | Planned | Smart cell type detection |
| ACCUMULATED_CLASS_GENERATOR v2 | Planned | Classification-based generation |
| USER_CLASS_GENERATOR | Planned | Handle `class...end` cells |
| Updated tests | Planned | New syntax coverage |

## Foundation for Future Phases

The engine is a **black box that takes cells in and produces output + errors + variable state out**:

| Future Feature | Depends On |
|----------------|------------|
| REPL/CLI interface | `SIMPLE_NOTEBOOK.run()`, `add_cell()`, `execute()` |
| Incremental execution | `LINE_MAPPING`, cell ordering, variable tracking |
| Error highlighting | `COMPILER_ERROR.cell_id`, `cell_line`, error mapping |
| LSP integration | `NOTEBOOK_ENGINE` for execution, `VARIABLE_TRACKER` for completions |
| Web/GUI frontend | `SIMPLE_NOTEBOOK` facade as backend API |

## Acknowledgments

Cell classification design by Eric Bezault (Gobo) - natural Eiffel syntax without special keywords.
