# S05-CONSTRAINTS.md
## simple_notebook - Design Constraints

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## 1. Cell Type Constraints

| Constraint | Rule |
|------------|------|
| Valid Types | "code" or "markdown" only |
| Type Immutability | Cell type set at creation |
| Code Cells Only | Only code cells are executed |
| Markdown Cells | Rendered but not executed |

## 2. Cell Status Constraints

| Status | Description | Transitions |
|--------|-------------|-------------|
| idle | Not yet executed | -> running |
| running | Currently executing | -> success, error |
| success | Execution completed | -> idle (on edit), running |
| error | Execution failed | -> idle (on edit), running |

## 3. Cell ID Constraints

| Constraint | Rule |
|------------|------|
| Format | "cell_NNN" (zero-padded) |
| Uniqueness | Unique within notebook |
| Immutability | ID fixed at creation |
| Non-empty | Must have value |

## 4. Execution Constraints

| Constraint | Rule |
|------------|------|
| Compilation Required | All code cells compile via ec.exe |
| Accumulated Class | Cells merged into NOTEBOOK_SESSION class |
| State Persistence | Variables persist across cells via class attributes |
| Order Matters | Cells execute in order (dependencies) |
| Timeout | Configurable execution timeout |

## 5. Variable Tracking Constraints

| Constraint | Rule |
|------------|------|
| Shared Variables | Declared as class attributes |
| Local Variables | Scoped to single cell |
| Type Tracking | Eiffel types preserved |
| Value Tracking | Values captured post-execution |

## 6. File Format Constraints

| Constraint | Rule |
|------------|------|
| Extension | .eifnb recommended |
| Format | JSON structure |
| Encoding | UTF-8 |
| Fields | metadata, cells array |

**JSON Structure:**
```json
{
  "metadata": {
    "title": "...",
    "created": "ISO-8601",
    "eiffel_version": "25.02"
  },
  "cells": [
    {
      "id": "cell_001",
      "cell_type": "code",
      "code": "...",
      "output": "...",
      "status": "success"
    }
  ]
}
```

## 7. Workspace Constraints

| Constraint | Rule |
|------------|------|
| Temp Directory | Generated code in workspace |
| ECF Required | Valid ECF for compilation |
| Compiler Path | ec.exe must be accessible |
| Precompile | Optional precompile for speed |

## 8. Timing Constraints

| Constraint | Default | Notes |
|------------|---------|-------|
| Initial Compile | ~5-10 seconds | Precompile helps |
| Cell Execution | ~1-3 seconds | Melting mode |
| Timeout | Configurable | Default varies |

## 9. Output Constraints

| Constraint | Rule |
|------------|------|
| Stdout Capture | Captured in cell output |
| Stderr Capture | Captured in cell error |
| Error Parsing | Compiler errors parsed |
| Line Mapping | Errors mapped to cell lines |

## 10. Dirty State Constraints

| Action | Effect on is_dirty |
|--------|-------------------|
| add_cell | True |
| update_cell | True |
| remove_cell | True |
| execute | True (output changes) |
| save | False |
| open | False |
| new_notebook | False |

## 11. Configuration Constraints

| Setting | Constraint |
|---------|------------|
| Workspace Directory | Must be writable |
| Compiler Path | Must exist |
| Timeout | Must be positive |
| Precompile | Optional path |

## 12. SCOOP Constraints

| Constraint | Rule |
|------------|------|
| Concurrency Model | SCOOP enabled |
| Cell Execution | Sequential within notebook |
| Variable Access | Via tracker (not shared directly) |
