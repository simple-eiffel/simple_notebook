note
	description: "Executes notebook cells by compiling accumulated class and running executable"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	CELL_EXECUTOR

create
	make

feature {NONE} -- Initialization

	make (a_config: NOTEBOOK_CONFIG)
			-- Create executor with given configuration
		require
			config_not_void: a_config /= Void
		do
			config := a_config
			create code_generator.make
			create error_parser.make
			create process.make
			create last_user_class_files.make (5)
			verbose_compile := True  -- Default to verbose for backwards compatibility
		ensure
			config_set: config = a_config
			verbose_by_default: verbose_compile
		end

feature -- Access

	config: NOTEBOOK_CONFIG
			-- Configuration

	code_generator: ACCUMULATED_CLASS_GENERATOR
			-- Class generator

	verbose_compile: BOOLEAN
			-- Should compiler output be streamed to console?
			-- Default is True for backwards compatibility

	last_user_class_files: ARRAYED_LIST [STRING]
			-- Paths of user class files from last compilation
			-- Used for cleanup on next run

feature -- Settings

	set_verbose_compile (a_verbose: BOOLEAN)
			-- Set whether to stream compiler output
		do
			verbose_compile := a_verbose
		ensure
			verbose_set: verbose_compile = a_verbose
		end

	line_mapping: LINE_MAPPING
			-- Last line mapping (for error mapping)
		do
			Result := code_generator.line_mapping
		end

feature -- Execution

	execute_notebook (a_notebook: NOTEBOOK): EXECUTION_RESULT
			-- Compile and execute all cells in notebook
		require
			notebook_not_void: a_notebook /= Void
			has_cells: a_notebook.code_cell_count > 0
		do
			Result := execute_cells_to (a_notebook, a_notebook.cell_at (a_notebook.cell_count))
		end

	execute_cells_to (a_notebook: NOTEBOOK; a_target_cell: NOTEBOOK_CELL): EXECUTION_RESULT
			-- Execute cells up to and including target cell
		require
			notebook_not_void: a_notebook /= Void
			cell_not_void: a_target_cell /= Void
		local
			l_class_code, l_ecf_code: STRING
			l_class_name: STRING
			l_compile_result: COMPILATION_RESULT
			l_start_time: DATE_TIME
			l_has_class_cells: BOOLEAN
		do
			create l_start_time.make_now

			-- Generate accumulated class
			l_class_code := code_generator.generate_class_to_cell (a_notebook, a_target_cell)
			l_class_name := code_generator.last_class_name
			l_ecf_code := code_generator.generate_ecf (a_notebook, l_class_name)

			-- Check if class structure changed (requires re-freeze)
			l_has_class_cells := not code_generator.user_classes.is_empty
			if l_has_class_cells and then has_class_structure_changed then
				reset_frozen_status
			end

			-- Write files to workspace (clean up old class files first)
			ensure_workspace_exists
			cleanup_old_class_files
			write_generated_files (l_class_code, l_class_name, l_ecf_code)

			-- Compile
			l_compile_result := compile_generated_class (l_class_name)

			if l_compile_result.success then
				-- Execute
				Result := execute_compiled (l_compile_result.executable_path)
				Result.set_compilation_result (l_compile_result)
			else
				-- Map errors to cells
				error_parser.map_errors_to_cells (l_compile_result.errors, code_generator.line_mapping, a_notebook)
				create Result.make_compilation_error (l_compile_result)
			end
		end

	execute_single_cell (a_notebook: NOTEBOOK; a_cell: NOTEBOOK_CELL): EXECUTION_RESULT
			-- Execute just one cell (includes all cells up to it)
		require
			notebook_not_void: a_notebook /= Void
			cell_not_void: a_cell /= Void
			cell_in_notebook: a_notebook.cell_by_id (a_cell.id) /= Void
		do
			Result := execute_cells_to (a_notebook, a_cell)
		end

feature -- Configuration

	set_timeout_seconds (a_timeout: INTEGER)
			-- Set execution timeout
		require
			positive: a_timeout > 0
		do
			config.set_timeout_seconds (a_timeout)
		end

