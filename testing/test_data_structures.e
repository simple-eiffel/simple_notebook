note
	description: "Tests for Phase 1.1: Data Structures (NOTEBOOK_CELL, NOTEBOOK, NOTEBOOK_STORAGE)"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_DATA_STRUCTURES

inherit
	TEST_SET_BASE
		redefine
			on_prepare
		end

feature {NONE} -- Setup

	on_prepare
			-- Setup test environment
		do
			create test_workspace.make_from_string ("./test_workspace/notebooks")
			ensure_test_directory
		end

	test_workspace: PATH
			-- Temporary test directory

	ensure_test_directory
			-- Create test directory if needed
		local
			l_file: SIMPLE_FILE
			l_ok: BOOLEAN
		do
			create l_file.make (test_workspace.name)
			if not l_file.is_directory then
				l_ok := l_file.create_directory_recursive
			end
		end

feature -- Test: NOTEBOOK_CELL Creation

	test_cell_creation
			-- Test basic cell creation
		local
			cell: NOTEBOOK_CELL
		do
			create cell.make_code ("cell_001")
			assert_equal ("id set", "cell_001", cell.id)
			assert_equal ("type is code", "code", cell.cell_type)
			assert ("is code cell", cell.is_code_cell)
			assert ("not markdown", not cell.is_markdown_cell)
			assert ("is idle", cell.is_idle)
			assert_equal ("empty code", "", cell.code)
		end

	test_markdown_cell_creation
			-- Test markdown cell creation
		local
			cell: NOTEBOOK_CELL
		do
			create cell.make_markdown ("md_001")
			assert ("is markdown", cell.is_markdown_cell)
			assert ("not code", not cell.is_code_cell)
		end

	test_cell_set_code
			-- Test setting cell code
		local
			cell: NOTEBOOK_CELL
		do
			create cell.make_code ("cell_001")
			cell.set_code ("x := 42")
			assert_equal ("code set", "x := 42", cell.code)
		end

	test_cell_output
			-- Test cell output handling
		local
			cell: NOTEBOOK_CELL
		do
			create cell.make_code ("cell_001")
			assert ("no output initially", not cell.has_output)

			cell.set_output ("Hello World")
			assert ("has output now", cell.has_output)
			assert_equal ("output correct", "Hello World", cell.output)
		end

	test_cell_error
			-- Test cell error handling
		local
			cell: NOTEBOOK_CELL
		do
			create cell.make_code ("cell_001")
			assert ("no error initially", not cell.has_error)

			cell.set_error ("Syntax error")
			assert ("has error now", cell.has_error)
			assert_equal ("error correct", "Syntax error", cell.error)
		end

	test_cell_status_transitions
			-- Test cell status changes
		local
			cell: NOTEBOOK_CELL
		do
			create cell.make_code ("cell_001")
			assert ("starts idle", cell.is_idle)

			cell.set_status_running
			assert ("now running", cell.is_running)

			cell.set_status_success
			assert ("now success", cell.is_success)

			cell.set_status_error
			assert ("now error", cell.is_error)

			cell.set_status_idle
			assert ("back to idle", cell.is_idle)
		end

	test_cell_clear_output
			-- Test clearing cell output
		local
			cell: NOTEBOOK_CELL
		do
			create cell.make_code ("cell_001")
			cell.set_output ("some output")
			cell.set_error ("some error")
			cell.set_execution_time_ms (100)
			cell.set_status_success

			cell.clear_output

			assert ("output cleared", cell.output.is_empty)
			assert ("error cleared", cell.error.is_empty)
			assert_equal ("time cleared", 0, cell.execution_time_ms)
			assert ("status idle", cell.is_idle)
		end

