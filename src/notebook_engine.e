note
	description: "Main engine that orchestrates notebook execution"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	NOTEBOOK_ENGINE

create
	make,
	make_with_config

feature {NONE} -- Initialization

	make
			-- Create engine with default configuration
		do
			create config.make_with_defaults
			initialize
		ensure
			config_set: config /= Void
			notebook_created: current_notebook /= Void
		end

	make_with_config (a_config: NOTEBOOK_CONFIG)
			-- Create engine with specific configuration
		require
			config_not_void: a_config /= Void
		do
			config := a_config
			initialize
		ensure
			config_set: config = a_config
			notebook_created: current_notebook /= Void
		end

	initialize
			-- Initialize engine components
		do
			create current_notebook.make ("untitled")
			create variable_tracker.make
			create code_generator.make
			create executor.make (config)
			create storage.make (config.workspace_dir)
			cell_counter := 0
			is_dirty := False
			last_execution_time_ms := 0
		end

feature -- Access

	config: NOTEBOOK_CONFIG
			-- Current configuration

	current_notebook: NOTEBOOK
			-- Active notebook

	variable_tracker: VARIABLE_TRACKER
			-- Tracks variables across cells

	code_generator: ACCUMULATED_CLASS_GENERATOR
			-- Generates Eiffel code from cells

	executor: CELL_EXECUTOR
			-- Compiles and runs generated code

	storage: NOTEBOOK_STORAGE
			-- File persistence

	current_file_path: detachable PATH
			-- Path of currently open notebook

	cell_counter: INTEGER
			-- Counter for unique cell IDs

	last_execution_time_ms: INTEGER_64
			-- Execution time of last run in milliseconds

feature -- Status

	is_dirty: BOOLEAN
			-- Has notebook been modified since last save?

	has_notebook: BOOLEAN
			-- Is a notebook currently loaded?
		do
			Result := current_notebook /= Void
		end

	cell_count: INTEGER
			-- Number of cells in current notebook
		do
			Result := current_notebook.cell_count
		end

	variable_count: INTEGER
			-- Number of tracked variables
		do
			Result := variable_tracker.count
		end

feature -- Session Management

	new_session
			-- Start a new notebook session
		do
			create current_notebook.make ("untitled")
			variable_tracker.clear
			current_file_path := Void
			cell_counter := 0
			is_dirty := False
		ensure
			fresh_notebook: current_notebook.cell_count = 0
			no_variables: variable_tracker.count = 0
			no_file: current_file_path = Void
			not_dirty: not is_dirty
		end

	open_notebook (a_path: PATH)
			-- Open notebook from file
		require
			path_not_void: a_path /= Void
		local
			l_notebook: detachable NOTEBOOK
			l_vars: ARRAYED_LIST [VARIABLE_INFO]
		do
			l_notebook := storage.load (a_path.name.to_string_8)
			if l_notebook /= Void then
				current_notebook := l_notebook
				current_file_path := a_path
				is_dirty := False
				-- Re-extract variables from loaded notebook
				variable_tracker.clear
				l_vars := variable_tracker.extract_variables (current_notebook)
			end
		ensure
			file_path_set: attached current_file_path as cfp implies cfp.name.same_string (a_path.name)
		end

	save_notebook
			-- Save notebook to current path
		require
			has_path: current_file_path /= Void
		local
			l_ok: BOOLEAN
		do
			if attached current_file_path as l_path then
				l_ok := storage.save (current_notebook, l_path.name.to_string_8)
				is_dirty := False
			end
		ensure
			not_dirty: not is_dirty
		end

	save_notebook_as (a_path: PATH)
			-- Save notebook to new path
		require
			path_not_void: a_path /= Void
		local
			l_ok: BOOLEAN
		do
			l_ok := storage.save (current_notebook, a_path.name.to_string_8)
			current_file_path := a_path
			is_dirty := False
		ensure
			path_updated: current_file_path = a_path
			not_dirty: not is_dirty
		end

feature -- Cell Management

	add_cell (a_code: STRING): STRING
			-- Add new code cell and return its ID
		require
			code_not_void: a_code /= Void
		local
			l_cell: NOTEBOOK_CELL
			l_id: STRING
		do
			l_id := next_cell_id
			create l_cell.make_code (l_id)
			l_cell.set_code (a_code)
			current_notebook.add_cell (l_cell)
			is_dirty := True
			Result := l_id
		ensure
			cell_added: current_notebook.cell_count = old current_notebook.cell_count + 1
			is_dirty: is_dirty
			result_not_empty: not Result.is_empty
		end

	add_markdown_cell (a_content: STRING): STRING
			-- Add new markdown cell and return its ID
		require
			content_not_void: a_content /= Void
		local
			l_cell: NOTEBOOK_CELL
			l_id: STRING
		do
			l_id := next_cell_id
			create l_cell.make_markdown (l_id)
			l_cell.set_code (a_content)
			current_notebook.add_cell (l_cell)
			is_dirty := True
			Result := l_id
		ensure
			cell_added: current_notebook.cell_count = old current_notebook.cell_count + 1
			is_dirty: is_dirty
		end

	update_cell (a_id: STRING; a_code: STRING)
			-- Update existing cell code
		require
			id_not_empty: not a_id.is_empty
			code_not_void: a_code /= Void
			cell_exists: current_notebook.cell_by_id (a_id) /= Void
		do
			if attached current_notebook.cell_by_id (a_id) as l_cell then
				l_cell.set_code (a_code)
				l_cell.set_status ({NOTEBOOK_CELL}.Status_idle)
				is_dirty := True
			end
		ensure
			is_dirty: is_dirty
		end

	remove_cell (a_id: STRING)
			-- Remove cell by ID
		require
			id_not_empty: not a_id.is_empty
			cell_exists: current_notebook.cell_by_id (a_id) /= Void
		do
			current_notebook.remove_cell (a_id)
			is_dirty := True
		ensure
			cell_removed: current_notebook.cell_by_id (a_id) = Void
			is_dirty: is_dirty
		end

	cell_code (a_id: STRING): STRING
			-- Get code for cell
		require
			id_not_empty: not a_id.is_empty
			cell_exists: current_notebook.cell_by_id (a_id) /= Void
		do
			if attached current_notebook.cell_by_id (a_id) as l_cell then
				Result := l_cell.code
			else
				Result := ""
			end
		end

	cell_output (a_id: STRING): STRING
			-- Get output for cell
		require
			id_not_empty: not a_id.is_empty
		do
			if attached current_notebook.cell_by_id (a_id) as l_cell then
				Result := l_cell.output
			else
				Result := ""
			end
		end

