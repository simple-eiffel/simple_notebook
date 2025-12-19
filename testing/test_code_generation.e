note
	description: "Tests for Phase 1.2: Code Generation (ACCUMULATED_CLASS_GENERATOR, LINE_MAPPING)"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CODE_GENERATION

inherit
	TEST_SET_BASE

feature -- Test: LINE_MAPPING_ENTRY

	test_mapping_entry_creation
			-- Test creating a mapping entry
		local
			entry: LINE_MAPPING_ENTRY
		do
			create entry.make (42, "cell_001", 3)

			assert_equal ("generated line", 42, entry.generated_line)
			assert_equal ("cell id", "cell_001", entry.cell_id)
			assert_equal ("cell line", 3, entry.cell_line)
		end

feature -- Test: LINE_MAPPING

	test_mapping_creation
			-- Test creating line mapping
		local
			mapping: LINE_MAPPING
		do
			create mapping.make (10)
			assert ("empty initially", mapping.is_empty)
			assert_equal ("no entries", 0, mapping.entry_count)
		end

	test_mapping_add_and_query
			-- Test adding and querying mappings
		local
			mapping: LINE_MAPPING
		do
			create mapping.make (10)
			mapping.add_mapping (45, "cell_001", 1)
			mapping.add_mapping (46, "cell_001", 2)
			mapping.add_mapping (50, "cell_002", 1)

			assert_equal ("three entries", 3, mapping.entry_count)

			assert_equal ("line 45 cell", "cell_001", mapping.cell_id_for_line (45))
			assert_equal ("line 45 cell line", 1, mapping.cell_line_for_line (45))

			assert_equal ("line 46 cell", "cell_001", mapping.cell_id_for_line (46))
			assert_equal ("line 46 cell line", 2, mapping.cell_line_for_line (46))

			assert_equal ("line 50 cell", "cell_002", mapping.cell_id_for_line (50))
		end

	test_mapping_not_found
			-- Test querying non-existent line
		local
			mapping: LINE_MAPPING
		do
			create mapping.make (10)
			mapping.add_mapping (45, "cell_001", 1)

			assert ("line 99 not found", mapping.cell_id_for_line (99) = Void)
			assert_equal ("line 99 cell line is 0", 0, mapping.cell_line_for_line (99))
		end

	test_mapping_cells_in_range
			-- Test getting cells in line range
		local
			mapping: LINE_MAPPING
			cells: ARRAYED_LIST [STRING]
		do
			create mapping.make (10)
			mapping.add_mapping (10, "cell_001", 1)
			mapping.add_mapping (11, "cell_001", 2)
			mapping.add_mapping (20, "cell_002", 1)
			mapping.add_mapping (30, "cell_003", 1)

			cells := mapping.cells_in_range (10, 20)
			cells.compare_objects
			assert_equal ("two cells in range", 2, cells.count)
			assert ("has cell_001", cells.has ("cell_001"))
			assert ("has cell_002", cells.has ("cell_002"))
		end

	test_mapping_lines_for_cell
			-- Test getting all lines for a cell
		local
			mapping: LINE_MAPPING
			lines: ARRAYED_LIST [INTEGER]
		do
			create mapping.make (10)
			mapping.add_mapping (10, "cell_001", 1)
			mapping.add_mapping (11, "cell_001", 2)
			mapping.add_mapping (12, "cell_001", 3)
			mapping.add_mapping (20, "cell_002", 1)

			lines := mapping.generated_lines_for_cell ("cell_001")
			assert_equal ("three lines for cell_001", 3, lines.count)
			assert ("has line 10", lines.has (10))
			assert ("has line 11", lines.has (11))
			assert ("has line 12", lines.has (12))
		end

	test_mapping_first_last_line
			-- Test first/last line for cell
		local
			mapping: LINE_MAPPING
		do
			create mapping.make (10)
			mapping.add_mapping (15, "cell_001", 3)
			mapping.add_mapping (10, "cell_001", 1)
			mapping.add_mapping (12, "cell_001", 2)

			assert_equal ("first line", 10, mapping.first_line_for_cell ("cell_001"))
			assert_equal ("last line", 15, mapping.last_line_for_cell ("cell_001"))
		end

	test_mapping_clear
			-- Test clearing mappings
		local
			mapping: LINE_MAPPING
		do
			create mapping.make (10)
			mapping.add_mapping (10, "cell_001", 1)
			mapping.add_mapping (20, "cell_002", 1)

			mapping.clear

			assert ("is empty", mapping.is_empty)
		end