feature -- Test: NOTEBOOK_CELL JSON

	test_cell_json_roundtrip
			-- Test cell JSON serialization
		local
			cell, loaded: NOTEBOOK_CELL
			json: SIMPLE_JSON_OBJECT
		do
			create cell.make_code ("cell_001")
			cell.set_code ("x := 42")
			cell.set_output ("42")
			cell.set_status_success
			cell.set_order (1)
			cell.set_execution_time_ms (150)

			json := cell.to_json

			create loaded.make_from_json (json)

			assert_equal ("id preserved", "cell_001", loaded.id)
			assert_equal ("code preserved", "x := 42", loaded.code)
			assert_equal ("output preserved", "42", loaded.output)
			assert ("status preserved", loaded.is_success)
			assert_equal ("order preserved", 1, loaded.order)
			assert_equal ("time preserved", 150, loaded.execution_time_ms)
		end

feature -- Test: NOTEBOOK Creation

	test_notebook_creation
			-- Test basic notebook creation
		local
			nb: NOTEBOOK
		do
			create nb.make ("My Notebook")
			assert_equal ("name set", "My Notebook", nb.name)
			assert ("id not empty", not nb.id.is_empty)
			assert ("starts empty", nb.is_empty)
			assert_equal ("cell count zero", 0, nb.cell_count)
		end

	test_notebook_add_cell
			-- Test adding cells to notebook
		local
			nb: NOTEBOOK
			cell: NOTEBOOK_CELL
		do
			create nb.make ("Test")
			create cell.make_code ("cell_001")
			nb.add_cell (cell)

			assert ("not empty", not nb.is_empty)
			assert_equal ("cell count", 1, nb.cell_count)
			assert ("cell added", nb.cells.has (cell))
			assert_equal ("cell order set", 1, cell.order)
		end

	test_notebook_add_code_cell
			-- Test convenience method for adding code cells
		local
			nb: NOTEBOOK
			cell: NOTEBOOK_CELL
		do
			create nb.make ("Test")
			cell := nb.add_code_cell ("x := 42")

			assert_equal ("cell count", 1, nb.cell_count)
			assert ("is code", cell.is_code_cell)
			assert_equal ("code set", "x := 42", cell.code)
			assert_equal ("order set", 1, cell.order)
		end

	test_notebook_add_markdown_cell
			-- Test adding markdown cells
		local
			nb: NOTEBOOK
			cell: NOTEBOOK_CELL
		do
			create nb.make ("Test")
			cell := nb.add_markdown_cell ("# Header")

			assert ("is markdown", cell.is_markdown_cell)
			assert_equal ("content set", "# Header", cell.code)
		end

	test_notebook_cell_by_id
			-- Test finding cell by ID
		local
			nb: NOTEBOOK
			cell: NOTEBOOK_CELL
		do
			create nb.make ("Test")
			cell := nb.add_code_cell ("x := 42")

			if attached nb.cell_by_id (cell.id) as found then
				assert ("found correct cell", found = cell)
			else
				assert ("cell found", False)
			end

			assert ("not found for invalid id", nb.cell_by_id ("invalid") = Void)
		end

	test_notebook_remove_cell
			-- Test removing cells
		local
			nb: NOTEBOOK
			cell1, cell2: NOTEBOOK_CELL
		do
			create nb.make ("Test")
			cell1 := nb.add_code_cell ("first")
			cell2 := nb.add_code_cell ("second")

			assert_equal ("two cells", 2, nb.cell_count)

			nb.remove_cell (cell1.id)

			assert_equal ("one cell left", 1, nb.cell_count)
			assert ("cell1 removed", nb.cell_by_id (cell1.id) = Void)
			assert ("cell2 still there", nb.cell_by_id (cell2.id) /= Void)
			assert_equal ("cell2 reordered", 1, cell2.order)
		end

	test_notebook_code_cells
			-- Test filtering code cells
		local
			nb: NOTEBOOK
			code_cells: ARRAYED_LIST [NOTEBOOK_CELL]
			l_cell: NOTEBOOK_CELL
			l_save_result: BOOLEAN
		do
			create nb.make ("Test")
			l_cell := nb.add_code_cell ("code 1")
			l_cell := nb.add_markdown_cell ("markdown 1")
			l_cell := nb.add_code_cell ("code 2")

			assert_equal ("total cells", 3, nb.cell_count)

			code_cells := nb.code_cells
			assert_equal ("code cells only", 2, code_cells.count)
		end

	test_notebook_update_cell_code
			-- Test updating cell code
		local
			nb: NOTEBOOK
			cell: NOTEBOOK_CELL
		do
			create nb.make ("Test")
			cell := nb.add_code_cell ("old code")
			cell.set_output ("old output")
			cell.set_status_success

			nb.update_cell_code (cell.id, "new code")

			assert_equal ("code updated", "new code", cell.code)
			assert ("output cleared", cell.output.is_empty)
			assert ("status reset", cell.is_idle)
		end

