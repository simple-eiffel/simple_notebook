note
	description: "[
		Command history manager for Eiffel Notebook CLI.

		Provides:
		- Persistent storage of input history
		- Navigation (up/down) through previous inputs
		- Re-execution by cell number (!N, !!)
		- Configurable max entries (default 1000)
	]"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	COMMAND_HISTORY

create
	make

feature {NONE} -- Initialization

	make (a_history_dir: PATH)
			-- Create history manager with storage in `a_history_dir`
		require
			dir_not_void: a_history_dir /= Void
		do
			history_dir := a_history_dir
			create entries.make (100)
			current_index := 0
			max_entries := Default_max_entries
			ensure_directory_exists
			load
		ensure
			dir_set: history_dir = a_history_dir
		end

feature -- Constants

	Default_max_entries: INTEGER = 1000
			-- Default maximum history entries

	History_file_name: STRING = "history"
			-- Name of history file

feature -- Access

	entries: ARRAYED_LIST [HISTORY_ENTRY]
			-- All history entries (oldest first)

	max_entries: INTEGER
			-- Maximum number of entries to keep

	count: INTEGER
			-- Number of history entries
		do
			Result := entries.count
		end

	current_index: INTEGER
			-- Current navigation position (0 = new input, 1 = most recent, etc.)

	entry_at (a_num: INTEGER): detachable HISTORY_ENTRY
			-- Entry at position `a_num` (1-based from oldest)
		require
			valid_num: a_num >= 1 and a_num <= count
		do
			Result := entries.i_th (a_num)
		end

	recent_entry (a_offset: INTEGER): detachable HISTORY_ENTRY
			-- Entry at `a_offset` from end (1 = most recent, 2 = second most recent)
		require
			valid_offset: a_offset >= 1 and a_offset <= count
		do
			Result := entries.i_th (count - a_offset + 1)
		end

	last_entry: detachable HISTORY_ENTRY
			-- Most recent entry
		do
			if not entries.is_empty then
				Result := entries.last
			end
		end

feature -- Status

	is_empty: BOOLEAN
			-- Is history empty?
		do
			Result := entries.is_empty
		end

	has_previous: BOOLEAN
			-- Is there a previous entry (for up navigation)?
		do
			Result := current_index < count
		end

	has_next: BOOLEAN
			-- Is there a next entry (for down navigation)?
		do
			Result := current_index > 0
		end

feature -- Navigation

	reset_navigation
			-- Reset to "new input" position
		do
			current_index := 0
		ensure
			at_new: current_index = 0
		end

	move_up: detachable STRING
			-- Move to previous (older) entry, return its input
		do
			if has_previous then
				current_index := current_index + 1
				if attached recent_entry (current_index) as e then
					Result := e.input
				end
			end
		ensure
			moved_if_possible: old has_previous implies current_index = old current_index + 1
		end

	move_down: detachable STRING
			-- Move to next (newer) entry, return its input
			-- Returns empty string when back at "new input" position
		do
			if current_index > 1 then
				current_index := current_index - 1
				if attached recent_entry (current_index) as e then
					Result := e.input
				end
			elseif current_index = 1 then
				current_index := 0
				Result := ""
			end
		ensure
			moved_if_possible: old current_index > 0 implies current_index = old current_index - 1
		end

feature -- Element change

	add (a_input: STRING; a_cell_number: INTEGER)
			-- Add new entry to history
		require
			input_not_void: a_input /= Void
			cell_positive: a_cell_number >= 0
		local
			l_entry: HISTORY_ENTRY
		do
			create l_entry.make (a_input, a_cell_number)
			entries.extend (l_entry)

			-- Trim if over max
			from
			until
				entries.count <= max_entries
			loop
				entries.start
				entries.remove
			end

			reset_navigation
			save
		ensure
			added: entries.last.input.same_string (a_input)
			not_over_max: entries.count <= max_entries
			navigation_reset: current_index = 0
		end

	set_max_entries (a_max: INTEGER)
			-- Set maximum entries to keep
		require
			positive: a_max > 0
		do
			max_entries := a_max
		ensure
			set: max_entries = a_max
		end

