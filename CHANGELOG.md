# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.4] - 2025-12-12

### Added
- New `webhooks test` command to send test webhook payloads to a URL
- Simulates Calendly's webhook payload structure for testing webhook receivers
- Supports `--url` (required) and `--event` (optional, defaults to `invitee.created`) options
- Test payloads include realistic data structure matching Calendly's documented format

## [0.2.3] - 2025-12-12

### Fixed
- `webhooks list` now correctly displays webhooks (fixed URL encoding issue with trailing newline)

## [0.2.2] - 2025-12-12

### Added
- New `webhooks events` command to list available webhook event types
- Shows descriptions for each event: `invitee.created`, `invitee.canceled`, `routing_form_submission.created`

## [0.2.1] - 2025-12-12

### Changed
- Warning messages now display `[WARN]` prefix in yellow color
- `webhooks list` now shows both organization-scoped and user-scoped webhooks in separate sections

## [0.2.0] - 2025-12-12

### Added
- New `events` command with subcommands: `list`, `get`, `invitees`
- New `webhooks` command with subcommands: `list`, `create`, `delete`
- `lib/events.sh` for event-related functions
- `lib/webhooks.sh` for webhook-related functions
- `calendly events list` - List scheduled events for current user
- `calendly events get <uuid>` - Get details of a specific event
- `calendly events invitees <uuid>` - List invitees for an event
- `calendly webhooks list` - List webhook subscriptions for organization
- `calendly webhooks create --url URL --events EVENTS` - Create webhook subscription
- `calendly webhooks delete <uuid>` - Delete a webhook subscription

### Changed
- Updated help message with new commands and examples

## [0.1.3] - 2025-12-12

### Fixed
- Debug output now displays correctly when using `-ddd` flag
- Removed `2>&1` stderr capture in `verify_auth()` that was swallowing debug messages

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
