note
	description: "Tracks variables defined across notebook cells"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	VARIABLE_TRACKER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize tracker
		do
			create variables.make (10)
			create previous_state.make (10)
		end

feature -- Access

	variables: HASH_TABLE [VARIABLE_INFO, STRING]
			-- Current variables by name

	count: INTEGER
			-- Number of tracked variables
		do
			Result := variables.count
		end

	variable_by_name (a_name: STRING): detachable VARIABLE_INFO
			-- Get variable by name
		require
			name_not_empty: not a_name.is_empty
		do
			Result := variables.item (a_name)
		end

	all_variables: ARRAYED_LIST [VARIABLE_INFO]
			-- All variables as list
		do
			create Result.make (variables.count)
			across variables as v loop
				Result.extend (v)
			end
		end

	shared_variables: ARRAYED_LIST [VARIABLE_INFO]
			-- Only shared (cross-cell) variables
		do
			create Result.make (variables.count)
			across variables as v loop
				if v.is_shared then
					Result.extend (v)
				end
			end
		end

	variables_for_cell (a_cell_id: STRING): ARRAYED_LIST [VARIABLE_INFO]
			-- Variables defined in specific cell
		require
			cell_id_not_empty: not a_cell_id.is_empty
		do
			create Result.make (5)
			across variables as v loop
				if v.cell_id.same_string (a_cell_id) then
					Result.extend (v)
				end
			end
		end

feature -- Extraction

	extract_variables (a_notebook: NOTEBOOK): ARRAYED_LIST [VARIABLE_INFO]
			-- Extract variable definitions from notebook cells
		require
			notebook_not_void: a_notebook /= Void
		local
			l_vars: ARRAYED_LIST [VARIABLE_INFO]
		do
			create Result.make (10)

			across a_notebook.code_cells as c loop
				l_vars := extract_from_code (c.code, c.id)
				Result.append (l_vars)
			end

			-- Update internal state
			update_state (Result)
		end

	extract_from_code (a_code: STRING; a_cell_id: STRING): ARRAYED_LIST [VARIABLE_INFO]
			-- Extract variable definitions from code string
		require
			code_not_void: a_code /= Void
			cell_id_not_empty: not a_cell_id.is_empty
		local
			l_lines: LIST [STRING]
			l_line: STRING
			l_info: detachable VARIABLE_INFO
		do
			create Result.make (5)
			l_lines := a_code.split ('%N')

			across l_lines as line loop
				l_line := line.twin
				l_line.left_adjust

				-- Check for shared declaration
				if l_line.starts_with ("shared ") then
					l_info := parse_shared_declaration (l_line.substring (8, l_line.count), a_cell_id)
					if l_info /= Void then
						l_info.set_shared (True)
						Result.extend (l_info)
					end

				-- Check for local declaration
				elseif is_local_declaration (l_line) then
					l_info := parse_local_declaration (l_line, a_cell_id)
					if l_info /= Void then
						Result.extend (l_info)
					end
				end
			end
		end

feature -- Change Detection

	detect_changes (a_before: ARRAYED_LIST [VARIABLE_INFO]; a_after: ARRAYED_LIST [VARIABLE_INFO]): ARRAYED_LIST [VARIABLE_CHANGE]
			-- Detect changes between two states
		require
			before_not_void: a_before /= Void
			after_not_void: a_after /= Void
		local
			l_before_map: HASH_TABLE [VARIABLE_INFO, STRING]
			l_change: VARIABLE_CHANGE
		do
			create Result.make (10)
			create l_before_map.make (a_before.count)

			-- Index before state
			across a_before as v loop
				l_before_map.force (v, v.name)
			end

			-- Check after state
			across a_after as v loop
				if l_before_map.has (v.name) then
					-- Existing variable - check if modified
					if attached l_before_map.item (v.name) as old_var then
						if v.value_changed (old_var) then
							create l_change.make_modified (v.name, old_var.value, v.value)
							Result.extend (l_change)
						end
					end
				else
					-- New variable
					create l_change.make_new (v.name, v.type_name, v.value)
					Result.extend (l_change)
				end
			end

			-- Check for removed variables (in before but not in after)
			across a_before as v loop
				if not has_variable_named (a_after, v.name) then
					create l_change.make_removed (v.name)
					Result.extend (l_change)
				end
			end
		end

	save_state
			-- Save current state for later comparison
		do
			previous_state.wipe_out
			across variables as v loop
				previous_state.force (v.twin, v.name)
			end
		end

	changes_since_save: ARRAYED_LIST [VARIABLE_CHANGE]
			-- Changes since last save_state call
		local
			l_current: ARRAYED_LIST [VARIABLE_INFO]
			l_previous: ARRAYED_LIST [VARIABLE_INFO]
		do
			l_current := all_variables
			create l_previous.make (previous_state.count)
			across previous_state as v loop
				l_previous.extend (v)
			end
			Result := detect_changes (l_previous, l_current)
		end