feature {NONE} -- Compilation

	compile_generated_class (a_class_name: STRING): COMPILATION_RESULT
			-- Compile the generated class using EiffelStudio
			-- Uses freeze on first run, quick_melt on subsequent (10-30x faster!)
		local
			l_cmd: STRING
			l_start_time: DATE_TIME
			l_elapsed_ms: INTEGER
			l_ecf_path, l_exe_path: PATH
			l_stdout, l_stderr: STRING
			l_old_exe: SIMPLE_FILE
			l_was_frozen: BOOLEAN
			l_parsed_errors: ARRAYED_LIST [COMPILER_ERROR]
			l_has_errors: BOOLEAN
		do
			create l_start_time.make_now
			l_ecf_path := workspace_ecf_path

			-- Check if we have a frozen exe (can use fast melt mode)
			check_frozen_status
			l_was_frozen := is_frozen

			-- Show mode indicator (only in verbose mode)
			if verbose_compile then
				if is_frozen then
					print ("(melt) ")
				else
					print ("(freeze) ")
				end
			end

			-- Only delete old exe if we're doing a fresh freeze
			-- Melting needs the existing exe (it contains the bytecode interpreter!)
			if not is_frozen then
				l_exe_path := find_executable (a_class_name)
				create l_old_exe.make (l_exe_path.name)
				if l_old_exe.exists then
					l_old_exe.delete.do_nothing
				end
			end

			-- Build compile command (freeze or quick_melt)
			l_cmd := build_compile_command (l_ecf_path)

			-- Run compiler with streaming output
			l_stdout := run_with_streaming_output (l_cmd, workspace_path.name.to_string_8)
			create l_stderr.make_empty

			l_elapsed_ms := elapsed_milliseconds (l_start_time)

			-- Parse errors from compiler output FIRST
			-- This is essential because:
			-- 1) ec.exe returns 0 even on errors
			-- 2) With melt mode, the exe always exists (from previous freeze)
			l_parsed_errors := error_parser.parse_errors (l_stdout + "%N" + l_stderr)
			l_has_errors := not l_parsed_errors.is_empty

			-- In silent mode, still report errors if any were found
			if not verbose_compile and l_has_errors then
				print ("%NCompilation errors:%N")
				across l_parsed_errors as e loop
					print ("  " + e.error_code + ": " + e.message + "%N")
				end
			end

			-- Check if exe exists
			l_exe_path := find_executable (a_class_name)
			create l_old_exe.make (l_exe_path.name)

			-- Compilation succeeds only if: exe exists AND no errors parsed
			if l_old_exe.exists and then not l_has_errors then
				-- Compilation succeeded
				create Result.make (True, l_stdout, l_stderr)
				Result.set_executable_path (l_exe_path)
				Result.set_compilation_time_ms (l_elapsed_ms)
				-- Mark as frozen after successful freeze
				if not l_was_frozen then
					is_frozen := True
				end
			else
				-- Compilation failed
				log_compile_failure (l_cmd, l_stdout, l_stderr)
				create Result.make (False, l_stdout, l_stderr)
				Result.set_compilation_time_ms (l_elapsed_ms)
				Result.errors.append (l_parsed_errors)
				-- If melt failed, try resetting to force fresh freeze next time
				if l_was_frozen then
					is_frozen := False
				end
			end
		end

feature {NONE} -- Execution

	execute_compiled (a_exe_path: PATH): EXECUTION_RESULT
			-- Execute the compiled executable
		local
			l_start_time: DATE_TIME
			l_elapsed_ms: INTEGER
			l_stdout, l_stderr: STRING
			l_output: STRING_32
		do
			create l_start_time.make_now

			-- DEBUG: Uncomment to trace execution issues
			-- print ("DEBUG EXECUTOR: Running exe: " + a_exe_path.name.to_string_8 + "%N")

			-- Use output_of_command_in_directory which returns STRING_32 directly
			l_output := process.output_of_command_in_directory (a_exe_path.name, workspace_path.name)

			-- DEBUG: Uncomment to trace execution issues
			-- print ("DEBUG EXECUTOR: exit_code=" + process.exit_code.out + "%N")
			-- print ("DEBUG EXECUTOR: was_successful=" + process.was_successful.out + "%N")
			-- print ("DEBUG EXECUTOR: output length=" + l_output.count.out + "%N")

			l_elapsed_ms := elapsed_milliseconds (l_start_time)

			-- Convert output to STRING
			l_stdout := l_output.to_string_8
			create l_stderr.make_empty

			-- DEBUG: Uncomment to trace execution issues
			-- print ("DEBUG EXECUTOR: final stdout=[" + l_stdout + "]%N")

			if process.exit_code = 0 then
				create Result.make_success (l_stdout, l_elapsed_ms)
			else
				create Result.make_runtime_error (l_stderr, process.exit_code, l_elapsed_ms)
			end
		end

