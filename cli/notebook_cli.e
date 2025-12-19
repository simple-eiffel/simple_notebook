note
	description: "Interactive CLI for Eiffel notebook - REPL-style execution"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	NOTEBOOK_CLI

create
	make

feature {NONE} -- Initialization

	make
			-- Launch interactive notebook session
		local
			l_ec_path: PATH
		do
			create notebook.make
			-- Hardcode compiler path for testing (TODO: fix CONFIG_DETECTOR)
			create l_ec_path.make_from_string ("C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\bin\ec.exe")
			notebook.config.set_eiffel_compiler (l_ec_path)
			running := True
			print_welcome
			repl_loop
		end

feature -- Access

	notebook: SIMPLE_NOTEBOOK
			-- The notebook engine

	running: BOOLEAN
			-- Is the REPL running?

	cell_number: INTEGER
			-- Current cell number for display

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
			-- Read a line of input from the user
		local
			l_line: STRING
			l_multiline: BOOLEAN
		do
			create Result.make_empty
			l_multiline := False

			-- Read first line
			io.read_line
			if attached io.last_string as s then
				l_line := s.twin
			else
				create l_line.make_empty
			end

			-- Check for multiline start
			if l_line.ends_with ("\") then
				l_multiline := True
				l_line.remove_tail (1)
				Result.append (l_line)
			elseif l_line.ends_with ("{") or l_line.ends_with ("do") or l_line.ends_with ("then") then
				l_multiline := True
				Result.append (l_line)
				Result.append_character ('%N')
			else
				Result := l_line
			end

			-- Continue reading if multiline
			if l_multiline then
				from
				until
					not l_multiline
				loop
					io.put_string ("   ... ")
					io.read_line
					if attached io.last_string as s then
						l_line := s.twin
						if l_line.is_empty or l_line.same_string (":done") then
							l_multiline := False
						else
							if l_line.ends_with ("\") then
								l_line.remove_tail (1)
							end
							Result.append (l_line)
							Result.append_character ('%N')
						end
					else
						l_multiline := False
					end
				end
			end

			Result.left_adjust
			Result.right_adjust
		end

	process_input (a_input: STRING)
			-- Process user input (command or code)
		require
			input_not_empty: not a_input.is_empty
		do
			if a_input.starts_with (":") then
				process_command (a_input)
			else
				execute_code (a_input)
			end
		end

	process_command (a_cmd: STRING)
			-- Process a :command
		local
			l_cmd: STRING
		do
			l_cmd := a_cmd.as_lower
			if l_cmd.same_string (":quit") or l_cmd.same_string (":q") or l_cmd.same_string (":exit") then
				running := False
			elseif l_cmd.same_string (":help") or l_cmd.same_string (":h") or l_cmd.same_string (":?") then
				print_help
			elseif l_cmd.same_string (":clear") or l_cmd.same_string (":c") then
				clear_notebook
			elseif l_cmd.same_string (":vars") or l_cmd.same_string (":v") then
				show_variables
			elseif l_cmd.same_string (":cells") then
				show_cells
			elseif l_cmd.same_string (":run") or l_cmd.same_string (":r") then
				run_all_cells
			else
				print ("Unknown command: " + a_cmd + "%N")
				print ("Type :help for available commands%N")
			end
		end

	execute_code (a_code: STRING)
			-- Add code as cell and execute
		local
			l_result: STRING
		do
			l_result := notebook.run (a_code)
			if not l_result.is_empty then
				print (l_result)
				if not l_result.ends_with ("%N") then
					print ("%N")
				end
			end
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
			-- Display all cells
		local
			i: INTEGER
			l_code: STRING
		do
			if notebook.cell_count = 0 then
				print ("No cells.%N")
			else
				print ("Cells:%N")
				from i := 1 until i > notebook.cell_count loop
					if attached notebook.engine.current_notebook.cell_at (i) as c then
						l_code := c.code
						print ("  [" + i.out + "] ")
						if l_code.count > 40 then
							print (l_code.substring (1, 40) + "...")
						else
							print (l_code)
						end
						print ("%N")
					end
					i := i + 1
				end
			end
		end

	run_all_cells
			-- Execute all cells in order
		do
			notebook.execute_all
			if not notebook.output.is_empty then
				print (notebook.output)
			end
		end

feature {NONE} -- Output

	print_welcome
			-- Print welcome banner
		do
			print ("%N")
			print ("Eiffel Notebook v1.0%N")
			print ("Type Eiffel code to execute. Type :help for commands.%N")
			print ("%N")
		end

	print_help
			-- Print help message
		do
			print ("%N")
			print ("Commands:%N")
			print ("  :help, :h, :?   Show this help%N")
			print ("  :quit, :q       Exit the notebook%N")
			print ("  :clear, :c      Clear all cells and start fresh%N")
			print ("  :vars, :v       Show all tracked variables%N")
			print ("  :cells          Show all cells%N")
			print ("  :run, :r        Re-run all cells%N")
			print ("%N")
			print ("Code entry:%N")
			print ("  - Type Eiffel code and press Enter to execute%N")
			print ("  - End line with \\ for multiline input%N")
			print ("  - Lines ending with 'do', 'then', or '{' auto-continue%N")
			print ("  - Type :done on empty line to finish multiline%N")
			print ("%N")
			print ("Variables:%N")
			print ("  - Use 'shared x: INTEGER' to declare cross-cell variables%N")
			print ("  - Regular declarations are cell-local%N")
			print ("%N")
		end

end
