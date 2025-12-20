note
	description: "Tests for CELL_CLASSIFIER - Eric Bezault design cell classification"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CLASSIFIER

inherit
	EQA_TEST_SET

feature -- Test Attributes

	test_simple_attribute
			-- Test: x: INTEGER -> attribute
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("x: INTEGER is attribute",
				c.classify ("x: INTEGER") = c.Classification_attribute)
		end

	test_attribute_with_string_type
			-- Test: name: STRING -> attribute
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("name: STRING is attribute",
				c.classify ("name: STRING") = c.Classification_attribute)
		end

	test_attribute_multiple_on_line
			-- Test: x, y: INTEGER -> attribute
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("x, y: INTEGER is attribute",
				c.classify ("x, y: INTEGER") = c.Classification_attribute)
		end

	test_attribute_detachable
			-- Test: obj: detachable STRING -> attribute
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("obj: detachable STRING is attribute",
				c.classify ("obj: detachable STRING") = c.Classification_attribute)
		end

	test_attribute_like
			-- Test: other: like Current -> attribute
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("other: like Current is attribute",
				c.classify ("other: like Current") = c.Classification_attribute)
		end

feature -- Test Routines

	test_simple_routine
			-- Test: f do print (42) end -> routine
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("simple routine",
				c.classify ("f%N%Tdo%N%T%Tprint (42)%N%Tend") = c.Classification_routine)
		end

	test_routine_with_args
			-- Test: double (n: INTEGER): INTEGER do Result := n * 2 end -> routine
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("routine with args",
				c.classify ("double (n: INTEGER): INTEGER%N%Tdo%N%T%TResult := n * 2%N%Tend") = c.Classification_routine)
		end

	test_routine_with_require
			-- Test: routine with require clause
		local
			c: CELL_CLASSIFIER
			code: STRING
		do
			create c.make
			code := "double (n: INTEGER): INTEGER%N%Trequire%N%T%Tn > 0%N%Tdo%N%T%TResult := n * 2%N%Tend"
			assert ("routine with require",
				c.classify (code) = c.Classification_routine)
		end

	test_routine_with_ensure
			-- Test: routine with ensure clause
		local
			c: CELL_CLASSIFIER
			code: STRING
		do
			create c.make
			code := "foo: INTEGER%N%Tdo%N%T%TResult := 42%N%Tensure%N%T%TResult > 0%N%Tend"
			assert ("routine with ensure",
				c.classify (code) = c.Classification_routine)
		end

	test_routine_with_local
			-- Test: routine with local variables
		local
			c: CELL_CLASSIFIER
			code: STRING
		do
			create c.make
			code := "compute: INTEGER%N%Tlocal%N%T%Ttemp: INTEGER%N%Tdo%N%T%Ttemp := 10%N%T%TResult := temp * 2%N%Tend"
			assert ("routine with local",
				c.classify (code) = c.Classification_routine)
		end

feature -- Test Instructions

	test_assignment
			-- Test: x := 42 -> instruction
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("assignment is instruction",
				c.classify ("x := 42") = c.Classification_instruction)
		end

	test_create_instruction
			-- Test: create obj.make -> instruction
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("create is instruction",
				c.classify ("create obj.make") = c.Classification_instruction)
		end

	test_print_instruction
			-- Test: print (x) -> instruction
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("print is instruction",
				c.classify ("print (x)") = c.Classification_instruction)
		end

	test_if_statement
			-- Test: if condition then -> instruction
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("if is instruction",
				c.classify ("if x > 0 then") = c.Classification_instruction)
		end

	test_from_loop
			-- Test: from i := 1 until -> instruction
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("from is instruction",
				c.classify ("from i := 1") = c.Classification_instruction)
		end

feature -- Test Expressions

	test_simple_expression
			-- Test: x -> expression
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("identifier is expression",
				c.classify ("x") = c.Classification_expression)
		end

	test_arithmetic_expression
			-- Test: x + 1 -> expression
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("arithmetic is expression",
				c.classify ("x + 1") = c.Classification_expression)
		end

	test_function_call_expression
			-- Test: my_function (arg) -> expression (when not print)
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("function call is expression",
				c.classify ("double (21)") = c.Classification_expression)
		end

	test_complex_expression
			-- Test: a.b.c (d) -> expression
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("chain call is expression",
				c.classify ("list.first.name") = c.Classification_expression)
		end

feature -- Test Classes

	test_simple_class
			-- Test: class FOO ... end -> class
		local
			c: CELL_CLASSIFIER
			code: STRING
		do
			create c.make
			code := "class FOO%Nfeature%N%Tx: INTEGER%Nend"
			assert ("class definition",
				c.classify (code) = c.Classification_class)
		end

	test_class_with_create
			-- Test: class with create clause
		local
			c: CELL_CLASSIFIER
			code: STRING
		do
			create c.make
			code := "class POINT%Ncreate%N%Tmake%Nfeature%N%Tx, y: INTEGER%N%Tmake (a_x, a_y: INTEGER)%N%T%Tdo%N%T%T%Tx := a_x%N%T%T%Ty := a_y%N%T%Tend%Nend"
			assert ("class with create",
				c.classify (code) = c.Classification_class)
		end

feature -- Test Edge Cases

	test_empty_cell
			-- Test: empty string -> empty
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("empty is empty",
				c.classify ("") = c.Classification_empty)
		end

	test_whitespace_only
			-- Test: whitespace only -> empty
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("whitespace is empty",
				c.classify ("   %N%T  ") = c.Classification_empty)
		end

	test_comment_line
			-- Test: -- comment -> expression (will be skipped in generation)
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			-- Comment-only is treated as expression (generator skips it)
			assert ("comment is expression",
				c.classify ("-- this is a comment") = c.Classification_expression)
		end

feature -- Test Classification Names

	test_classification_names
			-- Test classification_name returns correct strings
		local
			c: CELL_CLASSIFIER
		do
			create c.make
			assert ("empty name", c.classification_name (c.Classification_empty).same_string ("empty"))
			assert ("attribute name", c.classification_name (c.Classification_attribute).same_string ("attribute"))
			assert ("routine name", c.classification_name (c.Classification_routine).same_string ("routine"))
			assert ("instruction name", c.classification_name (c.Classification_instruction).same_string ("instruction"))
			assert ("expression name", c.classification_name (c.Classification_expression).same_string ("expression"))
			assert ("class name", c.classification_name (c.Classification_class).same_string ("class"))
		end

end
