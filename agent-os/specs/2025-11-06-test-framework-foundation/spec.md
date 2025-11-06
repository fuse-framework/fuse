# Specification: Test Framework Foundation

## Goal
Create core testing infrastructure for Fuse with xUnit-style TestCase base class, assertion library, convention-based test discovery, sequential test runner with automatic transaction rollback, and colorized console reporting.

## User Stories
- As a developer, I want to write tests that extend TestCase and use setup/teardown lifecycle methods so that I can prepare and clean up test state automatically
- As a developer, I want to run my tests with automatic database rollback so that tests remain isolated and don't pollute each other's data

## Specific Requirements

**TestCase Base Class**
- Provide `setup()` lifecycle method called before each test method
- Provide `teardown()` lifecycle method called after each test method
- Discover test methods automatically via naming convention (methods prefixed with `test`)
- Mix in assertion methods from Assertions component for use in tests
- Track test execution state (pass/fail/error) for reporting
- Located at `/fuse/testing/TestCase.cfc`

**Assertion Library**
- Implement 12-15 essential assertion methods: `assertEqual()`, `assertNotEqual()`, `assertTrue()`, `assertFalse()`, `assertNull()`, `assertNotNull()`, `assertThrows()`, `assertCount()`, `assertContains()`, `assertNotContains()`, `assertMatches()`, `assertEmpty()`, `assertNotEmpty()`, `assertInstanceOf()`, `assertGreaterThan()`, `assertLessThan()`
- Each assertion accepts optional message parameter for custom failure messages
- Stop on first assertion failure (throw exception with expected/actual details)
- Throw `AssertionFailedException` type for test failures
- Use consistent exception detail format: "Expected: [value], Actual: [value]"
- Located at `/fuse/testing/Assertions.cfc` as mixin component

**Test Discovery**
- Scan `/tests/**/*Test.cfc` pattern recursively for test files
- Discover only CFCs that extend TestCase base class
- Identify test methods via naming convention (public methods starting with `test`)
- Build registry of discovered test files and methods
- Store metadata: file path, component name, test method names
- Located at `/fuse/testing/TestDiscovery.cfc`

**Test Runner**
- Execute tests sequentially (one at a time, no parallelism)
- For each test: instantiate test class -> call setup() -> call test method -> call teardown() -> rollback transaction
- Catch and distinguish assertion failures vs unexpected errors
- Collect test results: pass (no exception), fail (AssertionFailedException), error (any other exception)
- Continue executing remaining tests after failures/errors
- Track total execution time for entire suite
- Provide public `run()` method accepting test path or discovery results
- Located at `/fuse/testing/TestRunner.cfc`

**Database Transaction Management**
- Begin transaction before each test method execution
- Rollback transaction after each test method (regardless of pass/fail/error)
- Use Lucee's `transaction` construct with `action="begin"` and `action="rollback"`
- Wrap test execution in try/finally to ensure rollback happens
- Work with any JDBC database supporting transactions
- Rollback applies to all database operations during test execution
- Access datasource from application scope or test framework config

**Console Reporting**
- Display real-time progress dots during test execution (`.` = pass, `F` = fail, `E` = error)
- Use ANSI color codes: green for pass, red for fail, yellow for error
- Display summary section after all tests: total tests, passes, failures, errors, total time
- For failures: show test name, expected vs actual, file path and line number
- For errors: show test name, exception message, stack trace
- Format matches Minitest style with clear visual separation
- Gracefully degrade if ANSI colors not supported (detect terminal capability)
- Located at `/fuse/testing/TestReporter.cfc`

**Integration with Fuse Framework**
- Package as core testing module at `/fuse/testing/`
- Tests can access DI container for dependency injection
- Tests can use existing ORM models and database connections
- Respect application datasource configuration
- Work in test environment with test database configuration
- No module registration required (testing framework used directly, not via DI)

**Code Organization and Conventions**
- Test files end with `Test.cfc` suffix (UserTest.cfc, PostTest.cfc)
- Test files located in `/tests/` directory with any subdirectory structure
- Test methods prefix with `test` (testUserCreation, testValidation)
- Test classes extend `fuse.testing.TestCase`
- One test class per file matching filename
- Follow existing Fuse patterns: component-based architecture, clear method documentation, descriptive variable names

## Visual Design
No visual assets provided - test framework is CLI-based with console output only.

## Existing Code to Leverage

**CallbackManager.cfc pattern**
- Reuse lifecycle callback pattern for setup/teardown execution
- Follow same callback registration and execution structure
- Use similar `executeCallbacks()` approach for before/after test hooks
- Apply boolean return value pattern for halting execution

**ActiveRecord.cfc structure**
- Follow similar base class pattern with init() and method organization
- Use same metadata inspection approach via `getMetadata(this)` for discovering test methods
- Apply consistent error handling with typed exceptions
- Use similar private helper method organization

**EventService.cfc conventions**
- Follow event registration and announcement patterns for test lifecycle events
- Use similar struct-based storage for test metadata
- Apply same naming conventions for public API methods

**Existing test structure (/tests/core/)**
- Maintain parallel structure with new Fuse test framework alongside existing TestBox tests
- Tests will eventually migrate from TestBox BDD style to Fuse xUnit style
- Keep existing test organization by functional area (core, orm, etc)

**Bootstrap.cfc singleton pattern**
- Use similar thread-safe initialization for test framework components
- Apply double-checked locking if needed for test discovery caching
- Follow same application scope integration pattern

## Out of Scope
- Model factories and data fixtures (deferred to spec #11 Test Helpers)
- Handler testing helpers and HTTP request simulation (deferred to spec #11)
- Mocking and stubbing utilities (deferred to spec #11)
- Test database setup/teardown automation (deferred to spec #11)
- Transaction rollback override flags for integration tests (deferred to spec #11)
- Parallel test execution (future enhancement)
- Test filtering by file, method name, or tags (future enhancement)
- Code coverage reporting (future enhancement)
- Custom output reporters (JUnit XML, JSON formats) (future enhancement)
- Per-test timing metrics (future enhancement)
- Test profiling and optimization tools (future enhancement)
- Watch mode or auto-rerun on file changes (future enhancement)
- Soft assertions that collect all failures (future enhancement)
