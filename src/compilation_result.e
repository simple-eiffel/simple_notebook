note
	description: "Result of EiffelStudio compilation including output, errors, and status"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	COMPILATION_RESULT

create
	make,
	make_success,
	make_failure

feature {NONE} -- Initialization

	make (a_success: BOOLEAN; a_stdout: STRING; a_stderr: STRING)
			-- Create result with given values
		require
			stdout_not_void: a_stdout /= Void
			stderr_not_void: a_stderr /= Void
		do
			success := a_success
			stdout := a_stdout
			stderr := a_stderr
			create errors.make (0)
			create warnings.make (0)
			create executable_path.make_empty
			compilation_time_ms := 0
		ensure
			success_set: success = a_success
			stdout_set: stdout = a_stdout
			stderr_set: stderr = a_stderr
		end

	make_success (a_exe_path: PATH; a_time_ms: INTEGER)
			-- Create successful compilation result
		require
			path_not_empty: not a_exe_path.is_empty
			time_non_negative: a_time_ms >= 0
		do
			make (True, "", "")
			executable_path := a_exe_path
			compilation_time_ms := a_time_ms
		ensure
			is_success: success
			exe_set: executable_path = a_exe_path
			time_set: compilation_time_ms = a_time_ms
		end

	make_failure (a_errors: ARRAYED_LIST [COMPILER_ERROR]; a_stdout: STRING; a_stderr: STRING)
			-- Create failed compilation result
		require
			errors_not_void: a_errors /= Void
			stdout_not_void: a_stdout /= Void
			stderr_not_void: a_stderr /= Void
		do
			make (False, a_stdout, a_stderr)
			errors := a_errors
		ensure
			is_failure: not success
			errors_set: errors = a_errors
		end

feature -- Access

	success: BOOLEAN
			-- Did compilation succeed?

	stdout: STRING
			-- Standard output from compiler

	stderr: STRING
			-- Standard error from compiler

	errors: ARRAYED_LIST [COMPILER_ERROR]
			-- Parsed compilation errors

	warnings: ARRAYED_LIST [COMPILER_ERROR]
			-- Parsed compilation warnings

	executable_path: PATH
			-- Path to compiled executable (if success)

	compilation_time_ms: INTEGER
			-- Time taken to compile in milliseconds

feature -- Status

	has_errors: BOOLEAN
			-- Are there compilation errors?
		do
			Result := not errors.is_empty
		end

	has_warnings: BOOLEAN
			-- Are there compilation warnings?
		do
			Result := not warnings.is_empty
		end

	error_count: INTEGER
			-- Number of errors
		do
			Result := errors.count
		end

	warning_count: INTEGER
			-- Number of warnings
		do
			Result := warnings.count
		end

	combined_output: STRING
			-- Combined stdout and stderr
		do
			create Result.make (stdout.count + stderr.count + 2)
			Result.append (stdout)
			if not stdout.is_empty and not stderr.is_empty then
				Result.append ("%N")
			end
			Result.append (stderr)
		end

feature -- Commands

	add_error (a_error: COMPILER_ERROR)
			-- Add an error
		require
			error_not_void: a_error /= Void
		do
			errors.extend (a_error)
		ensure
			error_added: errors.has (a_error)
		end

	add_warning (a_warning: COMPILER_ERROR)
			-- Add a warning
		require
			warning_not_void: a_warning /= Void
		do
			warnings.extend (a_warning)
		ensure
			warning_added: warnings.has (a_warning)
		end

	set_executable_path (a_path: PATH)
			-- Set executable path
		require
			path_not_void: a_path /= Void
		do
			executable_path := a_path
		ensure
			path_set: executable_path = a_path
		end

	set_compilation_time_ms (a_time: INTEGER)
			-- Set compilation time
		require
			time_non_negative: a_time >= 0
		do
			compilation_time_ms := a_time
		ensure
			time_set: compilation_time_ms = a_time
		end

feature -- Output

	formatted_errors: STRING
			-- Errors formatted for display
		do
			create Result.make (500)
			across errors as e loop
				Result.append (e.formatted_message)
				Result.append ("%N")
			end
		end

invariant
	stdout_not_void: stdout /= Void
	stderr_not_void: stderr /= Void
	errors_not_void: errors /= Void
	warnings_not_void: warnings /= Void
	compilation_time_non_negative: compilation_time_ms >= 0

end
