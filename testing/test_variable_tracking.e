note
	description: "Tests for Phase 1.4: Variable Tracking (VARIABLE_INFO, VARIABLE_TRACKER, VARIABLE_CHANGE)"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_VARIABLE_TRACKING

inherit
	TEST_SET_BASE

feature -- Test: VARIABLE_INFO

	test_variable_info_creation
			-- Test creating variable info
		local
			info: VARIABLE_INFO
		do
			create info.make ("x", "INTEGER", "cell_001")

			assert_equal ("name", "x", info.name)
			assert_equal ("type", "INTEGER", info.type_name)
			assert_equal ("cell", "cell_001", info.cell_id)
			assert ("no value", not info.has_value)
			assert ("not shared", not info.is_shared)
		end

	test_variable_info_with_value
			-- Test creating variable info with value
		local
			info: VARIABLE_INFO
		do
			create info.make_with_value ("x", "INTEGER", "42", "cell_001")

			assert ("has value", info.has_value)
			assert_equal ("value", "42", info.value)
		end

	test_variable_info_shared
			-- Test shared variable flag
		local
			info: VARIABLE_INFO
		do
			create info.make ("x", "INTEGER", "cell_001")
			info.set_shared (True)

			assert ("is shared", info.is_shared)
		end

	test_variable_info_formatted
			-- Test formatted output
		local
			info: VARIABLE_INFO
		do
			create info.make_with_value ("count", "INTEGER", "42", "cell_001")

			assert_equal ("formatted", "count: INTEGER = 42", info.formatted)
		end

	test_variable_info_string_value
			-- Test string value formatting
		local
			info: VARIABLE_INFO
		do
			create info.make_with_value ("msg", "STRING", "hello", "cell_001")

			assert ("value quoted", info.formatted_value.has_substring ("%"hello%""))
		end

	test_variable_info_comparison
			-- Test variable comparison
		local
			v1, v2: VARIABLE_INFO
		do
			create v1.make_with_value ("x", "INTEGER", "42", "cell_001")
			create v2.make_with_value ("x", "INTEGER", "84", "cell_002")

			assert ("same variable", v1.same_variable (v2))
			assert ("value changed", v1.value_changed (v2))
		end

feature -- Test: VARIABLE_CHANGE

	test_change_new
			-- Test new variable change
		local
			change: VARIABLE_CHANGE
		do
			create change.make_new ("x", "INTEGER", "42")

			assert ("is new", change.is_new)
			assert ("not modified", not change.is_modified)
			assert ("not removed", not change.is_removed)
			assert_equal ("marker", "+", change.marker)
		end

	test_change_modified
			-- Test modified variable change
		local
			change: VARIABLE_CHANGE
		do
			create change.make_modified ("x", "42", "84")

			assert ("is modified", change.is_modified)
			assert_equal ("marker", "~", change.marker)
			assert_equal ("old value", "42", change.old_value)
			assert_equal ("new value", "84", change.new_value)
		end

	test_change_removed
			-- Test removed variable change
		local
			change: VARIABLE_CHANGE
		do
			create change.make_removed ("x")

			assert ("is removed", change.is_removed)
			assert_equal ("marker", "-", change.marker)
		end

	test_change_formatted
			-- Test formatted change output
		local
			change: VARIABLE_CHANGE
			formatted: STRING
		do
			create change.make_new ("count", "INTEGER", "42")
			formatted := change.formatted

			assert ("has marker", formatted.starts_with ("+"))
			assert ("has name", formatted.has_substring ("count"))
			assert ("has type", formatted.has_substring ("INTEGER"))
			assert ("has value", formatted.has_substring ("42"))
		end

feature -- Test: VARIABLE_TRACKER - Extraction

	test_tracker_creation
			-- Test tracker creation
		local
			tracker: VARIABLE_TRACKER
		do
			create tracker.make
			assert_equal ("empty", 0, tracker.count)
		end

	test_tracker_extract_shared
			-- Test extracting shared variable declarations
		local
			tracker: VARIABLE_TRACKER
			vars: ARRAYED_LIST [VARIABLE_INFO]
		do
			create tracker.make
			vars := tracker.extract_from_code ("shared x: INTEGER%Nx := 42", "cell_001")

			assert_equal ("one var", 1, vars.count)
			assert_equal ("name is x", "x", vars.first.name)
			assert_equal ("type is INTEGER", "INTEGER", vars.first.type_name)
			assert ("is shared", vars.first.is_shared)
		end

	test_tracker_extract_local
			-- Test extracting local variable declarations
		local
			tracker: VARIABLE_TRACKER
			vars: ARRAYED_LIST [VARIABLE_INFO]
		do
			create tracker.make
			vars := tracker.extract_from_code ("y: STRING%Ny := %"hello%"", "cell_001")

			assert_equal ("one var", 1, vars.count)
			assert_equal ("name is y", "y", vars.first.name)
			assert_equal ("type is STRING", "STRING", vars.first.type_name)
			assert ("not shared", not vars.first.is_shared)
		end

	test_tracker_extract_multiple
			-- Test extracting multiple variables
		local
			tracker: VARIABLE_TRACKER
			vars: ARRAYED_LIST [VARIABLE_INFO]
		do
			create tracker.make
			vars := tracker.extract_from_code ("x: INTEGER%Ny: STRING%Nz: BOOLEAN", "cell_001")

			assert_equal ("three vars", 3, vars.count)
		end

	test_tracker_extract_from_notebook
			-- Test extracting variables from notebook
		local
			tracker: VARIABLE_TRACKER
			nb: NOTEBOOK
			vars: ARRAYED_LIST [VARIABLE_INFO]
			l_cell: NOTEBOOK_CELL
		do
			create tracker.make
			create nb.make ("test")
			l_cell := nb.add_code_cell ("shared x: INTEGER%Nx := 42")
			l_cell := nb.add_code_cell ("y: STRING%Ny := %"hello%"")

			vars := tracker.extract_variables (nb)

			assert ("at least 2 vars", vars.count >= 2)
		end

