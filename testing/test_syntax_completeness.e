note
	description: "Tests for SYNTAX_COMPLETENESS_CHECKER"
	author: "Claude"
	date: "$Date$"

class
	TEST_SYNTAX_COMPLETENESS

inherit
	EQA_TEST_SET

feature -- Tests: Complete code

	test_empty_is_complete
			-- Empty string is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("empty complete", checker.is_complete (""))
		end

	test_simple_assignment_complete
			-- Simple assignment is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("assignment complete", checker.is_complete ("x := 42"))
		end

	test_simple_expression_complete
			-- Simple expression is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("expression complete", checker.is_complete ("x + 1"))
		end

	test_attribute_declaration_complete
			-- Attribute declaration is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("attribute complete", checker.is_complete ("x: INTEGER"))
		end

	test_complete_routine
			-- Full routine with do...end is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("routine complete", checker.is_complete ("f do print (%"hi%") end"))
		end

	test_complete_if_then_end
			-- Full if...then...end is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("if complete", checker.is_complete ("if x > 0 then print (%"yes%") end"))
		end

	test_multiline_routine_complete
			-- Multi-line routine is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
			code: STRING
		do
			create checker.make
			code := "f%N%Tdo%N%T%Tprint (%"hi%")%N%Tend"
			assert ("multiline routine complete", checker.is_complete (code))
		end

feature -- Tests: Incomplete code

	test_do_without_end_incomplete
			-- 'do' without 'end' is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("do incomplete", checker.needs_continuation ("f do"))
		end

	test_then_without_end_incomplete
			-- 'then' without 'end' is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("then incomplete", checker.needs_continuation ("if x > 0 then"))
		end

	test_class_without_end_incomplete
			-- 'class' without 'end' is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("class incomplete", checker.needs_continuation ("class FOO"))
		end

	test_loop_without_end_incomplete
			-- 'loop' without 'end' is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("loop incomplete", checker.needs_continuation ("from i := 1 until i > 10 loop"))
		end

	test_unclosed_string_incomplete
			-- Unclosed string is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("unclosed string", checker.needs_continuation ("x := %"hello"))
		end

	test_unclosed_parentheses_incomplete
			-- Unclosed parentheses are incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("unclosed paren", checker.needs_continuation ("f (a, b"))
		end

	test_unclosed_brackets_incomplete
			-- Unclosed brackets are incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("unclosed bracket", checker.needs_continuation ("arr [1"))
		end

	test_trailing_comma_incomplete
			-- Trailing comma suggests continuation
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("trailing comma", checker.needs_continuation ("f (a,"))
		end

	test_trailing_backslash_incomplete
			-- Trailing backslash is explicit continuation
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("trailing backslash", checker.needs_continuation ("x := 1 + \"))
		end

feature -- Tests: Nested blocks

	test_nested_if_incomplete
			-- Nested if without enough ends is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
			code: STRING
		do
			create checker.make
			code := "if x > 0 then%N%Tif y > 0 then%N%T%Tprint (%"both%")%N%Tend"
			-- Only one 'end' for two 'then's
			assert ("nested incomplete", checker.needs_continuation (code))
		end

	test_nested_if_complete
			-- Nested if with both ends is complete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
			code: STRING
		do
			create checker.make
			code := "if x > 0 then%N%Tif y > 0 then%N%T%Tprint (%"both%")%N%Tend%Nend"
			assert ("nested complete", checker.is_complete (code))
		end

feature -- Tests: Edge cases

	test_end_in_string_not_counted
			-- 'end' inside a string doesn't count as block closer
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			-- This is still incomplete because the 'end' is in a string
			assert ("string end", checker.needs_continuation ("f do print (%"the end%")"))
		end

	test_keyword_in_identifier_not_counted
			-- 'do' as part of identifier (e.g., 'undo') doesn't count
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			-- 'undo' contains 'do' but shouldn't trigger
			assert ("undo complete", checker.is_complete ("undo_action"))
		end

	test_comment_ignored
			-- Keywords in comments are ignored
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			-- Comment has 'do' but shouldn't count
			assert ("comment ignored", checker.is_complete ("x := 42 -- do something"))
		end

	test_deferred_class_incomplete
			-- Deferred class without end is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("deferred class", checker.needs_continuation ("deferred class FOO"))
		end

	test_once_without_end_incomplete
			-- 'once' without 'end' is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("once incomplete", checker.needs_continuation ("instance: FOO once create Result.make"))
		end

	test_inspect_without_end_incomplete
			-- 'inspect' without 'end' is incomplete
		local
			checker: SYNTAX_COMPLETENESS_CHECKER
		do
			create checker.make
			assert ("inspect incomplete", checker.needs_continuation ("inspect x"))
		end

end
