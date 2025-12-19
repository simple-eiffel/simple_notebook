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
			-- Nicely formatted error message
		do
			create Result.make (200)

			if is_mapped then
				Result.append ("Error in cell [")
				Result.append (cell_id)
				Result.append ("], line ")
				Result.append (cell_line.out)
				Result.append (":%N")
			else
				Result.append ("Error at line ")
				Result.append (generated_line.out)
				Result.append (" in ")
				Result.append (class_name)
				Result.append (":%N")
			end

			Result.append ("  ")
			Result.append (error_code)
			Result.append (": ")
			Result.append (message)
			Result.append ("%N")

			if not source_line.is_empty then
				Result.append ("%N  |  ")
				Result.append (source_line)
				Result.append ("%N")
			end
		end

	short_message: STRING
			-- Short one-line error summary
		do
			create Result.make (100)
			Result.append (error_code)
			Result.append (": ")
			Result.append (message)
		end

invariant
	error_code_not_void: error_code /= Void
	message_not_void: message /= Void
	cell_id_not_void: cell_id /= Void
	source_line_not_void: source_line /= Void

end
