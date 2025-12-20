note
	description: "[
		Transforms notebook cells into a single accumulated Eiffel class for compilation.

		Eric Bezault Design: Uses CELL_CLASSIFIER for smart cell type detection.

		Cell types and their handling:
		- Attribute: becomes class attribute
		- Routine: becomes class feature (verbatim)
		- Instruction: wrapped in execute_cell_N
		- Expression: wrapped in execute_cell_N with print()
		- Class: generates separate file (via USER_CLASS_GENERATOR)
	]"
	author: "Larry Rix"
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
			create classifier.make
			create cell_attributes.make (10)
			create cell_routines.make (10)
			create executable_cells.make (10)
			create user_classes.make (5)
			current_line := 1
		end

feature -- Access

	line_mapping: LINE_MAPPING
			-- Maps generated line numbers to cell locations

	classifier: CELL_CLASSIFIER
			-- Cell content classifier

	last_class_name: STRING
			-- Name of last generated class
		attribute
			create Result.make_empty
		end

	user_classes: ARRAYED_LIST [TUPLE [name: STRING; content: STRING]]
			-- User-defined classes from class cells
			-- Each entry: [class_name, full_class_text]

feature -- Generation

	generate_class (a_notebook: NOTEBOOK): STRING
			-- Generate complete Eiffel class from notebook cells
		require
			notebook_has_cells: a_notebook.cell_count > 0
		local
			code_cells: ARRAYED_LIST [NOTEBOOK_CELL]
		do
			-- Reset state
			reset_state

			-- Classify all cells
			code_cells := a_notebook.code_cells
			classify_cells (code_cells)

			-- Build the class
			create Result.make (2000)
			Result.append (generate_header (a_notebook))
			Result.append (generate_cell_attributes)
			Result.append (generate_cell_routines)
			Result.append (generate_initialization)
			Result.append (generate_execute_all)
			Result.append (generate_executable_cell_features)
			Result.append (generate_footer)
		ensure
			result_not_empty: not Result.is_empty
		end

	generate_class_to_cell (a_notebook: NOTEBOOK; a_target_cell: NOTEBOOK_CELL): STRING
			-- Generate class executing cells up to and including target cell
		require
			notebook_not_empty: a_notebook.cell_count > 0
			cell_in_notebook: a_notebook.cell_by_id (a_target_cell.id) /= Void
		local
			code_cells: ARRAYED_LIST [NOTEBOOK_CELL]
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
			reset_state

			-- Classify cells up to target
			classify_cells (code_cells)

			-- Build the class
			create Result.make (2000)
			Result.append (generate_header (a_notebook))
			Result.append (generate_cell_attributes)
			Result.append (generate_cell_routines)
			Result.append (generate_initialization)
			Result.append (generate_execute_all)
			Result.append (generate_executable_cell_features)
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

feature {NONE} -- Classification

	classify_cells (cells: ARRAYED_LIST [NOTEBOOK_CELL])
			-- Classify all cells and sort into appropriate lists
		local
			l_classification: INTEGER
			l_index: INTEGER
		do
			l_index := 0
			across cells as c loop
				l_index := l_index + 1
				l_classification := classifier.classify (c.code)

				inspect l_classification
				when {CELL_CLASSIFIER}.Classification_attribute then
					cell_attributes.extend ([c, l_index])
				when {CELL_CLASSIFIER}.Classification_routine then
					cell_routines.extend ([c, l_index])
				when {CELL_CLASSIFIER}.Classification_instruction then
					executable_cells.extend ([c, l_index, False]) -- is_expression = False
				when {CELL_CLASSIFIER}.Classification_expression then
					executable_cells.extend ([c, l_index, True])  -- is_expression = True
				when {CELL_CLASSIFIER}.Classification_class then
					extract_user_class (c)
				else
					-- Empty or unknown: treat as expression if not empty
					if not c.code.is_empty then
						executable_cells.extend ([c, l_index, True])
					end
				end
			end
		end

	extract_user_class (a_cell: NOTEBOOK_CELL)
			-- Extract class name and content from a class cell
		local
			l_code, l_lower: STRING
			l_class_pos, l_name_start, l_name_end: INTEGER
			l_class_name: STRING
		do
			l_code := a_cell.code.twin
			l_lower := l_code.as_lower

			-- Find "class " keyword
			l_class_pos := l_lower.substring_index ("class ", 1)
			if l_class_pos > 0 then
				l_name_start := l_class_pos + 6
				-- Skip whitespace
				from until l_name_start > l_code.count or else not l_code.item (l_name_start).is_space loop
					l_name_start := l_name_start + 1
				end
				-- Find end of class name
				l_name_end := l_name_start
				from until l_name_end > l_code.count or else
				           l_code.item (l_name_end).is_space or else
				           l_code.item (l_name_end) = '%N' loop
					l_name_end := l_name_end + 1
				end

				if l_name_end > l_name_start then
					l_class_name := l_code.substring (l_name_start, l_name_end - 1)
					user_classes.extend ([l_class_name, l_code])
				end
			end
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

	generate_cell_attributes: STRING
			-- Generate attributes from attribute cells
		do
			create Result.make (200)
			if not cell_attributes.is_empty then
				add_line (Result, "feature -- Attributes (from cells)")
				add_line (Result, "")

				across cell_attributes as attr loop
					-- Add the attribute declaration verbatim (with indent)
					add_attribute_lines (Result, attr.cell.code, attr.index)
					add_line (Result, "")
				end
			end
		end

	add_attribute_lines (a_buffer: STRING; a_code: STRING; a_cell_index: INTEGER)
			-- Add attribute declaration lines to buffer with line mapping
		local
			l_lines: LIST [STRING]
			l_line_idx: INTEGER
		do
			-- Add cell identifier comment
			add_line (a_buffer, "%T%T-- Cell " + a_cell_index.out + ": cell_" + formatted_cell_id (a_cell_index))
			l_lines := a_code.split ('%N')
			from l_line_idx := 1 until l_line_idx > l_lines.count loop
				if not l_lines [l_line_idx].is_empty then
					line_mapping.add_mapping (current_line, "cell_" + a_cell_index.out, l_line_idx)
					add_line (a_buffer, "%T" + l_lines [l_line_idx].twin)
				end
				l_line_idx := l_line_idx + 1
			end
		end

