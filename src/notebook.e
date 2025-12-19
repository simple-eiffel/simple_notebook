note
	description: "Container for notebook cells with ordering and JSON serialization"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	NOTEBOOK

create
	make,
	make_from_json

feature {NONE} -- Initialization

	make (a_name: STRING)
			-- Create notebook with given name
		require
			name_not_empty: not a_name.is_empty
		local
			l_uuid: SIMPLE_UUID
		do
			create l_uuid.make
			id := "nb_" + l_uuid.new_v4_string.substring (1, 8)
			name := a_name
			create cells.make (10)
			create created_at.make_now
			create modified_at.make_now
			next_cell_number := 1
		ensure
			name_set: name = a_name
			cells_empty: cells.is_empty
		end

	make_from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Create notebook from JSON
		require
			json_not_void: a_json /= Void
		do
			make ("temp")
			from_json (a_json)
		end

feature -- Access

	id: STRING
			-- Unique notebook identifier

	name: STRING
			-- Notebook display name

	cells: ARRAYED_LIST [NOTEBOOK_CELL]
			-- Ordered list of cells

	created_at: DATE_TIME
			-- Creation timestamp

	modified_at: DATE_TIME
			-- Last modification timestamp

feature -- Queries

	cell_by_id (a_id: STRING): detachable NOTEBOOK_CELL
			-- Find cell by ID
		require
			id_not_empty: not a_id.is_empty
		local
			i: INTEGER
		do
			from i := 1 until i > cells.count or Result /= Void loop
				if cells [i].id.same_string (a_id) then
					Result := cells [i]
				end
				i := i + 1
			end
		end

	cell_at (a_index: INTEGER): NOTEBOOK_CELL
			-- Cell at given index (1-based)
		require
			valid_index: a_index >= 1 and a_index <= cell_count
		do
			Result := cells [a_index]
		end

	cell_count: INTEGER
			-- Number of cells
		do
			Result := cells.count
		end

	code_cells: ARRAYED_LIST [NOTEBOOK_CELL]
			-- Only executable code cells (not markdown)
		local
			i: INTEGER
		do
			create Result.make (cells.count)
			from i := 1 until i > cells.count loop
				if cells [i].is_code_cell then
					Result.extend (cells [i])
				end
				i := i + 1
			end
		end

	code_cell_count: INTEGER
			-- Number of code cells
		local
			i: INTEGER
		do
			from i := 1 until i > cells.count loop
				if cells [i].is_code_cell then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	is_empty: BOOLEAN
			-- Has no cells?
		do
			Result := cells.is_empty
		end

feature -- Cell Management

	add_cell (a_cell: NOTEBOOK_CELL)
			-- Add cell to end of notebook
		require
			cell_not_void: a_cell /= Void
		do
			a_cell.set_order (cells.count + 1)
			cells.extend (a_cell)
			touch
		ensure
			cell_added: cells.has (a_cell)
			count_increased: cell_count = old cell_count + 1
		end

	add_code_cell (a_code: STRING): NOTEBOOK_CELL
			-- Create and add a code cell
		require
			code_not_void: a_code /= Void
		do
			create Result.make_code (generate_cell_id)
			Result.set_code (a_code)
			add_cell (Result)
		ensure
			cell_created: Result /= Void
			is_code: Result.is_code_cell
			has_code: Result.code.same_string (a_code)
		end

	add_markdown_cell (a_content: STRING): NOTEBOOK_CELL
			-- Create and add a markdown cell
		require
			content_not_void: a_content /= Void
		do
			create Result.make_markdown (generate_cell_id)
			Result.set_code (a_content)
			add_cell (Result)
		ensure
			cell_created: Result /= Void
			is_markdown: Result.is_markdown_cell
		end

	insert_cell_at (a_cell: NOTEBOOK_CELL; a_position: INTEGER)
			-- Insert cell at given position (1-based)
		require
			cell_not_void: a_cell /= Void
			valid_position: a_position >= 1 and a_position <= cell_count + 1
		do
			if a_position > cells.count then
				cells.extend (a_cell)
			else
				cells.go_i_th (a_position)
				cells.put_left (a_cell)
			end
			reorder_cells
			touch
		ensure
			cell_inserted: cells.has (a_cell)
			count_increased: cell_count = old cell_count + 1
		end

	remove_cell (a_id: STRING)
			-- Remove cell by ID
		require
			id_not_empty: not a_id.is_empty
		local
			l_index: INTEGER
		do
			from
				l_index := 1
			until
				l_index > cells.count
			loop
				if cells [l_index].id.same_string (a_id) then
					cells.go_i_th (l_index)
					cells.remove
					l_index := cells.count + 1 -- Exit loop
				else
					l_index := l_index + 1
				end
			end
			reorder_cells
			touch
		end

	remove_cell_at (a_index: INTEGER)
			-- Remove cell at given index (1-based)
		require
			valid_index: a_index >= 1 and a_index <= cell_count
		do
			cells.go_i_th (a_index)
			cells.remove
			reorder_cells
			touch
		ensure
			count_decreased: cell_count = old cell_count - 1
		end

	move_cell (a_id: STRING; a_new_position: INTEGER)
			-- Move cell to new position
		require
			id_not_empty: not a_id.is_empty
			valid_position: a_new_position >= 1 and a_new_position <= cell_count
		local
			l_cell: detachable NOTEBOOK_CELL
			l_old_index: INTEGER
		do
			-- Find and remove the cell
			from l_old_index := 1 until l_old_index > cells.count loop
				if cells [l_old_index].id.same_string (a_id) then
					l_cell := cells [l_old_index]
					cells.go_i_th (l_old_index)
					cells.remove
					l_old_index := cells.count + 1
				else
					l_old_index := l_old_index + 1
				end
			end

			-- Insert at new position
			if attached l_cell as c then
				if a_new_position > cells.count then
					cells.extend (c)
				else
					cells.go_i_th (a_new_position)
					cells.put_left (c)
				end
			end

			reorder_cells
			touch
		end

	update_cell_code (a_id: STRING; a_code: STRING)
			-- Update cell code by ID
		require
			id_not_empty: not a_id.is_empty
			code_not_void: a_code /= Void
		do
			if attached cell_by_id (a_id) as c then
				c.set_code (a_code)
				c.clear_output
				touch
			end
		end

	clear_all_outputs
			-- Clear output from all cells
		local
			i: INTEGER
		do
			from i := 1 until i > cells.count loop
				cells [i].clear_output
				i := i + 1
			end
			touch
		end

