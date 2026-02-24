# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

## [1.2.1] - 2026-02-24

### Added
- Windows Server (RDP) guard for user-context scripts — NinjaOne's "run as logged-in user" cannot target a specific RDP session on multi-session servers, so user-centric automations now block execution on Windows Server by default.

## [1.2.0] - 2026-02-13

### Fixed
- Linux `SCRIPT_NAME` bug — NinjaOne copies scripts to temp paths, so `basename "$0"` resolved to a meaningless name. All macOS and Linux templates now hardcode `SCRIPT_NAME`.

### Added
- YAML frontmatter metadata (`author`, `version`) to all three SKILL.md files.

## [1.1.1] - 2026-02-13

### Fixed
- YAML frontmatter: quote version string (`version: "1.2.0"`) to prevent YAML parsers treating it as a float.
- Removed unsupported `tags` field from frontmatter metadata — Claude Desktop does not support it.

## [1.1.0] - 2026-02-09

### Changed
- Clarified custom fields usage and environment variable input across all platforms.
- Improved macOS privilege context description.

## [1.0.0] - 2026-02-09

### Added
- Initial release with three platform skills: PowerShell 5.1 (Windows), zsh (macOS), and bash (Linux).
- Shared RMM conventions covering non-interactive execution, security, idempotency, logging, exit codes, input validation, code review mode, and response structure.
- NinjaOne and Action1 platform support.
- README with installation guide for Claude Desktop and Claude Code.
