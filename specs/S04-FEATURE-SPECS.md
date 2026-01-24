# S04-FEATURE-SPECS.md
## simple_notebook - Feature Specifications

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## Feature Categories

### 1. Notebook Creation

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| make | SIMPLE_NOTEBOOK | | Create with defaults |
| make_with_config | SIMPLE_NOTEBOOK | (config: NOTEBOOK_CONFIG) | Create with config |
| make_from_file | SIMPLE_NOTEBOOK | (path: READABLE_STRING_GENERAL) | Open existing |
| new_notebook | SIMPLE_NOTEBOOK | | Start fresh |

### 2. Cell Management

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| add_cell | SIMPLE_NOTEBOOK | (code: STRING): STRING | Add code cell |
| add_markdown | SIMPLE_NOTEBOOK | (content: STRING): STRING | Add markdown cell |
| update_cell | SIMPLE_NOTEBOOK | (id, code: STRING) | Update cell content |
| remove_cell | SIMPLE_NOTEBOOK | (id: STRING) | Remove cell |
| cell_code | SIMPLE_NOTEBOOK | (id: STRING): STRING | Get cell code |
| cell_output | SIMPLE_NOTEBOOK | (id: STRING): STRING | Get cell output |

### 3. Cell Execution

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| execute | SIMPLE_NOTEBOOK | (id: STRING) | Execute single cell |
| execute_all | SIMPLE_NOTEBOOK | | Execute all cells |
| execute_from | SIMPLE_NOTEBOOK | (id: STRING) | Execute from cell to end |
| run | SIMPLE_NOTEBOOK | (code: STRING): STRING | Quick execute |

### 4. File Operations

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| open | SIMPLE_NOTEBOOK | (path: READABLE_STRING_GENERAL) | Open notebook |
| save | SIMPLE_NOTEBOOK | | Save to current path |
| save_as | SIMPLE_NOTEBOOK | (path: READABLE_STRING_GENERAL) | Save to new path |

### 5. Variable Tracking

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| variables | SIMPLE_NOTEBOOK | : ARRAYED_LIST [VARIABLE_INFO] | All variables |
| shared_variables | SIMPLE_NOTEBOOK | : ARRAYED_LIST [VARIABLE_INFO] | Shared variables |
| variable_count | SIMPLE_NOTEBOOK | : INTEGER | Variable count |
| print_variables | SIMPLE_NOTEBOOK | | Print to stdout |
| save_variable_state | SIMPLE_NOTEBOOK | | Save for comparison |
| variable_changes | SIMPLE_NOTEBOOK | : ARRAYED_LIST [VARIABLE_CHANGE] | Get changes |

### 6. Status Queries

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| is_dirty | SIMPLE_NOTEBOOK | : BOOLEAN | Modified? |
| has_file | SIMPLE_NOTEBOOK | : BOOLEAN | Has file path? |
| file_path | SIMPLE_NOTEBOOK | : detachable STRING | Current path |
| cell_count | SIMPLE_NOTEBOOK | : INTEGER | Number of cells |
| output | SIMPLE_NOTEBOOK | : STRING | Combined output |
| last_output | SIMPLE_NOTEBOOK | : STRING | Last cell output |
| execution_time_ms | SIMPLE_NOTEBOOK | : INTEGER_64 | Last execution time |
| last_compiler_output | SIMPLE_NOTEBOOK | : STRING | Compiler output |

### 7. Cell Properties

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| id | NOTEBOOK_CELL | : STRING | Unique identifier |
| cell_type | NOTEBOOK_CELL | : STRING | "code" or "markdown" |
| code | NOTEBOOK_CELL | : STRING | Source content |
| output | NOTEBOOK_CELL | : STRING | Execution output |
| error | NOTEBOOK_CELL | : STRING | Error message |
| status | NOTEBOOK_CELL | : STRING | Execution status |
| execution_time_ms | NOTEBOOK_CELL | : INTEGER | Execution time |
| order | NOTEBOOK_CELL | : INTEGER | Position |

### 8. Cell Status Queries

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| is_code_cell | NOTEBOOK_CELL | : BOOLEAN | Is code? |
| is_markdown_cell | NOTEBOOK_CELL | : BOOLEAN | Is markdown? |
| has_output | NOTEBOOK_CELL | : BOOLEAN | Has output? |
| has_error | NOTEBOOK_CELL | : BOOLEAN | Has error? |
| is_idle | NOTEBOOK_CELL | : BOOLEAN | Idle status? |
| is_running | NOTEBOOK_CELL | : BOOLEAN | Running? |
| is_success | NOTEBOOK_CELL | : BOOLEAN | Succeeded? |
| is_error | NOTEBOOK_CELL | : BOOLEAN | Failed? |

### 9. Cell Modification

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| set_code | NOTEBOOK_CELL | (code: STRING) | Set content |
| set_output | NOTEBOOK_CELL | (output: STRING) | Set output |
| set_error | NOTEBOOK_CELL | (error: STRING) | Set error |
| set_status | NOTEBOOK_CELL | (status: STRING) | Set status |
| set_status_idle | NOTEBOOK_CELL | | Set to idle |
| set_status_running | NOTEBOOK_CELL | | Set to running |
| set_status_success | NOTEBOOK_CELL | | Set to success |
| set_status_error | NOTEBOOK_CELL | | Set to error |
| clear_output | NOTEBOOK_CELL | | Clear output/error |

### 10. Cell Serialization

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| to_json | NOTEBOOK_CELL | : SIMPLE_JSON_OBJECT | Serialize to JSON |
| from_json | NOTEBOOK_CELL | (json: SIMPLE_JSON_OBJECT) | Load from JSON |

### 11. Engine Operations

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| new_session | NOTEBOOK_ENGINE | | Reset session |
| open_notebook | NOTEBOOK_ENGINE | (path: PATH) | Open file |
| save_notebook | NOTEBOOK_ENGINE | | Save current |
| save_notebook_as | NOTEBOOK_ENGINE | (path: PATH) | Save as |
| execute_cell | NOTEBOOK_ENGINE | (id: STRING) | Execute cell |
| execute_all | NOTEBOOK_ENGINE | | Execute all |
| execute_from | NOTEBOOK_ENGINE | (id: STRING) | Execute from |

### 12. Variable Info

| Feature | Class | Signature | Description |
|---------|-------|-----------|-------------|
| name | VARIABLE_INFO | : STRING | Variable name |
| type_name | VARIABLE_INFO | : STRING | Eiffel type |
| value | VARIABLE_INFO | : STRING | Current value |
| cell_id | VARIABLE_INFO | : STRING | Defining cell |
| is_shared | VARIABLE_INFO | : BOOLEAN | Cross-cell? |
| formatted | VARIABLE_INFO | : STRING | Display string |
