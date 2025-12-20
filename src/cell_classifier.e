note
	description: "[
		Classifies notebook cell content into types based on Eiffel syntax.

		Eric Bezault Design: Natural Eiffel syntax without special keywords.

		Classification hierarchy:
		1. User class: starts with 'class '
		2. Routine: contains balanced 'do...end' or 'external...end'
		3. Attribute: pattern 'identifier: TYPE' without ':='
		4. Instruction: contains ':=' or 'create' or known command
		5. Expression: everything else (evaluated and printed)
	]"
	author: "Larry Rix"
	date: "$Date$"
	revision: "$Revision$"

class
	CELL_CLASSIFIER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize classifier
		do
			-- No state needed currently
		end

feature -- Classification

	classify (a_code: STRING): INTEGER
			-- Classify cell content and return classification constant
		require
			code_not_void: a_code /= Void
		local
			l_trimmed: STRING
		do
			l_trimmed := a_code.twin
			l_trimmed.left_adjust
			l_trimmed.right_adjust

			if l_trimmed.is_empty then
				Result := Classification_empty
			elseif is_user_class (l_trimmed) then
				Result := Classification_class
			elseif is_routine (l_trimmed) then
				Result := Classification_routine
			elseif is_attribute (l_trimmed) then
				Result := Classification_attribute
			elseif is_instruction (l_trimmed) then
				Result := Classification_instruction
			else
				Result := Classification_expression
			end
		ensure
			valid_result: is_valid_classification (Result)
		end

	classification_name (a_classification: INTEGER): STRING
			-- Human-readable name for classification
		require
			valid: is_valid_classification (a_classification)
		do
			inspect a_classification
			when Classification_empty then
				Result := "empty"
			when Classification_attribute then
				Result := "attribute"
			when Classification_routine then
				Result := "routine"
			when Classification_instruction then
				Result := "instruction"
			when Classification_expression then
				Result := "expression"
			when Classification_class then
				Result := "class"
			else
				Result := "unknown"
			end
		ensure
			result_not_empty: not Result.is_empty
		end

