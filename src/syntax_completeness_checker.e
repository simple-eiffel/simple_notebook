note
	description: "[
		Detects whether Eiffel code is syntactically complete.

		Used by REPL to know when to show continuation prompt vs submit.

		Tracks:
		- Block keywords (if/do/class/loop) vs 'end' closers
		- Unclosed strings
		- Unclosed parentheses/brackets
	]"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	SYNTAX_COMPLETENESS_CHECKER

create
	make

feature {NONE} -- Initialization

	make
			-- Initialize checker
		do
			create block_openers.make (10)
			block_openers.compare_objects
			block_openers.extend ("do")
			block_openers.extend ("then")
			block_openers.extend ("loop")
			block_openers.extend ("check")
			block_openers.extend ("debug")
			block_openers.extend ("once")
			block_openers.extend ("deferred")
			-- Note: 'class' handled specially (must be at line start)
		end

feature -- Access

	block_openers: ARRAYED_LIST [STRING]
			-- Keywords that open blocks requiring 'end'

feature -- Status

	is_complete (a_code: STRING): BOOLEAN
			-- Is the code syntactically complete (can be submitted)?
		require
			code_not_void: a_code /= Void
		do
			if a_code.is_empty then
				Result := True
			else
				Result := not needs_continuation (a_code)
			end
		end

	needs_continuation (a_code: STRING): BOOLEAN
			-- Does the code need more input?
		require
			code_not_void: a_code /= Void
		local
			l_depth: INTEGER
		do
			if a_code.is_empty then
				Result := False
			else
				-- Check structural completeness
				l_depth := block_depth (a_code)
				Result := l_depth > 0

				-- Also check for unclosed delimiters
				if not Result then
					Result := has_unclosed_string (a_code) or
					          has_unclosed_parentheses (a_code) or
					          has_unclosed_brackets (a_code)
				end

				-- Check for trailing continuation indicators
				if not Result then
					Result := ends_with_continuation (a_code)
				end
			end
		end

	block_depth (a_code: STRING): INTEGER
			-- Count of unclosed blocks (openers - closers)
			-- Positive means incomplete, 0 or negative means complete
		require
			code_not_void: a_code /= Void
		local
			l_lower: STRING
			l_in_string: BOOLEAN
			i: INTEGER
			c: CHARACTER
			l_word_start, l_word_end: INTEGER
			l_word: STRING
		do
			l_lower := a_code.as_lower
			Result := 0

			-- Check for class definition at start of code
			if starts_with_class (l_lower) then
				Result := Result + 1
			end

			-- Tokenize and count block keywords vs 'end'
			-- Simple approach: find words and check them
			from
				i := 1
				l_in_string := False
			until
				i > l_lower.count
			loop
				c := l_lower.item (i)

				-- Track string state
				if c = '"' then
					l_in_string := not l_in_string
					i := i + 1
				elseif c = '-' and i < l_lower.count and l_lower.item (i + 1) = '-' and not l_in_string then
					-- Comment until end of line
					from until i > l_lower.count or l_lower.item (i) = '%N' loop
						i := i + 1
					end
				elseif l_in_string then
					-- Skip string content
					i := i + 1
				elseif c.is_alpha then
					-- Found start of word
					l_word_start := i
					from until i > l_lower.count or not (l_lower.item (i).is_alpha or l_lower.item (i) = '_') loop
						i := i + 1
					end
					l_word_end := i - 1
					l_word := l_lower.substring (l_word_start, l_word_end)

					-- Check if it's a block opener or closer
					if l_word.same_string ("end") then
						Result := Result - 1
					elseif block_openers.has (l_word) then
						-- Make sure 'do' is not part of 'undo' etc.
						if is_standalone_keyword (l_lower, l_word_start, l_word_end) then
							Result := Result + 1
						end
					elseif l_word.same_string ("if") then
						-- 'if' opens a block that needs 'then...end'
						-- But we count 'then' separately, so don't count 'if'
					elseif l_word.same_string ("from") then
						-- 'from' opens a loop that needs 'loop...end'
						-- 'loop' is counted separately
					elseif l_word.same_string ("inspect") then
						-- 'inspect' needs 'end'
						if is_standalone_keyword (l_lower, l_word_start, l_word_end) then
							Result := Result + 1
						end
					elseif l_word.same_string ("across") then
						-- 'across' needs 'loop...end' or 'all/some...end'
						-- 'loop' counted separately; for 'all/some' we need to count
					end
				else
					i := i + 1
				end
			end

			-- Ensure non-negative for unclosed strings affecting count
			if Result < 0 then
				Result := 0
			end
		end

