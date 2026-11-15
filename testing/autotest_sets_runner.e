note
	description: "[
		Runs the tests in simple_notebook's AutoTest test sets that TEST_APP did not call
		(port-coordination #17: 72 of them ran in no gate). Each goes through AutoTest's own
		EQA_TEST_EVALUATOR: a fresh test set (on_prepare), the test, then clean (on_clean),
		as AutoTest runs it. A failing test prints "FAIL:" with its tag and is counted.
	]"

class
	AUTOTEST_SETS_RUNNER

feature -- Counts

	passed, failed: INTEGER
			-- Tests run here.

feature -- Running

	run_all
			-- Every test below, 72 in all.
		do
			run_test_classifier
			run_test_code_generation
			run_test_config
			run_test_data_structures
			run_test_engine
			run_test_variable_tracking
		end

feature {NONE} -- Test sets

	run_test_classifier
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_CLASSIFIER]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_simple_attribute), "TEST_CLASSIFIER.test_simple_attribute")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_attribute_with_string_type), "TEST_CLASSIFIER.test_attribute_with_string_type")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_attribute_multiple_on_line), "TEST_CLASSIFIER.test_attribute_multiple_on_line")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_attribute_detachable), "TEST_CLASSIFIER.test_attribute_detachable")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_attribute_like), "TEST_CLASSIFIER.test_attribute_like")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_simple_routine), "TEST_CLASSIFIER.test_simple_routine")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_routine_with_args), "TEST_CLASSIFIER.test_routine_with_args")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_routine_with_require), "TEST_CLASSIFIER.test_routine_with_require")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_routine_with_ensure), "TEST_CLASSIFIER.test_routine_with_ensure")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_routine_with_local), "TEST_CLASSIFIER.test_routine_with_local")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_assignment), "TEST_CLASSIFIER.test_assignment")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_create_instruction), "TEST_CLASSIFIER.test_create_instruction")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_print_instruction), "TEST_CLASSIFIER.test_print_instruction")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_if_statement), "TEST_CLASSIFIER.test_if_statement")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_from_loop), "TEST_CLASSIFIER.test_from_loop")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_simple_expression), "TEST_CLASSIFIER.test_simple_expression")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_arithmetic_expression), "TEST_CLASSIFIER.test_arithmetic_expression")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_function_call_expression), "TEST_CLASSIFIER.test_function_call_expression")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_complex_expression), "TEST_CLASSIFIER.test_complex_expression")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_simple_class), "TEST_CLASSIFIER.test_simple_class")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_class_with_create), "TEST_CLASSIFIER.test_class_with_create")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_empty_cell), "TEST_CLASSIFIER.test_empty_cell")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_whitespace_only), "TEST_CLASSIFIER.test_whitespace_only")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_comment_line), "TEST_CLASSIFIER.test_comment_line")
			report (l_evaluator.execute (agent {TEST_CLASSIFIER}.test_classification_names), "TEST_CLASSIFIER.test_classification_names")
		end

	run_test_code_generation
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_CODE_GENERATION]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_mapping_creation), "TEST_CODE_GENERATION.test_mapping_creation")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_mapping_not_found), "TEST_CODE_GENERATION.test_mapping_not_found")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_mapping_lines_for_cell), "TEST_CODE_GENERATION.test_mapping_lines_for_cell")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_mapping_first_last_line), "TEST_CODE_GENERATION.test_mapping_first_last_line")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_mapping_clear), "TEST_CODE_GENERATION.test_mapping_clear")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_generator_line_mapping), "TEST_CODE_GENERATION.test_generator_line_mapping")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_generator_class_name), "TEST_CODE_GENERATION.test_generator_class_name")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_generate_to_cell), "TEST_CODE_GENERATION.test_generate_to_cell")
			report (l_evaluator.execute (agent {TEST_CODE_GENERATION}.test_markdown_cells_ignored), "TEST_CODE_GENERATION.test_markdown_cells_ignored")
		end

	run_test_config
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_CONFIG]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_CONFIG}.test_config_validation_invalid_path), "TEST_CONFIG.test_config_validation_invalid_path")
			report (l_evaluator.execute (agent {TEST_CONFIG}.test_config_file_save_load), "TEST_CONFIG.test_config_file_save_load")
			report (l_evaluator.execute (agent {TEST_CONFIG}.test_detector_finds_env_var), "TEST_CONFIG.test_detector_finds_env_var")
		end

	run_test_data_structures
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_DATA_STRUCTURES]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_cell_error), "TEST_DATA_STRUCTURES.test_cell_error")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_cell_clear_output), "TEST_DATA_STRUCTURES.test_cell_clear_output")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_notebook_add_markdown_cell), "TEST_DATA_STRUCTURES.test_notebook_add_markdown_cell")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_notebook_code_cells), "TEST_DATA_STRUCTURES.test_notebook_code_cells")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_notebook_update_cell_code), "TEST_DATA_STRUCTURES.test_notebook_update_cell_code")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_storage_creation), "TEST_DATA_STRUCTURES.test_storage_creation")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_storage_delete), "TEST_DATA_STRUCTURES.test_storage_delete")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_storage_list_notebooks), "TEST_DATA_STRUCTURES.test_storage_list_notebooks")
			report (l_evaluator.execute (agent {TEST_DATA_STRUCTURES}.test_storage_error_handling), "TEST_DATA_STRUCTURES.test_storage_error_handling")
		end

	run_test_engine
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_ENGINE]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_engine_with_config), "TEST_ENGINE.test_engine_with_config")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_engine_add_markdown), "TEST_ENGINE.test_engine_add_markdown")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_engine_update_cell), "TEST_ENGINE.test_engine_update_cell")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_engine_remove_cell), "TEST_ENGINE.test_engine_remove_cell")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_simple_notebook_creation), "TEST_ENGINE.test_simple_notebook_creation")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_simple_notebook_add_cell), "TEST_ENGINE.test_simple_notebook_add_cell")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_simple_notebook_new), "TEST_ENGINE.test_simple_notebook_new")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_simple_notebook_output), "TEST_ENGINE.test_simple_notebook_output")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_simple_notebook_run), "TEST_ENGINE.test_simple_notebook_run")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_simple_notebook_dirty), "TEST_ENGINE.test_simple_notebook_dirty")
			report (l_evaluator.execute (agent {TEST_ENGINE}.test_config_access), "TEST_ENGINE.test_config_access")
		end

	run_test_variable_tracking
		local
			l_evaluator: EQA_TEST_EVALUATOR [TEST_VARIABLE_TRACKING]
		do
			create l_evaluator
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_variable_info_shared), "TEST_VARIABLE_TRACKING.test_variable_info_shared")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_variable_info_formatted), "TEST_VARIABLE_TRACKING.test_variable_info_formatted")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_variable_info_string_value), "TEST_VARIABLE_TRACKING.test_variable_info_string_value")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_variable_info_comparison), "TEST_VARIABLE_TRACKING.test_variable_info_comparison")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_change_removed), "TEST_VARIABLE_TRACKING.test_change_removed")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_change_formatted), "TEST_VARIABLE_TRACKING.test_change_formatted")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_creation), "TEST_VARIABLE_TRACKING.test_tracker_creation")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_extract_local), "TEST_VARIABLE_TRACKING.test_tracker_extract_local")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_extract_multiple), "TEST_VARIABLE_TRACKING.test_tracker_extract_multiple")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_extract_from_notebook), "TEST_VARIABLE_TRACKING.test_tracker_extract_from_notebook")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_detect_removed_variable), "TEST_VARIABLE_TRACKING.test_tracker_detect_removed_variable")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_detect_mixed_changes), "TEST_VARIABLE_TRACKING.test_tracker_detect_mixed_changes")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_save_state), "TEST_VARIABLE_TRACKING.test_tracker_save_state")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_clear), "TEST_VARIABLE_TRACKING.test_tracker_clear")
			report (l_evaluator.execute (agent {TEST_VARIABLE_TRACKING}.test_tracker_variables_for_cell), "TEST_VARIABLE_TRACKING.test_tracker_variables_for_cell")
		end

feature {NONE} -- Implementation

	report (a_result: EQA_PARTIAL_RESULT; a_name: STRING)
			-- Count and print `a_result' of test `a_name'.
		do
			if a_result.is_pass then
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			else
				print ("  FAIL: " + a_name + " [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (a_result.tag) + "]%N")
				failed := failed + 1
			end
		end

end