feature -- Execution

	execute_cell (a_id: STRING)
			-- Execute a single cell
		require
			id_not_empty: not a_id.is_empty
			cell_exists: current_notebook.cell_by_id (a_id) /= Void
		local
			l_exec_result: EXECUTION_RESULT
			l_start_time: INTEGER_64
			l_time: TIME
			l_vars: ARRAYED_LIST [VARIABLE_INFO]
		do
			create l_time.make_now
			l_start_time := l_time.seconds.to_integer_64 * 1000

			if attached current_notebook.cell_by_id (a_id) as l_cell then
				l_cell.set_status ({NOTEBOOK_CELL}.Status_running)

				-- Execute using CELL_EXECUTOR
				l_exec_result := executor.execute_single_cell (current_notebook, l_cell)

				if l_exec_result.compilation_succeeded and l_exec_result.execution_succeeded then
					l_cell.set_output (l_exec_result.stdout)
					l_cell.set_status ({NOTEBOOK_CELL}.Status_success)
					-- Update variable tracker
					l_vars := variable_tracker.extract_from_code (l_cell.code, a_id)
				else
					l_cell.set_status ({NOTEBOOK_CELL}.Status_error)
					if not l_exec_result.compilation_succeeded then
						-- Compilation failed
						if attached l_exec_result.compilation_result as cr then
							l_cell.set_output (format_compilation_errors (cr))
						else
							l_cell.set_output ("Compilation failed")
						end
					elseif l_exec_result.timed_out then
						l_cell.set_output ("Execution timed out after " + config.timeout_seconds.out + " seconds")
					else
						l_cell.set_output (l_exec_result.stderr)
					end
				end

				is_dirty := True
			end

			create l_time.make_now
			last_execution_time_ms := l_time.seconds.to_integer_64 * 1000 - l_start_time
		end

	execute_all
			-- Execute all code cells in order
		do
			across current_notebook.code_cells as c loop
				execute_cell (c.id)
			end
		end

	execute_from (a_id: STRING)
			-- Execute from given cell to end
		require
			id_not_empty: not a_id.is_empty
			cell_exists: current_notebook.cell_by_id (a_id) /= Void
		local
			l_found: BOOLEAN
		do
			across current_notebook.code_cells as c loop
				if c.id.same_string (a_id) then
					l_found := True
				end
				if l_found then
					execute_cell (c.id)
				end
			end
		end

feature -- Variables

	shared_variables: ARRAYED_LIST [VARIABLE_INFO]
			-- All shared variables in session
		do
			Result := variable_tracker.shared_variables
		end

	all_variables: ARRAYED_LIST [VARIABLE_INFO]
			-- All tracked variables
		do
			Result := variable_tracker.all_variables
		end

	variables_for_cell (a_id: STRING): ARRAYED_LIST [VARIABLE_INFO]
			-- Variables defined in specific cell
		require
			id_not_empty: not a_id.is_empty
		do
			Result := variable_tracker.variables_for_cell (a_id)
		end

feature {NONE} -- Implementation

	next_cell_id: STRING
			-- Generate next unique cell ID
		do
			cell_counter := cell_counter + 1
			Result := "cell_" + cell_counter.out.as_lower
			Result.prepend_character ('0')
			if cell_counter < 10 then
				Result := "cell_00" + cell_counter.out
			elseif cell_counter < 100 then
				Result := "cell_0" + cell_counter.out
			else
				Result := "cell_" + cell_counter.out
			end
		ensure
			result_not_empty: not Result.is_empty
		end

	format_compilation_errors (a_result: COMPILATION_RESULT): STRING
			-- Format compilation errors for display
		require
			result_not_void: a_result /= Void
		do
			create Result.make (500)
			Result.append ("Compilation failed:%N")
			across a_result.errors as e loop
				Result.append ("  ")
				if e.is_mapped then
					Result.append ("Cell ")
					Result.append (e.cell_id)
					Result.append (", line ")
					Result.append (e.cell_line.out)
					Result.append (": ")
				end
				Result.append (e.error_code)
				Result.append (": ")
				Result.append (e.message)
				Result.append ("%N")
			end
		end

invariant
	config_not_void: config /= Void
	notebook_not_void: current_notebook /= Void
	tracker_not_void: variable_tracker /= Void
	generator_not_void: code_generator /= Void
	executor_not_void: executor /= Void
	storage_not_void: storage /= Void

end