feature -- Test: NOTEBOOK JSON

	test_notebook_json_roundtrip
			-- Test notebook JSON serialization
		local
			nb, loaded: NOTEBOOK
			json: SIMPLE_JSON_OBJECT
			l_cell: NOTEBOOK_CELL
			l_save_result: BOOLEAN
		do
			create nb.make ("My Analysis")
			l_cell := nb.add_code_cell ("x := 42")
			l_cell := nb.add_code_cell ("print(x)")
			l_cell := nb.add_markdown_cell ("# Results")

			json := nb.to_json

			create loaded.make_from_json (json)

			assert_equal ("name preserved", "My Analysis", loaded.name)
			assert_equal ("cell count", 3, loaded.cell_count)
			assert_equal ("cell 1 code", "x := 42", loaded.cell_at (1).code)
			assert ("cell 3 is markdown", loaded.cell_at (3).is_markdown_cell)
		end

feature -- Test: NOTEBOOK_STORAGE

	test_storage_creation
			-- Test storage creation
		local
			storage: NOTEBOOK_STORAGE
		do
			create storage.make (test_workspace)
			-- Just verify no crash
			assert ("storage created", True)
		end

	test_storage_save_load
			-- Test saving and loading notebooks
		local
			storage: NOTEBOOK_STORAGE
			nb, loaded: NOTEBOOK
			l_cell: NOTEBOOK_CELL
			l_save_result: BOOLEAN
		do
			create storage.make (test_workspace)

			create nb.make ("Test Notebook")
			l_cell := nb.add_code_cell ("x := 42")
			l_cell := nb.add_code_cell ("y := x * 2")

			l_save_result := storage.save (nb, "test_save.enb")
			assert ("save succeeds", l_save_result)
			assert ("file exists", storage.exists ("test_save.enb"))

			loaded := storage.load ("test_save.enb")
			assert ("load succeeds", loaded /= Void)

			if attached loaded as l then
				assert_equal ("name preserved", "Test Notebook", l.name)
				assert_equal ("cell count", 2, l.cell_count)
				assert_equal ("code preserved", "x := 42", l.cell_at (1).code)
			end
		end

	test_storage_delete
			-- Test deleting notebook files
		local
			storage: NOTEBOOK_STORAGE
			nb: NOTEBOOK
			l_ok: BOOLEAN
		do
			create storage.make (test_workspace)

			create nb.make ("To Delete")
			l_ok := storage.save (nb, "to_delete.enb")

			assert ("file exists", storage.exists ("to_delete.enb"))
			assert ("delete succeeds", storage.delete ("to_delete.enb"))
			assert ("file gone", not storage.exists ("to_delete.enb"))
		end

	test_storage_list_notebooks
			-- Test listing notebook files
		local
			storage: NOTEBOOK_STORAGE
			nb: NOTEBOOK
			files: ARRAYED_LIST [STRING]
			l_ok: BOOLEAN
		do
			create storage.make (test_workspace)

			-- Create a few notebooks
			create nb.make ("Notebook A")
			l_ok := storage.save (nb, "notebook_a.enb")

			create nb.make ("Notebook B")
			l_ok := storage.save (nb, "notebook_b.enb")

			files := storage.list_notebooks

			assert ("at least 2 files", files.count >= 2)
		end

	test_storage_error_handling
			-- Test error handling for non-existent files
		local
			storage: NOTEBOOK_STORAGE
		do
			create storage.make (test_workspace)

			assert ("load fails for missing", storage.load ("nonexistent.enb") = Void)
			assert ("has error message", storage.last_error /= Void)
		end

end
