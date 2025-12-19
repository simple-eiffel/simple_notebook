note
	description: "Test aggregator for simple_notebook - holds all test class instances"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	LIB_TESTS

create
	default_create

feature -- Test Classes

	config_tests: TEST_CONFIG
			-- Phase 1.0: Configuration tests
		once
			create Result
		end

	data_tests: TEST_DATA_STRUCTURES
			-- Phase 1.1: Data structure tests
		once
			create Result
		end

	codegen_tests: TEST_CODE_GENERATION
			-- Phase 1.2: Code generation tests
		once
			create Result
		end

	compile_tests: TEST_COMPILATION
			-- Phase 1.3: Compilation tests
		once
			create Result
		end

	var_tests: TEST_VARIABLE_TRACKING
			-- Phase 1.4: Variable tracking tests
		once
			create Result
		end

	engine_tests: TEST_ENGINE
			-- Phase 1.5: Engine tests
		once
			create Result
		end

end
