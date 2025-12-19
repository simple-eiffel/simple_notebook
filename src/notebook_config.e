note
	description: "Configuration container for Eiffel Notebook with validation and persistence"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	NOTEBOOK_CONFIG

inherit
	ANY
		redefine
			default_create
		end

create
	default_create,
	make,
	make_from_file,
	make_with_defaults

feature {NONE} -- Initialization

	default_create
			-- Create with sensible defaults
		do
			make_with_defaults
		end

	make (a_compiler_path: PATH)
			-- Create with specified compiler path
		require
			compiler_path_not_empty: not a_compiler_path.is_empty
		do
			make_with_defaults
			eiffel_compiler := a_compiler_path
		ensure
			compiler_set: eiffel_compiler = a_compiler_path
		end

	make_from_file (a_path: PATH)
			-- Load configuration from JSON file
		require
			path_not_empty: not a_path.is_empty
		local
			l_file: SIMPLE_FILE
			l_json: SIMPLE_JSON
		do
			make_with_defaults
			config_file_path := a_path

			create l_file.make (a_path.name)
			if l_file.exists then
				create l_json
				if attached l_json.parse (l_file.content) as l_value and then attached l_value.as_object as jo then
					from_json (jo)
				end
			end
		end

	make_with_defaults
			-- Create with sensible default values
		do
			create eiffel_compiler.make_empty
			create ise_library.make_empty
			create simple_eiffel.make_empty
			create workspace_dir.make_from_string (default_workspace_path)

			timeout_seconds := Default_timeout
			autosave_interval_seconds := Default_autosave_interval
			history_size := Default_history_size

			prompt_style := Default_prompt_style
			show_timing := True
			show_variable_changes := True
			quiet_mode := False

			web_port := Default_web_port
			web_host := Default_web_host

			create validation_errors.make (0)
			create config_file_path.make_empty
		ensure
			timeout_set: timeout_seconds = Default_timeout
			port_set: web_port = Default_web_port
		end

feature -- Access

	eiffel_compiler: PATH
			-- Path to ec.exe

	ise_library: PATH
			-- Path to ISE_LIBRARY

	simple_eiffel: PATH
			-- Path to SIMPLE_EIFFEL root

	workspace_dir: PATH
			-- Working directory for generated files

	timeout_seconds: INTEGER
			-- Maximum execution time per cell

	autosave_interval_seconds: INTEGER
			-- Auto-checkpoint frequency

	history_size: INTEGER
			-- Command history limit

	config_file_path: PATH
			-- Path to loaded config file (if any)

feature -- REPL Settings

	prompt_style: STRING
			-- REPL prompt format (e.g., "e[N]>")

	show_timing: BOOLEAN
			-- Show compilation/execution timing

	show_variable_changes: BOOLEAN
			-- Show variable changes after execution

	quiet_mode: BOOLEAN
			-- Suppress verbose output

feature -- Web Settings

	web_port: INTEGER
			-- HTTP server port

	web_host: STRING
			-- HTTP server host

feature -- Status

	is_valid: BOOLEAN
			-- All required paths exist and are accessible
		do
			validate
			Result := validation_errors.is_empty
		end

	validation_errors: ARRAYED_LIST [STRING]
			-- List of configuration problems