feature -- Commands

	clear
			-- Clear all tracked variables
		do
			variables.wipe_out
			previous_state.wipe_out
		ensure
			empty: count = 0
		end

	add_variable (a_info: VARIABLE_INFO)
			-- Add or update a variable
		require
			info_not_void: a_info /= Void
		do
			variables.force (a_info, a_info.name)
		ensure
			has_variable: variables.has (a_info.name)
		end

	remove_variable (a_name: STRING)
			-- Remove a variable
		require
			name_not_empty: not a_name.is_empty
		do
			variables.remove (a_name)
		ensure
			removed: not variables.has (a_name)
		end

feature {NONE} -- Parsing

	parse_shared_declaration (a_decl: STRING; a_cell_id: STRING): detachable VARIABLE_INFO
			-- Parse "name: TYPE" declaration
		local
			l_colon: INTEGER
			l_name, l_type: STRING
		do
			l_colon := a_decl.index_of (':', 1)
			if l_colon > 1 then
				l_name := a_decl.substring (1, l_colon - 1)
				l_name.right_adjust
				l_type := a_decl.substring (l_colon + 1, a_decl.count)
				l_type.left_adjust
				l_type.right_adjust

				-- Remove any trailing assignment
				if l_type.has (' ') then
					l_type := l_type.substring (1, l_type.index_of (' ', 1) - 1)
				end

				create Result.make (l_name, l_type, a_cell_id)
			end
		end

	parse_local_declaration (a_line: STRING; a_cell_id: STRING): detachable VARIABLE_INFO
			-- Parse local variable declaration
		do
			Result := parse_shared_declaration (a_line, a_cell_id)
		end

	is_local_declaration (line: STRING): BOOLEAN
			-- Is this line a local variable declaration?
		local
			l_colon_pos, l_assign_pos: INTEGER
			l_before_colon: STRING
		do
			l_colon_pos := line.index_of (':', 1)
			l_assign_pos := line.index_of ('=', 1)

			if l_colon_pos > 1 then
				-- Has colon, check if it's a declaration vs assignment
				if l_assign_pos = 0 or else l_assign_pos < l_colon_pos then
					-- Check if before colon is a simple identifier
					l_before_colon := line.substring (1, l_colon_pos - 1)
					l_before_colon.right_adjust
					Result := is_identifier (l_before_colon)
				end
			end
		end

	is_identifier (s: STRING): BOOLEAN
			-- Is this a valid Eiffel identifier?
		local
			i: INTEGER
			c: CHARACTER
		do
			if s.count > 0 then
				c := s.item (1)
				if c.is_alpha or c = '_' then
					Result := True
					from i := 2 until i > s.count or not Result loop
						c := s.item (i)
						Result := c.is_alpha or c.is_digit or c = '_'
						i := i + 1
					end
				end
			end
		end

	has_variable_named (vars: ARRAYED_LIST [VARIABLE_INFO]; a_name: STRING): BOOLEAN
			-- Does list contain variable with given name?
		do
			across vars as v loop
				if v.name.same_string (a_name) then
					Result := True
				end
			end
		end

	update_state (vars: ARRAYED_LIST [VARIABLE_INFO])
			-- Update internal variables table
		do
			across vars as v loop
				variables.force (v, v.name)
			end
		end

feature {NONE} -- State

	previous_state: HASH_TABLE [VARIABLE_INFO, STRING]
			-- Previous state for change detection

invariant
	variables_not_void: variables /= Void
	previous_state_not_void: previous_state /= Void

end