feature {NONE} -- File Operations

	ensure_workspace_exists
			-- Create workspace directory if needed
		local
			l_dir_file: SIMPLE_FILE
			l_ok: BOOLEAN
		do
			create l_dir_file.make (workspace_path.name)
			if not l_dir_file.is_directory then
				l_ok := l_dir_file.create_directory
			end
		end

	cleanup_old_class_files
			-- Remove old accumulated_session_*.e and user class files
		local
			l_dir: DIRECTORY
			l_workspace: STRING
			l_file: RAW_FILE
			l_user_file: SIMPLE_FILE
		do
			l_workspace := workspace_path.name.to_string_8

			-- Remove accumulated_session_*.e files
			create l_dir.make (l_workspace)
			if l_dir.exists then
				l_dir.open_read
				from
					l_dir.readentry
				until
					l_dir.lastentry = Void
				loop
					if attached l_dir.lastentry as l_filename then
						if l_filename.starts_with ("accumulated_session_") and l_filename.ends_with (".e") then
							create l_file.make_with_name (l_workspace + "/" + l_filename)
							if l_file.exists then
								l_file.delete
							end
						end
					end
					l_dir.readentry
				end
				l_dir.close
			end

			-- Remove user class files from last run
			across last_user_class_files as f loop
				create l_user_file.make (f)
				if l_user_file.exists then
					l_user_file.delete.do_nothing
				end
			end
			last_user_class_files.wipe_out
		end

	write_generated_files (a_class: STRING; a_class_name: STRING; a_ecf: STRING)
			-- Write generated class, user classes, and ECF to workspace
		local
			l_class_file, l_ecf_file, l_user_file: SIMPLE_FILE
			l_class_path, l_ecf_path, l_user_path: STRING
			l_ok: BOOLEAN
		do
			-- Write main accumulated session class
			l_class_path := workspace_path.name.to_string_8 + "/" + a_class_name.as_lower + ".e"
			create l_class_file.make (l_class_path)
			l_ok := l_class_file.set_content (a_class)

			-- Write ECF
			l_ecf_path := workspace_ecf_path.name.to_string_8
			create l_ecf_file.make (l_ecf_path)
			l_ok := l_ecf_file.set_content (a_ecf)

			-- Write user-defined class files
			across code_generator.user_classes as uc loop
				l_user_path := workspace_path.name.to_string_8 + "/" + uc.name.as_lower + ".e"
				create l_user_file.make (l_user_path)
				l_ok := l_user_file.set_content (uc.content)
				last_user_class_files.extend (l_user_path)
			end
		end

	find_executable (a_class_name: STRING): PATH
			-- Find the compiled executable
		local
			l_w_code_path, l_exe_name: STRING
		do
			-- EiffelStudio puts exe in EIFGENs/target/W_code/
			l_w_code_path := workspace_path.name.to_string_8 + "/EIFGENs/notebook_session/W_code/"

			if (create {PLATFORM}).is_windows then
				l_exe_name := "notebook_session.exe"
			else
				l_exe_name := "notebook_session"
			end

			create Result.make_from_string (l_w_code_path + l_exe_name)
		end

feature {NONE} -- Paths

	workspace_path: PATH
			-- Path to workspace directory
		do
			Result := config.workspace_dir
		end

	workspace_ecf_path: PATH
			-- Path to ECF file in workspace
		do
			create Result.make_from_string (workspace_path.name.to_string_8 + "/notebook_session.ecf")
		end

