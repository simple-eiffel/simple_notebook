note
	description: "Parsed compiler error with cell mapping information"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	COMPILER_ERROR

create
	make,
	make_mapped

feature {NONE} -- Initialization

	make (a_code: STRING; a_message: STRING; a_line: INTEGER; a_class_name: STRING)
			-- Create error with raw compiler information
		require
			code_not_void: a_code /= Void
			message_not_void: a_message /= Void
			line_positive: a_line >= 0
			class_name_not_void: a_class_name /= Void
		do
			error_code := a_code
			message := a_message
			generated_line := a_line
			class_name := a_class_name
			cell_id := ""
			cell_line := 0
			source_line := ""
		ensure
			code_set: error_code = a_code
			message_set: message = a_message
			line_set: generated_line = a_line
			class_set: class_name = a_class_name
		end

	make_mapped (a_code: STRING; a_message: STRING; a_cell_id: STRING; a_cell_line: INTEGER; a_source: STRING)
			-- Create error mapped to cell location
		require
			code_not_void: a_code /= Void
			message_not_void: a_message /= Void
			cell_id_not_empty: not a_cell_id.is_empty
			cell_line_positive: a_cell_line > 0
			source_not_void: a_source /= Void
		do
			error_code := a_code
			message := a_message
			cell_id := a_cell_id
			cell_line := a_cell_line
			source_line := a_source
			generated_line := 0
			class_name := ""
		ensure
			code_set: error_code = a_code
			message_set: message = a_message
			cell_id_set: cell_id = a_cell_id
			cell_line_set: cell_line = a_cell_line
		end

feature -- Access

	error_code: STRING
			-- EiffelStudio error code (e.g., "VEEN", "VJAR")

	message: STRING
			-- Error message text

	generated_line: INTEGER
			-- Line number in generated class

	class_name: STRING
			-- Name of class with error

	cell_id: STRING
			-- Mapped cell ID (empty if not mapped)

	cell_line: INTEGER
			-- Line number within cell (0 if not mapped)

	source_line: STRING
			-- Source code line that caused error

feature -- Status

	is_mapped: BOOLEAN
			-- Has this error been mapped to a cell?
		do
			Result := not cell_id.is_empty and cell_line > 0
		end

feature -- Commands

	map_to_cell (a_cell_id: STRING; a_cell_line: INTEGER; a_source: STRING)
			-- Map this error to a cell location
		require
			cell_id_not_empty: not a_cell_id.is_empty
			cell_line_positive: a_cell_line > 0
			source_not_void: a_source /= Void
		do
			cell_id := a_cell_id
			cell_line := a_cell_line
			source_line := a_source
		ensure
			is_mapped: is_mapped
			cell_id_set: cell_id = a_cell_id
			cell_line_set: cell_line = a_cell_line
		end

feature -- Output

	formatted_message: STRING
			-- Nicely formatted error message with source context
		local
			l_trimmed: STRING
			l_indent: INTEGER
		do
			create Result.make (300)

			-- Header: Error in cell [N], line M:
			if is_mapped then
				Result.append ("Error in cell [")
				Result.append (cell_id_number)
				Result.append ("], line ")
				Result.append (cell_line.out)
				Result.append (":%N")
			else
				Result.append ("Error at line ")
				Result.append (generated_line.out)
				if not class_name.is_empty then
					Result.append (" in ")
					Result.append (class_name)
				end
				Result.append (":%N")
			end

			-- Error message
			Result.append ("  ")
			Result.append (error_code)
			Result.append (": ")
			Result.append (clean_message)
			Result.append ("%N")

			-- Source line with indicator
			if not source_line.is_empty then
				l_trimmed := source_line.twin
				l_indent := leading_spaces (source_line)
				l_trimmed.left_adjust

				Result.append ("%N     |  ")
				Result.append (l_trimmed)
				Result.append ("%N     |  ")
				Result.append (underline_for_error (l_trimmed))
				Result.append ("%N")
			end
		end

	formatted_message_compact: STRING
			-- Compact format: cell[N]:line: CODE: message
		do
			create Result.make (150)
			if is_mapped then
				Result.append ("cell[")
				Result.append (cell_id_number)
				Result.append ("]:")
				Result.append (cell_line.out)
				Result.append (": ")
			end
			Result.append (error_code)
			Result.append (": ")
			Result.append (clean_message)
		end

	short_message: STRING
			-- Short one-line error summary
		do
			create Result.make (100)
			Result.append (error_code)
			Result.append (": ")
			Result.append (clean_message)
		end

