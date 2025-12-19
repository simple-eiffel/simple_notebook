note
	description: "Maps generated class line numbers back to notebook cell locations for error reporting"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	LINE_MAPPING

create
	make

feature {NONE} -- Initialization

	make (initial_capacity: INTEGER)
			-- Create mapping with initial capacity
		require
			positive_capacity: initial_capacity > 0
		do
			create entries.make (initial_capacity)
		end

feature -- Access

	cell_id_for_line (a_line: INTEGER): detachable STRING
			-- Get cell ID for generated line number
		do
			if attached entry_for_line (a_line) as e then
				Result := e.cell_id
			end
		end

	cell_line_for_line (a_line: INTEGER): INTEGER
			-- Get cell-relative line number for generated line
		do
			if attached entry_for_line (a_line) as e then
				Result := e.cell_line
			end
		end

	entry_for_line (a_line: INTEGER): detachable LINE_MAPPING_ENTRY
			-- Get full entry for line
		do
			across entries as e loop
				if e.generated_line = a_line then
					Result := e
				end
			end
		end

	entry_count: INTEGER
			-- Number of mapping entries
		do
			Result := entries.count
		end

	is_empty: BOOLEAN
			-- No entries?
		do
			Result := entries.is_empty
		end

feature -- Commands

	add_mapping (a_generated_line: INTEGER; a_cell_id: STRING; a_cell_line: INTEGER)
			-- Add mapping from generated line to cell location
		require
			valid_generated_line: a_generated_line > 0
			cell_id_not_empty: not a_cell_id.is_empty
			valid_cell_line: a_cell_line > 0
		local
			l_entry: LINE_MAPPING_ENTRY
		do
			create l_entry.make (a_generated_line, a_cell_id, a_cell_line)
			entries.extend (l_entry)
		ensure
			count_increased: entry_count = old entry_count + 1
		end

	clear
			-- Remove all mappings
		do
			entries.wipe_out
		ensure
			is_empty: is_empty
		end

feature -- Queries

	cells_in_range (start_line, end_line: INTEGER): ARRAYED_LIST [STRING]
			-- Get unique cell IDs for lines in range
		local
			l_seen: HASH_TABLE [BOOLEAN, STRING]
		do
			create Result.make (5)
			create l_seen.make (5)

			across entries as e loop
				if e.generated_line >= start_line and e.generated_line <= end_line then
					if not l_seen.has (e.cell_id) then
						Result.extend (e.cell_id)
						l_seen.force (True, e.cell_id)
					end
				end
			end
		end

	generated_lines_for_cell (a_cell_id: STRING): ARRAYED_LIST [INTEGER]
			-- Get all generated line numbers for a cell
		require
			cell_id_not_empty: not a_cell_id.is_empty
		do
			create Result.make (10)
			across entries as e loop
				if e.cell_id.same_string (a_cell_id) then
					Result.extend (e.generated_line)
				end
			end
		end

	first_line_for_cell (a_cell_id: STRING): INTEGER
			-- Get first generated line for a cell (0 if not found)
		require
			cell_id_not_empty: not a_cell_id.is_empty
		do
			across entries as e loop
				if e.cell_id.same_string (a_cell_id) then
					if Result = 0 or else e.generated_line < Result then
						Result := e.generated_line
					end
				end
			end
		end

	last_line_for_cell (a_cell_id: STRING): INTEGER
			-- Get last generated line for a cell (0 if not found)
		require
			cell_id_not_empty: not a_cell_id.is_empty
		do
			across entries as e loop
				if e.cell_id.same_string (a_cell_id) then
					if e.generated_line > Result then
						Result := e.generated_line
					end
				end
			end
		end

feature {NONE} -- Implementation

	entries: ARRAYED_LIST [LINE_MAPPING_ENTRY]
			-- Mapping entries

invariant
	entries_not_void: entries /= Void

end
