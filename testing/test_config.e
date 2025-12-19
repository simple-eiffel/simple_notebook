note
	description: "Tests for Phase 1.0: Configuration classes"
	author: "Claude"
	date: "$Date$"
	revision: "$Revision$"

class
	TEST_CONFIG

inherit
	TEST_SET_BASE
		redefine
			on_prepare
		end

feature {NONE} -- Setup

	on_prepare
			-- Setup test environment
		do
			create test_workspace.make_from_string ("./test_workspace")
			ensure_test_directory
		end

	test_workspace: PATH
			-- Temporary test directory

	ensure_test_directory
			-- Create test directory if needed
		local
			l_file: SIMPLE_FILE
			l_ok: BOOLEAN
		do
			create l_file.make (test_workspace.name)
			if not l_file.is_directory then
				l_ok := l_file.create_directory_recursive
			end
		end

feature -- Test: Defaults

	test_config_defaults
			-- Test default configuration values
		local
			config: NOTEBOOK_CONFIG
		do
			create config.make_with_defaults

			assert_equal ("default timeout", 30, config.timeout_seconds)
			assert_equal ("default autosave", 30, config.autosave_interval_seconds)
			assert_equal ("default history", 1000, config.history_size)
			assert_equal ("default port", 8080, config.web_port)
			assert_equal ("default host", "localhost", config.web_host)
			assert_equal ("default prompt", "e[N]>", config.prompt_style)
			assert ("show timing on", config.show_timing)
			assert ("show var changes on", config.show_variable_changes)
			assert ("quiet mode off", not config.quiet_mode)
		end

	test_config_setters
			-- Test configuration setters
		local
			config: NOTEBOOK_CONFIG
		do
			create config.make_with_defaults

			config.set_timeout_seconds (60)
			assert_equal ("timeout set", 60, config.timeout_seconds)

			config.set_web_port (3000)
			assert_equal ("port set", 3000, config.web_port)

			config.set_prompt_style (">>>")
			assert_equal ("prompt set", ">>>", config.prompt_style)

			config.set_quiet_mode (True)
			assert ("quiet mode on", config.quiet_mode)
		end

feature -- Test: JSON Serialization

	test_config_json_roundtrip
			-- Test JSON serialization roundtrip
		local
			config, loaded: NOTEBOOK_CONFIG
			json: SIMPLE_JSON_OBJECT
		do
			create config.make_with_defaults
			config.set_timeout_seconds (60)
			config.set_web_port (3000)
			config.set_prompt_style ("eiffel>")
			config.set_quiet_mode (True)

			-- Serialize
			json := config.to_json

			-- Deserialize
			create loaded.make_with_defaults
			loaded.from_json (json)

			-- Verify
			assert_equal ("timeout preserved", 60, loaded.timeout_seconds)
			assert_equal ("port preserved", 3000, loaded.web_port)
			assert_equal ("prompt preserved", "eiffel>", loaded.prompt_style)
			assert ("quiet preserved", loaded.quiet_mode)
		end

	test_config_json_paths
			-- Test path serialization
		local
			config, loaded: NOTEBOOK_CONFIG
			json: SIMPLE_JSON_OBJECT
		do
			create config.make_with_defaults
			config.set_eiffel_compiler (create {PATH}.make_from_string ("C:/test/ec.exe"))
			config.set_ise_library (create {PATH}.make_from_string ("C:/test/library"))
			config.set_simple_eiffel (create {PATH}.make_from_string ("D:/prod"))

			json := config.to_json

			create loaded.make_with_defaults
			loaded.from_json (json)

			assert ("compiler path", loaded.eiffel_compiler.name.to_string_8.has_substring ("test") and loaded.eiffel_compiler.name.to_string_8.has_substring ("ec.exe"))
			assert ("library path", loaded.ise_library.name.to_string_8.has_substring ("test") and loaded.ise_library.name.to_string_8.has_substring ("library"))
			assert ("simple path", loaded.simple_eiffel.name.to_string_8.has_substring ("prod"))
		end

feature -- Test: Validation

	test_config_validation_missing_compiler
			-- Test validation fails when compiler missing
		local
			config: NOTEBOOK_CONFIG
		do
			create config.make_with_defaults
			-- Don't set eiffel_compiler
			config.validate

			assert ("not valid", not config.is_valid)
			assert ("has errors", config.validation_errors.count > 0)
			assert ("mentions compiler", config.validation_errors.first.has_substring ("compiler"))
		end

	test_config_validation_invalid_path
			-- Test validation fails with non-existent path
		local
			config: NOTEBOOK_CONFIG
		do
			create config.make_with_defaults
			config.set_eiffel_compiler (create {PATH}.make_from_string ("/nonexistent/path/ec.exe"))
			config.validate

			assert ("not valid", not config.is_valid)
			assert ("has errors", not config.validation_errors.is_empty)
		end

feature -- Test: File Persistence

	test_config_file_save_load
			-- Test saving and loading config file
		local
			config, loaded: NOTEBOOK_CONFIG
			test_path: PATH
			l_file: SIMPLE_FILE
		do
			create test_path.make_from_string (test_workspace.name + "/test_config.json")

			create config.make_with_defaults
			config.set_timeout_seconds (45)
			config.set_web_port (9000)
			config.save (test_path)

			-- Verify file exists
			create l_file.make (test_path.name)
			assert ("file created", l_file.exists)

			-- Load and verify
			create loaded.make_from_file (test_path)
			assert_equal ("timeout loaded", 45, loaded.timeout_seconds)
			assert_equal ("port loaded", 9000, loaded.web_port)
		end

feature -- Test: Detector

	test_detector_creation
			-- Test detector can be created
		local
			detector: CONFIG_DETECTOR
		do
			create detector.make
			-- Just verify no crash
			assert ("detector created", True)
		end

	test_detector_finds_env_var
			-- Test detection via environment variable (if set)
		local
			detector: CONFIG_DETECTOR
			ec_path: detachable PATH
			l_env: EXECUTION_ENVIRONMENT
		do
			create l_env
			create detector.make
			ec_path := detector.detect_eiffel_compiler

			-- This test passes if ISE_EIFFEL env var is set
			if attached l_env.get ("ISE_EIFFEL") then
				assert ("found compiler", ec_path /= Void)
			else
				-- No env var set, detection may or may not find it
				assert ("detection ran", True)
			end
		end

	test_detector_detect_all
			-- Test full auto-detection
		local
			detector: CONFIG_DETECTOR
			config: NOTEBOOK_CONFIG
		do
			create detector.make
			config := detector.detect_all

			-- Verify we get a valid config object
			assert ("config created", config /= Void)
			assert ("has defaults", config.timeout_seconds = 30)
		end

feature -- Test: Wizard

	test_wizard_silent
			-- Test non-interactive wizard mode
		local
			wizard: CONFIG_WIZARD
			config: NOTEBOOK_CONFIG
		do
			create wizard.make
			config := wizard.run_silent

			assert ("config created", config /= Void)
			assert ("has defaults", config.timeout_seconds = 30)
		end

end
