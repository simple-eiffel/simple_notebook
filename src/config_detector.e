note
	description: "Auto-detect EiffelStudio and Simple Eiffel installation paths"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	CONFIG_DETECTOR

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize detector
		do
			create env
		end

feature -- Detection

	detect_eiffel_compiler: detachable PATH
			-- Find ec.exe via:
			-- 1. ISE_EIFFEL environment variable
			-- 2. Common installation paths
			-- 3. PATH search
		local
			l_path: STRING
		do
			-- Try ISE_EIFFEL first
			if attached env.item ("ISE_EIFFEL") as ise then
				l_path := ise.to_string_8 + compiler_relative_path
				if file_exists (l_path) then
					create Result.make_from_string (l_path)
				end
			end

			-- Try common paths
			if Result = Void then
				across search_paths as p loop
					if Result = Void then
						across eiffel_versions as v loop
							if Result = Void then
								l_path := p + "/" + v + compiler_relative_path
								if file_exists (l_path) then
									create Result.make_from_string (l_path)
								end
							end
						end
					end
				end
			end
		end

	detect_ise_library: detachable PATH
			-- Find ISE_LIBRARY via:
			-- 1. ISE_LIBRARY environment variable
			-- 2. Relative to detected compiler
		local
			l_path: STRING
		do
			-- Try ISE_LIBRARY env var
			if attached env.item ("ISE_LIBRARY") as lib then
				if directory_exists (lib.to_string_8) then
					create Result.make_from_string (lib.to_string_8)
				end
			end

			-- Try ISE_EIFFEL/library
			if Result = Void then
				if attached env.item ("ISE_EIFFEL") as ise then
					l_path := ise.to_string_8 + "/library"
					if directory_exists (l_path) then
						create Result.make_from_string (l_path)
					end
				end
			end

			-- Try relative to compiler
			if Result = Void then
				if attached detect_eiffel_compiler as ec then
					-- ec.exe is in studio/spec/win64/bin, library is in ../../../library
					l_path := ec.parent.parent.parent.parent.name.to_string_8 + "/library"
					if directory_exists (l_path) then
						create Result.make_from_string (l_path)
					end
				end
			end
		end

	detect_simple_eiffel: detachable PATH
			-- Find SIMPLE_EIFFEL via:
			-- 1. SIMPLE_EIFFEL environment variable
			-- 2. Common paths (D:/prod, ~/simple-eiffel)
		local
			l_path: STRING
		do
			-- Try SIMPLE_EIFFEL env var
			if attached env.item ("SIMPLE_EIFFEL") as se then
				if directory_exists (se.to_string_8) then
					create Result.make_from_string (se.to_string_8)
				end
			end

			-- Try common locations
			if Result = Void then
				across simple_eiffel_paths as p loop
					if Result = Void then
						l_path := expand_path (p)
						if directory_exists (l_path) then
							-- Verify it's really Simple Eiffel (has simple_json)
							if directory_exists (l_path + "/simple_json") then
								create Result.make_from_string (l_path)
							end
						end
					end
				end
			end
		end

	detect_all: NOTEBOOK_CONFIG
			-- Create config with all auto-detected values
		local
			ec, ise, simple: detachable PATH
		do
			ec := detect_eiffel_compiler
			ise := detect_ise_library
			simple := detect_simple_eiffel

			create Result.make_with_defaults
			if attached ec as e then
				Result.set_eiffel_compiler (e)
			end
			if attached ise as i then
				Result.set_ise_library (i)
			end
			if attached simple as s then
				Result.set_simple_eiffel (s)
			end
		end

feature -- Status

	compiler_found: BOOLEAN
			-- Was compiler detected?
		do
			Result := detect_eiffel_compiler /= Void
		end

	ise_library_found: BOOLEAN
			-- Was ISE_LIBRARY detected?
		do
			Result := detect_ise_library /= Void
		end

	simple_eiffel_found: BOOLEAN
			-- Was SIMPLE_EIFFEL detected?
		do
			Result := detect_simple_eiffel /= Void
		end

feature {NONE} -- Platform-specific paths

	search_paths: ARRAYED_LIST [STRING]
			-- Common EiffelStudio installation paths
		do
			create Result.make (5)
			if is_windows then
				Result.extend ("C:/Program Files/Eiffel Software")
				Result.extend ("C:/Program Files (x86)/Eiffel Software")
				Result.extend ("C:/EiffelStudio")
				Result.extend (home_path + "/EiffelStudio")
			else
				Result.extend ("/opt/eiffelstudio")
				Result.extend ("/usr/local/eiffelstudio")
				Result.extend (home_path + "/eiffelstudio")
				Result.extend (home_path + "/EiffelStudio")
			end
		end

	eiffel_versions: ARRAYED_LIST [STRING]
			-- Known EiffelStudio version folder names
		do
			create Result.make (5)
			Result.extend ("EiffelStudio 25.02 Standard")
			Result.extend ("EiffelStudio 24.11 Standard")
			Result.extend ("EiffelStudio 24.05 Standard")
			Result.extend ("EiffelStudio 23.09 Standard")
			Result.extend ("EiffelStudio 23.02 Standard")
		end

	simple_eiffel_paths: ARRAYED_LIST [STRING]
			-- Common Simple Eiffel locations
		do
			create Result.make (4)
			Result.extend ("D:/prod")
			Result.extend ("~/simple-eiffel")
			Result.extend ("~/simple_eiffel")
			Result.extend ("~/dev/simple-eiffel")
		end

	compiler_relative_path: STRING
			-- Relative path from ISE_EIFFEL to ec executable
		do
			if is_windows then
				Result := "/studio/spec/win64/bin/ec.exe"
			else
				Result := "/studio/spec/linux-x86-64/bin/ec"
			end
		end

feature {NONE} -- File helpers

	file_exists (a_path: STRING): BOOLEAN
			-- Does file exist at path?
		local
			l_file: SIMPLE_FILE
		do
			create l_file.make (a_path)
			Result := l_file.exists
		end

	directory_exists (a_path: STRING): BOOLEAN
			-- Does directory exist at path?
		local
			l_file: SIMPLE_FILE
		do
			create l_file.make (a_path)
			Result := l_file.is_directory
		end

feature {NONE} -- Implementation

	env: EXECUTION_ENVIRONMENT
			-- Environment access

	is_windows: BOOLEAN
			-- Running on Windows?
		do
			Result := (create {PLATFORM}).is_windows
		end

	home_path: STRING
			-- User home directory
		do
			if attached env.home_directory_path as h then
				Result := h.name.to_string_8
			else
				Result := "."
			end
		end

	expand_path (a_path: STRING): STRING
			-- Expand ~ to home directory
		do
			if a_path.starts_with ("~/") then
				Result := home_path + a_path.substring (2, a_path.count)
			else
				Result := a_path
			end
		end

end