feature {NONE} -- Analysis

	starts_with_class (a_lower: STRING): BOOLEAN
			-- Does code start with 'class' keyword (possibly after 'note' or 'deferred')?
		local
			l_trimmed: STRING
		do
			l_trimmed := a_lower.twin
			l_trimmed.left_adjust

			-- Check for class or deferred class or expanded class or frozen class
			Result := l_trimmed.starts_with ("class ") or
			          l_trimmed.starts_with ("class%N") or
			          l_trimmed.starts_with ("class%T") or
			          l_trimmed.starts_with ("deferred class") or
			          l_trimmed.starts_with ("expanded class") or
			          l_trimmed.starts_with ("frozen class")

			-- Also check if starts with 'note' followed by class
			if not Result and l_trimmed.starts_with ("note") then
				if l_trimmed.has_substring ("class ") or l_trimmed.has_substring ("class%N") then
					Result := True
				end
			end
		end

	is_standalone_keyword (a_code: STRING; a_start, a_end: INTEGER): BOOLEAN
			-- Is the word at [a_start, a_end] a standalone keyword?
			-- (not part of a larger identifier)
		do
			Result := True
			-- Check character before
			if a_start > 1 then
				if a_code.item (a_start - 1).is_alpha or a_code.item (a_start - 1) = '_' then
					Result := False
				end
			end
			-- Check character after
			if Result and a_end < a_code.count then
				if a_code.item (a_end + 1).is_alpha or a_code.item (a_end + 1) = '_' then
					Result := False
				end
			end
		end

	has_unclosed_string (a_code: STRING): BOOLEAN
			-- Does the code have an unclosed string literal?
		local
			i: INTEGER
			l_in_string: BOOLEAN
			c: CHARACTER
		do
			from
				i := 1
				l_in_string := False
			until
				i > a_code.count
			loop
				c := a_code.item (i)
				if c = '"' then
					l_in_string := not l_in_string
				elseif c = '%%' and l_in_string and i < a_code.count then
					-- Escaped character, skip next
					i := i + 1
				end
				i := i + 1
			end
			Result := l_in_string
		end

	has_unclosed_parentheses (a_code: STRING): BOOLEAN
			-- Does the code have unclosed parentheses?
		local
			l_depth: INTEGER
			i: INTEGER
			l_in_string: BOOLEAN
			c: CHARACTER
		do
			from
				i := 1
				l_depth := 0
				l_in_string := False
			until
				i > a_code.count
			loop
				c := a_code.item (i)
				if c = '"' then
					l_in_string := not l_in_string
				elseif not l_in_string then
					if c = '(' then
						l_depth := l_depth + 1
					elseif c = ')' then
						l_depth := l_depth - 1
					end
				end
				i := i + 1
			end
			Result := l_depth > 0
		end

	has_unclosed_brackets (a_code: STRING): BOOLEAN
			-- Does the code have unclosed brackets?
		local
			l_depth: INTEGER
			i: INTEGER
			l_in_string: BOOLEAN
			c: CHARACTER
		do
			from
				i := 1
				l_depth := 0
				l_in_string := False
			until
				i > a_code.count
			loop
				c := a_code.item (i)
				if c = '"' then
					l_in_string := not l_in_string
				elseif not l_in_string then
					if c = '[' then
						l_depth := l_depth + 1
					elseif c = ']' then
						l_depth := l_depth - 1
					end
				end
				i := i + 1
			end
			Result := l_depth > 0
		end

	ends_with_continuation (a_code: STRING): BOOLEAN
			-- Does code end with a token that suggests continuation?
		local
			l_trimmed: STRING
		do
			l_trimmed := a_code.twin
			l_trimmed.right_adjust

			Result := l_trimmed.ends_with ("\") or
			          l_trimmed.ends_with (",") or
			          l_trimmed.ends_with ("(") or
			          l_trimmed.ends_with ("[") or
			          l_trimmed.ends_with ("{")
		end

end