feature -- Test: ACCUMULATED_CLASS_GENERATOR

	test_generator_creation
			-- Test creating generator
		local
			gen: ACCUMULATED_CLASS_GENERATOR
		do
			create gen.make
			assert ("generator created", True)
		end

	test_single_cell_generation
			-- Test generating class from single cell
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			code: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("x := 42%Nprint(x)")

			create gen.make
			code := gen.generate_class (nb)

			-- Verify structure
			assert ("has class header", code.has_substring ("class ACCUMULATED_SESSION_"))
			assert ("has execute_cell_1", code.has_substring ("execute_cell_1"))
			assert ("has cell code", code.has_substring ("x := 42"))
			assert ("has print", code.has_substring ("print(x)"))
			assert ("ends with end", code.ends_with ("end%N"))
		end

	test_multiple_cells_generation
			-- Test generating class from multiple cells
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			code: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("x := 42")
			l_cell := nb.add_code_cell ("y := x * 2")
			l_cell := nb.add_code_cell ("print(y.out)")

			create gen.make
			code := gen.generate_class (nb)

			assert ("has execute_cell_1", code.has_substring ("execute_cell_1"))
			assert ("has execute_cell_2", code.has_substring ("execute_cell_2"))
			assert ("has execute_cell_3", code.has_substring ("execute_cell_3"))
			assert ("has execute_all", code.has_substring ("execute_all"))
		end

	test_generator_line_mapping
			-- Test that generator creates line mapping
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			code: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("x := 42%Ny := x * 2")
			l_cell := nb.add_code_cell ("print(y)")

			create gen.make
			code := gen.generate_class (nb)

			assert ("mapping populated", gen.line_mapping.entry_count > 0)
		end

	test_generator_class_name
			-- Test that generator produces valid class name
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			code: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("x := 42")

			create gen.make
			code := gen.generate_class (nb)

			assert ("class name not empty", not gen.last_class_name.is_empty)
			assert ("starts with ACCUMULATED", gen.last_class_name.starts_with ("ACCUMULATED_SESSION_"))
		end

	test_shared_variable_collection
			-- Test shared variable detection
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			code: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("shared x: INTEGER%Nx := 42")
			l_cell := nb.add_code_cell ("print(x)")

			create gen.make
			code := gen.generate_class (nb)

			-- x should be an attribute, not local
			assert ("has shared section", code.has_substring ("feature -- Shared Variables"))
			assert ("x is attribute", code.has_substring ("%Tx: INTEGER"))
		end

	test_local_variable_extraction
			-- Test local variable detection
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			code: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("x: INTEGER%Nx := 42")

			create gen.make
			code := gen.generate_class (nb)

			-- x should be local
			assert ("has local section", code.has_substring ("local"))
		end

	test_generate_to_cell
			-- Test generating class up to specific cell
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			cell1, cell2, cell3: NOTEBOOK_CELL
			code: STRING
		do
			create nb.make ("test")
			cell1 := nb.add_code_cell ("x := 1")
			cell2 := nb.add_code_cell ("x := 2")
			cell3 := nb.add_code_cell ("x := 3")

			create gen.make
			code := gen.generate_class_to_cell (nb, cell2)

			assert ("has cell 1", code.has_substring ("x := 1"))
			assert ("has cell 2", code.has_substring ("x := 2"))
			assert ("no cell 3", not code.has_substring ("x := 3"))
		end

	test_generate_ecf
			-- Test ECF generation
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			ecf: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("x := 42")

			create gen.make
			ecf := gen.generate_ecf (nb, "TEST_SESSION")

			assert ("has system tag", ecf.has_substring ("<system"))
			assert ("has root class", ecf.has_substring ("TEST_SESSION"))
			assert ("has base library", ecf.has_substring ("base.ecf"))
		end

feature -- Test: Markdown cells ignored

	test_markdown_cells_ignored
			-- Test that markdown cells are not in generated code
		local
			gen: ACCUMULATED_CLASS_GENERATOR
			nb: NOTEBOOK
			code: STRING
			l_cell: NOTEBOOK_CELL
		do
			create nb.make ("test")
			l_cell := nb.add_code_cell ("x := 42")
			l_cell := nb.add_markdown_cell ("# This is documentation")
			l_cell := nb.add_code_cell ("print(x)")

			create gen.make
			code := gen.generate_class (nb)

			-- Should have cell_1 and cell_2 (code cells only)
			assert ("has execute_cell_1", code.has_substring ("execute_cell_1"))
			assert ("has execute_cell_2", code.has_substring ("execute_cell_2"))
			assert ("no execute_cell_3", not code.has_substring ("execute_cell_3"))
			assert ("no markdown content", not code.has_substring ("documentation"))
		end

end