feature {NONE} -- Helpers

	run_with_streaming_output (a_cmd: STRING; a_dir: STRING): STRING
			-- Run command and stream output to console as it arrives
		local
			l_async: SIMPLE_ASYNC_PROCESS
			l_env: EXECUTION_ENVIRONMENT
		do
			create Result.make (4096)
			create l_async.make
			create l_env

			-- Start the process
			l_async.start_in_directory (a_cmd, a_dir)

			if l_async.was_started_successfully then
				-- Poll for output while running
				from
				until
					not l_async.is_running
				loop
					if attached l_async.read_available_output as chunk then
						-- Stream to console only if verbose
						if verbose_compile then
							print (chunk)
						end
						Result.append (chunk.to_string_8)
					end
					-- Small sleep to avoid busy-waiting (100ms)
					l_env.sleep (100_000_000)
				end

				-- Read any remaining output after process ends
				if attached l_async.read_available_output as final_chunk then
					if verbose_compile then
						print (final_chunk)
					end
					Result.append (final_chunk.to_string_8)
				end

				l_async.close
			else
				if attached l_async.last_error as err then
					Result := "Failed to start: " + err.to_string_8
				else
					Result := "Failed to start compiler"
				end
			end
		end

	elapsed_milliseconds (a_start: DATE_TIME): INTEGER
			-- Milliseconds elapsed since start time
		local
			l_now: DATE_TIME
			l_diff: DATE_TIME_DURATION
		do
			create l_now.make_now
			l_diff := l_now.relative_duration (a_start)
			Result := l_diff.seconds_count.to_integer_32 * 1000 +
			         l_diff.fine_second.truncated_to_integer // 1000000
		end

feature {NONE} -- Implementation

	error_parser: COMPILER_ERROR_PARSER
			-- Error parser

	process: SIMPLE_PROCESS
			-- Process executor

	is_frozen: BOOLEAN
			-- Has initial freeze been done?
			-- After freeze, we can use fast melt mode (no C compilation)

	last_user_class_count: INTEGER
			-- Number of user classes from last compilation
			-- Used to detect class structure changes

feature {NONE} -- Melt Mode

	check_frozen_status
			-- Check if W_code exe exists (meaning freeze was done previously)
		local
			l_exe_file: SIMPLE_FILE
		do
			if not is_frozen then
				create l_exe_file.make (find_executable ("notebook_session").name)
				is_frozen := l_exe_file.exists
			end
		ensure
			stable_if_frozen: old is_frozen implies is_frozen
		end

	reset_frozen_status
			-- Force fresh freeze on next compile (e.g., after config change)
		do
			is_frozen := False
		ensure
			not_frozen: not is_frozen
		end

	has_class_structure_changed: BOOLEAN
			-- Have user class cells changed since last freeze?
			-- If count differs, structure has changed
		do
			Result := code_generator.user_classes.count /= last_user_class_count
			last_user_class_count := code_generator.user_classes.count
		end

	build_compile_command (a_ecf_path: PATH): STRING
			-- Build the appropriate compile command
			-- Freeze with C compile on first run, quick_melt on subsequent
		do
			create Result.make (200)
			Result.append ("%"")
			Result.append (config.eiffel_compiler.name.to_string_8)
			Result.append ("%"")
			Result.append (" -batch")

			if is_frozen then
				-- FAST PATH: Already frozen, just melt (no C compile!)
				Result.append (" -config %"")
				Result.append (a_ecf_path.name.to_string_8)
				Result.append ("%"")
				Result.append (" -target notebook_session")
				Result.append (" -quick_melt")
			else
				-- INITIAL PATH: Need to freeze and C compile
				Result.append (" -clean")
				Result.append (" -config %"")
				Result.append (a_ecf_path.name.to_string_8)
				Result.append ("%"")
				Result.append (" -target notebook_session")
				Result.append (" -freeze")
				Result.append (" -c_compile")
			end
		ensure
			not_empty: not Result.is_empty
		end

feature {NONE} -- Debugging

	log_compile_failure (a_cmd: STRING; a_stdout: STRING; a_stderr: STRING)
			-- Log compilation failure for debugging
		local
			l_file: SIMPLE_FILE
			l_content: STRING
		do
			create l_content.make (2000)
			l_content.append ("=== COMPILE FAILURE LOG ===%N")
			l_content.append ("Command: " + a_cmd + "%N%N")
			l_content.append ("=== STDOUT (" + a_stdout.count.out + " chars) ===%N")
			l_content.append (a_stdout)
			l_content.append ("%N%N=== STDERR (" + a_stderr.count.out + " chars) ===%N")
			l_content.append (a_stderr)
			l_content.append ("%N=== END LOG ===%N")
			create l_file.make (workspace_path.name.to_string_8 + "/compile_debug.log")
			l_file.set_content (l_content).do_nothing
		end

invariant
	config_not_void: config /= Void
	code_generator_not_void: code_generator /= Void

end


