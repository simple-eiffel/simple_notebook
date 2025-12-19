note
	description: "Test application for simple_notebook - runs all tests"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run all tests
		do
			print ("Running simple_notebook tests...%N%N")
			passed := 0
			failed := 0

			run_all_tests

			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")

			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Test Runners

	run_all_tests
			-- Run all test classes
		do
			run_config_tests
			run_data_structure_tests
			run_code_generation_tests
			run_compilation_tests
			run_variable_tracking_tests
			run_engine_tests
		end

	run_config_tests
			-- Phase 1.0: Configuration tests
		local
			t: TEST_CONFIG
		do
			print ("=== Configuration Tests ===%N")
			create t
			run_test (agent t.test_config_defaults, "test_config_defaults")
			run_test (agent t.test_config_setters, "test_config_setters")
			run_test (agent t.test_config_json_roundtrip, "test_config_json_roundtrip")
			run_test (agent t.test_config_json_paths, "test_config_json_paths")
			run_test (agent t.test_config_validation_missing_compiler, "test_config_validation_missing_compiler")
			run_test (agent t.test_detector_creation, "test_detector_creation")
			run_test (agent t.test_detector_detect_all, "test_detector_detect_all")
			run_test (agent t.test_wizard_silent, "test_wizard_silent")
		end

	run_data_structure_tests
			-- Phase 1.1: Data structure tests
		local
			t: TEST_DATA_STRUCTURES
		do
			print ("%N=== Data Structure Tests ===%N")
			create t
			run_test (agent t.test_cell_creation, "test_cell_creation")
			run_test (agent t.test_markdown_cell_creation, "test_markdown_cell_creation")
			run_test (agent t.test_cell_set_code, "test_cell_set_code")
			run_test (agent t.test_cell_output, "test_cell_output")
			run_test (agent t.test_cell_status_transitions, "test_cell_status_transitions")
			run_test (agent t.test_cell_json_roundtrip, "test_cell_json_roundtrip")
			run_test (agent t.test_notebook_creation, "test_notebook_creation")
			run_test (agent t.test_notebook_add_cell, "test_notebook_add_cell")
			run_test (agent t.test_notebook_add_code_cell, "test_notebook_add_code_cell")
			run_test (agent t.test_notebook_cell_by_id, "test_notebook_cell_by_id")
			run_test (agent t.test_notebook_remove_cell, "test_notebook_remove_cell")
			run_test (agent t.test_notebook_json_roundtrip, "test_notebook_json_roundtrip")
			run_test (agent t.test_storage_save_load, "test_storage_save_load")
		end

	run_code_generation_tests
			-- Phase 1.2: Code generation tests
		local
			t: TEST_CODE_GENERATION
		do
			print ("%N=== Code Generation Tests ===%N")
			create t
			run_test (agent t.test_mapping_entry_creation, "test_mapping_entry_creation")
			run_test (agent t.test_mapping_add_and_query, "test_mapping_add_and_query")
			run_test (agent t.test_mapping_cells_in_range, "test_mapping_cells_in_range")
			run_test (agent t.test_generator_creation, "test_generator_creation")
			run_test (agent t.test_single_cell_generation, "test_single_cell_generation")
			run_test (agent t.test_multiple_cells_generation, "test_multiple_cells_generation")
			run_test (agent t.test_shared_variable_collection, "test_shared_variable_collection")
			run_test (agent t.test_generate_ecf, "test_generate_ecf")
		end

	run_compilation_tests
			-- Phase 1.3: Compilation tests
		local
			t: TEST_COMPILATION
		do
			print ("%N=== Compilation Tests ===%N")
			create t
			run_test (agent t.test_compiler_error_creation, "test_compiler_error_creation")
			run_test (agent t.test_compiler_error_mapping, "test_compiler_error_mapping")
			run_test (agent t.test_compilation_result_success, "test_compilation_result_success")
			run_test (agent t.test_execution_result_success, "test_execution_result_success")
			run_test (agent t.test_execution_result_timeout, "test_execution_result_timeout")
			run_test (agent t.test_error_parser_vd_error, "test_error_parser_vd_error")
			run_test (agent t.test_executor_creation, "test_executor_creation")
			run_test (agent t.test_simple_compilation_succeeds, "test_simple_compilation_succeeds")
			run_test (agent t.test_compilation_error_detected, "test_compilation_error_detected")
			run_test (agent t.test_variable_across_cells, "test_variable_across_cells")
			run_test (agent t.test_timeout_protection, "test_timeout_protection")
		end

	run_variable_tracking_tests
			-- Phase 1.4: Variable tracking tests
		local
			t: TEST_VARIABLE_TRACKING
		do
			print ("%N=== Variable Tracking Tests ===%N")
			create t
			run_test (agent t.test_variable_info_creation, "test_variable_info_creation")
			run_test (agent t.test_variable_info_with_value, "test_variable_info_with_value")
			run_test (agent t.test_change_new, "test_change_new")
			run_test (agent t.test_change_modified, "test_change_modified")
			run_test (agent t.test_tracker_extract_shared, "test_tracker_extract_shared")
			run_test (agent t.test_tracker_detect_new_variable, "test_tracker_detect_new_variable")
			run_test (agent t.test_tracker_detect_modified_variable, "test_tracker_detect_modified_variable")
		end

	run_engine_tests
			-- Phase 1.5: Engine tests
		local
			t: TEST_ENGINE
		do
			print ("%N=== Engine Tests ===%N")
			create t
			run_test (agent t.test_engine_creation, "test_engine_creation")
			run_test (agent t.test_engine_new_session, "test_engine_new_session")
			run_test (agent t.test_engine_add_cell, "test_engine_add_cell")
			run_test (agent t.test_engine_variables, "test_engine_variables")
		end

feature {NONE} -- Implementation

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run a single test and update counters with exception capture
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name)
			if attached (create {EXCEPTION_MANAGER}).last_exception as exc then
				if attached exc.description as desc then
					print (" - " + desc.to_string_8)
				end
			end
			print ("%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end