feature -- Serialization

	to_json: SIMPLE_JSON_OBJECT
			-- Convert to JSON object
		local
			l_cells: SIMPLE_JSON_ARRAY
			l_ignore: SIMPLE_JSON_OBJECT
			i: INTEGER
		do
			create Result.make
			l_ignore := Result.put_string (id, "id")
			l_ignore := Result.put_string (name, "name")
			l_ignore := Result.put_string (created_at.out, "created_at")
			l_ignore := Result.put_string (modified_at.out, "modified_at")

			create l_cells.make
			from i := 1 until i > cells.count loop
				l_cells := l_cells.add_object (cells [i].to_json)
				i := i + 1
			end
			l_ignore := Result.put_array (l_cells, "cells")
		end

	from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Load from JSON object
		require
			json_not_void: a_json /= Void
		local
			l_cell: NOTEBOOK_CELL
			i: INTEGER
		do
			if attached a_json.string_item ("id") as s then
				id := s.to_string_8
			end
			if attached a_json.string_item ("name") as s then
				name := s.to_string_8
			end

			-- Load cells
			cells.wipe_out
			if attached a_json.array_item ("cells") as l_arr then
				from i := 1 until i > l_arr.count loop
					if attached l_arr.object_item (i) as jo then
						create l_cell.make_from_json (jo)
						cells.extend (l_cell)
					end
					i := i + 1
				end
			end

			-- Track highest cell number for ID generation
			from i := 1 until i > cells.count loop
				update_next_cell_number (cells [i].id)
				i := i + 1
			end
		end

feature {NONE} -- Implementation

	next_cell_number: INTEGER
			-- Counter for generating cell IDs

	generate_cell_id: STRING
			-- Generate unique cell ID
		do
			if next_cell_number < 10 then
				Result := "cell_00" + next_cell_number.out
			elseif next_cell_number < 100 then
				Result := "cell_0" + next_cell_number.out
			else
				Result := "cell_" + next_cell_number.out
			end
			next_cell_number := next_cell_number + 1
		end

	update_next_cell_number (a_cell_id: STRING)
			-- Update next_cell_number based on loaded cell ID
		local
			l_num: INTEGER
			l_str: STRING
		do
			if a_cell_id.starts_with ("cell_") then
				l_str := a_cell_id.substring (6, a_cell_id.count)
				if l_str.is_integer then
					l_num := l_str.to_integer
					if l_num >= next_cell_number then
						next_cell_number := l_num + 1
					end
				end
			end
		end

	reorder_cells
			-- Update cell order values to match list position
		local
			i: INTEGER
		do
			from i := 1 until i > cells.count loop
				cells [i].set_order (i)
				i := i + 1
			end
		end

	touch
			-- Update modification timestamp
		do
			create modified_at.make_now
		end

invariant
	id_not_empty: not id.is_empty
	name_not_empty: not name.is_empty
	cells_not_void: cells /= Void

end
