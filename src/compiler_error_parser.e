note
	description: "Parses EiffelStudio compiler error output and maps to cell locations"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	COMPILER_ERROR_PARSER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize parser
		do
			-- Ready to parse
		end

feature -- Parsing

	parse_errors (a_output: STRING): ARRAYED_LIST [COMPILER_ERROR]
			-- Parse compiler output for errors
		require
			output_not_void: a_output /= Void
		local
			l_lines: LIST [STRING]
			l_line: STRING
			l_error: detachable COMPILER_ERROR
			l_in_error: BOOLEAN
			l_error_code, l_message, l_class: STRING
			l_line_num: INTEGER
		do
			create Result.make (10)
			l_lines := a_output.split ('%N')
			l_error_code := ""
			l_message := ""
			l_class := ""
			l_line_num := 0

			across l_lines as line loop
				l_line := line.twin
				l_line.left_adjust

				if l_line.starts_with ("Error code: ") then
					-- Start of new error
					if l_error /= Void then
						Result.extend (l_error)
					end
					l_error_code := l_line.substring (13, l_line.count)
					l_in_error := True
					l_message := ""
					l_class := ""
					l_line_num := 0

				elseif l_in_error and l_line.starts_with ("Error: ") then
					l_message := l_line.substring (8, l_line.count)

				elseif l_in_error and l_line.starts_with ("Line: ") then
					l_line_num := extract_line_number (l_line)

				elseif l_in_error and l_line.starts_with ("Class: ") then
					l_class := l_line.substring (8, l_line.count)

				elseif l_in_error and l_line.starts_with ("What to do: ") then
					-- End of error block
					create l_error.make (l_error_code, l_message, l_line_num, l_class)
					l_in_error := False

				elseif is_vd_error_line (l_line) then
					-- Parse VD-style validity error: "VD[XX]: message"
					l_error := parse_vd_error (l_line)
					if l_error /= Void then
						Result.extend (l_error)
						l_error := Void
					end

				elseif is_syntax_error_line (l_line) then
					-- Parse syntax error
					l_error := parse_syntax_error (l_line)
					if l_error /= Void then
						Result.extend (l_error)
						l_error := Void
					end
				end
			end

			-- Don't forget last error if no "What to do" line
			if l_error /= Void then
				Result.extend (l_error)
			end
		end

	map_errors_to_cells (a_errors: ARRAYED_LIST [COMPILER_ERROR]; a_mapping: LINE_MAPPING; a_notebook: NOTEBOOK)
			-- Map parsed errors to cell locations using line mapping
		require
			errors_not_void: a_errors /= Void
			mapping_not_void: a_mapping /= Void
			notebook_not_void: a_notebook /= Void
		local
			l_cell_id: detachable STRING
			l_cell_line: INTEGER
			l_source: STRING
		do
			across a_errors as e loop
				if e.generated_line > 0 and not e.is_mapped then
					l_cell_id := a_mapping.cell_id_for_line (e.generated_line)
					if attached l_cell_id as cid then
						l_cell_line := a_mapping.cell_line_for_line (e.generated_line)

						-- Get source line from cell
						l_source := ""
						if attached a_notebook.cell_by_id (cid) as cell then
							l_source := get_source_line (cell.code, l_cell_line)
						end

						e.map_to_cell (cid, l_cell_line, l_source)
					end
				end
			end
		end

feature {NONE} -- Error Line Detection

	is_vd_error_line (line: STRING): BOOLEAN
			-- Is this a VD-style validity error line?
		do
			Result := line.count >= 4 and then
			         line.item (1) = 'V' and then
			         line.item (2).is_alpha and then
			         line.index_of (':', 1) > 0
		end

	is_syntax_error_line (line: STRING): BOOLEAN
			-- Is this a syntax error line?
		do
			Result := line.has_substring ("Syntax error") or
			         line.has_substring ("syntax error") or
			         line.has_substring ("SXXX")
		end

feature {NONE} -- Parsing Helpers

	parse_vd_error (line: STRING): detachable COMPILER_ERROR
			-- Parse VD-style error: "VEEN: Feature 'foo' is not..."
		local
			l_colon: INTEGER
			l_code, l_message: STRING
		do
			l_colon := line.index_of (':', 1)
			if l_colon > 0 then
				l_code := line.substring (1, l_colon - 1)
				l_code.right_adjust
				l_message := line.substring (l_colon + 1, line.count)
				l_message.left_adjust
				create Result.make (l_code, l_message, 0, "")
			end
		end

	parse_syntax_error (line: STRING): detachable COMPILER_ERROR
			-- Parse syntax error line
		local
			l_line_num: INTEGER
			l_message: STRING
		do
			l_line_num := extract_line_number (line)
			l_message := line.twin
			create Result.make ("SXXX", l_message, l_line_num, "")
		end

	extract_line_number (line: STRING): INTEGER
			-- Extract line number from string like "Line: 42" or "line 42"
		local
			i: INTEGER
			l_num_start, l_num_end: INTEGER
			l_in_number: BOOLEAN
		do
			from
				i := 1
				l_in_number := False
			until
				i > line.count or (l_in_number and not line.item (i).is_digit)
			loop
				if line.item (i).is_digit then
					if not l_in_number then
						l_num_start := i
						l_in_number := True
					end
					l_num_end := i
				end
				i := i + 1
			end

			if l_in_number and l_num_start > 0 then
				Result := line.substring (l_num_start, l_num_end).to_integer
			end
		end

	get_source_line (code: STRING; line_num: INTEGER): STRING
			-- Get specific line from code
		local
			l_lines: LIST [STRING]
		do
			Result := ""
			if line_num > 0 then
				l_lines := code.split ('%N')
				if line_num <= l_lines.count then
					Result := l_lines [line_num].twin
				end
			end
		end

end
