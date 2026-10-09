# Changelog

## [Unreleased] - 2026-10-08

### Fixed
- `CELL_EXECUTOR` reads process output as raw bytes (`last_output_bytes` / `accumulated_bytes`) instead of `to_string_8` of decoded text, which fails with simple_process 1.1.0.
- Compiler warning cleanup (removed unused locals in `COMPILER_ERROR` and `test_data_structures`).