feature -- Classification Queries

	is_user_class (a_code: STRING): BOOLEAN
			-- Is this a class definition?
			-- Pattern: class NAME ... end
		require
			code_not_void: a_code /= Void
		local
			l_lower: STRING
		do
			l_lower := a_code.as_lower
			-- Must start with "class " AND (have " end" or end with "end")
			Result := l_lower.starts_with ("class ") and then
			          (l_lower.has_substring (" end") or else l_lower.ends_with ("end"))
		end

	is_routine (a_code: STRING): BOOLEAN
			-- Is this a routine definition?
			-- Pattern: name [(args)] [: TYPE] [require...] do|once|external ... end
		require
			code_not_void: a_code /= Void
		local
			l_lower: STRING
			l_has_body_keyword: BOOLEAN
			l_has_end: BOOLEAN
		do
			l_lower := a_code.as_lower

			-- Must have a body keyword (do, once, external, deferred)
			l_has_body_keyword := l_lower.has_substring ("%Ndo%N") or else
			                      l_lower.has_substring ("%Ndo ") or else
			                      l_lower.has_substring (" do%N") or else
			                      l_lower.has_substring ("%N%Tdo%N") or else
			                      l_lower.has_substring ("%N%T%Tdo%N") or else
			                      l_lower.has_substring ("%Nonce%N") or else
			                      l_lower.has_substring ("%Nonce ") or else
			                      l_lower.has_substring (" once%N") or else
			                      l_lower.has_substring ("%Nexternal ") or else
			                      l_lower.has_substring ("%Ndeferred%N") or else
			                      l_lower.has_substring (" deferred%N") or else
			                      -- Single-line patterns
			                      has_routine_signature_with_do (l_lower)

			-- Must end with 'end'
			l_has_end := l_lower.ends_with ("end") or else
			             l_lower.ends_with ("end%N") or else
			             l_lower.has_substring ("%Nend%N") or else
			             l_lower.has_substring ("%N%Tend")

			Result := l_has_body_keyword and l_has_end

			-- Additional check: must NOT be a class (which also has 'end')
			if Result and then is_user_class (a_code) then
				Result := False
			end
		end

	is_attribute (a_code: STRING): BOOLEAN
			-- Is this an attribute declaration?
			-- Pattern: identifier: TYPE (no := assignment)
		require
			code_not_void: a_code /= Void
		local
			l_lines: LIST [STRING]
			l_first_line: STRING
			l_colon_pos, l_assign_pos: INTEGER
			l_before_colon, l_after_colon: STRING
			l_found: BOOLEAN
		do
			-- Get first meaningful line
			create l_first_line.make_empty
			l_lines := a_code.split ('%N')
			across l_lines as line until l_found loop
				l_first_line := line.twin
				l_first_line.left_adjust
				l_first_line.right_adjust
				-- Skip comment lines
				if l_first_line.starts_with ("--") then
					l_first_line := ""
				elseif not l_first_line.is_empty then
					l_found := True
				end
			end

			if l_found and then not l_first_line.is_empty then
				l_colon_pos := l_first_line.index_of (':', 1)
				l_assign_pos := l_first_line.substring_index (":=", 1)

				-- Must have colon, must NOT have := before or at colon position
				if l_colon_pos > 1 and then (l_assign_pos = 0 or else l_assign_pos > l_colon_pos) then
					l_before_colon := l_first_line.substring (1, l_colon_pos - 1)
					l_before_colon.right_adjust
					l_after_colon := l_first_line.substring (l_colon_pos + 1, l_first_line.count)
					l_after_colon.left_adjust

					-- Before colon must be identifier (possibly with comma for multiple)
					-- After colon must be a type name
					Result := is_valid_attribute_name (l_before_colon) and then
					          is_valid_type_name (l_after_colon) and then
					          not has_routine_keywords (a_code)
				end
			end
		end

	is_instruction (a_code: STRING): BOOLEAN
			-- Is this an instruction (statement)?
			-- Pattern: assignment, create, procedure call, control structure
		require
			code_not_void: a_code /= Void
		local
			l_lower, l_trimmed: STRING
		do
			l_trimmed := a_code.twin
			l_trimmed.left_adjust
			l_lower := l_trimmed.as_lower

			-- Assignment
			if l_trimmed.has_substring (":=") then
				Result := True
			-- Creation instruction
			elseif l_lower.starts_with ("create ") then
				Result := True
			-- Check/debug/inspect blocks
			elseif l_lower.starts_with ("check ") or else
			       l_lower.starts_with ("debug ") or else
			       l_lower.starts_with ("inspect ") then
				Result := True
			-- Control structures
			elseif l_lower.starts_with ("if ") or else
			       l_lower.starts_with ("from ") or else
			       l_lower.starts_with ("across ") or else
			       l_lower.starts_with ("loop ") then
				Result := True
			-- Known command procedures (print, io.put_*, etc.)
			elseif is_known_command (l_trimmed) then
				Result := True
			end
		end

	is_expression (a_code: STRING): BOOLEAN
			-- Is this an expression (to be evaluated and printed)?
			-- Default: anything that's not attribute, routine, instruction, or class
		require
			code_not_void: a_code /= Void
		do
			Result := not is_user_class (a_code) and then
			          not is_routine (a_code) and then
			          not is_attribute (a_code) and then
			          not is_instruction (a_code)
		end

feature -- Classification Constants

	Classification_empty: INTEGER = 0
	Classification_attribute: INTEGER = 1
	Classification_routine: INTEGER = 2
	Classification_instruction: INTEGER = 3
	Classification_expression: INTEGER = 4
	Classification_class: INTEGER = 5

	is_valid_classification (a_value: INTEGER): BOOLEAN
			-- Is this a valid classification constant?
		do
			Result := a_value >= Classification_empty and then
			          a_value <= Classification_class
		end

