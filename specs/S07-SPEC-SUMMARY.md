# S07-SPEC-SUMMARY.md
## simple_notebook - Specification Summary

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## Executive Summary

**simple_notebook** is a Jupyter-style interactive notebook for Eiffel:
- Execute Eiffel code in cells
- Track variables across cells
- Save/load notebooks (.eifnb format)
- Full Design by Contract

## Quick Reference

### Create and Use Notebook
```eiffel
local
    nb: SIMPLE_NOTEBOOK
do
    create nb.make
    nb.add_cell ("x := 42")
    nb.add_cell ("print (x.out)")
    nb.execute_all
    print (nb.output)  -- "42"
end
```

### Quick Execute
```eiffel
nb: SIMPLE_NOTEBOOK
create nb.make
print (nb.run ("print (%"Hello, Eiffel!%")"))
-- Output: "Hello, Eiffel!"
```

### Variable Tracking
```eiffel
nb.add_cell ("counter: INTEGER")    -- Declaration
nb.add_cell ("counter := counter + 1")
nb.execute_all
across nb.variables as v loop
    print (v.formatted)  -- "counter: INTEGER = 1"
end
```

### File Operations
```eiffel
nb.save_as ("my_notebook.eifnb")
-- Later...
create nb.make_from_file ("my_notebook.eifnb")
```

## Class Summary

| Class | Purpose | Key Features |
|-------|---------|--------------|
| SIMPLE_NOTEBOOK | Main facade | Cell ops, execution, file I/O |
| NOTEBOOK_ENGINE | Orchestrator | Compile, execute, track |
| NOTEBOOK_CELL | Cell container | Code, output, status |
| NOTEBOOK_CONFIG | Configuration | Paths, timeout |
| VARIABLE_TRACKER | State tracking | Variables across cells |
| CELL_EXECUTOR | Compilation | ec.exe integration |
| ACCUMULATED_CLASS_GENERATOR | Code gen | Merge cells to class |

## Execution Model

```
+-------------------+     +-------------------+
| Cell 1: x := 42   | --> |                   |
+-------------------+     |  NOTEBOOK_SESSION |
| Cell 2: y := x+1  | --> |    (generated)    |
+-------------------+     |                   |
| Cell 3: print(y)  | --> |  make: cell_1     |
+-------------------+     |        cell_2     |
                          |        cell_3     |
                          +-------------------+
                                   |
                                   v
                          +-------------------+
                          |   ec.exe compile  |
                          |   + execute       |
                          +-------------------+
                                   |
                                   v
                          +-------------------+
                          |  Output: "43"     |
                          +-------------------+
```

## Cell Status Flow

```
idle --> running --> success
    \            \
     \            --> error
      \
       --> (edit) --> idle
```

## Contract Highlights

| Contract | Feature | Rule |
|----------|---------|------|
| Precondition | add_cell | code_not_void |
| Precondition | save | has_file |
| Postcondition | add_cell | cell_count = old + 1 |
| Postcondition | new_notebook | cell_count = 0 |
| Invariant | NOTEBOOK_CELL | id_not_empty |
| Invariant | NOTEBOOK_CELL | type_valid |

## Key Design Decisions

1. **Accumulated Class Model**: Cells merge into single class
2. **Variable Persistence**: Via class attributes
3. **Melting Compilation**: Fast incremental compile
4. **JSON Format**: Human-readable .eifnb files
5. **CLI First**: Interactive terminal interface

## Known Limitations

- Compilation delay (1-3 seconds per cell)
- No web interface (planned)
- No auto-complete (requires simple_lsp)
- No debugger integration
- Single user only

## Related Documents

- S01-PROJECT-INVENTORY.md - Project structure
- S02-CLASS-CATALOG.md - Class details
- S03-CONTRACTS.md - Contract specifications
- S04-FEATURE-SPECS.md - Feature catalog
- S05-CONSTRAINTS.md - Design constraints
- S06-BOUNDARIES.md - Scope and limits
- S08-VALIDATION-REPORT.md - Test coverage
- research/EIFFEL_NOTEBOOK_VISION.md - Full vision document
