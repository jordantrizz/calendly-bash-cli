# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
