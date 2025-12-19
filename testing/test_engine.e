note
	description: "Tests for Phase 1.5: NOTEBOOK_ENGINE and SIMPLE_NOTEBOOK facade"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_ENGINE

inherit
	TEST_SET_BASE

feature -- Test: Engine Creation

	test_engine_creation
			-- Test engine can be created with defaults
		local
			engine: NOTEBOOK_ENGINE
		do
			create engine.make

			assert ("engine created", engine /= Void)
			assert ("has config", engine.config /= Void)
			assert ("has notebook", engine.current_notebook /= Void)
			assert ("empty notebook", engine.cell_count = 0)
			assert ("no variables", engine.variable_count = 0)
		end

	test_engine_with_config
			-- Test engine with custom configuration
		local
			engine: NOTEBOOK_ENGINE
			config: NOTEBOOK_CONFIG
		do
			create config.make_with_defaults
			config.set_timeout_seconds (60)

			create engine.make_with_config (config)

			assert_equal ("custom timeout", 60, engine.config.timeout_seconds)
		end

feature -- Test: Session Management

	test_engine_new_session
			-- Test starting new session
		local
			engine: NOTEBOOK_ENGINE
			l_id, l_id2: STRING
		do
			create engine.make

			-- Add some cells
			l_id := engine.add_cell ("x := 1")
			l_id2 := engine.add_cell ("y := 2")

			assert ("has cells", engine.cell_count = 2)

			-- New session should clear
			engine.new_session

			assert ("empty after new", engine.cell_count = 0)
			assert ("no variables", engine.variable_count = 0)
			assert ("no file", engine.current_file_path = Void)
			assert ("not dirty", not engine.is_dirty)
		end

feature -- Test: Cell Management

	test_engine_add_cell
			-- Test adding cells
		local
			engine: NOTEBOOK_ENGINE
			id1, id2: STRING
		do
			create engine.make

			id1 := engine.add_cell ("x := 1")
			assert ("first cell added", engine.cell_count = 1)
			assert ("id not empty", not id1.is_empty)
			assert ("is dirty", engine.is_dirty)

			id2 := engine.add_cell ("y := 2")
			assert ("second cell added", engine.cell_count = 2)
			assert ("different ids", not id1.same_string (id2))
		end

	test_engine_add_markdown
			-- Test adding markdown cells
		local
			engine: NOTEBOOK_ENGINE
			l_id: STRING
		do
			create engine.make
			l_id := engine.add_markdown_cell ("# Heading")

			assert ("cell added", engine.cell_count = 1)
			assert ("id not empty", not l_id.is_empty)
		end

	test_engine_update_cell
			-- Test updating cell code
		local
			engine: NOTEBOOK_ENGINE
			l_id: STRING
		do
			create engine.make
			l_id := engine.add_cell ("x := 1")

			engine.update_cell (l_id, "x := 42")

			assert_equal ("code updated", "x := 42", engine.cell_code (l_id))
		end

	test_engine_remove_cell
			-- Test removing cells
		local
			engine: NOTEBOOK_ENGINE
			l_id, l_id2: STRING
		do
			create engine.make
			l_id := engine.add_cell ("x := 1")
			l_id2 := engine.add_cell ("y := 2")

			assert ("two cells", engine.cell_count = 2)

			engine.remove_cell (l_id)

			assert ("one cell", engine.cell_count = 1)
		end

feature -- Test: Variables

	test_engine_variables
			-- Test variable tracking through engine
		local
			engine: NOTEBOOK_ENGINE
		do
			create engine.make

			-- Variables are tracked during extraction
			assert ("no variables initially", engine.variable_count = 0)
			assert ("empty all_variables", engine.all_variables.is_empty)
			assert ("empty shared_variables", engine.shared_variables.is_empty)
		end

feature -- Test: SIMPLE_NOTEBOOK Facade

	test_simple_notebook_creation
			-- Test facade creation
		local
			nb: SIMPLE_NOTEBOOK
		do
			create nb.make

			assert ("notebook created", nb /= Void)
			assert ("empty", nb.cell_count = 0)
			assert ("has config", nb.config /= Void)
		end

	test_simple_notebook_add_cell
			-- Test adding cells via facade
		local
			nb: SIMPLE_NOTEBOOK
			l_id: STRING
		do
			create nb.make
			l_id := nb.add_cell ("x := 1")

			assert ("cell added", nb.cell_count = 1)
			assert_equal ("code stored", "x := 1", nb.cell_code (l_id))
		end

	test_simple_notebook_new
			-- Test new notebook clears state
		local
			nb: SIMPLE_NOTEBOOK
			l_id1, l_id2: STRING
		do
			create nb.make
			l_id1 := nb.add_cell ("x := 1")
			l_id2 := nb.add_cell ("y := 2")

			nb.new_notebook

			assert ("empty after new", nb.cell_count = 0)
			assert ("no variables", nb.variable_count = 0)
		end

	test_simple_notebook_output
			-- Test combined output
		local
			nb: SIMPLE_NOTEBOOK
			l_id: STRING
		do
			create nb.make

			-- Without execution, output is empty
			l_id := nb.add_cell ("print (%"hello%")")

			assert ("no output yet", nb.output.is_empty)
		end

	test_simple_notebook_run
			-- Test quick run API (just structure, no compilation)
		local
			nb: SIMPLE_NOTEBOOK
			l_id: STRING
		do
			create nb.make
			l_id := nb.add_cell ("x := 1")

			-- Verify cell was added
			assert ("cell exists", nb.cell_count = 1)
			assert_equal ("code correct", "x := 1", nb.cell_code (l_id))
		end

	test_simple_notebook_dirty
			-- Test dirty flag tracking
		local
			nb: SIMPLE_NOTEBOOK
			l_id: STRING
		do
			create nb.make
			assert ("clean initially", not nb.is_dirty)

			l_id := nb.add_cell ("x := 1")
			assert ("dirty after add", nb.is_dirty)

			nb.new_notebook
			assert ("clean after new", not nb.is_dirty)
		end

feature -- Test: Configuration Access

	test_config_access
			-- Test configuration access through facade
		local
			nb: SIMPLE_NOTEBOOK
			config: NOTEBOOK_CONFIG
		do
			create config.make_with_defaults
			config.set_timeout_seconds (90)

			create nb.make_with_config (config)

			assert_equal ("timeout accessible", 90, nb.config.timeout_seconds)
		end

end