feature -- Query

	recent (a_count: INTEGER): ARRAYED_LIST [HISTORY_ENTRY]
			-- Most recent `a_count` entries (newest first)
		require
			positive: a_count > 0
		local
			i, l_actual: INTEGER
		do
			l_actual := a_count.min (count)
			create Result.make (l_actual)
			from
				i := 1
			until
				i > l_actual
			loop
				if attached recent_entry (i) as e then
					Result.extend (e)
				end
				i := i + 1
			end
		ensure
			count_ok: Result.count = a_count.min (count)
		end

	find_by_cell (a_cell_number: INTEGER): detachable HISTORY_ENTRY
			-- Find entry for cell number `a_cell_number`
		local
			i: INTEGER
		do
			-- Search from newest to oldest
			from
				i := count
			until
				i < 1 or Result /= Void
			loop
				if attached entries.i_th (i) as e and then e.cell_number = a_cell_number then
					Result := e
				end
				i := i - 1
			end
		end

feature -- Persistence

	load
			-- Load history from file
		local
			l_file: PLAIN_TEXT_FILE
			l_line, l_input: STRING
			l_parts: LIST [STRING]
			l_timestamp: INTEGER_64
			l_cell: INTEGER
			l_entry: HISTORY_ENTRY
			l_retried: BOOLEAN
		do
			if not l_retried then
				entries.wipe_out
				create l_file.make_with_path (history_file_path)
				if l_file.exists then
					l_file.open_read
					from
					until
						l_file.end_of_file
					loop
						l_file.read_line
						l_line := l_file.last_string.twin
						-- Format: timestamp|cell_number|input (input may contain |)
						if l_line.count > 0 then
							l_parts := l_line.split ('|')
							if l_parts.count >= 3 then
								if l_parts.i_th (1).is_integer_64 then
									l_timestamp := l_parts.i_th (1).to_integer_64
								else
									l_timestamp := 0
								end
								if l_parts.i_th (2).is_integer then
									l_cell := l_parts.i_th (2).to_integer
								else
									l_cell := 0
								end
								-- Reconstruct input (may contain |)
								l_input := l_parts.i_th (3).twin
								from
									l_parts.go_i_th (4)
								until
									l_parts.after
								loop
									l_input.append_character ('|')
									l_input.append (l_parts.item)
									l_parts.forth
								end
								-- Decode escaped newlines
								l_input.replace_substring_all ("\\n", "%N")
								l_input.replace_substring_all ("\\\\", "\")
								create l_entry.make_with_timestamp (l_input, l_cell, l_timestamp)
								entries.extend (l_entry)
							end
						end
					end
					l_file.close
				end
			end
		rescue
			l_retried := True
			retry
		end

	save
			-- Save history to file
		local
			l_file: PLAIN_TEXT_FILE
			l_encoded: STRING
			l_retried: BOOLEAN
		do
			if not l_retried then
				ensure_directory_exists
				create l_file.make_with_path (history_file_path)
				l_file.open_write
				across entries as e loop
					-- Encode: escape backslashes first, then newlines
					l_encoded := e.input.twin
					l_encoded.replace_substring_all ("\", "\\")
					l_encoded.replace_substring_all ("%N", "\n")
					l_file.put_string (e.timestamp.out)
					l_file.put_character ('|')
					l_file.put_string (e.cell_number.out)
					l_file.put_character ('|')
					l_file.put_string (l_encoded)
					l_file.put_new_line
				end
				l_file.close
			end
		rescue
			l_retried := True
			retry
		end

feature {NONE} -- Implementation

	history_dir: PATH
			-- Directory for history file

	history_file_path: PATH
			-- Full path to history file
		do
			Result := history_dir.extended (History_file_name)
		end

	ensure_directory_exists
			-- Make sure history directory exists
		local
			l_dir: DIRECTORY
		do
			create l_dir.make_with_path (history_dir)
			if not l_dir.exists then
				l_dir.recursive_create_dir
			end
		end

invariant
	entries_not_void: entries /= Void
	index_valid: current_index >= 0 and current_index <= count
	max_positive: max_entries > 0

end
