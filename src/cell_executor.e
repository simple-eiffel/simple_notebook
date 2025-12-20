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
		ensure
			config_set: config = a_config
		end

feature -- Access

	config: NOTEBOOK_CONFIG
			-- Configuration

	code_generator: ACCUMULATED_CLASS_GENERATOR
			-- Class generator

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
		do
			create l_start_time.make_now

			-- Generate accumulated class
			l_class_code := code_generator.generate_class_to_cell (a_notebook, a_target_cell)
			l_class_name := code_generator.last_class_name
			l_ecf_code := code_generator.generate_ecf (a_notebook, l_class_name)

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
		local
			l_cmd: STRING
			l_start_time: DATE_TIME
			l_elapsed_ms: INTEGER
			l_ecf_path, l_exe_path: PATH
			l_stdout, l_stderr: STRING
			l_old_exe: SIMPLE_FILE
		do
			create l_start_time.make_now
			l_ecf_path := workspace_ecf_path

			-- Delete old executable to prevent linker lock issues on Windows
			l_exe_path := find_executable (a_class_name)
			create l_old_exe.make (l_exe_path.name)
			if l_old_exe.exists then
				l_old_exe.delete.do_nothing
			end

			-- Build compile command (use -clean to force fresh compile each time)
			l_cmd := config.eiffel_compiler.name.to_string_8 +
			        " -batch" +
			        " -clean" +
			        " -config " + l_ecf_path.name.to_string_8 +
			        " -target notebook_session" +
			        " -c_compile"

			-- Run compiler
			-- DEBUG: Uncomment to trace compilation issues
			-- print ("DEBUG COMPILE: cmd=[" + l_cmd + "]%N")
			-- print ("DEBUG COMPILE: dir=[" + workspace_path.name.to_string_8 + "]%N")

			process.execute_in_directory (l_cmd, workspace_path.name)

			l_elapsed_ms := elapsed_milliseconds (l_start_time)

			-- Get output
			if attached process.stdout as s then
				l_stdout := s.to_string_8
			else
				create l_stdout.make_empty
			end
			if attached process.stderr as s then
				l_stderr := s.to_string_8
			else
				create l_stderr.make_empty
			end

			-- DEBUG: Uncomment to trace compilation issues
			-- print ("DEBUG COMPILE: exit_code=" + process.exit_code.out + "%N")
			-- print ("DEBUG COMPILE: stdout_len=" + l_stdout.count.out + "%N")
			-- print ("DEBUG COMPILE: stderr_len=" + l_stderr.count.out + "%N")

			-- Check if exe was created (ec.exe returns 0 even on errors!)
			l_exe_path := find_executable (a_class_name)
			create l_old_exe.make (l_exe_path.name)

			if l_old_exe.exists then
				-- Compilation succeeded - exe was created
				create Result.make_success (l_exe_path, l_elapsed_ms)
			else
				-- Compilation failed - parse errors from output
				-- LOG to file for debugging
				log_compile_failure (l_cmd, l_stdout, l_stderr)
				create Result.make (False, l_stdout, l_stderr)
				Result.set_compilation_time_ms (l_elapsed_ms)
				Result.errors.append (error_parser.parse_errors (l_stdout + "%N" + l_stderr))
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
			-- Remove old accumulated_session_*.e files before generating new one
		local
			l_dir: DIRECTORY
			l_workspace: STRING
			l_file: RAW_FILE
		do
			l_workspace := workspace_path.name.to_string_8
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
		end

	write_generated_files (a_class: STRING; a_class_name: STRING; a_ecf: STRING)
			-- Write generated class and ECF to workspace
		local
			l_class_file, l_ecf_file: SIMPLE_FILE
			l_class_path, l_ecf_path: STRING
			l_ok: BOOLEAN
		do
			l_class_path := workspace_path.name.to_string_8 + "/" + a_class_name.as_lower + ".e"
			l_ecf_path := workspace_ecf_path.name.to_string_8

			create l_class_file.make (l_class_path)
			l_ok := l_class_file.set_content (a_class)

			create l_ecf_file.make (l_ecf_path)
			l_ok := l_ecf_file.set_content (a_ecf)
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
