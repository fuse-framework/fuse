# Fuse Framework Tests

## Running Tests

### Via CommandBox Server

Start server:
```bash
box server start
```

Run tests:
```bash
curl "http://localhost:{port}/tests/text-runner.cfm"
```

Or visit in browser: `http://localhost:{port}/tests/runner.cfm`

Stop server:
```bash
box server stop
```

### Via CommandBox CLI

```bash
box testbox run
```

## Test Structure

- `/tests/core/` - Core framework tests (Container, Config, etc.)
- `/tests/fixtures/` - Test fixtures and mock objects
- `/tests/runner.cfm` - HTML test runner
- `/tests/text-runner.cfm` - Text-based test runner
- `/tests/Application.cfc` - Test application configuration

## Test Coverage

### Task Group 1: DI Container Foundation (Complete)
- Singleton vs transient binding/resolution
- Constructor injection with dependencies
- Property injection via inject metadata
- Circular dependency detection
- Missing dependency error handling
- Closure-based bindings
- Container passing to factory closures

**Status:** 8/8 tests passing
