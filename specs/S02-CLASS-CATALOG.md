# S02-CLASS-CATALOG.md
## simple_notebook - Class Catalog

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

### CLASS: SIMPLE_NOTEBOOK

**Role:** Main facade for interactive notebook environment

**Creation Procedures:**
- `make` - Create with default configuration
- `make_with_config(config)` - Create with specific configuration
- `make_from_file(path)` - Open existing notebook

**Key Features:**
- Access: `engine`, `output`, `last_output`, `variables`, `shared_variables`, `cell_count`, `variable_count`, `config`, `execution_time_ms`, `last_compiler_output`
- Status: `is_dirty`, `has_file`, `file_path`
- Cell Operations: `add_cell`, `add_markdown`, `update_cell`, `remove_cell`, `cell_code`, `cell_output`
- Execution: `execute`, `execute_all`, `execute_from`
- File Operations: `new_notebook`, `open`, `save`, `save_as`
- Quick API: `run`, `print_variables`
- Change Tracking: `save_variable_state`, `variable_changes`, `has_variable_changes`

**Collaborators:** NOTEBOOK_ENGINE, NOTEBOOK_CONFIG

---

### CLASS: NOTEBOOK_ENGINE

**Role:** Main engine that orchestrates notebook execution

**Creation Procedures:**
- `make` - Create with default configuration
- `make_with_config(config)` - Create with specific configuration

**Key Features:**
- Access: `config`, `current_notebook`, `variable_tracker`, `code_generator`, `executor`, `storage`, `current_file_path`, `cell_counter`, `last_execution_time_ms`, `last_execution_result`
- Status: `is_dirty`, `has_notebook`, `cell_count`, `variable_count`
- Session: `new_session`, `open_notebook`, `save_notebook`, `save_notebook_as`, `mark_clean`, `replace_notebook`
- Cell Management: `add_cell`, `add_markdown_cell`, `update_cell`, `remove_cell`, `cell_code`, `cell_output`
- Execution: `execute_cell`, `execute_all`, `execute_from`
- Variables: `shared_variables`, `all_variables`, `variables_for_cell`
- Change Tracking: `save_variable_state`, `variable_changes`, `has_variable_changes`

**Collaborators:** NOTEBOOK, NOTEBOOK_CONFIG, VARIABLE_TRACKER, ACCUMULATED_CLASS_GENERATOR, CELL_EXECUTOR, NOTEBOOK_STORAGE

---

### CLASS: NOTEBOOK_CELL

**Role:** Individual cell containing code, output, and execution state

**Creation Procedures:**
- `make(id, type)` - Create with ID and type
- `make_code(id)` - Create code cell
- `make_markdown(id)` - Create markdown cell
- `make_from_json(json)` - Create from JSON

**Key Features:**
- Access: `id`, `cell_type`, `code`, `output`, `error`, `execution_time_ms`, `order`, `status`
- Status Queries: `is_code_cell`, `is_markdown_cell`, `has_output`, `has_error`, `is_idle`, `is_running`, `is_success`, `is_error`
- Commands: `set_code`, `set_output`, `set_error`, `set_execution_time_ms`, `set_order`, `set_status`, `clear_output`
- Serialization: `to_json`, `from_json`

**Constants:**
- `Status_idle`, `Status_running`, `Status_success`, `Status_error`

**Invariants:**
- `id_not_empty: not id.is_empty`
- `type_valid: cell_type.same_string ("code") or cell_type.same_string ("markdown")`
- `status_valid: status in valid set`
- `execution_time_non_negative: execution_time_ms >= 0`

---

### CLASS: NOTEBOOK_CONFIG

**Role:** Configuration settings for notebook environment

**Key Features:**
- Eiffel compiler path
- Workspace directory
- Timeout settings
- Precompile options

---

### CLASS: VARIABLE_TRACKER

**Role:** Tracks variables across notebook cells

**Key Features:**
- `add_variable`, `remove_variable`, `clear`
- `all_variables`, `shared_variables`, `variables_for_cell`
- `extract_variables`, `extract_from_code`
- `save_state`, `changes_since_save`

---

### CLASS: VARIABLE_INFO

**Role:** Variable data container

**Key Features:**
- `name`, `type_name`, `value`, `cell_id`
- `is_shared`, `is_local`
- `formatted` - Display string

---

### CLASS: VARIABLE_CHANGE

**Role:** Tracks variable state changes

**Key Features:**
- `variable_name`, `old_value`, `new_value`
- `change_type` - added, modified, removed

---

### CLASS: CELL_EXECUTOR

**Role:** Compiles and runs generated Eiffel code

**Key Features:**
- `execute_single_cell`, `execute_notebook`
- Compilation via ec.exe
- Output capture

---

### CLASS: ACCUMULATED_CLASS_GENERATOR

**Role:** Generates Eiffel class from notebook cells

**Key Features:**
- Generates NOTEBOOK_SESSION class
- Converts cells to feature bodies
- Tracks declarations as class attributes

---

### CLASS: COMPILATION_RESULT

**Role:** Holds compiler output

**Key Features:**
- `succeeded`, `stdout`, `stderr`
- `errors` - Parsed error list

---

### CLASS: EXECUTION_RESULT

**Role:** Holds execution output

**Key Features:**
- `compilation_succeeded`, `execution_succeeded`
- `compilation_result`, `stdout`, `stderr`
- `timed_out`

---

### CLASS: COMPILER_ERROR

**Role:** Parsed compiler error details

**Key Features:**
- `error_code`, `message`, `file_path`, `line`, `column`
- `formatted_message`

---

### CLASS: NOTEBOOK_STORAGE

**Role:** File persistence for notebooks

**Key Features:**
- `save(notebook, path)`, `load(path)`
- JSON format (.eifnb)
