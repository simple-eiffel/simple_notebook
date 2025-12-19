note
	description: "Transforms notebook cells into a single accumulated Eiffel class for compilation"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	ACCUMULATED_CLASS_GENERATOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize generator
		do
			create line_mapping.make (100)
			create shared_variables.make (10)
			current_line := 1
		end

feature -- Access

	line_mapping: LINE_MAPPING
			-- Maps generated line numbers to cell locations

	last_class_name: STRING
			-- Name of last generated class
		attribute
			create Result.make_empty
		end

feature -- Generation

	generate_class (a_notebook: NOTEBOOK): STRING
			-- Generate complete Eiffel class from notebook cells
		require
			notebook_has_cells: a_notebook.cell_count > 0
		local
			code_cells: ARRAYED_LIST [NOTEBOOK_CELL]; i: INTEGER
		do
			-- Reset state
			create line_mapping.make (100)
			create shared_variables.make (10)
			current_line := 1

			code_cells := a_notebook.code_cells
			collect_shared_variables (code_cells)

			create Result.make (2000)
			Result.append (generate_header (a_notebook))
			Result.append (generate_result_attributes (code_cells))
			Result.append (generate_shared_attributes)
			Result.append (generate_initialization)
			Result.append (generate_execute_all (code_cells))

			from i := 1 until i > code_cells.count loop
				Result.append (generate_cell_feature (code_cells [i], i))
				i := i + 1
			end

			Result.append (generate_footer)
		ensure
			result_not_empty: not Result.is_empty
			line_mapping_populated: line_mapping.entry_count > 0
		end

	generate_class_to_cell (a_notebook: NOTEBOOK; a_target_cell: NOTEBOOK_CELL): STRING
			-- Generate class executing cells up to and including target cell
		require
			notebook_not_empty: a_notebook.cell_count > 0
			cell_in_notebook: a_notebook.cell_by_id (a_target_cell.id) /= Void
		local
			code_cells: ARRAYED_LIST [NOTEBOOK_CELL]; i: INTEGER
			target_order: INTEGER
		do
			target_order := a_target_cell.order

			-- Get code cells up to target
			create code_cells.make (target_order)
			across a_notebook.code_cells as c loop
				if c.order <= target_order then
					code_cells.extend (c)
				end
			end

			-- Reset state
			create line_mapping.make (100)
			create shared_variables.make (10)
			current_line := 1

			collect_shared_variables (code_cells)

			create Result.make (2000)
			Result.append (generate_header (a_notebook))
			Result.append (generate_result_attributes (code_cells))
			Result.append (generate_shared_attributes)
			Result.append (generate_initialization)
			Result.append (generate_execute_all (code_cells))

			from i := 1 until i > code_cells.count loop
				Result.append (generate_cell_feature (code_cells [i], i))
				i := i + 1
			end

			Result.append (generate_footer)
		end

	generate_ecf (a_notebook: NOTEBOOK; a_class_name: STRING): STRING
			-- Generate ECF file for compilation
		require
			notebook_not_void: a_notebook /= Void
			class_name_not_empty: not a_class_name.is_empty
		do
			create Result.make (500)
			Result.append ("<?xml version=%"1.0%" encoding=%"ISO-8859-1%"?>%N")
			Result.append ("<system xmlns=%"http://www.eiffel.com/developers/xml/configuration-1-23-0%"%N")
			Result.append ("        name=%"notebook_session%"%N")
			Result.append ("        uuid=%"00000000-0000-0000-0000-000000000001%">%N%N")

			Result.append ("    <target name=%"notebook_session%">%N")
			Result.append ("        <root class=%"" + a_class_name.as_upper + "%" feature=%"make%"/>%N%N")

			Result.append ("        <option warning=%"warning%" syntax=%"standard%">%N")
			Result.append ("            <assertions precondition=%"true%" postcondition=%"true%"/>%N")
			Result.append ("        </option>%N%N")

			Result.append ("        <setting name=%"console_application%" value=%"true%"/>%N")
			Result.append ("        <capability>%N")
			Result.append ("            <concurrency support=%"none%"/>%N")
			Result.append ("            <void_safety support=%"none%"/>%N")
			Result.append ("        </capability>%N%N")

			Result.append ("        <library name=%"base%" location=%"$ISE_LIBRARY/library/base/base.ecf%"/>%N")
			Result.append ("        <library name=%"time%" location=%"$ISE_LIBRARY/library/time/time.ecf%"/>%N%N")

			Result.append ("        <cluster name=%"src%" location=%".%"/>%N")
			Result.append ("    </target>%N")
			Result.append ("</system>%N")
		end

feature {NONE} -- Header/Footer Generation

	generate_header (a_notebook: NOTEBOOK): STRING
			-- Generate class header
		local
			l_timestamp: DATE_TIME
		do
			create l_timestamp.make_now
			last_class_name := "ACCUMULATED_SESSION_" + timestamp_string (l_timestamp)

			create Result.make (300)
			add_line (Result, "note")
			add_line (Result, "%Tdescription: %"Generated notebook session: " + a_notebook.name + "%"")
			add_line (Result, "%Tgenerated: %"" + l_timestamp.out + "%"")
			add_line (Result, "")
			add_line (Result, "class " + last_class_name)
			add_line (Result, "")
			add_line (Result, "inherit")
			add_line (Result, "%TANY")
			add_line (Result, "%T%Tredefine")
			add_line (Result, "%T%T%Tdefault_create")
			add_line (Result, "%T%Tend")
			add_line (Result, "")
			add_line (Result, "create")
			add_line (Result, "%Tmake, default_create")
			add_line (Result, "")
		end

	generate_footer: STRING
			-- Generate class footer
		do
			create Result.make (10)
			add_line (Result, "end")
		end

feature {NONE} -- Attribute Generation
	generate_result_attributes (cells: ARRAYED_LIST [NOTEBOOK_CELL]): STRING
			-- Generate cell result attributes
		local
			i: INTEGER
		do
			create Result.make (200)
			add_line (Result, "feature -- Cell Results")
			add_line (Result, "")

			from i := 1 until i > cells.count loop
				add_line (Result, "%Tcell_" + i.out + "_result: detachable ANY")
				add_line (Result, "%T%T%T-- Result from cell " + i.out)
				add_line (Result, "")
				i := i + 1
			end
		end

	generate_shared_attributes: STRING
			-- Generate shared variable attributes
		do
			create Result.make (200)
			if not shared_variables.is_empty then
				add_line (Result, "feature -- Shared Variables")
				add_line (Result, "")

				from shared_variables.start until shared_variables.after loop
					add_line (Result, "%T" + shared_variables.key_for_iteration + ": " + shared_variables.item_for_iteration)
					add_line (Result, "")
					shared_variables.forth
				end
			end
		end

feature {NONE} -- Method Generation

	generate_initialization: STRING
			-- Generate initialization features
		do
			create Result.make (200)
			add_line (Result, "feature {NONE} -- Initialization")
			add_line (Result, "")
			add_line (Result, "%Tdefault_create")
			add_line (Result, "%T%T%T-- Default creation")
			add_line (Result, "%T%Tdo")
			add_line (Result, "%T%T%Tmake")
			add_line (Result, "%T%Tend")
			add_line (Result, "")
			add_line (Result, "%Tmake")
			add_line (Result, "%T%T%T-- Execute all cells")
			add_line (Result, "%T%Tdo")
			add_line (Result, "%T%T%Texecute_all")
			add_line (Result, "%T%Tend")
			add_line (Result, "")
		end

	generate_execute_all (cells: ARRAYED_LIST [NOTEBOOK_CELL]): STRING
			-- Generate execute_all feature
		local
			i: INTEGER
		do
			create Result.make (300)
			add_line (Result, "feature -- Execution")
			add_line (Result, "")
			add_line (Result, "%Texecute_all")
			add_line (Result, "%T%T%T-- Execute all cells in order")
			add_line (Result, "%T%Tdo")

			from i := 1 until i > cells.count loop
				add_line (Result, "%T%T%Texecute_cell_" + i.out)
				i := i + 1
			end

			add_line (Result, "%T%Tend")
			add_line (Result, "")
		end

	generate_cell_feature (cell: NOTEBOOK_CELL; index: INTEGER): STRING
			-- Generate execute_cell_N feature for given cell
		local
			l_locals, l_body: STRING
			l_cell_start_line: INTEGER; l_lines: LIST [STRING]; l_line_idx: INTEGER
		do
			create Result.make (500)

			add_line (Result, "%Texecute_cell_" + index.out)
			add_line (Result, "%T%T%T-- Cell " + index.out + ": " + cell.id)

			-- Extract locals and body
			l_locals := extract_locals (cell.code)
			l_body := extract_body (cell.code)

			-- Generate local section if needed
			if not l_locals.is_empty then
				add_line (Result, "%T%Tlocal")
				across l_locals.split ('%N') as loc loop
					if not loc.is_empty then
						add_line (Result, "%T%T%T" + loc.twin)
					end
				end
			end

			add_line (Result, "%T%Tdo")

			-- Record start of cell code for line mapping
			l_cell_start_line := current_line

			-- Add body lines with line mapping
			l_lines := l_body.split ('%N')
			from l_line_idx := 1 until l_line_idx > l_lines.count loop
				line_mapping.add_mapping (current_line, cell.id, l_line_idx)
				add_line (Result, "%T%T%T" + l_lines [l_line_idx].twin)
				l_line_idx := l_line_idx + 1
			end

			-- Store result
			add_line (Result, "%T%T%T-- Store result")
			add_line (Result, "%T%T%Tcell_" + index.out + "_result := Void -- placeholder")

			add_line (Result, "%T%Tend")
			add_line (Result, "")
		end

feature {NONE} -- Code Parsing

	collect_shared_variables (cells: ARRAYED_LIST [NOTEBOOK_CELL])
			-- Parse cells for `shared x: TYPE` declarations
		local
			l_lines: LIST [STRING]
			l_line, l_name, l_type: STRING
			l_colon_pos: INTEGER
		do
			shared_variables.wipe_out

			across cells as c loop
				l_lines := c.code.split ('%N')
				across l_lines as line loop
					l_line := line.twin
					l_line.left_adjust
					if l_line.starts_with ("shared ") then
						-- Parse: shared var_name: TYPE
						l_line := l_line.substring (8, l_line.count)
						l_colon_pos := l_line.index_of (':', 1)
						if l_colon_pos > 0 then
							l_name := l_line.substring (1, l_colon_pos - 1)
							l_name.right_adjust
							l_type := l_line.substring (l_colon_pos + 1, l_line.count)
							l_type.left_adjust
							l_type.right_adjust
							shared_variables.force (l_type, l_name)
						end
					end
				end
			end
		end

	extract_locals (code: STRING): STRING
			-- Extract local declarations from cell code
		local
			l_lines: LIST [STRING]
			l_line: STRING
		do
			create Result.make (100)

			l_lines := code.split ('%N')
			across l_lines as line loop
				l_line := line.twin
				l_line.left_adjust

				-- Skip shared declarations (they become attributes)
				if not l_line.starts_with ("shared ") then
					-- Look for local declarations: name: TYPE
					if is_local_declaration (l_line) then
						if not Result.is_empty then
							Result.append ("%N")
						end
						Result.append (l_line)
					end
				end
			end
		end

	extract_body (code: STRING): STRING
			-- Extract executable statements from cell code
		local
			l_lines: LIST [STRING]
			l_line: STRING
		do
			create Result.make (code.count)

			l_lines := code.split ('%N')
			across l_lines as line loop
				l_line := line.twin
				l_line.left_adjust

				-- Skip shared declarations
				if not l_line.starts_with ("shared ") then
					-- Skip local declarations
					if not is_local_declaration (l_line) then
						if not Result.is_empty then
							Result.append ("%N")
						end
						Result.append (l_line)
					end
				end
			end
		end

	is_local_declaration (line: STRING): BOOLEAN
			-- Is this line a local variable declaration?
			-- Pattern: identifier: TYPE (no assignment)
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

feature {NONE} -- Helpers

	add_line (buffer: STRING; line: STRING)
			-- Add line to buffer and increment line counter
		do
			buffer.append (line)
			buffer.append ("%N")
			current_line := current_line + 1
		end

	timestamp_string (dt: DATE_TIME): STRING
			-- Format timestamp for class name
		do
			Result := dt.year.out +
			          two_digit (dt.month) +
			          two_digit (dt.day) + "_" +
			          two_digit (dt.hour) +
			          two_digit (dt.minute) +
			          two_digit (dt.second)
		end

	two_digit (n: INTEGER): STRING
			-- Format integer as two digits
		do
			if n < 10 then
				Result := "0" + n.out
			else
				Result := n.out
			end
		end

feature {NONE} -- State

	current_line: INTEGER
			-- Current line number in generated output

	shared_variables: HASH_TABLE [STRING, STRING]
			-- Shared variables: name -> type

end