feature {NONE} -- Routine Generation

	generate_cell_routines: STRING
			-- Generate routines from routine cells
		do
			create Result.make (500)
			if not cell_routines.is_empty then
				add_line (Result, "feature -- Routines (from cells)")
				add_line (Result, "")

				across cell_routines as routine loop
					-- Add the routine definition verbatim (with indent)
					add_routine_lines (Result, routine.cell.code, routine.index)
					add_line (Result, "")
				end
			end
		end

	add_routine_lines (a_buffer: STRING; a_code: STRING; a_cell_index: INTEGER)
			-- Add routine definition lines to buffer with line mapping
		local
			l_lines: LIST [STRING]
			l_line_idx: INTEGER
			l_line: STRING
		do
			-- Add cell identifier comment
			add_line (a_buffer, "%T%T-- Cell " + a_cell_index.out + ": cell_" + formatted_cell_id (a_cell_index))
			l_lines := a_code.split ('%N')
			from l_line_idx := 1 until l_line_idx > l_lines.count loop
				l_line := l_lines [l_line_idx].twin
				line_mapping.add_mapping (current_line, "cell_" + a_cell_index.out, l_line_idx)
				add_line (a_buffer, "%T" + l_line)
				l_line_idx := l_line_idx + 1
			end
		end

feature {NONE} -- Initialization Generation

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

feature {NONE} -- Execution Generation

	generate_execute_all: STRING
			-- Generate execute_all feature
		do
			create Result.make (300)
			add_line (Result, "feature -- Execution")
			add_line (Result, "")
			add_line (Result, "%Texecute_all")
			add_line (Result, "%T%T%T-- Execute all instruction/expression cells in order")
			add_line (Result, "%T%Tdo")

			across executable_cells as exec loop
				add_line (Result, "%T%T%Texecute_cell_" + exec.index.out)
			end

			add_line (Result, "%T%Tend")
			add_line (Result, "")
		end

	generate_executable_cell_features: STRING
			-- Generate execute_cell_N features for instruction/expression cells
		do
			create Result.make (500)

			across executable_cells as exec loop
				Result.append (generate_executable_cell_feature (exec.cell, exec.index, exec.is_expression))
			end
		end

	generate_executable_cell_feature (a_cell: NOTEBOOK_CELL; a_index: INTEGER; a_is_expression: BOOLEAN): STRING
			-- Generate execute_cell_N feature for an instruction or expression cell
			-- Note: Code is emitted verbatim - no automatic print() wrapping.
			-- User controls output explicitly.
		local
			l_lines: LIST [STRING]
			l_line_idx: INTEGER
			l_line: STRING
		do
			create Result.make (300)

			add_line (Result, "%Texecute_cell_" + a_index.out)
			add_line (Result, "%T%T%T-- Cell " + a_index.out + ": " + a_cell.id)
			add_line (Result, "%T%Tdo")

			l_lines := a_cell.code.split ('%N')
			from l_line_idx := 1 until l_line_idx > l_lines.count loop
				l_line := l_lines [l_line_idx].twin
				l_line.left_adjust
				l_line.right_adjust

				if not l_line.is_empty and then not l_line.starts_with ("--") then
					line_mapping.add_mapping (current_line, a_cell.id, l_line_idx)
					add_line (Result, "%T%T%T" + l_line)
				end
				l_line_idx := l_line_idx + 1
			end

			add_line (Result, "%T%Tend")
			add_line (Result, "")
		end

feature {NONE} -- Helpers

	reset_state
			-- Reset internal state for new generation
		do
			create line_mapping.make (100)
			cell_attributes.wipe_out
			cell_routines.wipe_out
			executable_cells.wipe_out
			user_classes.wipe_out
			current_line := 1
		end

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

	formatted_cell_id (n: INTEGER): STRING
			-- Format cell ID as three digits (e.g., 001, 012, 123)
		do
			if n < 10 then
				Result := "00" + n.out
			elseif n < 100 then
				Result := "0" + n.out
			else
				Result := n.out
			end
		end

feature {NONE} -- State

	current_line: INTEGER
			-- Current line number in generated output

	cell_attributes: ARRAYED_LIST [TUPLE [cell: NOTEBOOK_CELL; index: INTEGER]]
			-- Cells classified as attributes

	cell_routines: ARRAYED_LIST [TUPLE [cell: NOTEBOOK_CELL; index: INTEGER]]
			-- Cells classified as routines

	executable_cells: ARRAYED_LIST [TUPLE [cell: NOTEBOOK_CELL; index: INTEGER; is_expression: BOOLEAN]]
			-- Cells that need execute_cell_N (instructions and expressions)

end