feature -- Commands

	validate
			-- Check all paths exist, populate validation_errors
		local
			l_file: SIMPLE_FILE
		do
			validation_errors.wipe_out

			-- Compiler is required
			if eiffel_compiler.is_empty then
				validation_errors.extend ("Eiffel compiler path not set")
			else
				create l_file.make (eiffel_compiler.name)
				if not l_file.exists then
					validation_errors.extend ("Eiffel compiler not found: " + eiffel_compiler.name.to_string_8)
				end
			end

			-- ISE_LIBRARY is required
			if ise_library.is_empty then
				validation_errors.extend ("ISE_LIBRARY path not set")
			else
				create l_file.make (ise_library.name)
				if not l_file.is_directory then
					validation_errors.extend ("ISE_LIBRARY not found: " + ise_library.name.to_string_8)
				end
			end

			-- SIMPLE_EIFFEL is optional but warn if not found
			if not simple_eiffel.is_empty then
				create l_file.make (simple_eiffel.name)
				if not l_file.is_directory then
					validation_errors.extend ("SIMPLE_EIFFEL path not found: " + simple_eiffel.name.to_string_8)
				end
			end
		end

	set_eiffel_compiler (a_path: PATH)
			-- Set compiler path
		require
			path_not_void: a_path /= Void
		do
			eiffel_compiler := a_path
		ensure
			compiler_set: eiffel_compiler = a_path
		end

	set_ise_library (a_path: PATH)
			-- Set ISE_LIBRARY path
		require
			path_not_void: a_path /= Void
		do
			ise_library := a_path
		ensure
			ise_library_set: ise_library = a_path
		end

	set_simple_eiffel (a_path: PATH)
			-- Set SIMPLE_EIFFEL path
		require
			path_not_void: a_path /= Void
		do
			simple_eiffel := a_path
		ensure
			simple_eiffel_set: simple_eiffel = a_path
		end

	set_workspace_dir (a_path: PATH)
			-- Set workspace directory
		require
			path_not_void: a_path /= Void
		do
			workspace_dir := a_path
		ensure
			workspace_set: workspace_dir = a_path
		end

	set_timeout_seconds (a_timeout: INTEGER)
			-- Set execution timeout
		require
			positive: a_timeout > 0
		do
			timeout_seconds := a_timeout
		ensure
			timeout_set: timeout_seconds = a_timeout
		end

	set_autosave_interval_seconds (a_interval: INTEGER)
			-- Set autosave interval
		require
			positive: a_interval > 0
		do
			autosave_interval_seconds := a_interval
		ensure
			interval_set: autosave_interval_seconds = a_interval
		end

	set_history_size (a_size: INTEGER)
			-- Set history size
		require
			positive: a_size > 0
		do
			history_size := a_size
		ensure
			size_set: history_size = a_size
		end

	set_prompt_style (a_style: STRING)
			-- Set REPL prompt style
		require
			style_not_empty: not a_style.is_empty
		do
			prompt_style := a_style
		ensure
			style_set: prompt_style = a_style
		end

	set_show_timing (a_value: BOOLEAN)
			-- Set timing display
		do
			show_timing := a_value
		ensure
			timing_set: show_timing = a_value
		end

	set_show_variable_changes (a_value: BOOLEAN)
			-- Set variable change display
		do
			show_variable_changes := a_value
		ensure
			changes_set: show_variable_changes = a_value
		end

	set_quiet_mode (a_value: BOOLEAN)
			-- Set quiet mode
		do
			quiet_mode := a_value
		ensure
			quiet_set: quiet_mode = a_value
		end

	set_web_port (a_port: INTEGER)
			-- Set web server port
		require
			valid_port: a_port >= 1024 and a_port <= 65535
		do
			web_port := a_port
		ensure
			port_set: web_port = a_port
		end

	set_web_host (a_host: STRING)
			-- Set web server host
		require
			host_not_empty: not a_host.is_empty
		do
			web_host := a_host
		ensure
			host_set: web_host = a_host
		end

	save (a_path: PATH)
			-- Persist configuration to JSON file
		require
			path_not_empty: not a_path.is_empty
		local
			l_file: SIMPLE_FILE
			l_json: SIMPLE_JSON_OBJECT
			l_ok: BOOLEAN
		do
			l_json := to_json
			create l_file.make (a_path.name)
			l_ok := l_file.set_content (l_json.representation)
			config_file_path := a_path
		end

	reload
			-- Re-read configuration from file
		require
			has_config_file: not config_file_path.is_empty
		do
			make_from_file (config_file_path)
		end