feature -- Test: VARIABLE_TRACKER - Change Detection

	test_tracker_detect_new_variable
			-- Test detecting new variable
		local
			tracker: VARIABLE_TRACKER
			before, after: ARRAYED_LIST [VARIABLE_INFO]
			changes: ARRAYED_LIST [VARIABLE_CHANGE]
		do
			create tracker.make

			create before.make (0)
			create after.make (1)
			after.extend (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "42", "cell_001"))

			changes := tracker.detect_changes (before, after)

			assert_equal ("one change", 1, changes.count)
			assert ("is new", changes.first.is_new)
			assert_equal ("name is x", "x", changes.first.name)
		end

	test_tracker_detect_modified_variable
			-- Test detecting modified variable
		local
			tracker: VARIABLE_TRACKER
			before, after: ARRAYED_LIST [VARIABLE_INFO]
			changes: ARRAYED_LIST [VARIABLE_CHANGE]
		do
			create tracker.make

			create before.make (1)
			before.extend (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "42", "cell_001"))

			create after.make (1)
			after.extend (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "84", "cell_002"))

			changes := tracker.detect_changes (before, after)

			assert_equal ("one change", 1, changes.count)
			assert ("is modified", changes.first.is_modified)
			assert_equal ("old value", "42", changes.first.old_value)
			assert_equal ("new value", "84", changes.first.new_value)
		end

	test_tracker_detect_removed_variable
			-- Test detecting removed variable
		local
			tracker: VARIABLE_TRACKER
			before, after: ARRAYED_LIST [VARIABLE_INFO]
			changes: ARRAYED_LIST [VARIABLE_CHANGE]
		do
			create tracker.make

			create before.make (1)
			before.extend (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "42", "cell_001"))

			create after.make (0)

			changes := tracker.detect_changes (before, after)

			assert_equal ("one change", 1, changes.count)
			assert ("is removed", changes.first.is_removed)
		end

	test_tracker_detect_mixed_changes
			-- Test detecting multiple types of changes
		local
			tracker: VARIABLE_TRACKER
			before, after: ARRAYED_LIST [VARIABLE_INFO]
			changes: ARRAYED_LIST [VARIABLE_CHANGE]
			new_count, mod_count, rem_count: INTEGER
		do
			create tracker.make

			create before.make (2)
			before.extend (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "1", "c1"))
			before.extend (create {VARIABLE_INFO}.make_with_value ("y", "INTEGER", "2", "c1"))

			create after.make (2)
			after.extend (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "10", "c2")) -- Modified
			after.extend (create {VARIABLE_INFO}.make_with_value ("z", "INTEGER", "3", "c2"))  -- New
			-- y is removed

			changes := tracker.detect_changes (before, after)

			across changes as c loop
				if c.is_new then
					new_count := new_count + 1
				elseif c.is_modified then
					mod_count := mod_count + 1
				elseif c.is_removed then
					rem_count := rem_count + 1
				end
			end

			assert_equal ("one new", 1, new_count)
			assert_equal ("one modified", 1, mod_count)
			assert_equal ("one removed", 1, rem_count)
		end

feature -- Test: VARIABLE_TRACKER - State Management

	test_tracker_save_state
			-- Test saving state for comparison
		local
			tracker: VARIABLE_TRACKER
			changes: ARRAYED_LIST [VARIABLE_CHANGE]
		do
			create tracker.make
			tracker.add_variable (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "42", "c1"))

			tracker.save_state

			-- No changes yet
			changes := tracker.changes_since_save
			assert_equal ("no changes", 0, changes.count)

			-- Modify variable
			tracker.add_variable (create {VARIABLE_INFO}.make_with_value ("x", "INTEGER", "84", "c2"))

			changes := tracker.changes_since_save
			assert ("has change", changes.count > 0)
			assert ("x modified", changes.first.is_modified)
		end

	test_tracker_clear
			-- Test clearing tracker
		local
			tracker: VARIABLE_TRACKER
		do
			create tracker.make
			tracker.add_variable (create {VARIABLE_INFO}.make ("x", "INTEGER", "c1"))
			tracker.add_variable (create {VARIABLE_INFO}.make ("y", "STRING", "c1"))

			tracker.clear

			assert_equal ("empty", 0, tracker.count)
		end

	test_tracker_variables_for_cell
			-- Test getting variables for specific cell
		local
			tracker: VARIABLE_TRACKER
			vars: ARRAYED_LIST [VARIABLE_INFO]
		do
			create tracker.make
			tracker.add_variable (create {VARIABLE_INFO}.make ("x", "INTEGER", "cell_001"))
			tracker.add_variable (create {VARIABLE_INFO}.make ("y", "INTEGER", "cell_001"))
			tracker.add_variable (create {VARIABLE_INFO}.make ("z", "INTEGER", "cell_002"))

			vars := tracker.variables_for_cell ("cell_001")

			assert_equal ("two in cell_001", 2, vars.count)
		end

end
