# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.2] - 2025-12-12

### Added
- New `-ddd` flag for curl command debug output
- Reproducible curl command output with masked tokens at debug level 3
- Raw curl response output at debug level 3
- New `debug_curl()`, `debug_curl_command()`, `debug_curl_response()` functions in `lib/logging.sh`

### Changed
- All debug messages now display `[DEBUG]` prefix in cyan color
- Updated help message with `-ddd` option and examples
- `CALENDLY_DEBUG` config option now supports values 0, 1, 2, or 3

## [0.1.1] - 2025-12-12

### Added
- Debug/logging functionality with `-d` flag (basic debug) and `-dd` flag (verbose with masked tokens)
- New `lib/logging.sh` with `debug()`, `debug_verbose()`, `log_info()`, `log_error()`, `log_warn()` functions
- Token masking function `mask_token()` that shows only first 4 characters
- Config file permission check with warning for insecure permissions
- Support for `CALENDLY_DEBUG` config option (0, 1, or 2)

### Changed
- Config file format now uses `KEY=value` syntax (e.g., `CALENDLY_API_KEY=your_token`)
- API base URL can now be configured via `CALENDLY_API_BASE` in config or environment
- Updated help message with new options and config file documentation
- Improved error messages using logging functions

### Fixed
- API base URL is now configurable instead of hardcoded

## [0.1.0] - 2025-12-12

### Added
- Initial project structure and CLI framework
- Authentication via `CALENDLY_API_KEY` environment variable or `~/.calendly` config file
- Core API request functions with Bearer token authentication
- `calendly auth test` command to verify authentication
- `calendly auth user` command to display current user information
- `calendly help` and `calendly version` commands
- Dependency checking for `curl` and `jq`
- README with installation and usage instructions
- Example configuration file
