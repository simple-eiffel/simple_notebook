note
	description: "Interactive first-run setup wizard for CLI"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	CONFIG_WIZARD

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize wizard
		do
			create detector.make
		end

feature -- Wizard Flow

	run: NOTEBOOK_CONFIG
			-- Interactive setup returning completed config
		do
			print_welcome
			Result := run_detection
			if not Result.is_valid then
				Result := prompt_for_missing (Result)
			end
			show_summary (Result)
			confirm_and_save (Result)
		end

	run_silent: NOTEBOOK_CONFIG
			-- Non-interactive detection only
		do
			Result := detector.detect_all
		end

feature {NONE} -- Steps

	print_welcome
			-- Display welcome message
		do
			io.put_string ("%N")
			io.put_string ("+===========================================================+%N")
			io.put_string ("|           Eiffel Notebook - First Run Setup               |%N")
			io.put_string ("+===========================================================+%N")
			io.put_string ("%N")
		end

	run_detection: NOTEBOOK_CONFIG
			-- Auto-detect and display results
		do
			io.put_string ("Detecting EiffelStudio installation...%N")
			io.put_string ("%N")

			Result := detector.detect_all

			if attached Result.eiffel_compiler as ec and then not ec.is_empty then
				io.put_string ("  [OK] Compiler: ")
				io.put_string (ec.name.to_string_8)
				io.put_string ("%N")
			else
				io.put_string ("  [!!] Compiler not found%N")
			end

			if attached Result.ise_library as lib and then not lib.is_empty then
				io.put_string ("  [OK] ISE_LIBRARY: ")
				io.put_string (lib.name.to_string_8)
				io.put_string ("%N")
			else
				io.put_string ("  [!!] ISE_LIBRARY not found%N")
			end

			if attached Result.simple_eiffel as se and then not se.is_empty then
				io.put_string ("  [OK] Simple Eiffel: ")
				io.put_string (se.name.to_string_8)
				io.put_string ("%N")
			else
				io.put_string ("  [--] Simple Eiffel not found (optional)%N")
			end

			io.put_string ("%N")
		end

	prompt_for_missing (a_config: NOTEBOOK_CONFIG): NOTEBOOK_CONFIG
			-- Prompt user for missing required paths
		do
			Result := a_config

			-- Prompt for compiler if missing
			if Result.eiffel_compiler.is_empty then
				io.put_string ("Enter path to EiffelStudio ec.exe:%N")
				io.put_string ("  > ")
				io.read_line
				if attached io.last_string as s and then not s.is_empty then
					Result.set_eiffel_compiler (create {PATH}.make_from_string (s.twin))
				end
			end

			-- Prompt for ISE_LIBRARY if missing
			if Result.ise_library.is_empty then
				io.put_string ("%NEnter path to ISE_LIBRARY:%N")
				io.put_string ("  > ")
				io.read_line
				if attached io.last_string as s and then not s.is_empty then
					Result.set_ise_library (create {PATH}.make_from_string (s.twin))
				end
			end

			-- Optionally prompt for Simple Eiffel
			if Result.simple_eiffel.is_empty then
				io.put_string ("%NEnter path to Simple Eiffel (press Enter to skip):%N")
				io.put_string ("  > ")
				io.read_line
				if attached io.last_string as s and then not s.is_empty then
					Result.set_simple_eiffel (create {PATH}.make_from_string (s.twin))
				end
			end

			io.put_string ("%N")
		end

	show_summary (a_config: NOTEBOOK_CONFIG)
			-- Display configuration summary
		do
			io.put_string ("+-----------------------------------------------------------+%N")
			io.put_string ("|                 Configuration Summary                      |%N")
			io.put_string ("+-----------------------------------------------------------+%N")
			io.put_string ("%N")

			io.put_string ("  Compiler:      ")
			io.put_string (a_config.eiffel_compiler.name.to_string_8)
			io.put_string ("%N")
			io.put_string ("  ISE_LIBRARY:   ")
			io.put_string (a_config.ise_library.name.to_string_8)
			io.put_string ("%N")
			if not a_config.simple_eiffel.is_empty then
				io.put_string ("  Simple Eiffel: ")
				io.put_string (a_config.simple_eiffel.name.to_string_8)
				io.put_string ("%N")
			end
			io.put_string ("  Workspace:     ")
			io.put_string (a_config.workspace_dir.name.to_string_8)
			io.put_string ("%N")
			io.put_string ("  Timeout:       ")
			io.put_string (a_config.timeout_seconds.out)
			io.put_string ("s%N")
			io.put_string ("  Web port:      ")
			io.put_string (a_config.web_port.out)
			io.put_string ("%N")

			io.put_string ("%N")

			-- Validate and show any errors
			a_config.validate
			if not a_config.validation_errors.is_empty then
				io.put_string ("  Warnings:%N")
				across a_config.validation_errors as err loop
					io.put_string ("    - ")
					io.put_string (err)
					io.put_string ("%N")
				end
				io.put_string ("%N")
			end
		end

	confirm_and_save (a_config: NOTEBOOK_CONFIG)
			-- Ask user to confirm and save configuration
		local
			l_path: PATH
			l_file: SIMPLE_FILE
			l_ok: BOOLEAN
		do
			create l_path.make_from_string (default_config_path)

			io.put_string ("Save configuration to ")
			io.put_string (l_path.name.to_string_8)
			io.put_string ("? [Y/n] ")
			io.read_line

			if attached io.last_string as s then
				if s.is_empty or else s.item (1).as_lower = 'y' then
					-- Create directory if needed
					create l_file.make (l_path.parent.name)
					if not l_file.is_directory then
						l_ok := l_file.create_directory
					end

					-- Save config
					a_config.save (l_path)
					io.put_string ("%N  [OK] Configuration saved.%N")
				else
					io.put_string ("%N  [--] Configuration not saved.%N")
				end
			end

			io.put_string ("%N")
		end

feature {NONE} -- Implementation

	detector: CONFIG_DETECTOR
			-- Path detector

	default_config_path: STRING
			-- Default configuration file path
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

end
