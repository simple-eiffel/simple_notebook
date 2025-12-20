note
	description: "Interactive CLI for Eiffel notebook - REPL-style execution"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	NOTEBOOK_CLI

create
	make

feature -- Constants

	Version: STRING = "1.0.0-alpha.14"
			-- Current version for issue tracking

	Log_file_name: STRING = "eiffel_notebook_session.log"
			-- Session log filename

feature {NONE} -- Initialization

	make
			-- Launch interactive notebook session
		local
			l_config_path: PATH
		do
			load_config
			create notebook.make_with_config (loaded_config)
			init_session_log
			running := True
			log_event ("Session started", "version=" + Version)
			print_welcome
			repl_loop
		end

	load_config
			-- Load configuration from file next to exe, or use defaults
		local
			l_env: EXECUTION_ENVIRONMENT
			l_exe_dir: detachable STRING
			l_config_file: STRING
			l_file: PLAIN_TEXT_FILE
			l_path: PATH
		do
			create l_env
			-- Try to find config.json next to the executable
			if attached l_env.command_line.argument (0) as exe_path then
				l_exe_dir := exe_path.substring (1, exe_path.last_index_of ('\', exe_path.count))
				if l_exe_dir.is_empty then
					l_exe_dir := exe_path.substring (1, exe_path.last_index_of ('/', exe_path.count))
				end
			end

			if l_exe_dir /= Void and then not l_exe_dir.is_empty then
				l_config_file := l_exe_dir + "config.json"
				create l_file.make_with_name (l_config_file)
				if l_file.exists then
					create l_path.make_from_string (l_config_file)
					create loaded_config.make_from_file (l_path)
					config_source := l_config_file
				else
					create loaded_config.make_with_defaults
					config_source := "(defaults)"
				end
			else
				create loaded_config.make_with_defaults
				config_source := "(defaults)"
			end
		ensure
			config_loaded: loaded_config /= Void
		end

	loaded_config: NOTEBOOK_CONFIG
			-- Configuration loaded at startup

	config_source: STRING
			-- Where config was loaded from

feature -- Access

	notebook: SIMPLE_NOTEBOOK
			-- The notebook engine

	running: BOOLEAN
			-- Is the REPL running?

	cell_number: INTEGER
			-- Current cell number for display

	session_log: detachable PLAIN_TEXT_FILE
			-- Session log file for troubleshooting

feature {NONE} -- REPL

	repl_loop
			-- Main read-eval-print loop
		local
			l_input: STRING
		do
			from
				cell_number := 1
			until
				not running
			loop
				print_prompt
				l_input := read_input
				if not l_input.is_empty then
					process_input (l_input)
				end
			end
			print ("%NGoodbye!%N")
		end

	print_prompt
			-- Display the input prompt
		do
			io.put_string ("e[" + cell_number.out + "]> ")
		end

	read_input: STRING
			-- Read input line by line until empty line submits
			-- First line never auto-submits - always shows ... for continuation
			-- Empty line (just Enter) triggers submission
		local
			l_line: STRING
			l_done: BOOLEAN
		do
			create Result.make_empty

			-- Read first line
			io.read_line
			if attached io.last_string as s then
				l_line := s.twin
			else
				create l_line.make_empty
			end

			-- Handle explicit line continuation with backslash (remove all trailing \)
			from until not l_line.ends_with ("\") loop
				l_line.remove_tail (1)
			end

			-- Check for commands (single-line, immediate execution)
			if not l_line.is_empty and then l_line.item (1) = '-' then
				Result := l_line
				Result.left_adjust
				Result.right_adjust
			elseif l_line.is_empty then
				-- Empty first line = nothing to do
				Result := ""
			else
				-- Multi-line mode: accumulate until empty line
				Result.append (l_line)

				from
					l_done := False
				until
					l_done
				loop
					io.put_string ("...   ")
					io.read_line
					if attached io.last_string as s then
						l_line := s.twin
					else
						l_line := ""
					end

					-- Empty line = submit
					if l_line.is_empty then
						l_done := True
					-- -done also submits
					elseif l_line.same_string ("-done") then
						l_done := True
					else
						-- Handle explicit continuation (remove all trailing \)
						from until not l_line.ends_with ("\") loop
							l_line.remove_tail (1)
						end
						Result.append_character ('%N')
						Result.append (l_line)
					end
				end

				Result.left_adjust
				Result.right_adjust
			end
		end

	process_input (a_input: STRING)
			-- Process user input (command or code)
		require
			input_not_empty: not a_input.is_empty
		do
			log_input (a_input)
			if a_input.starts_with ("-") then
				process_command (a_input)
			else
				execute_code (a_input)
			end
		end

	process_command (a_cmd: STRING)
			-- Process a -command (may include arguments)
		local
			l_parts: LIST [STRING]
			l_base_cmd, l_arg: STRING
		do
			l_parts := a_cmd.split (' ')
			l_base_cmd := l_parts.first.as_lower
			if l_parts.count > 1 then l_arg := l_parts.i_th (2) else l_arg := "" end

			if l_base_cmd.same_string ("-quit") or l_base_cmd.same_string ("-q") then
				log_event ("Session ended", "cells=" + notebook.cell_count.out)
				running := False
			elseif l_base_cmd.same_string ("-help") or l_base_cmd.same_string ("-h") or l_base_cmd.same_string ("-?") then
				print_help
			elseif l_base_cmd.same_string ("-clear") or l_base_cmd.same_string ("-c") then
				clear_notebook
			elseif l_base_cmd.same_string ("-vars") or l_base_cmd.same_string ("-v") then
				show_variables
			elseif l_base_cmd.same_string ("-cells") then
				show_cells
			elseif l_base_cmd.same_string ("-run") or l_base_cmd.same_string ("-r") then
				run_all_cells
			elseif l_base_cmd.same_string ("-show") or l_base_cmd.same_string ("-s") then
				if l_arg.is_empty then
					print ("Usage: -show N (show cell N code)%N")
				elseif l_arg.is_integer then
					show_cell_code (l_arg.to_integer)
				else
					print ("Invalid cell number%N")
				end
			elseif l_base_cmd.same_string ("-delete") or l_base_cmd.same_string ("-del") or l_base_cmd.same_string ("-d") then
				if l_arg.is_empty then
					print ("Usage: -d N (delete cell N)%N")
				elseif l_arg.is_integer then
					delete_cell (l_arg.to_integer)
				else
					print ("Invalid cell number%N")
				end
			elseif l_base_cmd.same_string ("-code") then
				if l_arg.is_empty then
					print ("Usage: -code N (show cell N in generated class)%N")
				elseif l_arg.is_integer then
					show_cell_in_class (l_arg.to_integer)
				else
					print ("Invalid cell number%N")
				end
			elseif l_base_cmd.same_string ("-class") then
				show_generated_class
			elseif l_base_cmd.same_string ("-debug") then
				show_debug_classification
			elseif l_base_cmd.same_string ("-edit") or l_base_cmd.same_string ("-e") then
				if l_arg.is_empty then
					if notebook.cell_count > 0 then
						edit_cell (notebook.cell_count)
					else
						print ("No cells to edit%N")
					end
				elseif l_arg.is_integer then
					edit_cell (l_arg.to_integer)
				else
					print ("Invalid cell number%N")
				end
			else
				print ("Unknown command: " + l_base_cmd + ". Type -help%N")
			end
		end

	execute_code (a_code: STRING)
			-- Add code as cell and execute
		local
			l_result: STRING
			l_success: BOOLEAN
		do
			io.put_string ("Compiling...")
			l_result := notebook.run (a_code)
			io.put_string ("%R             %R")

			-- Determine if this was success or error
			l_success := not l_result.has_substring ("Error") and
			             not l_result.has_substring ("failed")

			if not l_result.is_empty then
				print ("e[" + cell_number.out + "] Output:%N")
				print (l_result)
				if not l_result.ends_with ("%N") then
					print ("%N")
				end
			end

			log_output (l_result, l_success)
			cell_number := cell_number + 1
		end

feature {NONE} -- Commands

	clear_notebook
			-- Clear all cells and start fresh
		do
			notebook.new_notebook
			cell_number := 1
			print ("Notebook cleared.%N")
		end

	show_variables
			-- Display all tracked variables
		do
			if notebook.variables.is_empty then
				print ("No variables defined.%N")
			else
				print ("Variables:%N")
				across notebook.variables as v loop
					print ("  " + v.name + ": " + v.type_name)
					if v.is_shared then
						print (" (shared)")
					end
					print ("%N")
				end
			end
		end

	show_cells
			-- Display summary of all cells
		local
			i: INTEGER
			l_code, l_first_line: STRING
		do
			if notebook.cell_count = 0 then
				print ("No cells.%N")
			else
				print ("Cells:%N")
				from i := 1 until i > notebook.cell_count loop
					if attached notebook.engine.current_notebook.cell_at (i) as c then
						l_code := c.code
						if l_code.has ('%N') then
							l_first_line := l_code.substring (1, l_code.index_of ('%N', 1) - 1)
						else
							l_first_line := l_code
						end
						if l_first_line.count > 50 then
							l_first_line := l_first_line.substring (1, 50) + "..."
						end
						print ("  [" + i.out + "] " + l_first_line + "%N")
					end
					i := i + 1
				end
			end
		end

	run_all_cells
			-- Execute all cells in order
		do
			io.put_string ("Compiling...")
			notebook.execute_all
			io.put_string ("%R             %R")
			if not notebook.output.is_empty then
				print ("Output:%N")
				print (notebook.output)
				if not notebook.output.ends_with ("%N") then
					print ("%N")
				end
			end
		end

	show_cell_code (a_num: INTEGER)
			-- Display full code of cell N with line numbers
		local
			l_lines: LIST [STRING]
			l_line_num: INTEGER
		do
			if a_num < 1 or a_num > notebook.cell_count then
				print ("Invalid cell number. Valid: 1-" + notebook.cell_count.out + "%N")
			elseif attached notebook.engine.current_notebook.cell_at (a_num) as c then
				print ("--- Cell " + a_num.out + " ---%N")
				l_lines := c.code.split ('%N')
				l_line_num := 1
				across l_lines as ln loop
					print ("  " + l_line_num.out + ": " + ln + "%N")
					l_line_num := l_line_num + 1
				end
				print ("--------------%N")
			end
		end

	delete_cell (a_num: INTEGER)
			-- Delete cell N
		do
			if a_num < 1 or a_num > notebook.cell_count then
				print ("Invalid cell number. Valid: 1-" + notebook.cell_count.out + "%N")
			elseif attached notebook.engine.current_notebook.cell_at (a_num) as c then
				notebook.engine.remove_cell (c.id)
				cell_number := notebook.cell_count + 1
				print ("Deleted cell " + a_num.out + ". Use :run to re-execute.%N")
			end
		end

	show_cell_in_class (a_num: INTEGER)
			-- Show how cell N appears in the generated class
		local
			l_lines: LIST [STRING]
			l_line_num: INTEGER
		do
			if notebook.cell_count = 0 then
				print ("No cells.%N")
			elseif a_num < 1 or a_num > notebook.cell_count then
				print ("Invalid cell number. Valid: 1-" + notebook.cell_count.out + "%N")
			elseif attached notebook.engine.current_notebook.cell_at (a_num) as c then
				print ("=== Cell " + a_num.out + " ===%N")
				print ("Feature: execute_cell_" + a_num.out + "%N%N")
				l_lines := c.code.split ('%N')
				l_line_num := 1
				across l_lines as ln loop
					print ("  " + l_line_num.out + ": " + ln + "%N")
					l_line_num := l_line_num + 1
				end
				print ("=================%N")
			end
		end

	show_generated_class
			-- Show the full generated Eiffel class (what compiler sees)
		local
			l_generator: ACCUMULATED_CLASS_GENERATOR
			l_code: STRING
			l_lines: LIST [STRING]
			l_line_num: INTEGER
		do
			if notebook.cell_count = 0 then
				print ("No cells.%N")
			else
				create l_generator.make
				l_code := l_generator.generate_class (notebook.engine.current_notebook)
				print ("=== Generated Class ===%N")
				l_lines := l_code.split ('%N')
				l_line_num := 1
				across l_lines as ln loop
					print (formatted_line_number (l_line_num) + ln + "%N")
					l_line_num := l_line_num + 1
				end
				print ("=======================%N")
			end
		end

	show_debug_classification
			-- Debug: show classification of each cell
		local
			l_classifier: CELL_CLASSIFIER
			l_classification: INTEGER
			i: INTEGER
		do
			if notebook.cell_count = 0 then
				print ("No cells.%N")
			else
				create l_classifier.make
				print ("=== Cell Classifications ===%N")
				from i := 1 until i > notebook.cell_count loop
					if attached notebook.engine.current_notebook.cell_at (i) as c then
						l_classification := l_classifier.classify (c.code)
						print ("  [" + i.out + "] " + l_classifier.classification_name (l_classification))
						print (": " + c.code.substring (1, c.code.count.min (40)))
						if c.code.count > 40 then print ("...") end
						print ("%N")
					end
					i := i + 1
				end
				print ("============================%N")
			end
		end

	edit_cell (a_num: INTEGER)
			-- Edit cell N line by line
		local
			l_lines: ARRAYED_LIST [STRING]
			l_new_code, l_input, l_line_str: STRING
			l_done: BOOLEAN
			l_line_num, l_colon_pos: INTEGER
		do
			if a_num < 1 or a_num > notebook.cell_count then
				print ("Invalid cell number. Valid: 1-" + notebook.cell_count.out + "%N")
			elseif attached notebook.engine.current_notebook.cell_at (a_num) as c then
				create l_lines.make (10)
				across c.code.split ('%N') as ln loop l_lines.extend (ln.twin) end
				print ("Editing cell " + a_num.out + " (" + l_lines.count.out + " lines)%N")
				print ("N:text=replace, +text=append, ~N=delete line, -done=finish%N%N")
				l_line_num := 1
				across l_lines as ln loop
					print ("  " + l_line_num.out + ": " + ln + "%N")
					l_line_num := l_line_num + 1
				end
				print ("%N")
				from l_done := False until l_done loop
					io.put_string ("edit> ")
					io.read_line
					if attached io.last_string as s then
						l_input := s.twin
						l_input.left_adjust
						l_input.right_adjust
						if l_input.same_string ("-done") or l_input.is_empty then
							l_done := True
						elseif l_input.starts_with ("+") then
							l_lines.extend (l_input.substring (2, l_input.count))
							print ("  Added line " + l_lines.count.out + "%N")
						elseif l_input.starts_with ("~") and l_input.count > 1 then
							l_line_str := l_input.substring (2, l_input.count)
							l_line_str.left_adjust
							if l_line_str.is_integer then
								l_line_num := l_line_str.to_integer
								if l_line_num >= 1 and l_line_num <= l_lines.count then
									l_lines.go_i_th (l_line_num)
									l_lines.remove
									print ("  Deleted line " + l_line_num.out + "%N")
								else
									print ("  Invalid line%N")
								end
							end
						else
							l_colon_pos := l_input.index_of (':', 1)
							if l_colon_pos > 1 then
								l_line_str := l_input.substring (1, l_colon_pos - 1)
								l_line_str.left_adjust
								l_line_str.right_adjust
								if l_line_str.is_integer then
									l_line_num := l_line_str.to_integer
									if l_line_num >= 1 and l_line_num <= l_lines.count then
										l_lines.put_i_th (l_input.substring (l_colon_pos + 1, l_input.count), l_line_num)
										print ("  Line " + l_line_num.out + " replaced%N")
									else
										print ("  Invalid line%N")
									end
								end
							else
								print ("  N:text, +text, ~N, -done%N")
							end
						end
					else
						l_done := True
					end
				end
				create l_new_code.make (500)
				from l_line_num := 1 until l_line_num > l_lines.count loop
					l_new_code.append (l_lines.i_th (l_line_num))
					if l_line_num < l_lines.count then l_new_code.append_character ('%N') end
					l_line_num := l_line_num + 1
				end
				notebook.engine.update_cell (c.id, l_new_code)
				print ("Cell updated. Use :run to re-execute.%N")
			end
		end

feature {NONE} -- Helpers

	formatted_line_number (a_num: INTEGER): STRING
			-- Format line number with padding
		do
			if a_num < 10 then
				Result := "   " + a_num.out + "  "
			elseif a_num < 100 then
				Result := "  " + a_num.out + "  "
			else
				Result := " " + a_num.out + "  "
			end
		end

feature {NONE} -- Output

	print_welcome
			-- Print welcome banner with version
		do
			print ("%N")
			print ("Eiffel Notebook " + Version + "%N")
			print ("Type Eiffel code to execute. Type -help for commands.%N")
			print ("Config: " + config_source + "%N")
			print ("Log: " + log_path + "%N")
			print ("%N")
		end

feature {NONE} -- Logging

	init_session_log
			-- Initialize session log file
		local
			l_timestamp: DATE_TIME
			l_retried: BOOLEAN
		do
			if not l_retried then
				create l_timestamp.make_now
				create session_log.make_open_append (log_path)

				if attached session_log as log then
					log.put_string ("========================================%N")
					log.put_string ("Eiffel Notebook Session Log%N")
					log.put_string ("Version: " + Version + "%N")
					log.put_string ("Started: " + l_timestamp.out + "%N")
					log.put_string ("========================================%N%N")
					log.flush
				end
			end
		rescue
			-- Logging should never crash the app
			l_retried := True
			session_log := Void
			retry
		end

	log_path: STRING
			-- Path to session log file
		local
			l_workspace: STRING
		do
			l_workspace := notebook.config.workspace_dir.name.to_string_8
			Result := l_workspace + "/" + Log_file_name
		end

	log_event (a_event: STRING; a_details: STRING)
			-- Log event with timestamp
		require
			event_not_empty: not a_event.is_empty
		local
			l_timestamp: DATE_TIME
			l_retried: BOOLEAN
		do
			if not l_retried and attached session_log as log then
				create l_timestamp.make_now
				log.put_string ("[" + formatted_timestamp (l_timestamp) + "] ")
				log.put_string (a_event)
				if not a_details.is_empty then
					log.put_string (" | " + a_details)
				end
				log.put_new_line
				log.flush
			end
		rescue
			-- Logging should never crash the app
			l_retried := True
			retry
		end

	log_input (a_input: STRING)
			-- Log user input
		require
			input_not_void: a_input /= Void
		do
			if a_input.starts_with ("-") then
				log_event ("CMD", a_input)
			else
				log_event ("INPUT", "cell[" + cell_number.out + "] " + truncate (a_input, 80))
			end
		end

	log_output (a_output: STRING; a_success: BOOLEAN)
			-- Log execution output
		require
			output_not_void: a_output /= Void
		do
			if a_success then
				log_event ("OUTPUT", "cell[" + cell_number.out + "] success, " + a_output.count.out + " chars")
			else
				log_event ("ERROR", "cell[" + cell_number.out + "] " + truncate (a_output, 200))
			end
		end

	formatted_timestamp (a_dt: DATE_TIME): STRING
			-- Format as HH:MM:SS
		do
			Result := two_digit (a_dt.hour) + ":" +
			          two_digit (a_dt.minute) + ":" +
			          two_digit (a_dt.second)
		end

	two_digit (n: INTEGER): STRING
			-- Format as two digits
		do
			if n < 10 then
				Result := "0" + n.out
			else
				Result := n.out
			end
		end

	truncate (a_str: STRING; a_max: INTEGER): STRING
			-- Truncate string with ellipsis if too long
		require
			str_not_void: a_str /= Void
			max_positive: a_max > 3
		do
			if a_str.count <= a_max then
				Result := a_str.twin
			else
				Result := a_str.substring (1, a_max - 3) + "..."
			end
			-- Replace newlines with spaces for single-line log
			Result.replace_substring_all ("%N", " ")
		ensure
			not_too_long: Result.count <= a_max
		end

	print_help
			-- Print help message
		do
			print ("%NCommands:%N")
			print ("  -help, -h      Show this help%N")
			print ("  -quit, -q      Exit%N")
			print ("  -clear, -c     Clear all cells%N")
			print ("%NCell Management:%N")
			print ("  -cells         List cells (summary)%N")
			print ("  -show N, -s N  Show cell N code%N")
			print ("  -d N           Delete cell N%N")
			print ("  -edit N, -e N  Edit cell N (or last)%N")
			print ("%NExecution:%N")
			print ("  -run, -r       Re-run all cells%N")
			print ("%NInspection (see generated code):%N")
			print ("  -class         Show full generated Eiffel class%N")
			print ("  -code N        Show how cell N appears in class%N")
			print ("  -vars, -v      Show tracked variables%N")
			print ("  -debug         Show cell classifications%N")
			print ("%NCode Entry (multi-line):%N")
			print ("  Type code, press Enter for next line%N")
			print ("  Shows '...' prompt for continuation%N")
			print ("  Empty line (just Enter) submits the cell%N")
			print ("%NCell Types (auto-detected):%N")
			print ("  x: INTEGER           -> attribute (persists)%N")
			print ("  f do ... end         -> routine%N")
			print ("  x := 42              -> instruction%N")
			print ("  x + 1                -> expression (printed)%N")
			print ("%NVersion: " + Version + "%N")
			print ("Session log: " + log_path + "%N%N")
		end

end