note
	description: "Single entry in line mapping: generated line -> cell location"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	LINE_MAPPING_ENTRY

create
	make

feature {NONE} -- Initialization

	make (a_generated_line: INTEGER; a_cell_id: STRING; a_cell_line: INTEGER)
			-- Create mapping entry
		require
			valid_generated_line: a_generated_line > 0
			cell_id_not_empty: not a_cell_id.is_empty
			valid_cell_line: a_cell_line > 0
		do
			generated_line := a_generated_line
			cell_id := a_cell_id
			cell_line := a_cell_line
		ensure
			generated_line_set: generated_line = a_generated_line
			cell_id_set: cell_id = a_cell_id
			cell_line_set: cell_line = a_cell_line
		end

feature -- Access

	generated_line: INTEGER
			-- Line number in generated class

	cell_id: STRING
			-- ID of source cell

	cell_line: INTEGER
			-- Line number within cell (1-based)

feature -- Output

	formatted: STRING
			-- String representation
		do
			Result := "Line " + generated_line.out + " -> " + cell_id + ":" + cell_line.out
		end

invariant
	generated_line_positive: generated_line > 0
	cell_id_not_empty: not cell_id.is_empty
	cell_line_positive: cell_line > 0

end
