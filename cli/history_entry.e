note
	description: "A single entry in command history"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	HISTORY_ENTRY

create
	make,
	make_with_timestamp

feature {NONE} -- Initialization

	make (a_input: STRING; a_cell_number: INTEGER)
			-- Create entry with current timestamp
		require
			input_not_void: a_input /= Void
			cell_valid: a_cell_number >= 0
		local
			l_time: DATE_TIME
		do
			input := a_input.twin
			cell_number := a_cell_number
			create l_time.make_now
			-- Unix timestamp (seconds since epoch, approximated)
			timestamp := l_time.date.days.to_integer_64 * 86400 +
			             l_time.time.seconds.to_integer_64
		ensure
			input_set: input.same_string (a_input)
			cell_set: cell_number = a_cell_number
		end

	make_with_timestamp (a_input: STRING; a_cell_number: INTEGER; a_timestamp: INTEGER_64)
			-- Create entry with specific timestamp (for loading from file)
		require
			input_not_void: a_input /= Void
			cell_valid: a_cell_number >= 0
		do
			input := a_input.twin
			cell_number := a_cell_number
			timestamp := a_timestamp
		ensure
			input_set: input.same_string (a_input)
			cell_set: cell_number = a_cell_number
			timestamp_set: timestamp = a_timestamp
		end

feature -- Access

	input: STRING
			-- The input that was entered

	cell_number: INTEGER
			-- Cell number when this was entered (0 for commands)

	timestamp: INTEGER_64
			-- When this was entered (seconds since epoch)

feature -- Display

	formatted: STRING
			-- Format for display in -history listing
		do
			create Result.make (80)
			if cell_number > 0 then
				Result.append ("[")
				Result.append (cell_number.out)
				Result.append ("] ")
			else
				Result.append ("[-] ")
			end
			Result.append (first_line)
			if is_multiline then
				Result.append (" ...")
			end
		end

	first_line: STRING
			-- First line of input (for display)
		local
			l_pos: INTEGER
		do
			l_pos := input.index_of ('%N', 1)
			if l_pos > 0 then
				Result := input.substring (1, l_pos - 1)
			else
				Result := input.twin
			end
			-- Truncate if too long
			if Result.count > 60 then
				Result := Result.substring (1, 57) + "..."
			end
		end

	is_multiline: BOOLEAN
			-- Does input span multiple lines?
		do
			Result := input.has ('%N')
		end

invariant
	input_not_void: input /= Void
	cell_non_negative: cell_number >= 0

end
