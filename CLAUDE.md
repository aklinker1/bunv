# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Build all executables to `./zig-out/bin`: `zig build`
- Run an executable: `./zig-out/bin/bun --version`
- Release build and install to path: `zig build --release=fast --prefix ~/.bunv`

## Code Style Guidelines
- **Imports**: Standard library imports first, followed by project imports
- **Formatting**: Follow Zig standard formatting, no whitespace on blank lines
- **Types**: Use explicit types, prefer enums for related constants
- **Naming**:
  - snake_case for variables
  - camelCase for functions and enum values
  - PascalCase for structs and enums
  - one word, lowercase filenames
- **Error Handling**: Use Zig's error system, propagate errors with try
- **Memory Management**: Always free allocated memory, use defer for cleanup
- **Debug Prints**: Only use in debug mode with `if (is_debug) std.debug.print(...)`
- **Functions**: Keep functions short and focused on a single task
- **Documentation**: Add descriptive comments for public functions
- **Committing**: Commits to the `main` branch must be in conventional commit format. Commits to other branches should not be.
- **PR Titles**: Should be in conventional commit format so when they're squashed and merged, they are conventional commits on `main`.

## Development Testing
- Run debug mode with environment variable: `DEBUG=bunv zig build [binary] -- [args]`
- Test installation script: `env BUNV_INSTALL=.bunv-test curl -sL https://raw.githubusercontent.com/aklinker1/bunv/main/install.sh | sh`
