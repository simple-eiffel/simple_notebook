note
	description: "File-based notebook persistence for .enb (Eiffel NotBook) JSON files"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	NOTEBOOK_STORAGE

create
	make

feature {NONE} -- Initialization

	make (a_base_path: PATH)
			-- Create storage with given base path
		require
			path_not_empty: not a_base_path.is_empty
		do
			base_path := a_base_path
			create json
			ensure_directory_exists
		ensure
			path_set: base_path = a_base_path
		end

feature -- Access

	base_path: PATH
			-- Base directory for notebook files

	last_error: detachable STRING
			-- Last error message if operation failed

feature -- Queries

	exists (a_filename: STRING): BOOLEAN
			-- Does notebook file exist?
		require
			filename_not_empty: not a_filename.is_empty
		local
			l_file: SIMPLE_FILE
		do
			create l_file.make (full_path (a_filename))
			Result := l_file.exists
		end

	list_notebooks: ARRAYED_LIST [STRING]
			-- List all .enb files in base path
		local
			l_dir: DIRECTORY
			l_entry: STRING
		do
			create Result.make (10)
			create l_dir.make (base_path.name)
			if l_dir.exists then
				l_dir.open_read
				from l_dir.readentry until l_dir.lastentry = Void loop
					if attached l_dir.lastentry as e then
						l_entry := e.twin
						if l_entry.ends_with (".enb") then
							Result.extend (l_entry)
						end
					end
					l_dir.readentry
				end
				l_dir.close
			end
		end

feature -- Operations

	save (a_notebook: NOTEBOOK; a_filename: STRING): BOOLEAN
			-- Save notebook to file
		require
			notebook_not_void: a_notebook /= Void
			filename_not_empty: not a_filename.is_empty
		local
			l_file: SIMPLE_FILE
			l_json: SIMPLE_JSON_OBJECT
		do
			last_error := Void

			l_json := a_notebook.to_json
			create l_file.make (full_path (a_filename))

			if l_file.set_content (l_json.representation) then
				Result := True
			else
				last_error := "Failed to write file: " + full_path (a_filename)
			end
		ensure
			success_or_error: Result or last_error /= Void
		end

	load (a_filename: STRING): detachable NOTEBOOK
			-- Load notebook from file
		require
			filename_not_empty: not a_filename.is_empty
		local
			l_file: SIMPLE_FILE
			l_content: STRING_32
		do
			last_error := Void
			create l_file.make (full_path (a_filename))

			if l_file.exists then
				l_content := l_file.content
				if not l_content.is_empty then
					if attached json.parse (l_content) as l_value then
						if attached l_value.as_object as jo then
							create Result.make_from_json (jo)
						else
							last_error := "Invalid JSON structure in file"
						end
					else
						last_error := "Failed to parse JSON"
					end
				else
					last_error := "File is empty"
				end
			else
				last_error := "File not found: " + full_path (a_filename)
			end
		ensure
			success_or_error: Result /= Void or last_error /= Void
		end

	delete (a_filename: STRING): BOOLEAN
			-- Delete notebook file
		require
			filename_not_empty: not a_filename.is_empty
		local
			l_file: SIMPLE_FILE
		do
			last_error := Void
			create l_file.make (full_path (a_filename))

			if l_file.exists then
				if l_file.delete then
					Result := True
				else
					last_error := "Failed to delete file: " + full_path (a_filename)
				end
			else
				last_error := "File not found: " + full_path (a_filename)
			end
		ensure
			success_or_error: Result or last_error /= Void
		end

	rename_file (a_old_name, a_new_name: STRING): BOOLEAN
			-- Rename notebook file
		require
			old_name_not_empty: not a_old_name.is_empty
			new_name_not_empty: not a_new_name.is_empty
		local
			l_old_file, l_new_file: SIMPLE_FILE; l_ignore: BOOLEAN
			l_content: STRING_32
		do
			last_error := Void
			create l_old_file.make (full_path (a_old_name))
			create l_new_file.make (full_path (a_new_name))

			if l_old_file.exists then
				if l_new_file.exists then
					last_error := "Target file already exists: " + full_path (a_new_name)
				else
					-- Read, write new, delete old (portable approach)
					l_content := l_old_file.content
					if l_new_file.set_content (l_content) then
						if l_old_file.delete then
							Result := True
						else
							-- Rollback: delete new file
							l_ignore := l_new_file.delete
							last_error := "Failed to delete old file"
						end
					else
						last_error := "Failed to write new file"
					end
				end
			else
				last_error := "Source file not found: " + full_path (a_old_name)
			end
		ensure
			success_or_error: Result or last_error /= Void
		end

feature -- Notebook for Cell

	notebook_for_cell (a_cell_id: STRING): detachable NOTEBOOK
			-- Find notebook containing given cell
		require
			cell_id_not_empty: not a_cell_id.is_empty
		local
			l_files: ARRAYED_LIST [STRING]
			l_notebook: detachable NOTEBOOK
		do
			l_files := list_notebooks
			across l_files as f loop
				if Result = Void then
					l_notebook := load (f)
					if attached l_notebook as nb then
						if attached nb.cell_by_id (a_cell_id) then
							Result := nb
						end
					end
				end
			end
		end

feature {NONE} -- Implementation

	json: SIMPLE_JSON
			-- JSON parser

	full_path (a_filename: STRING): STRING
			-- Full path for filename
		do
			Result := base_path.name.to_string_8 + "/" + ensure_extension (a_filename)
		end

	ensure_extension (a_filename: STRING): STRING
			-- Ensure filename has .enb extension
		do
			if a_filename.ends_with (".enb") then
				Result := a_filename
			else
				Result := a_filename + ".enb"
			end
		end

	ensure_directory_exists
			-- Create base directory if it doesn't exist
		local
			l_dir: SIMPLE_FILE; l_ok: BOOLEAN
		do
			create l_dir.make (base_path.name)
			if not l_dir.is_directory then
				l_ok := l_dir.create_directory_recursive
			end
		end

invariant
	base_path_not_empty: not base_path.is_empty

end