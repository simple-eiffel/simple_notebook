# S06-BOUNDARIES.md
## simple_notebook - System Boundaries

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Scope Boundaries

### IN SCOPE

| Capability | Description |
|------------|-------------|
| Code cells | Execute Eiffel code |
| Markdown cells | Documentation support |
| Variable tracking | Track state across cells |
| Accumulated class | Merge cells into compilable class |
| File persistence | Save/load .eifnb format |
| Error handling | Parse and display compiler errors |
| Configuration | Workspace, timeout, compiler settings |
| CLI interface | Interactive command-line notebook |

### OUT OF SCOPE

| Capability | Reason |
|------------|--------|
| Web interface | Separate project (future) |
| Jupyter kernel | Alternative approach (see vision doc) |
| Multi-user | Single user only |
| Real-time collaboration | Not planned |
| Non-Eiffel languages | Eiffel only |
| Full IDE features | Not an IDE replacement |
| Auto-complete | Requires simple_lsp integration |
| Debugger integration | Not implemented |

## 2. Integration Boundaries

### INTERNAL DEPENDENCIES

```
simple_notebook
    |
    +-- simple_json (Notebook serialization)
    |
    +-- simple_file (File operations)
    |
    +-- simple_process (Compiler execution)
    |
    +-- simple_uuid (Cell IDs)
    |
    +-- simple_template (Code generation)
```

### EXTERNAL INTERFACES

| Interface | Protocol | Notes |
|-----------|----------|-------|
| EiffelStudio Compiler | ec.exe CLI | Batch mode compilation |
| File System | Local files | Workspace and notebooks |
| JSON | RFC 8259 | Notebook format |

## 3. Error Boundaries

### Compilation Errors

| Error Type | Handling |
|------------|----------|
| Syntax errors | Parsed and displayed in cell |
| Type errors | Parsed with line numbers |
| Contract violations | Displayed as runtime errors |
| Missing features | Displayed as compilation error |

### Runtime Errors

| Error Type | Handling |
|------------|----------|
| Exception | Captured in stderr |
| Timeout | Execution stopped, message shown |
| Assertion violation | Captured and formatted |

### File Errors

| Error Type | Handling |
|------------|----------|
| File not found | Graceful failure |
| Invalid JSON | Parse error reported |
| Permission denied | Error displayed |

## 4. Data Boundaries

### Cell Content

| Attribute | Limit | Notes |
|-----------|-------|-------|
| Code size | STRING capacity | Memory limited |
| Output size | STRING capacity | Truncation possible |
| Cell count | ARRAYED_LIST capacity | Practical limit ~1000 |

### Variable Tracking

| Attribute | Limit | Notes |
|-----------|-------|-------|
| Variable count | HASH_TABLE capacity | Practical limit ~10000 |
| Value capture | STRING representation | Complex objects limited |

## 5. Behavioral Boundaries

### Execution Model

The accumulated class model:

1. **Cell declarations** become class attributes
2. **Cell code** becomes feature bodies
3. **make** calls cell features in order
4. **Variables persist** across cells via class state

```eiffel
class NOTEBOOK_SESSION
feature -- State (from declaration cells)
    x: INTEGER
    y: STRING

feature -- Cells
    cell_1 do x := 42 end
    cell_2 do y := x.out end
    cell_3 do print (y) end

feature -- Execution
    make do cell_1; cell_2; cell_3 end
end
```

### Performance Expectations

| Operation | Expected Time |
|-----------|---------------|
| Initial compile | 5-10 seconds |
| Subsequent cells | 1-3 seconds |
| File save | < 1 second |
| File load | < 1 second |

## 6. Extension Points

### Custom Configuration

Override NOTEBOOK_CONFIG for custom settings.

### Custom Executors

Implement alternative CELL_EXECUTOR for different compilation strategies.

### Custom Storage

Implement alternative NOTEBOOK_STORAGE for different persistence formats.

## 7. Version Boundaries

| Component | Version | Notes |
|-----------|---------|-------|
| EiffelStudio | 25.02+ | Required |
| Void Safety | All | Full void safety |
| SCOOP | Yes | Concurrency support |

## 8. Future Extension Points (from Vision)

| Extension | Status |
|-----------|--------|
| Web UI (HTMX + Alpine) | Planned |
| Jupyter kernel | Alternative approach |
| VS Code integration | Via simple_lsp |
| Visualization cells | Phase 4 |
| Database cells | Phase 4 |
