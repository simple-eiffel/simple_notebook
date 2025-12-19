note
	description: "Individual notebook cell containing code, output, and execution state"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	NOTEBOOK_CELL

create
	make,
	make_code,
	make_markdown,
	make_from_json

feature {NONE} -- Initialization

	make (a_id: STRING; a_type: STRING)
			-- Create cell with given id and type
		require
			id_not_empty: not a_id.is_empty
			type_valid: a_type.same_string ("code") or a_type.same_string ("markdown")
		do
			id := a_id
			cell_type := a_type
			code := ""
			create output.make_empty
			create error.make_empty
			execution_time_ms := 0
			order := 0
			status := Status_idle
		ensure
			id_set: id = a_id
			type_set: cell_type = a_type
			status_idle: status.same_string (Status_idle)
		end

	make_code (a_id: STRING)
			-- Create code cell
		require
			id_not_empty: not a_id.is_empty
		do
			make (a_id, "code")
		ensure
			is_code: is_code_cell
		end

	make_markdown (a_id: STRING)
			-- Create markdown cell
		require
			id_not_empty: not a_id.is_empty
		do
			make (a_id, "markdown")
		ensure
			is_markdown: is_markdown_cell
		end

	make_from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Create cell from JSON object
		require
			json_not_void: a_json /= Void
		do
			make ("temp", "code")
			from_json (a_json)
		end

feature -- Access

	id: STRING
			-- Unique cell identifier

	cell_type: STRING
			-- Cell type: "code" or "markdown"

	code: STRING
			-- Cell source code or markdown content

	output: STRING
			-- Execution output (stdout)

	error: STRING
			-- Execution error (stderr or compiler errors)

	execution_time_ms: INTEGER
			-- Last execution time in milliseconds

	order: INTEGER
			-- Position in notebook (1-based)

	status: STRING
			-- Execution status: idle, running, success, error

feature -- Status Queries

	is_code_cell: BOOLEAN
			-- Is this a code cell?
		do
			Result := cell_type.same_string ("code")
		end

	is_markdown_cell: BOOLEAN
			-- Is this a markdown cell?
		do
			Result := cell_type.same_string ("markdown")
		end

	has_output: BOOLEAN
			-- Does cell have output?
		do
			Result := not output.is_empty
		end

	has_error: BOOLEAN
			-- Does cell have error?
		do
			Result := not error.is_empty
		end

	is_idle: BOOLEAN
			-- Is cell idle?
		do
			Result := status.same_string (Status_idle)
		end

	is_running: BOOLEAN
			-- Is cell currently running?
		do
			Result := status.same_string (Status_running)
		end

	is_success: BOOLEAN
			-- Did cell execute successfully?
		do
			Result := status.same_string (Status_success)
		end

	is_error: BOOLEAN
			-- Did cell execution fail?
		do
			Result := status.same_string (Status_error)
		end

feature -- Commands

	set_code (a_code: STRING)
			-- Set cell code/content
		require
			code_not_void: a_code /= Void
		do
			code := a_code
		ensure
			code_set: code = a_code
		end

	set_output (a_output: STRING)
			-- Set execution output
		require
			output_not_void: a_output /= Void
		do
			output := a_output
		ensure
			output_set: output = a_output
		end

	set_error (a_error: STRING)
			-- Set execution error
		require
			error_not_void: a_error /= Void
		do
			error := a_error
		ensure
			error_set: error = a_error
		end

	set_execution_time_ms (a_time: INTEGER)
			-- Set execution time
		require
			time_non_negative: a_time >= 0
		do
			execution_time_ms := a_time
		ensure
			time_set: execution_time_ms = a_time
		end

	set_order (a_order: INTEGER)
			-- Set cell order
		require
			order_positive: a_order >= 0
		do
			order := a_order
		ensure
			order_set: order = a_order
		end

	set_status (a_status: STRING)
			-- Set execution status
		require
			status_valid: a_status.same_string (Status_idle) or
			             a_status.same_string (Status_running) or
			             a_status.same_string (Status_success) or
			             a_status.same_string (Status_error)
		do
			status := a_status
		ensure
			status_set: status = a_status
		end

	set_status_idle
			-- Set status to idle
		do
			status := Status_idle
		ensure
			is_idle: is_idle
		end

	set_status_running
			-- Set status to running
		do
			status := Status_running
		ensure
			is_running: is_running
		end

	set_status_success
			-- Set status to success
		do
			status := Status_success
		ensure
			is_success: is_success
		end

	set_status_error
			-- Set status to error
		do
			status := Status_error
		ensure
			is_error: is_error
		end

	clear_output
			-- Clear output and error
		do
			output := ""
			error := ""
			execution_time_ms := 0
			status := Status_idle
		ensure
			output_empty: output.is_empty
			error_empty: error.is_empty
			time_zero: execution_time_ms = 0
			is_idle: is_idle
		end

feature -- Serialization

	to_json: SIMPLE_JSON_OBJECT
			-- Convert to JSON object
		local
			l_ignore: SIMPLE_JSON_OBJECT
		do
			create Result.make
			l_ignore := Result.put_string (id, "id")
			l_ignore := Result.put_string (cell_type, "cell_type")
			l_ignore := Result.put_integer (order, "order")
			l_ignore := Result.put_string (code, "code")
			l_ignore := Result.put_string (output, "output")
			l_ignore := Result.put_string (error, "error")
			l_ignore := Result.put_string (status, "status")
			l_ignore := Result.put_integer (execution_time_ms, "execution_time_ms")
		end

	from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Load from JSON object
		require
			json_not_void: a_json /= Void
		do
			if attached a_json.string_item ("id") as s then
				id := s.to_string_8
			end
			if attached a_json.string_item ("cell_type") as s then
				cell_type := s.to_string_8
			end
			if a_json.has_key ("order") then
				order := a_json.integer_32_item ("order")
			end
			if attached a_json.string_item ("code") as s then
				code := s.to_string_8
			end
			if attached a_json.string_item ("output") as s then
				output := s.to_string_8
			end
			if attached a_json.string_item ("error") as s then
				error := s.to_string_8
			end
			if attached a_json.string_item ("status") as s then
				status := s.to_string_8
			end
			if a_json.has_key ("execution_time_ms") then
				execution_time_ms := a_json.integer_32_item ("execution_time_ms")
			end
		end

feature -- Constants

	Status_idle: STRING = "idle"
	Status_running: STRING = "running"
	Status_success: STRING = "success"
	Status_error: STRING = "error"

invariant
	id_not_empty: not id.is_empty
	type_valid: cell_type.same_string ("code") or cell_type.same_string ("markdown")
	status_valid: status.same_string (Status_idle) or
	             status.same_string (Status_running) or
	             status.same_string (Status_success) or
	             status.same_string (Status_error)
	execution_time_non_negative: execution_time_ms >= 0

end
