note
	description: "Represents a change to a variable (new, modified, or removed)"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	VARIABLE_CHANGE

create
	make_new,
	make_modified,
	make_removed

feature {NONE} -- Initialization

	make_new (a_name: STRING; a_type: STRING; a_value: STRING)
			-- Create change for new variable
		require
			name_not_empty: not a_name.is_empty
			type_not_empty: not a_type.is_empty
			value_not_void: a_value /= Void
		do
			name := a_name
			type_name := a_type
			new_value := a_value
			old_value := ""
			change_type := Change_new
		ensure
			is_new: is_new
			name_set: name = a_name
		end

	make_modified (a_name: STRING; a_old_value: STRING; a_new_value: STRING)
			-- Create change for modified variable
		require
			name_not_empty: not a_name.is_empty
			old_value_not_void: a_old_value /= Void
			new_value_not_void: a_new_value /= Void
		do
			name := a_name
			type_name := ""
			old_value := a_old_value
			new_value := a_new_value
			change_type := Change_modified
		ensure
			is_modified: is_modified
			name_set: name = a_name
		end

	make_removed (a_name: STRING)
			-- Create change for removed variable
		require
			name_not_empty: not a_name.is_empty
		do
			name := a_name
			type_name := ""
			old_value := ""
			new_value := ""
			change_type := Change_removed
		ensure
			is_removed: is_removed
			name_set: name = a_name
		end

feature -- Access

	name: STRING
			-- Variable name

	type_name: STRING
			-- Type name (for new variables)

	old_value: STRING
			-- Previous value (for modified)

	new_value: STRING
			-- New value

	change_type: INTEGER
			-- Type of change

feature -- Status

	is_new: BOOLEAN
			-- Is this a newly defined variable?
		do
			Result := change_type = Change_new
		end

	is_modified: BOOLEAN
			-- Is this a modification to existing variable?
		do
			Result := change_type = Change_modified
		end

	is_removed: BOOLEAN
			-- Was this variable removed?
		do
			Result := change_type = Change_removed
		end

feature -- Output

	formatted: STRING
			-- Formatted for display: "x: 42 → 52  (modified)"
		do
			create Result.make (50)
			Result.append ("  ")
			Result.append (name)
			Result.append (": ")

			if is_new then
				if not new_value.is_empty then
					Result.append (new_value)
				else
					Result.append (type_name)
				end
				Result.append ("  (new)")

			elseif is_modified then
				Result.append (old_value)
				Result.append (" -> ")
				Result.append (new_value)
				Result.append ("  (modified)")

			elseif is_removed then
				Result.append ("--  (removed)")
			end
		end

	marker: STRING
			-- Change marker for display
		do
			if is_new then
				Result := "+"
			elseif is_modified then
				Result := "~"
			elseif is_removed then
				Result := "-"
			else
				Result := " "
			end
		end

feature {NONE} -- Constants

	Change_new: INTEGER = 1
	Change_modified: INTEGER = 2
	Change_removed: INTEGER = 3

invariant
	name_not_empty: not name.is_empty
	type_name_not_void: type_name /= Void
	old_value_not_void: old_value /= Void
	new_value_not_void: new_value /= Void
	valid_change_type: change_type = Change_new or change_type = Change_modified or change_type = Change_removed

end
