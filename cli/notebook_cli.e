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

	Version: STRING = "1.0.0-alpha.34"
			-- Current version for issue tracking

	Log_file_name: STRING = "eiffel_notebook_session.log"
			-- Session log filename

	Default_notebook_name: STRING = "default"
			-- Default notebook name when none specified

	Notebooks_subdir: STRING = "notebooks"
			-- Subdirectory for notebook files

feature {NONE} -- Initialization

	make
			-- Launch interactive notebook session
		do
			load_config
			create notebook.make_with_config (loaded_config)
			-- Start in silent compile mode (user can switch with -compile verbose)
			notebook.engine.executor.set_verbose_compile (False)
			init_storage
			init_history
			current_notebook_name := Default_notebook_name
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
			if attached l_env.arguments.argument (0) as exe_path then
				l_exe_dir := exe_path.substring (1, exe_path.last_index_of ('\', exe_path.count)).to_string_8
				if l_exe_dir.is_empty then
					l_exe_dir := exe_path.substring (1, exe_path.last_index_of ('/', exe_path.count)).to_string_8
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
					-- Auto-detect EiffelStudio paths
					loaded_config := (create {CONFIG_DETECTOR}.make).detect_all
					config_source := "(auto-detected)"
				end
			else
				-- Auto-detect EiffelStudio paths
				loaded_config := (create {CONFIG_DETECTOR}.make).detect_all
				config_source := "(auto-detected)"
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

	verbose_compile: BOOLEAN
			-- Show compiler output during execution?

	storage: detachable NOTEBOOK_STORAGE
			-- Notebook file storage

	current_notebook_name: STRING
			-- Name of current notebook (without extension)

	scratch_mode: BOOLEAN
			-- If True, no auto-save

	history: COMMAND_HISTORY
			-- Command history manager

	focused_class_name: detachable STRING
			-- Name of class currently being edited (Void = session mode)

	focused_class_inherit: detachable STRING
			-- Inherit clause for focused class (e.g., "inherit CAR BOAT")

	focused_class_content: detachable ARRAYED_LIST [STRING]
			-- Lines of the class being edited (between class header and end)

	editing_class_cell: INTEGER
			-- Cell number being edited (0 = creating new class, >0 = replacing cell)

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
			-- Display the input prompt with dirty indicator
		local
			l_dirty: STRING
			l_line_count: INTEGER
		do
			if notebook.is_dirty then
				l_dirty := "*"
			else
				l_dirty := ""
			end
			if attached focused_class_name as fcn then
				-- Focused on a class: show class name and line count
				if attached focused_class_content as fcc then
					l_line_count := fcc.count + 2  -- +2 for class header and end
				else
					l_line_count := 2
				end
				io.put_string ("e[" + fcn + " " + l_line_count.out + "]" + l_dirty + "> ")
			else
				-- Normal session mode
				io.put_string ("e[" + cell_number.out + "]" + l_dirty + "> ")
			end
		end

	read_input: STRING
			-- Read input line by line until empty line submits
			-- First line never auto-submits - always shows ... for continuation
			-- Empty line (just Enter) triggers submission
		local
			l_line: STRING
			l_class_name: STRING
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
			-- Special case: -class NAME -> class NAME (triggers multi-line)
			-- If class already exists, show it and set editing_class_cell for update
			if not l_line.is_empty and then l_line.as_lower.starts_with ("-class ") then
				-- Extract class name and check if it exists
				l_class_name := l_line.substring (8, l_line.count)
				l_class_name.left_adjust
				l_class_name.right_adjust
				l_class_name := l_class_name.as_upper
				
				-- Check if this class already exists
				editing_class_cell := find_class_cell_number (l_class_name)
				if editing_class_cell > 0 then
					print ("Editing class " + l_class_name + " (cell " + editing_class_cell.out + "):%N")
					show_cell_code (editing_class_cell)
					print ("Type complete new class (starts with 'class " + l_class_name + "'):%N")
					-- Don't prepend class name - user types full replacement
					l_line := ""
				else
					-- Creating new class - add class header automatically
					l_line := "class " + l_class_name
				end
			elseif not l_line.is_empty and then l_line.item (1) = '-' then
				Result := l_line
				Result.left_adjust
				Result.right_adjust
			end
			
			if not Result.is_empty then
				-- Already handled as command
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
			-- Process user input (command, history recall, or code)
		require
			input_not_empty: not a_input.is_empty
		local
			l_num_str: STRING
			l_num: INTEGER
		do
			log_input (a_input)
			if a_input.starts_with ("-") then
				-- Commands work in both modes
				if a_input.same_string ("-show") and focused_class_name /= Void then
					-- Special: -show in focus mode shows class content
					show_focused_class_content
				else
					process_command (a_input)
				end
			elseif focused_class_name /= Void then
				-- In class focus mode: add line to class
				add_line_to_focused_class (a_input)
			elseif a_input.same_string ("!!") then
				-- Re-execute last cell
				do_history_recall (0)
			elseif a_input.starts_with ("!") and a_input.count > 1 then
				-- Re-execute cell N
				l_num_str := a_input.substring (2, a_input.count)
				l_num_str.left_adjust
				l_num_str.right_adjust
				if l_num_str.is_integer then
					l_num := l_num_str.to_integer
					do_history_recall (l_num)
				else
					execute_code (a_input)
				end
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
			elseif l_base_cmd.same_string ("-generated") or l_base_cmd.same_string ("-gen") then
				show_generated_class
			elseif l_base_cmd.same_string ("-class") then
				do_class_focus (a_cmd)
			elseif l_base_cmd.same_string ("-exit") then
				do_exit_class_focus
			elseif l_base_cmd.same_string ("-cancel") or l_base_cmd.same_string ("-abort") then
				do_cancel_class_focus
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
			elseif l_base_cmd.same_string ("-compile") then
				if l_arg.same_string ("verbose") then
					verbose_compile := True
					notebook.engine.executor.set_verbose_compile (True)
					print ("Compile mode: verbose (shows compiler output)%N")
				elseif l_arg.same_string ("silent") then
					verbose_compile := False
					notebook.engine.executor.set_verbose_compile (False)
					print ("Compile mode: silent%N")
				else
					print ("Usage: -compile verbose|silent (current: ")
					if verbose_compile then print ("verbose") else print ("silent") end
					print (")%N")
				end
			-- Session management commands
			elseif l_base_cmd.same_string ("-save") then
				do_save (l_arg)
			elseif l_base_cmd.same_string ("-open") or l_base_cmd.same_string ("-restore") then
				if l_arg.is_empty then
					print ("Usage: -open <name> (open notebook)%N")
				else
					do_open (l_arg)
				end
			elseif l_base_cmd.same_string ("-new") then
				do_new
			elseif l_base_cmd.same_string ("-notebooks") or l_base_cmd.same_string ("-list") then
				do_list_notebooks
			-- History commands
			elseif l_base_cmd.same_string ("-history") then
				if l_arg.is_empty then
					do_show_history (20)
				elseif l_arg.is_integer then
					do_show_history (l_arg.to_integer)
				else
					print ("Usage: -history [N] (show last N commands)%N")
				end
			elseif l_base_cmd.same_string ("-classes") then
				show_user_classes
			else
				print ("Unknown command: " + l_base_cmd + ". Type -help%N")
			end
		end

	execute_code (a_code: STRING)
			-- Add code as cell and execute
		local
			l_result: STRING
			l_success: BOOLEAN
			l_cell_count_before: INTEGER
			l_changes: ARRAYED_LIST [VARIABLE_CHANGE]
			l_final_code: STRING
			l_lower: STRING
			l_is_class_edit: BOOLEAN
		do
			-- For class definitions:
			-- 1. Auto-add 'feature' if no inherit/feature keyword
			-- 2. Always add class 'end' (user types routine ends, we add class end)
			l_final_code := a_code
			if a_code.as_lower.starts_with ("class ") then
				l_lower := a_code.as_lower
				-- Add 'feature' after class line if missing and no inherit
				if not l_lower.has_substring ("feature") and not l_lower.has_substring ("inherit") then
					-- Insert 'feature' after first line (class NAME)
					l_final_code := insert_feature_after_class_line (a_code)
				end
				-- Always add class 'end'
				l_final_code := l_final_code + "%Nend"
			end

			-- Record in history
			history.add (l_final_code, cell_number)

			-- Save variable state for change detection
			notebook.save_variable_state

			-- DBC trace: caller logs preconditions before call
			l_cell_count_before := notebook.cell_count
			log_dbc_call ("CLI.execute_code", "NOTEBOOK.run",
				"code_not_empty=" + b(not a_code.is_empty) +
				", cell_count=" + l_cell_count_before.out)

			if editing_class_cell > 0 then
				-- Update existing class cell instead of creating new
				l_is_class_edit := True
				if attached notebook.engine.current_notebook.cell_at (editing_class_cell) as c then
					notebook.update_cell (c.id, l_final_code)
					l_result := "Class " + extract_class_name (l_final_code) + " updated in cell " + editing_class_cell.out + "."
				else
					l_result := "Error: cell " + editing_class_cell.out + " not found"
				end
				editing_class_cell := 0  -- Reset after update
			else
				io.put_string ("Compiling...")
				l_result := notebook.run (l_final_code)
				io.put_string ("%R             %R")
			end

			-- Show compiler output if verbose mode
			if verbose_compile then
				print ("%N--- Compiler Output ---%N")
				print (notebook.last_compiler_output)
				print ("--- End Compiler Output ---%N%N")
			end

			-- DBC trace: log postconditions after return
			log_dbc_return ("NOTEBOOK.run",
				"result_attached=" + b(l_result /= Void) +
				", cell_added=" + b(notebook.cell_count > l_cell_count_before))

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

			-- Show variable changes if any
			l_changes := notebook.variable_changes
			if not l_changes.is_empty then
				across l_changes as c loop
					print (c.formatted + "%N")
				end
			end

			-- Auto-save if not in scratch mode
			if not scratch_mode then
				auto_save
			end

			if not l_is_class_edit then
				cell_number := cell_number + 1
			end
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

	show_user_classes
			-- Show list of user-defined classes from cells
		local
			l_classifier: CELL_CLASSIFIER
			l_class_name: STRING
			l_count, i: INTEGER
		do
			create l_classifier.make
			l_count := 0

			-- Scan cells for class definitions
			from i := 1 until i > notebook.cell_count loop
				if attached notebook.engine.current_notebook.cell_at (i) as c then
					if l_classifier.classify (c.code) = {CELL_CLASSIFIER}.Classification_class then
						l_class_name := extract_class_name (c.code)
						if l_count = 0 then
							print ("User-defined classes:%N")
						end
						l_count := l_count + 1
						print ("  " + l_count.out + ". " + l_class_name + " (cell " + i.out + ")%N")
					end
				end
				i := i + 1
			end

			if l_count = 0 then
				print ("No user-defined classes.%N")
			end
		end

	extract_class_name (a_code: STRING): STRING
			-- Extract class name from class definition
		local
			l_lower: STRING
			l_pos, l_end: INTEGER
		do
			l_lower := a_code.as_lower
			l_pos := l_lower.substring_index ("class ", 1)
			if l_pos > 0 then
				l_pos := l_pos + 6
				-- Skip whitespace
				from until l_pos > a_code.count or else not a_code.item (l_pos).is_space loop
					l_pos := l_pos + 1
				end
				-- Find end of name
				l_end := l_pos
				from until l_end > a_code.count or else a_code.item (l_end).is_space or else a_code.item (l_end) = '%N' loop
					l_end := l_end + 1
				end
				if l_end > l_pos then
					Result := a_code.substring (l_pos, l_end - 1)
				else
					Result := "UNKNOWN"
				end
			else
				Result := "UNKNOWN"
			end
		end

	is_valid_class_name (a_name: STRING): BOOLEAN
			-- Is this a valid Eiffel class name?
			-- Must start with letter, contain only letters/digits/underscores
		local
			i: INTEGER
			c: CHARACTER
		do
			if a_name.count > 0 then
				c := a_name.item (1)
				if c.is_alpha then
					Result := True
					from i := 2 until i > a_name.count or not Result loop
						c := a_name.item (i)
						Result := c.is_alpha or c.is_digit or c = '_'
						i := i + 1
					end
				end
			end
		end

feature {NONE} -- Class Focus Mode

	do_class_focus (a_cmd: STRING)
			-- Enter or manage class focus mode
			-- -class NAME [inherit X Y Z]: focus on class (create if new)
			-- -class: show current focused class or list if none
		local
			l_parts: LIST [STRING]
			l_name, l_inherit: STRING
			l_inherit_pos: INTEGER
		do
			l_parts := a_cmd.split (' ')
			if l_parts.count >= 2 then
				l_name := l_parts.i_th (2).as_upper
				-- Check for inherit clause
				l_inherit_pos := a_cmd.as_lower.substring_index (" inherit ", 1)
				if l_inherit_pos > 0 then
					l_inherit := a_cmd.substring (l_inherit_pos + 1, a_cmd.count)
					l_inherit.left_adjust
				else
					l_inherit := ""
				end
				if not is_valid_class_name (l_name) then
					print ("Invalid class name: " + l_name + "%N")
					print ("Class names must start with a letter and contain only letters, digits, underscores.%N")
				else
					enter_class_focus_with_inherit (l_name, l_inherit)
				end
			else
				-- No argument: show current focus or list classes
				if attached focused_class_name as fcn then
					print ("Currently editing class: " + fcn + "%N")
					show_focused_class_content
				else
					show_user_classes
					print ("Use: -class NAME to focus on a class%N")
				end
			end
		end

	enter_class_focus_with_inherit (a_name: STRING; a_inherit: STRING)
			-- Focus on class with given name and optional inherit clause
		require
			name_not_empty: not a_name.is_empty
			valid_class_name: is_valid_class_name (a_name)
		local
			l_existing: detachable STRING
			l_lines: ARRAYED_LIST [STRING]
		do
			-- Check if class already exists
			l_existing := find_existing_class_content (a_name)

			focused_class_name := a_name
			if a_inherit.is_empty then
				focused_class_inherit := Void
			else
				focused_class_inherit := a_inherit
			end

			if attached l_existing as existing then
				-- Parse existing class into lines (content between header and end)
				focused_class_content := parse_class_content (existing)
				focused_class_inherit := parse_class_inherit (existing)
				print ("Editing existing class: " + a_name + "%N")
			else
				-- Create new class with empty content
				create l_lines.make (5)
				focused_class_content := l_lines
				if not a_inherit.is_empty then
					print ("Creating new class: " + a_name + " " + a_inherit + "%N")
				else
					print ("Creating new class: " + a_name + "%N")
				end
			end

			print ("Add features/attributes. Type -exit when done, -show to see class.%N")
		end

	parse_class_inherit (a_class_code: STRING): detachable STRING
			-- Extract inherit clause from class code
		local
			l_lower: STRING
			l_inherit_pos, l_feature_pos: INTEGER
		do
			l_lower := a_class_code.as_lower
			l_inherit_pos := l_lower.substring_index ("inherit", 1)
			if l_inherit_pos > 0 then
				l_feature_pos := l_lower.substring_index ("feature", l_inherit_pos)
				if l_feature_pos > 0 then
					Result := a_class_code.substring (l_inherit_pos, l_feature_pos - 1)
					Result.right_adjust
				end
			end
		end

	find_existing_class_content (a_name: STRING): detachable STRING
			-- Find content of existing class cell by name
		local
			l_classifier: CELL_CLASSIFIER
			l_code_lower: STRING
			i: INTEGER
		do
			create l_classifier.make
			from i := 1 until i > notebook.cell_count or Result /= Void loop
				if attached notebook.engine.current_notebook.cell_at (i) as c then
					if l_classifier.classify (c.code) = {CELL_CLASSIFIER}.Classification_class then
						l_code_lower := c.code.as_lower
						if l_code_lower.has_substring ("class " + a_name.as_lower) then
							Result := c.code
						end
					end
				end
				i := i + 1
			end
		end

	parse_class_content (a_class_code: STRING): ARRAYED_LIST [STRING]
			-- Extract content lines between class header and end
		local
			l_lines: LIST [STRING]
			l_in_content: BOOLEAN
			l_lower: STRING
		do
			create Result.make (10)
			l_lines := a_class_code.split ('%N')
			l_in_content := False

			across l_lines as ln loop
				l_lower := ln.as_lower
				l_lower.left_adjust
				if not l_in_content then
					-- Skip until we pass the class header
					if l_lower.starts_with ("class ") then
						l_in_content := True
					end
				else
					-- Stop at end keyword
					if l_lower.same_string ("end") then
						-- Don't add the end
					else
						Result.extend (ln.twin)
					end
				end
			end
		end

	do_exit_class_focus
			-- Exit class focus mode and save class as cell
		local
			l_class_code: STRING
		do
			if attached focused_class_name as fcn then
				if attached focused_class_content as fcc then
					-- Build complete class code
					l_class_code := build_class_code (fcn, fcc)

					-- Add or update as a cell
					update_class_cell (fcn, l_class_code)

					print ("Class " + fcn + " saved. Exiting focus mode.%N")
				end
				focused_class_name := Void
				focused_class_content := Void
			else
				print ("Not in class focus mode.%N")
			end
		end

	do_cancel_class_focus
			-- Exit class focus mode WITHOUT saving
		do
			if attached focused_class_name as fcn then
				print ("Discarded class " + fcn + ". Exiting focus mode.%N")
				focused_class_name := Void
				focused_class_content := Void
			else
				print ("Not in class focus mode.%N")
			end
		end

	build_class_code (a_name: STRING; a_lines: ARRAYED_LIST [STRING]): STRING
			-- Build complete class code from name and content lines
			-- Each entry in a_lines is a multi-line block (one per user input)
			-- Smart auto-insert of "feature":
			-- - If first block starts with "inherit", insert feature AFTER that block
			-- - Otherwise insert feature BEFORE all blocks
		local
			l_has_feature: BOOLEAN
			l_starts_with_inherit: BOOLEAN
			l_first: BOOLEAN
		do
			create Result.make (500)
			Result.append ("class " + a_name + "%N")

			-- Scan for feature keyword and check if first block is inherit
			across a_lines as ln loop
				if ln.as_lower.has_substring ("feature") then
					l_has_feature := True
				end
			end
			if not a_lines.is_empty then
				l_starts_with_inherit := a_lines.first.as_lower.starts_with ("inherit")
			end

			if l_has_feature then
				-- User added feature themselves, just output all blocks
				across a_lines as ln loop
					Result.append (ln)
					Result.append ("%N")
				end
			elseif l_starts_with_inherit then
				-- First block is inherit - output it, then add feature, then rest
				l_first := True
				across a_lines as ln loop
					Result.append (ln)
					Result.append ("%N")
					if l_first then
						-- After inherit block, insert feature
						Result.append ("%Nfeature%N%N")
						l_first := False
					end
				end
				-- If only inherit block (no features yet), still add feature
				if a_lines.count = 1 then
					Result.append ("%Nfeature%N")
				end
			elseif not a_lines.is_empty then
				-- No inherit, no feature - insert feature at start
				Result.append ("%Nfeature%N%N")
				across a_lines as ln loop
					Result.append (ln)
					Result.append ("%N")
				end
			end

			Result.append ("%Nend")
		end

	update_class_cell (a_name: STRING; a_code: STRING)
			-- Update existing class cell or create new one
		local
			l_classifier: CELL_CLASSIFIER
			l_code_lower: STRING
			l_found: BOOLEAN
			l_cell_id: STRING
			i: INTEGER
		do
			create l_classifier.make

			-- Try to find existing class cell
			from i := 1 until i > notebook.cell_count or l_found loop
				if attached notebook.engine.current_notebook.cell_at (i) as c then
					if l_classifier.classify (c.code) = {CELL_CLASSIFIER}.Classification_class then
						l_code_lower := c.code.as_lower
						if l_code_lower.has_substring ("class " + a_name.as_lower) then
							-- Update existing cell using its ID
							l_cell_id := c.id
							notebook.update_cell (l_cell_id, a_code)
							l_found := True
						end
					end
				end
				i := i + 1
			end

			if not l_found then
				-- Add as new cell
				notebook.add_cell (a_code).do_nothing
				cell_number := cell_number + 1
			end
		end

	show_focused_class_content
			-- Display current focused class content
		local
			l_line_num: INTEGER
		do
			if attached focused_class_name as fcn and attached focused_class_content as fcc then
				print ("=== class " + fcn + " ===%N")
				l_line_num := 1
				across fcc as ln loop
					print ("  " + l_line_num.out + ": " + ln + "%N")
					l_line_num := l_line_num + 1
				end
				print ("  end%N")
				print ("=====================%N")
			end
		end

	add_line_to_focused_class (a_line: STRING)
			-- Add a line to the focused class content
		require
			in_focus_mode: focused_class_name /= Void
		do
			if attached focused_class_content as fcc then
				fcc.extend (a_line)
				print ("  Added: " + a_line.substring (1, a_line.count.min (50)))
				if a_line.count > 50 then print ("...") end
				print ("%N")
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

feature {NONE} -- Session Management

	init_storage
			-- Initialize notebook storage
		local
			l_notebooks_dir: PATH
		do
			l_notebooks_dir := notebook.config.workspace_dir.extended (Notebooks_subdir)
			create storage.make (l_notebooks_dir)
		end

	init_history
			-- Initialize command history
		do
			create history.make (notebook.config.workspace_dir)
		end

	auto_save
			-- Auto-save current notebook
		do
			if attached storage as s then
				if s.save (notebook.engine.current_notebook, current_notebook_name) then
					-- Saved successfully, mark clean
					notebook.engine.mark_clean
				end
			end
		end

	do_save (a_name: STRING)
			-- Handle -save [name] command
		do
			if a_name.is_empty then
				-- Save to current notebook
				auto_save
				print ("Saved: " + current_notebook_name + ".enb%N")
			else
				-- Save As: copy to new name
				current_notebook_name := a_name
				auto_save
				print ("Saved as: " + current_notebook_name + ".enb%N")
			end
		end

	do_open (a_name: STRING)
			-- Handle -open command
		do
			if attached storage as s then
				if s.exists (a_name) then
					if attached s.load (a_name) as nb then
						notebook.engine.replace_notebook (nb)
						current_notebook_name := a_name
						cell_number := notebook.cell_count + 1
						print ("Opened: " + a_name + ".enb (" + notebook.cell_count.out + " cells)%N")
					else
						if attached s.last_error as l_err then
						print ("Error loading: " + l_err + "%N")
					else
						print ("Error loading notebook%N")
					end
					end
				else
					-- Create new notebook with this name
					notebook.new_notebook
					current_notebook_name := a_name
					cell_number := 1
					auto_save
					print ("Created new notebook: " + a_name + ".enb%N")
				end
			end
		end

	do_new
			-- Handle -new command
		do
			notebook.new_notebook
			current_notebook_name := Default_notebook_name
			cell_number := 1
			print ("New notebook started. Use -save <name> to name it.%N")
		end

	do_list_notebooks
			-- Handle -notebooks/-list command
		local
			l_files: ARRAYED_LIST [STRING]
		do
			if attached storage as s then
				l_files := s.list_notebooks
				if l_files.is_empty then
					print ("No saved notebooks.%N")
				else
					print ("Notebooks:%N")
					across l_files as f loop
						if f.same_string (current_notebook_name + ".enb") then
							print ("  * " + f + " (current)%N")
						else
							print ("    " + f + "%N")
						end
					end
				end
			end
		end

feature {NONE} -- History

	do_show_history (a_count: INTEGER)
			-- Show last a_count history entries
		require
			positive: a_count > 0
		local
			l_entries: ARRAYED_LIST [HISTORY_ENTRY]
			i: INTEGER
		do
			l_entries := history.recent (a_count)
			if l_entries.is_empty then
				print ("No history.%N")
			else
				print ("History (last " + l_entries.count.out + "):" + "%N")
				from
					i := l_entries.count
				until
					i < 1
				loop
					print ("  " + l_entries.i_th (i).formatted + "%N")
					i := i - 1
				end
			end
		end

	do_history_recall (a_cell_num: INTEGER)
			-- Re-execute code from history by cell number
			-- If a_cell_num = 0, use last entry
		local
			l_entry: detachable HISTORY_ENTRY
			l_code: STRING
		do
			if a_cell_num = 0 then
				l_entry := history.last_entry
			else
				l_entry := history.find_by_cell (a_cell_num)
			end
			if l_entry /= Void then
				l_code := l_entry.input
				print ("Recalling: " + l_entry.first_line + "%N")
				execute_code (l_code)
			else
				if a_cell_num = 0 then
					print ("No history to recall.%N")
				else
					print ("Cell " + a_cell_num.out + " not found in history.%N")
				end
			end
		end

feature {NONE} -- Helpers

	insert_feature_after_class_line (a_code: STRING): STRING
			-- Insert 'feature' keyword after the class line
		local
			l_newline_pos: INTEGER
		do
			l_newline_pos := a_code.index_of ('%N', 1)
			if l_newline_pos > 0 then
				-- Insert after first line
				Result := a_code.substring (1, l_newline_pos) + "feature%N" + a_code.substring (l_newline_pos + 1, a_code.count)
			else
				-- Single line class (unlikely)
				Result := a_code + "%Nfeature"
			end
		end

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

	find_class_cell_number (a_name: STRING): INTEGER
			-- Find cell number containing class with given name
			-- Returns 0 if not found
		local
			l_classifier: CELL_CLASSIFIER
			l_code_lower: STRING
			i: INTEGER
		do
			create l_classifier.make
			from i := 1 until i > notebook.cell_count or Result > 0 loop
				if attached notebook.engine.current_notebook.cell_at (i) as c then
					if l_classifier.classify (c.code) = {CELL_CLASSIFIER}.Classification_class then
						l_code_lower := c.code.as_lower
						if l_code_lower.has_substring ("class " + a_name.as_lower) then
							Result := i
						end
					end
				end
				i := i + 1
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

	log_dbc_call (a_caller, a_supplier, a_preconditions: STRING)
			-- Log caller-side: about to call supplier with preconditions met
			-- Example: "NOTEBOOK_CLI.execute_code → SIMPLE_NOTEBOOK.run | pre: code_not_empty=T"
		do
			log_event ("→CALL", a_caller + " → " + a_supplier + " | pre: " + a_preconditions)
		end

	log_dbc_return (a_supplier, a_postconditions: STRING)
			-- Log supplier-side: returning with postconditions met
			-- Example: "SIMPLE_NOTEBOOK.run ← | post: result_attached=T, cell_added=T"
		do
			log_event ("←RET", a_supplier + " | post: " + a_postconditions)
		end

	b (a_bool: BOOLEAN): STRING
			-- Boolean to compact string: T or F
		do
			if a_bool then Result := "T" else Result := "F" end
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
			print ("  -compile verbose|silent  Show/hide compiler output%N")
			print ("%NNotebook (session persistence):%N")
			print ("  -save [name]   Save current / Save As%N")
			print ("  -open <name>   Open notebook (alias: -restore)%N")
			print ("  -new           Start fresh notebook%N")
			print ("  -notebooks     List saved notebooks (alias: -list)%N")
			print ("%NHistory:%N")
			print ("  -history [N]   Show last N commands (default 20)%N")
			print ("  !N             Re-execute cell N%N")
			print ("  !!             Re-execute last cell%N")
			print ("%NClass Editing:%N")
			print ("  -class NAME    Create or edit class (replaces if exists)%N")
			print ("  -class         Show focused class / list classes%N")
			print ("  -exit          Exit class focus, save class%N")
			print ("  -cancel/-abort Exit class focus, discard changes%N")
			print ("  -show          (in focus mode) Show class content%N")
			print ("  -classes       List user-defined classes%N")
			print ("%NInspection (see generated code):%N")
			print ("  -generated     Show full generated Eiffel class%N")
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
			print ("  class FOO ... end    -> user class%N")
			print ("%NVersion: " + Version + "%N")
			print ("Session log: " + log_path + "%N%N")
		end

end