feature {NONE} -- Formatting Helpers

	cell_id_number: STRING
			-- Extract just the number from cell_id (e.g., "cell_001" -> "1")
		local
			l_num: STRING
			i: INTEGER
		do
			-- Find the numeric part
			create l_num.make_empty
			from i := cell_id.count until i < 1 or else not cell_id.item (i).is_digit loop
				l_num.prepend_character (cell_id.item (i))
				i := i - 1
			end
			if l_num.is_empty then
				Result := cell_id
			else
				-- Remove leading zeros
				from until l_num.is_empty or else l_num.item (1) /= '0' or else l_num.count = 1 loop
					l_num.remove_head (1)
				end
				Result := l_num
			end
		end

	clean_message: STRING
			-- Clean up error message (trim, single line)
		local
			l_newline_pos: INTEGER
		do
			Result := message.twin
			Result.left_adjust
			Result.right_adjust
			-- Take only first line if multi-line
			l_newline_pos := Result.index_of ('%N', 1)
			if l_newline_pos > 0 then
				Result := Result.substring (1, l_newline_pos - 1)
			end
		end

	leading_spaces (a_line: STRING): INTEGER
			-- Count leading spaces/tabs
		local
			i: INTEGER
		do
			from i := 1 until i > a_line.count or else not a_line.item (i).is_space loop
				Result := Result + 1
				i := i + 1
			end
		end

	underline_for_error (a_line: STRING): STRING
			-- Create underline indicator for error
			-- Uses ^^^^ for now (could be enhanced to target specific tokens)
		local
			l_len: INTEGER
		do
			create Result.make (a_line.count)
			-- Find first identifier or meaningful content
			l_len := meaningful_token_length (a_line)
			if l_len = 0 then
				l_len := a_line.count.min (20)
			end
			Result.append (create {STRING}.make_filled ('^', l_len))
		end

	meaningful_token_length (a_line: STRING): INTEGER
			-- Length of first meaningful token (identifier, operator, etc.)
			-- For smarter underlining
		local
			i, l_start: INTEGER
			l_in_token: BOOLEAN
		do
			-- Skip leading whitespace (already trimmed, but just in case)
			from i := 1 until i > a_line.count or else not a_line.item (i).is_space loop
				i := i + 1
			end
			l_start := i

			-- Find end of first token (identifier, number, or operator sequence)
			if i <= a_line.count then
				if a_line.item (i).is_alpha or a_line.item (i) = '_' then
					-- Identifier
					from until i > a_line.count or else not (a_line.item (i).is_alpha_numeric or a_line.item (i) = '_') loop
						i := i + 1
					end
				elseif a_line.item (i).is_digit then
					-- Number
					from until i > a_line.count or else not a_line.item (i).is_digit loop
						i := i + 1
					end
				else
					-- Operator or punctuation - take one or two chars
					i := i + 1
					if i <= a_line.count and then not a_line.item (i).is_alpha_numeric then
						i := i + 1
					end
				end
			end

			Result := i - l_start
			if Result < 3 then
				-- Minimum underline length
				Result := a_line.count.min (10)
			end
		end

invariant
	error_code_not_void: error_code /= Void
	message_not_void: message /= Void
	cell_id_not_void: cell_id /= Void
	source_line_not_void: source_line /= Void

end
