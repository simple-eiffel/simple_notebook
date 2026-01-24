# S01-PROJECT-INVENTORY.md
## simple_notebook - Interactive Eiffel Notebook

**Generation Type:** BACKWASH (reverse-engineered from implementation)
**Date:** 2026-01-23
**Source:** Implementation analysis + research/EIFFEL_NOTEBOOK_VISION.md

---

### 1. PROJECT IDENTITY

| Field | Value |
|-------|-------|
| Name | simple_notebook |
| UUID | 23C18F41-F0DD-4288-BBB0-0F6D8B264348 |
| Description | Interactive Eiffel notebook environment - execute code in cells, see results inline |
| Version | 1.0.0 |
| License | MIT License |
| Author | Claude |

### 2. PURPOSE

Provides Jupyter-style interactive notebook for Eiffel:
- Execute Eiffel code in cells
- Track variables across cells
- Accumulated class compilation model
- Save/load notebook files (.eifnb)
- Markdown cell support

### 3. DEPENDENCIES

| Library | Location | Purpose |
|---------|----------|---------|
| base | $ISE_LIBRARY/library/base/base.ecf | Core Eiffel types |
| time | $ISE_LIBRARY/library/time/time.ecf | Time tracking |
| simple_json | $SIMPLE_EIFFEL/simple_json/simple_json.ecf | Notebook serialization |
| simple_file | $SIMPLE_EIFFEL/simple_file/simple_file.ecf | File operations |
| simple_process | $SIMPLE_EIFFEL/simple_process/simple_process.ecf | Compiler execution |
| simple_uuid | $SIMPLE_EIFFEL/simple_uuid/simple_uuid.ecf | Cell IDs |
| simple_template | $SIMPLE_EIFFEL/simple_template/simple_template.ecf | Code generation |

### 4. FILE INVENTORY

| File | Class | Role |
|------|-------|------|
| src/simple_notebook.e | SIMPLE_NOTEBOOK | Main facade |
| src/notebook_engine.e | NOTEBOOK_ENGINE | Execution orchestrator |
| src/notebook.e | NOTEBOOK | Notebook data model |
| src/notebook_cell.e | NOTEBOOK_CELL | Cell container |
| src/notebook_config.e | NOTEBOOK_CONFIG | Configuration |
| src/notebook_storage.e | NOTEBOOK_STORAGE | File persistence |
| src/cell_executor.e | CELL_EXECUTOR | Compilation/execution |
| src/cell_classifier.e | CELL_CLASSIFIER | Cell type detection |
| src/accumulated_class_generator.e | ACCUMULATED_CLASS_GENERATOR | Eiffel code generation |
| src/variable_tracker.e | VARIABLE_TRACKER | Variable state tracking |
| src/variable_info.e | VARIABLE_INFO | Variable data |
| src/variable_change.e | VARIABLE_CHANGE | Change tracking |
| src/compilation_result.e | COMPILATION_RESULT | Compiler output |
| src/execution_result.e | EXECUTION_RESULT | Run output |
| src/compiler_error.e | COMPILER_ERROR | Error details |
| src/compiler_error_parser.e | COMPILER_ERROR_PARSER | Error parsing |
| src/config_detector.e | CONFIG_DETECTOR | ECF detection |
| src/config_wizard.e | CONFIG_WIZARD | Config setup |
| src/line_mapping.e | LINE_MAPPING | Source mapping |
| src/line_mapping_entry.e | LINE_MAPPING_ENTRY | Mapping entry |
| src/syntax_completeness_checker.e | SYNTAX_COMPLETENESS_CHECKER | Syntax validation |

### 5. BUILD TARGETS

| Target | Root Class | Purpose |
|--------|------------|---------|
| simple_notebook | (library) | Main library target |
| notebook_cli | NOTEBOOK_CLI | Interactive CLI |
| simple_notebook_tests | TEST_APP | Test suite |

### 6. CAPABILITIES

- Concurrency: SCOOP support
- Void Safety: Full (all)
- Assertions: Full (precondition, postcondition, check, invariant, loop)

### 7. RELATED RESEARCH

- research/EIFFEL_NOTEBOOK_VISION.md - Vision document with architecture
- design/ - Design documents
- guide/ - User guides
- plan/ - Project planning
