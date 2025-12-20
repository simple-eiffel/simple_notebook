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
			run_syntax_completeness_tests
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
			run_test (agent t.test_attribute_cell_collection, "test_attribute_cell_collection")
			run_test (agent t.test_instruction_cell_generation, "test_instruction_cell_generation")
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
			run_test (agent t.test_compiler_error_formatted_message, "test_compiler_error_formatted_message")
			run_test (agent t.test_compiler_error_formatted_with_underline, "test_compiler_error_formatted_with_underline")
			run_test (agent t.test_compiler_error_cell_id_number_extraction, "test_compiler_error_cell_id_number_extraction")
			run_test (agent t.test_compiler_error_compact_format, "test_compiler_error_compact_format")
			run_test (agent t.test_compiler_error_underline_identifies_token, "test_compiler_error_underline_identifies_token")
			run_test (agent t.test_compilation_result_success, "test_compilation_result_success")
			run_test (agent t.test_compilation_result_failure, "test_compilation_result_failure")
			run_test (agent t.test_execution_result_success, "test_execution_result_success")
			run_test (agent t.test_execution_result_compilation_error, "test_execution_result_compilation_error")
			run_test (agent t.test_execution_result_timeout, "test_execution_result_timeout")
			run_test (agent t.test_error_parser_vd_error, "test_error_parser_vd_error")
			run_test (agent t.test_error_parser_multiple_errors, "test_error_parser_multiple_errors")
			run_test (agent t.test_executor_creation, "test_executor_creation")
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

	run_syntax_completeness_tests
			-- Phase 2: Syntax completeness checker tests
		local
			t: TEST_SYNTAX_COMPLETENESS
		do
			print ("%N=== Syntax Completeness Tests ===%N")
			create t
			-- Complete code tests
			run_test (agent t.test_empty_is_complete, "test_empty_is_complete")
			run_test (agent t.test_simple_assignment_complete, "test_simple_assignment_complete")
			run_test (agent t.test_simple_expression_complete, "test_simple_expression_complete")
			run_test (agent t.test_attribute_declaration_complete, "test_attribute_declaration_complete")
			run_test (agent t.test_complete_routine, "test_complete_routine")
			run_test (agent t.test_complete_if_then_end, "test_complete_if_then_end")
			run_test (agent t.test_multiline_routine_complete, "test_multiline_routine_complete")
			-- Incomplete code tests
			run_test (agent t.test_do_without_end_incomplete, "test_do_without_end_incomplete")
			run_test (agent t.test_then_without_end_incomplete, "test_then_without_end_incomplete")
			run_test (agent t.test_class_without_end_incomplete, "test_class_without_end_incomplete")
			run_test (agent t.test_loop_without_end_incomplete, "test_loop_without_end_incomplete")
			run_test (agent t.test_unclosed_string_incomplete, "test_unclosed_string_incomplete")
			run_test (agent t.test_unclosed_parentheses_incomplete, "test_unclosed_parentheses_incomplete")
			run_test (agent t.test_unclosed_brackets_incomplete, "test_unclosed_brackets_incomplete")
			run_test (agent t.test_trailing_comma_incomplete, "test_trailing_comma_incomplete")
			run_test (agent t.test_trailing_backslash_incomplete, "test_trailing_backslash_incomplete")
			-- Nested blocks
			run_test (agent t.test_nested_if_incomplete, "test_nested_if_incomplete")
			run_test (agent t.test_nested_if_complete, "test_nested_if_complete")
			-- Edge cases
			run_test (agent t.test_end_in_string_not_counted, "test_end_in_string_not_counted")
			run_test (agent t.test_keyword_in_identifier_not_counted, "test_keyword_in_identifier_not_counted")
			run_test (agent t.test_comment_ignored, "test_comment_ignored")
			run_test (agent t.test_deferred_class_incomplete, "test_deferred_class_incomplete")
			run_test (agent t.test_once_without_end_incomplete, "test_once_without_end_incomplete")
			run_test (agent t.test_inspect_without_end_incomplete, "test_inspect_without_end_incomplete")
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
