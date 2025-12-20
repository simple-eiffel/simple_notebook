note
	description: "[
		SIMPLE_NOTEBOOK - Interactive Eiffel notebook environment

		Main facade for the simple_notebook library. Provides a clean API
		for creating, editing, and executing Eiffel notebooks.

		Usage:
			local
				nb: SIMPLE_NOTEBOOK
			do
				create nb.make
				nb.add_cell ("print (%"Hello, Eiffel!%")")
				nb.execute_all
				print (nb.output)
			end
	]"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	SIMPLE_NOTEBOOK

create
	make,
	make_with_config,
	make_from_file

feature {NONE} -- Initialization

	make
			-- Create new notebook with default configuration
		do
			create engine.make
		ensure
			engine_created: engine /= Void
		end

	make_with_config (a_config: NOTEBOOK_CONFIG)
			-- Create notebook with specific configuration
		require
			config_not_void: a_config /= Void
		do
			create engine.make_with_config (a_config)
		ensure
			engine_created: engine /= Void
		end

	make_from_file (a_path: READABLE_STRING_GENERAL)
			-- Open existing notebook from file
		require
			path_not_empty: a_path /= Void and then not a_path.is_empty
		do
			create engine.make
			engine.open_notebook (create {PATH}.make_from_string (a_path.to_string_32))
		end

feature -- Access

	engine: NOTEBOOK_ENGINE
			-- Underlying notebook engine

	output: STRING
			-- Combined output from all executed cells
		do
			create Result.make (1000)
			across engine.current_notebook.code_cells as c loop
				if not c.output.is_empty then
					if not Result.is_empty then
						Result.append ("%N")
					end
					Result.append (c.output)
				end
			end
		end

	last_output: STRING
			-- Output from most recently executed cell
		do
			if attached last_executed_cell_id as l_id then
				Result := engine.cell_output (l_id)
			else
				Result := ""
			end
		end

	variables: ARRAYED_LIST [VARIABLE_INFO]
			-- All tracked variables
		do
			Result := engine.all_variables
		end

	shared_variables: ARRAYED_LIST [VARIABLE_INFO]
			-- Shared (cross-cell) variables
		do
			Result := engine.shared_variables
		end

	cell_count: INTEGER
			-- Number of cells
		do
			Result := engine.cell_count
		end

	variable_count: INTEGER
			-- Number of tracked variables
		do
			Result := engine.variable_count
		end

	config: NOTEBOOK_CONFIG
			-- Current configuration
		do
			Result := engine.config
		end

	execution_time_ms: INTEGER_64
			-- Last execution time in milliseconds
		do
			Result := engine.last_execution_time_ms
		end

	last_compiler_output: STRING
			-- Compiler stdout/stderr from last execution (for verbose mode)
		do
			if attached engine.last_execution_result as r and then
			   attached r.compilation_result as cr then
				Result := cr.stdout + cr.stderr
			else
				create Result.make_empty
			end
		end

feature -- Status

	is_dirty: BOOLEAN
			-- Has notebook been modified?
		do
			Result := engine.is_dirty
		end

	has_file: BOOLEAN
			-- Is notebook associated with a file?
		do
			Result := engine.current_file_path /= Void
		end

	file_path: detachable STRING
			-- Current file path (if any)
		do
			if attached engine.current_file_path as p then
				Result := p.name.to_string_8
			end
		end

feature -- Cell Operations

	add_cell (a_code: STRING): STRING
			-- Add code cell and return cell ID
		require
			code_not_void: a_code /= Void
		do
			Result := engine.add_cell (a_code)
			last_executed_cell_id := Void
		ensure
			cell_added: cell_count = old cell_count + 1
		end

	add_markdown (a_content: STRING): STRING
			-- Add markdown cell and return cell ID
		require
			content_not_void: a_content /= Void
		do
			Result := engine.add_markdown_cell (a_content)
		end

	update_cell (a_id: STRING; a_code: STRING)
			-- Update cell code
		require
			id_valid: a_id /= Void and then not a_id.is_empty
			code_not_void: a_code /= Void
		do
			engine.update_cell (a_id, a_code)
		end

	remove_cell (a_id: STRING)
			-- Remove cell by ID
		require
			id_valid: a_id /= Void and then not a_id.is_empty
		do
			engine.remove_cell (a_id)
		end

	cell_code (a_id: STRING): STRING
			-- Get code for cell
		require
			id_valid: a_id /= Void and then not a_id.is_empty
		do
			Result := engine.cell_code (a_id)
		end

	cell_output (a_id: STRING): STRING
			-- Get output for cell
		require
			id_valid: a_id /= Void and then not a_id.is_empty
		do
			Result := engine.cell_output (a_id)
		end

feature -- Execution

	execute (a_id: STRING)
			-- Execute specific cell
		require
			id_valid: a_id /= Void and then not a_id.is_empty
		do
			engine.execute_cell (a_id)
			last_executed_cell_id := a_id
		end

	execute_all
			-- Execute all cells
		do
			engine.execute_all
			if cell_count > 0 then
				last_executed_cell_id := engine.current_notebook.cells.last.id
			end
		end

	execute_from (a_id: STRING)
			-- Execute from given cell to end
		require
			id_valid: a_id /= Void and then not a_id.is_empty
		do
			engine.execute_from (a_id)
			if cell_count > 0 then
				last_executed_cell_id := engine.current_notebook.cells.last.id
			end
		end

feature -- File Operations

	new_notebook
			-- Start fresh notebook
		do
			engine.new_session
			last_executed_cell_id := Void
		ensure
			empty: cell_count = 0
			no_variables: variable_count = 0
		end

	open (a_path: READABLE_STRING_GENERAL)
			-- Open notebook from file
		require
			path_valid: a_path /= Void and then not a_path.is_empty
		do
			engine.open_notebook (create {PATH}.make_from_string (a_path.to_string_32))
		end

	save
			-- Save to current file
		require
			has_file: has_file
		do
			engine.save_notebook
		ensure
			not_dirty: not is_dirty
		end

	save_as (a_path: READABLE_STRING_GENERAL)
			-- Save to new file
		require
			path_valid: a_path /= Void and then not a_path.is_empty
		do
			engine.save_notebook_as (create {PATH}.make_from_string (a_path.to_string_32))
		ensure
			not_dirty: not is_dirty
			has_file: has_file
		end

feature -- Quick API

	run (a_code: STRING): STRING
			-- Quick execute: add cell, run it, return output
		require
			code_not_void: a_code /= Void
		local
			l_id: STRING
		do
			l_id := add_cell (a_code)
			execute (l_id)
			Result := cell_output (l_id)
		end

	print_variables
			-- Print all variables to stdout
		do
			across variables as v loop
				print (v.formatted)
				print ("%N")
			end
		end

feature {NONE} -- Implementation

	last_executed_cell_id: detachable STRING
			-- ID of most recently executed cell

invariant
	engine_not_void: engine /= Void

end