feature {NONE} -- Implementation

	has_routine_signature_with_do (a_lower: STRING): BOOLEAN
			-- Does this look like a routine signature followed by do?
			-- Pattern: name [(args)] [: TYPE] do
		do
			-- Simple heuristic: has 'do' or 'once' and looks like a signature
			Result := (a_lower.has_substring (" do ") or else
			           a_lower.has_substring (" do%N") or else
			           a_lower.has_substring (" once ") or else
			           a_lower.has_substring (" once%N")) and then
			          (a_lower.has_substring ("): ") or else  -- has return type
			           a_lower.has_substring (")%N") or else  -- procedure with args
			           has_simple_routine_start (a_lower))    -- no-arg routine
		end

	has_simple_routine_start (a_lower: STRING): BOOLEAN
			-- Does this start with identifier followed by routine body?
			-- Pattern: name do ... end or name: TYPE do ... end or name(args) do ... end
		local
			l_first_word_end: INTEGER
			l_first_word: STRING
			l_paren_pos: INTEGER
		do
			-- Find first word boundary (space, newline, colon, or open paren)
			l_first_word_end := a_lower.index_of (' ', 1)
			l_paren_pos := a_lower.index_of ('(', 1)

			-- If open paren comes before first space, use it as the word boundary
			-- This handles f(args) where there's no space after the routine name
			if l_paren_pos > 0 and then (l_first_word_end = 0 or else l_paren_pos < l_first_word_end) then
				l_first_word_end := l_paren_pos
			end

			if l_first_word_end = 0 then
				l_first_word_end := a_lower.index_of ('%N', 1)
			end
			if l_first_word_end = 0 then
				l_first_word_end := a_lower.index_of (':', 1)
			end

			if l_first_word_end > 1 then
				l_first_word := a_lower.substring (1, l_first_word_end - 1)
				-- First word should be an identifier, not a keyword
				Result := is_identifier (l_first_word) and then
				          not is_eiffel_keyword (l_first_word)
			end
		end

	has_routine_keywords (a_code: STRING): BOOLEAN
			-- Does this code contain routine body keywords?
		local
			l_lower: STRING
		do
			l_lower := a_code.as_lower
			-- Multi-line patterns
			Result := l_lower.has_substring ("%Ndo%N") or else
			          l_lower.has_substring ("%Ndo ") or else
			          l_lower.has_substring (" do%N") or else
			          l_lower.has_substring ("%Nonce%N") or else
			          l_lower.has_substring ("%Nonce ") or else
			          l_lower.has_substring (" once%N") or else
			          l_lower.has_substring ("%Nrequire%N") or else
			          l_lower.has_substring ("%Nrequire ") or else
			          l_lower.has_substring ("%Nensure%N") or else
			          l_lower.has_substring ("%Nensure ") or else
			          l_lower.has_substring ("%Nlocal%N") or else
			          l_lower.has_substring ("%Nexternal ") or else
			          -- Single-line patterns (space-keyword-space)
			          l_lower.has_substring (" do ") or else
			          l_lower.has_substring (" once ") or else
			          l_lower.has_substring (" external ") or else
			          l_lower.has_substring (" deferred ") or else
			          l_lower.has_substring (" deferred%N")
		end

	is_valid_attribute_name (a_name: STRING): BOOLEAN
			-- Is this a valid attribute name (identifier or comma-separated list)?
		local
			l_parts: LIST [STRING]
			l_part: STRING
		do
			if a_name.has (',') then
				-- Multiple attributes: x, y: INTEGER
				l_parts := a_name.split (',')
				Result := True
				across l_parts as p loop
					l_part := p.twin
					l_part.left_adjust
					l_part.right_adjust
					if not is_identifier (l_part) then
						Result := False
					end
				end
			else
				Result := is_identifier (a_name)
			end
		end

	is_valid_type_name (a_type: STRING): BOOLEAN
			-- Is this a valid type name?
			-- Allows: INTEGER, STRING, ARRAY [INTEGER], like Current, etc.
		local
			l_type: STRING
		do
			l_type := a_type.twin
			l_type.left_adjust
			l_type.right_adjust

			if l_type.is_empty then
				Result := False
			elseif l_type.starts_with ("like ") then
				-- Anchored type
				Result := True
			elseif l_type.starts_with ("detachable ") or else
			       l_type.starts_with ("attached ") then
				-- Attachment mark
				Result := True
			else
				-- Regular type: starts with uppercase or is a basic type
				Result := l_type.item (1).is_upper or else
				          is_basic_type (l_type)
			end
		end

	is_basic_type (a_type: STRING): BOOLEAN
			-- Is this a basic Eiffel type?
		local
			l_lower: STRING
			l_base: STRING
			l_bracket: INTEGER
		do
			l_lower := a_type.as_lower
			-- Handle generic types like ARRAY [X]
			l_bracket := l_lower.index_of (' ', 1)
			if l_bracket > 0 then
				l_base := l_lower.substring (1, l_bracket - 1)
			else
				l_bracket := l_lower.index_of ('[', 1)
				if l_bracket > 0 then
					l_base := l_lower.substring (1, l_bracket - 1)
				else
					l_base := l_lower
				end
			end

			Result := l_base.same_string ("integer") or else
			          l_base.same_string ("integer_32") or else
			          l_base.same_string ("integer_64") or else
			          l_base.same_string ("natural") or else
			          l_base.same_string ("natural_32") or else
			          l_base.same_string ("natural_64") or else
			          l_base.same_string ("real") or else
			          l_base.same_string ("real_32") or else
			          l_base.same_string ("real_64") or else
			          l_base.same_string ("double") or else
			          l_base.same_string ("boolean") or else
			          l_base.same_string ("character") or else
			          l_base.same_string ("character_8") or else
			          l_base.same_string ("character_32") or else
			          l_base.same_string ("string") or else
			          l_base.same_string ("string_8") or else
			          l_base.same_string ("string_32") or else
			          l_base.same_string ("any") or else
			          l_base.same_string ("pointer")
		end

	is_identifier (a_str: STRING): BOOLEAN
			-- Is this a valid Eiffel identifier?
		local
			i: INTEGER
			c: CHARACTER
		do
			if a_str.count > 0 then
				c := a_str.item (1)
				if c.is_alpha or c = '_' then
					Result := True
					from i := 2 until i > a_str.count or not Result loop
						c := a_str.item (i)
						Result := c.is_alpha or c.is_digit or c = '_'
						i := i + 1
					end
				end
			end
		end

	is_eiffel_keyword (a_word: STRING): BOOLEAN
			-- Is this an Eiffel keyword?
		do
			Result := a_word.same_string ("do") or else
			          a_word.same_string ("end") or else
			          a_word.same_string ("if") or else
			          a_word.same_string ("then") or else
			          a_word.same_string ("else") or else
			          a_word.same_string ("elseif") or else
			          a_word.same_string ("from") or else
			          a_word.same_string ("until") or else
			          a_word.same_string ("loop") or else
			          a_word.same_string ("across") or else
			          a_word.same_string ("create") or else
			          a_word.same_string ("class") or else
			          a_word.same_string ("feature") or else
			          a_word.same_string ("inherit") or else
			          a_word.same_string ("require") or else
			          a_word.same_string ("ensure") or else
			          a_word.same_string ("local") or else
			          a_word.same_string ("once") or else
			          a_word.same_string ("external") or else
			          a_word.same_string ("deferred") or else
			          a_word.same_string ("check") or else
			          a_word.same_string ("debug") or else
			          a_word.same_string ("inspect") or else
			          a_word.same_string ("when") or else
			          a_word.same_string ("variant") or else
			          a_word.same_string ("invariant") or else
			          a_word.same_string ("rescue") or else
			          a_word.same_string ("retry") or else
			          a_word.same_string ("and") or else
			          a_word.same_string ("or") or else
			          a_word.same_string ("not") or else
			          a_word.same_string ("xor") or else
			          a_word.same_string ("implies") or else
			          a_word.same_string ("old") or else
			          a_word.same_string ("agent") or else
			          a_word.same_string ("attached") or else
			          a_word.same_string ("detachable") or else
			          a_word.same_string ("like") or else
			          a_word.same_string ("current") or else
			          a_word.same_string ("result") or else
			          a_word.same_string ("precursor") or else
			          a_word.same_string ("void") or else
			          a_word.same_string ("true") or else
			          a_word.same_string ("false")
		end

	is_known_command (a_code: STRING): BOOLEAN
			-- Is this a known command/procedure call?
		local
			l_lower: STRING
		do
			l_lower := a_code.as_lower
			-- Common output procedures
			Result := l_lower.starts_with ("print ") or else
			          l_lower.starts_with ("print(") or else
			          l_lower.starts_with ("io.put") or else
			          l_lower.starts_with ("io.new_line") or else
			          l_lower.starts_with ("io.read")
		end

end
