note
	description: "Information about a variable defined in a notebook cell"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	VARIABLE_INFO

create
	make,
	make_with_value

feature {NONE} -- Initialization

	make (a_name: STRING; a_type: STRING; a_cell_id: STRING)
			-- Create variable info without value
		require
			name_not_empty: not a_name.is_empty
			type_not_empty: not a_type.is_empty
			cell_id_not_empty: not a_cell_id.is_empty
		do
			name := a_name
			type_name := a_type
			cell_id := a_cell_id
			value := ""
			is_shared := False
		ensure
			name_set: name = a_name
			type_set: type_name = a_type
			cell_set: cell_id = a_cell_id
		end

	make_with_value (a_name: STRING; a_type: STRING; a_value: STRING; a_cell_id: STRING)
			-- Create variable info with value
		require
			name_not_empty: not a_name.is_empty
			type_not_empty: not a_type.is_empty
			value_not_void: a_value /= Void
			cell_id_not_empty: not a_cell_id.is_empty
		do
			make (a_name, a_type, a_cell_id)
			value := a_value
		ensure
			name_set: name = a_name
			type_set: type_name = a_type
			value_set: value = a_value
			cell_set: cell_id = a_cell_id
		end

feature -- Access

	name: STRING
			-- Variable name

	type_name: STRING
			-- Type name (e.g., "INTEGER", "STRING")

	value: STRING
			-- Current value as string representation

	cell_id: STRING
			-- ID of cell where variable was defined

	is_shared: BOOLEAN
			-- Is this a shared (cross-cell) variable?

feature -- Status

	has_value: BOOLEAN
			-- Has a value been assigned?
		do
			Result := not value.is_empty
		end

feature -- Commands

	set_value (a_value: STRING)
			-- Set variable value
		require
			value_not_void: a_value /= Void
		do
			value := a_value
		ensure
			value_set: value = a_value
		end

	set_shared (a_shared: BOOLEAN)
			-- Set whether variable is shared
		do
			is_shared := a_shared
		ensure
			shared_set: is_shared = a_shared
		end

	set_cell_id (a_cell_id: STRING)
			-- Update cell ID (for tracking modifications)
		require
			cell_id_not_empty: not a_cell_id.is_empty
		do
			cell_id := a_cell_id
		ensure
			cell_set: cell_id = a_cell_id
		end

feature -- Output

	formatted: STRING
			-- Formatted display: "name: TYPE = value"
		do
			create Result.make (50)
			Result.append (name)
			Result.append (": ")
			Result.append (type_name)
			if has_value then
				Result.append (" = ")
				Result.append (formatted_value)
			end
		end

	formatted_value: STRING
			-- Value formatted for display (strings quoted, etc.)
		do
			if type_name.same_string ("STRING") or type_name.same_string ("STRING_32") then
				Result := "%"" + value + "%""
			elseif value.count > 50 then
				Result := value.substring (1, 47) + "..."
			else
				Result := value
			end
		end

	short: STRING
			-- Short display: "name: TYPE"
		do
			create Result.make (30)
			Result.append (name)
			Result.append (": ")
			Result.append (type_name)
		end

feature -- Comparison

	same_variable (other: VARIABLE_INFO): BOOLEAN
			-- Is this the same variable (by name)?
		require
			other_not_void: other /= Void
		do
			Result := name.same_string (other.name)
		end

	value_changed (other: VARIABLE_INFO): BOOLEAN
			-- Has value changed compared to other?
		require
			other_not_void: other /= Void
			same_var: same_variable (other)
		do
			Result := not value.same_string (other.value)
		end

invariant
	name_not_empty: not name.is_empty
	type_not_empty: not type_name.is_empty
	cell_id_not_empty: not cell_id.is_empty
	value_not_void: value /= Void

end