feature -- Serialization

	to_json: SIMPLE_JSON_OBJECT
			-- Convert to JSON object
		local
			l_repl, l_web: SIMPLE_JSON_OBJECT
			l_ignore: SIMPLE_JSON_OBJECT
		do
			create Result.make

			l_ignore := Result.put_string (eiffel_compiler.name.to_string_8, "eiffel_compiler")
			l_ignore := Result.put_string (ise_library.name.to_string_8, "ise_library")
			l_ignore := Result.put_string (simple_eiffel.name.to_string_8, "simple_eiffel")
			l_ignore := Result.put_string (workspace_dir.name.to_string_8, "workspace_dir")
			l_ignore := Result.put_integer (timeout_seconds, "timeout_seconds")
			l_ignore := Result.put_integer (autosave_interval_seconds, "autosave_interval_seconds")
			l_ignore := Result.put_integer (history_size, "history_size")

			-- REPL settings
			create l_repl.make
			l_ignore := l_repl.put_string (prompt_style, "prompt_style")
			l_ignore := l_repl.put_boolean (show_timing, "show_timing")
			l_ignore := l_repl.put_boolean (show_variable_changes, "show_variable_changes")
			l_ignore := l_repl.put_boolean (quiet_mode, "quiet_mode")
			l_ignore := Result.put_object (l_repl, "repl")

			-- Web settings
			create l_web.make
			l_ignore := l_web.put_integer (web_port, "port")
			l_ignore := l_web.put_string (web_host, "host")
			l_ignore := Result.put_object (l_web, "web")
		end

	from_json (a_json: SIMPLE_JSON_OBJECT)
			-- Load from JSON object
		require
			json_not_void: a_json /= Void
		do
			if attached a_json.string_item ("eiffel_compiler") as s then
				create eiffel_compiler.make_from_string (s)
			end
			if attached a_json.string_item ("ise_library") as s then
				create ise_library.make_from_string (s)
			end
			if attached a_json.string_item ("simple_eiffel") as s then
				create simple_eiffel.make_from_string (s)
			end
			if attached a_json.string_item ("workspace_dir") as s then
				create workspace_dir.make_from_string (s)
			end
			if a_json.has_key ("timeout_seconds") then
				timeout_seconds := a_json.integer_32_item ("timeout_seconds")
			end
			if a_json.has_key ("autosave_interval_seconds") then
				autosave_interval_seconds := a_json.integer_32_item ("autosave_interval_seconds")
			end
			if a_json.has_key ("history_size") then
				history_size := a_json.integer_32_item ("history_size")
			end

			-- REPL settings
			if attached a_json.object_item ("repl") as l_repl then
				if attached l_repl.string_item ("prompt_style") as s then
					prompt_style := s.to_string_8
				end
				if l_repl.has_key ("show_timing") then
					show_timing := l_repl.boolean_item ("show_timing")
				end
				if l_repl.has_key ("show_variable_changes") then
					show_variable_changes := l_repl.boolean_item ("show_variable_changes")
				end
				if l_repl.has_key ("quiet_mode") then
					quiet_mode := l_repl.boolean_item ("quiet_mode")
				end
			end

			-- Web settings
			if attached a_json.object_item ("web") as l_web then
				if l_web.has_key ("port") then
					web_port := l_web.integer_32_item ("port")
				end
				if attached l_web.string_item ("host") as h then
					web_host := h.to_string_8
				end
			end
		end
feature -- Constants

	Default_timeout: INTEGER = 30
			-- Default execution timeout in seconds

	Default_autosave_interval: INTEGER = 30
			-- Default autosave interval in seconds

	Default_history_size: INTEGER = 1000
			-- Default command history size

	Default_prompt_style: STRING = "e[N]>"
			-- Default REPL prompt style

	Default_web_port: INTEGER = 8080
			-- Default web server port

	Default_web_host: STRING = "localhost"
			-- Default web server host

feature {NONE} -- Implementation

	default_workspace_path: STRING
			-- Default workspace path based on platform
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.home_directory_path as h then
				Result := h.name.to_string_8 + "/.eiffel_notebook/workspace"
			else
				Result := ".eiffel_notebook/workspace"
			end
		end

	default_config_path: STRING
			-- Default config file path
		local
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			if attached l_env.home_directory_path as h then
				Result := h.name.to_string_8 + "/.eiffel_notebook/config.json"
			else
				Result := ".eiffel_notebook/config.json"
			end
		end

invariant
	timeout_positive: timeout_seconds > 0
	autosave_positive: autosave_interval_seconds > 0
	history_positive: history_size > 0
	port_valid: web_port >= 1024 and web_port <= 65535
	validation_errors_not_void: validation_errors /= Void

end
