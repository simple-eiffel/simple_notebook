# S03-CONTRACTS.md
## simple_notebook - Contract Specifications

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23

---

## SIMPLE_NOTEBOOK Contracts

### make
```eiffel
make
    ensure
        engine_created: engine /= Void
```

### make_with_config
```eiffel
make_with_config (a_config: NOTEBOOK_CONFIG)
    require
        config_not_void: a_config /= Void
    ensure
        engine_created: engine /= Void
```

### make_from_file
```eiffel
make_from_file (a_path: READABLE_STRING_GENERAL)
    require
        path_not_empty: a_path /= Void and then not a_path.is_empty
```

### add_cell
```eiffel
add_cell (a_code: STRING): STRING
    require
        code_not_void: a_code /= Void
    ensure
        cell_added: cell_count = old cell_count + 1
```

### add_markdown
```eiffel
add_markdown (a_content: STRING): STRING
    require
        content_not_void: a_content /= Void
```

### update_cell
```eiffel
update_cell (a_id: STRING; a_code: STRING)
    require
        id_valid: a_id /= Void and then not a_id.is_empty
        code_not_void: a_code /= Void
```

### remove_cell
```eiffel
remove_cell (a_id: STRING)
    require
        id_valid: a_id /= Void and then not a_id.is_empty
```

### execute
```eiffel
execute (a_id: STRING)
    require
        id_valid: a_id /= Void and then not a_id.is_empty
```

### open
```eiffel
open (a_path: READABLE_STRING_GENERAL)
    require
        path_valid: a_path /= Void and then not a_path.is_empty
```

### save
```eiffel
save
    require
        has_file: has_file
    ensure
        not_dirty: not is_dirty
```

### save_as
```eiffel
save_as (a_path: READABLE_STRING_GENERAL)
    require
        path_valid: a_path /= Void and then not a_path.is_empty
    ensure
        not_dirty: not is_dirty
        has_file: has_file
```

### run
```eiffel
run (a_code: STRING): STRING
    require
        code_not_void: a_code /= Void
```

### new_notebook
```eiffel
new_notebook
    ensure
        empty: cell_count = 0
        no_variables: variable_count = 0
```

### Class Invariant
```eiffel
invariant
    engine_not_void: engine /= Void
```

---

## NOTEBOOK_ENGINE Contracts

### make
```eiffel
make
    ensure
        config_set: config /= Void
        notebook_created: current_notebook /= Void
```

### make_with_config
```eiffel
make_with_config (a_config: NOTEBOOK_CONFIG)
    require
        config_not_void: a_config /= Void
    ensure
        config_set: config = a_config
        notebook_created: current_notebook /= Void
```

### new_session
```eiffel
new_session
    ensure
        fresh_notebook: current_notebook.cell_count = 0
        no_variables: variable_tracker.count = 0
        no_file: current_file_path = Void
        not_dirty: not is_dirty
```

### add_cell
```eiffel
add_cell (a_code: STRING): STRING
    require
        code_not_void: a_code /= Void
    ensure
        cell_added: current_notebook.cell_count = old current_notebook.cell_count + 1
        is_dirty: is_dirty
        result_not_empty: not Result.is_empty
```

### update_cell
```eiffel
update_cell (a_id: STRING; a_code: STRING)
    require
        id_not_empty: not a_id.is_empty
        code_not_void: a_code /= Void
        cell_exists: current_notebook.cell_by_id (a_id) /= Void
    ensure
        is_dirty: is_dirty
```

### remove_cell
```eiffel
remove_cell (a_id: STRING)
    require
        id_not_empty: not a_id.is_empty
        cell_exists: current_notebook.cell_by_id (a_id) /= Void
    ensure
        cell_removed: current_notebook.cell_by_id (a_id) = Void
        is_dirty: is_dirty
```

### execute_cell
```eiffel
execute_cell (a_id: STRING)
    require
        id_not_empty: not a_id.is_empty
        cell_exists: current_notebook.cell_by_id (a_id) /= Void
```

### save_notebook
```eiffel
save_notebook
    require
        has_path: current_file_path /= Void
    ensure
        not_dirty: not is_dirty
```

### save_notebook_as
```eiffel
save_notebook_as (a_path: PATH)
    require
        path_not_void: a_path /= Void
    ensure
        path_updated: current_file_path = a_path
        not_dirty: not is_dirty
```

### Class Invariant
```eiffel
invariant
    config_not_void: config /= Void
    notebook_not_void: current_notebook /= Void
    tracker_not_void: variable_tracker /= Void
    generator_not_void: code_generator /= Void
    executor_not_void: executor /= Void
    storage_not_void: storage /= Void
```

---

## NOTEBOOK_CELL Contracts

### make
```eiffel
make (a_id: STRING; a_type: STRING)
    require
        id_not_empty: not a_id.is_empty
        type_valid: a_type.same_string ("code") or a_type.same_string ("markdown")
    ensure
        id_set: id = a_id
        type_set: cell_type = a_type
        status_idle: status.same_string (Status_idle)
```

### make_code
```eiffel
make_code (a_id: STRING)
    require
        id_not_empty: not a_id.is_empty
    ensure
        is_code: is_code_cell
```

### make_markdown
```eiffel
make_markdown (a_id: STRING)
    require
        id_not_empty: not a_id.is_empty
    ensure
        is_markdown: is_markdown_cell
```

### set_status
```eiffel
set_status (a_status: STRING)
    require
        status_valid: a_status.same_string (Status_idle) or
                     a_status.same_string (Status_running) or
                     a_status.same_string (Status_success) or
                     a_status.same_string (Status_error)
    ensure
        status_set: status = a_status
```

### set_execution_time_ms
```eiffel
set_execution_time_ms (a_time: INTEGER)
    require
        time_non_negative: a_time >= 0
    ensure
        time_set: execution_time_ms = a_time
```

### clear_output
```eiffel
clear_output
    ensure
        output_empty: output.is_empty
        error_empty: error.is_empty
        time_zero: execution_time_ms = 0
        is_idle: is_idle
```

### Class Invariant
```eiffel
invariant
    id_not_empty: not id.is_empty
    type_valid: cell_type.same_string ("code") or cell_type.same_string ("markdown")
    status_valid: status in {Status_idle, Status_running, Status_success, Status_error}
    execution_time_non_negative: execution_time_ms >= 0
```
