note
	description: "Result of executing compiled notebook, including output and timing"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	EXECUTION_RESULT

create
	make,
	make_success,
	make_compilation_error,
	make_runtime_error,
	make_timeout

feature {NONE} -- Initialization

	make (a_exit_code: INTEGER; a_stdout: STRING; a_stderr: STRING; a_time_ms: INTEGER)
			-- Create result with all values
		require
			stdout_not_void: a_stdout /= Void
			stderr_not_void: a_stderr /= Void
			time_non_negative: a_time_ms >= 0
		do
			exit_code := a_exit_code
			stdout := a_stdout
			stderr := a_stderr
			execution_time_ms := a_time_ms
			timed_out := False
			create errors.make (0)
			create compilation_result.make (True, "", "")
		ensure
			exit_code_set: exit_code = a_exit_code
			stdout_set: stdout = a_stdout
			stderr_set: stderr = a_stderr
			time_set: execution_time_ms = a_time_ms
		end

	make_success (a_stdout: STRING; a_time_ms: INTEGER)
			-- Create successful execution result
		require
			stdout_not_void: a_stdout /= Void
			time_non_negative: a_time_ms >= 0
		do
			make (0, a_stdout, "", a_time_ms)
		ensure
			is_success: execution_succeeded
		end

	make_compilation_error (a_comp_result: COMPILATION_RESULT)
			-- Create result for compilation failure
		require
			result_not_void: a_comp_result /= Void
			is_failure: not a_comp_result.success
		do
			make (-1, "", "", 0)
			compilation_result := a_comp_result
			errors := a_comp_result.errors
		ensure
			compilation_failed: not compilation_succeeded
		end

	make_runtime_error (a_stderr: STRING; a_exit_code: INTEGER; a_time_ms: INTEGER)
			-- Create result for runtime failure
		require
			stderr_not_void: a_stderr /= Void
			time_non_negative: a_time_ms >= 0
		do
			make (a_exit_code, "", a_stderr, a_time_ms)
		ensure
			runtime_failed: not execution_succeeded
		end

	make_timeout (a_message: STRING)
			-- Create result for timeout
		require
			message_not_void: a_message /= Void
		do
			make (-1, "", a_message, 0)
			timed_out := True
		ensure
			is_timeout: timed_out
		end

feature -- Access

	exit_code: INTEGER
			-- Process exit code (0 = success)

	stdout: STRING
			-- Standard output from execution

	stderr: STRING
			-- Standard error from execution

	execution_time_ms: INTEGER
			-- Time taken to execute in milliseconds

	timed_out: BOOLEAN
			-- Did execution time out?

	errors: ARRAYED_LIST [COMPILER_ERROR]
			-- Compilation or runtime errors

	compilation_result: COMPILATION_RESULT
			-- Underlying compilation result

feature -- Status

	compilation_succeeded: BOOLEAN
			-- Did compilation succeed?
		do
			Result := compilation_result.success
		end

	execution_succeeded: BOOLEAN
			-- Did execution succeed?
		do
			Result := compilation_succeeded and then exit_code = 0 and then not timed_out
		end

	has_output: BOOLEAN
			-- Is there any stdout output?
		do
			Result := not stdout.is_empty
		end

	has_error_output: BOOLEAN
			-- Is there any stderr output?
		do
			Result := not stderr.is_empty
		end

feature -- Output

	combined_errors: STRING
			-- All error messages combined
		do
			create Result.make (500)

			if not compilation_result.success then
				Result.append ("Compilation failed:%N")
				Result.append (compilation_result.formatted_errors)
			end

			if not stderr.is_empty then
				if not Result.is_empty then
					Result.append ("%N")
				end
				Result.append ("Runtime error:%N")
				Result.append (stderr)
			end

			if timed_out then
				Result.append ("Execution timed out%N")
			end
		end

	status_summary: STRING
			-- Short status summary
		do
			if execution_succeeded then
				Result := "Success (" + execution_time_ms.out + "ms)"
			elseif timed_out then
				Result := "Timeout"
			elseif not compilation_succeeded then
				Result := "Compilation failed (" + errors.count.out + " errors)"
			else
				Result := "Runtime error (exit code " + exit_code.out + ")"
			end
		end

feature -- Commands

	set_compilation_result (a_result: COMPILATION_RESULT)
			-- Set compilation result
		require
			result_not_void: a_result /= Void
		do
			compilation_result := a_result
			if not a_result.success then
				errors := a_result.errors
			end
		ensure
			result_set: compilation_result = a_result
		end

	add_error (a_error: COMPILER_ERROR)
			-- Add an error
		require
			error_not_void: a_error /= Void
		do
			errors.extend (a_error)
		ensure
			error_added: errors.has (a_error)
		end

invariant
	stdout_not_void: stdout /= Void
	stderr_not_void: stderr /= Void
	errors_not_void: errors /= Void
	execution_time_non_negative: execution_time_ms >= 0

end
