# Spec Requirements: Test Framework Foundation

## Initial Description
Create the Test Framework Foundation as outlined in roadmap item #10.

This feature involves building the core testing infrastructure for Fuse, including:
- Test framework foundation
- Test utilities and helpers
- Integration with Lucee testing capabilities

## Requirements Discussion

### First Round Questions

**Q1:** I assume you want xUnit-style testing (method-based tests in a TestCase class) like Rails/Laravel, rather than BDD-style specs (describe/it blocks) like RSpec/Jasmine. Is that correct?
**Answer:** Approved - xUnit-style testing

**Q2:** For test discovery, I'm thinking convention-based automatic discovery scanning `/tests/**/*Test.cfc` files. Should we require a specific base class (TestCase) for discovery, or discover any CFC with test methods (test*, should*, etc)?
**Answer:** Approved - Convention-based discovery (`/tests/**/*Test.cfc`)

**Q3:** I assume the TestCase base class should provide setup/teardown lifecycle methods and assertion helpers. What about test fixtures or data loading - should that be included in this foundation or saved for the Test Helpers spec (#11)?
**Answer:** Approved - Minimal TestCase base class with setup/teardown + assertions. Fixtures/factories deferred to spec #11.

**Q4:** For assertions, I'm thinking 12-15 essential methods (assertEqual, assertTrue, assertNull, assertThrows, etc) matching common patterns from Rails/PHPUnit. Should we include soft assertions (collect all failures) or stop on first failure?
**Answer:** Approved - 12-15 essential assertion methods. Stop on first failure (standard behavior).

**Q5:** I assume a sequential test runner (not parallel) for this foundation phase, with colorized console output showing pass/fail/error. Should the runner support filtering tests (by file, method name, tags)?
**Answer:** Approved - Sequential runner. Filtering deferred to future enhancements.

**Q6:** For database testing, I'm thinking automatic transaction rollback after each test method (like Rails) to keep tests isolated. Should we also provide a flag to disable rollback for specific tests (integration tests that verify commits)?
**Answer:** Approved - Automatic transaction rollback per-test. Rollback override deferred to spec #11.

**Q7:** For test output, I assume colored console reporting with Minitest-style format (dots for progress, F for failures, summary with failure details). Should we also include timing information per test or just total suite time?
**Answer:** Approved - Colored console output, Minitest-style. Just total suite time for now.

**Q8:** Is there anything that should explicitly be excluded from this foundation phase? For example: mocking/stubbing, HTTP request simulation, model factories, code coverage, parallel execution, custom reporters, etc?
**Answer:** Approved scope boundaries:
- **Foundation (this spec):** TestCase base class, assertion library, test runner, discovery, transaction rollback, console reporting
- **Deferred to spec #11 (Test Helpers):** Model factories, handler testing, HTTP request simulation, mocking/stubbing
- **Out of scope:** Code coverage, parallel execution, custom reporters (future enhancements)

### Existing Code to Reference

No similar existing features identified for reference. This is foundational testing infrastructure with no prior test framework code in Fuse.

### Follow-up Questions

None required. All clarifications received and scope clearly defined.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
Not applicable - test framework foundation does not require visual design.

## Requirements Summary

### Functional Requirements

**Core Testing Components:**
- TestCase base class providing:
  - `setup()` lifecycle method (runs before each test)
  - `teardown()` lifecycle method (runs after each test)
  - Assertion methods accessible to test methods
  - Automatic discovery/registration of test methods

**Assertion Library:**
- 12-15 essential assertion methods including:
  - `assertEqual(expected, actual, message?)` - value equality
  - `assertNotEqual(expected, actual, message?)` - value inequality
  - `assertTrue(value, message?)` - boolean true
  - `assertFalse(value, message?)` - boolean false
  - `assertNull(value, message?)` - null/undefined
  - `assertNotNull(value, message?)` - not null
  - `assertThrows(callable, exceptionType?, message?)` - exception thrown
  - `assertCount(expected, collection, message?)` - array/query size
  - `assertContains(needle, haystack, message?)` - membership test
  - `assertMatches(pattern, string, message?)` - regex match
  - Additional assertions as needed (assertEmpty, assertInstanceOf, etc)
- Stop on first assertion failure (standard xUnit behavior)
- Clear failure messages with expected vs actual values

**Test Discovery:**
- Convention-based automatic discovery
- Scan pattern: `/tests/**/*Test.cfc`
- Discover any CFC extending TestCase base class
- Discover test methods by naming convention (methods starting with `test`)
- Build registry of test files and methods to execute

**Test Runner:**
- Sequential execution (one test at a time)
- Per-test lifecycle:
  1. Instantiate test class
  2. Call setup()
  3. Call test method
  4. Call teardown()
  5. Automatic database transaction rollback
- Collect pass/fail/error results
- Continue executing remaining tests after failures

**Database Transaction Management:**
- Automatic transaction begin before each test method
- Automatic transaction rollback after each test method (success or failure)
- Ensures test isolation and clean database state
- Works with any database supporting transactions

**Console Reporting:**
- Colorized output (green=pass, red=fail, yellow=error)
- Minitest-style progress dots during execution
- Summary section showing:
  - Total tests run
  - Passes/failures/errors counts
  - Total execution time
  - Failure details with stack traces
- Format example:
  ```
  Running tests...
  .....F.....E...

  Failures:
  1) UserTest::testValidationFailsWithoutEmail
     Expected: false
     Actual: true
     at UserTest.cfc:23

  Errors:
  1) PostTest::testCreatePost
     Division by zero
     at PostTest.cfc:45

  15 tests, 13 passed, 1 failure, 1 error
  Finished in 2.34 seconds
  ```

**Integration with Fuse:**
- Test framework available as core module
- Works with existing DI container, ORM, database connections
- Respects application configuration and environment
- Can test models, handlers, services, modules

### Reusability Opportunities

No existing similar features in codebase. This is new foundational infrastructure.

Potential code patterns to establish:
- Base class pattern (TestCase) for future test helper extensions
- Component discovery pattern reusable for other auto-loading scenarios
- Console output/coloring utilities reusable for CLI commands
- Lifecycle hooks pattern (setup/teardown) consistent with existing callbacks

### Scope Boundaries

**In Scope (This Spec - Foundation):**
- TestCase base class with setup/teardown
- Assertion library (12-15 essential methods)
- Test runner with sequential execution
- Convention-based test discovery (`/tests/**/*Test.cfc`)
- Automatic database transaction rollback per-test
- Colorized console reporting (Minitest-style)
- Basic error/failure collection and reporting

**Out of Scope (Deferred to Spec #11 - Test Helpers):**
- Model factories (make/create methods)
- Handler testing helpers
- HTTP request/response simulation
- Mocking and stubbing utilities
- Test database setup/teardown automation
- Transaction rollback override flags

**Out of Scope (Future Enhancements):**
- Parallel test execution
- Test filtering (by file, method, tags)
- Code coverage reporting
- Custom output reporters (JUnit XML, JSON, etc)
- Per-test timing metrics
- Test profiling and optimization
- Watch mode / auto-rerun on file changes
- Soft assertions (collect all failures)

### Technical Considerations

**Framework Integration:**
- Leverage existing module system for test framework registration
- Use DI container for injecting test dependencies
- Access ORM models and database connections from application
- Respect environment configuration (test database, etc)

**Database Transaction Handling:**
- Must work with Lucee's transaction system
- Rollback should clean up all database changes (inserts, updates, deletes)
- Nested transaction handling (if test code uses transactions)
- Compatible with all JDBC databases supporting transactions

**Test Method Discovery:**
- Reflection/metadata inspection to find test methods
- Methods must start with "test" prefix (testUserCreation, testValidation, etc)
- Public methods only (private/package methods ignored)
- No parameters required for test methods

**Assertion Architecture:**
- Single Assertions component with all assertion methods
- Mixed into or inherited by TestCase base class
- Assertions throw exceptions on failure
- Exception contains expected/actual/message for reporting

**Error Handling:**
- Distinguish between assertion failures and unexpected errors
- Assertion failure = test failed (expected behavior didn't occur)
- Unexpected error = test error (exception thrown, code broke)
- Capture stack traces for debugging

**Console Output:**
- Use ANSI color codes for terminal coloring
- Graceful degradation if colors not supported
- Clear visual separation between progress, failures, summary
- Readable failure messages with context

**Performance Targets:**
- Test suite execution: <5s for 100 tests (from roadmap mission)
- Framework overhead: minimal per-test (<10ms setup/teardown)
- Transaction rollback: fast (<50ms per test)

**Code Organization:**
- `/fuse/modules/testing/` - Test framework module
- `/fuse/modules/testing/TestCase.cfc` - Base class
- `/fuse/modules/testing/Assertions.cfc` - Assertion library
- `/fuse/modules/testing/TestRunner.cfc` - Execution engine
- `/fuse/modules/testing/TestDiscovery.cfc` - Test finder
- `/fuse/modules/testing/TestReporter.cfc` - Console output

**Conventions Established:**
- Test files end with `Test.cfc` (UserTest.cfc, PostTest.cfc)
- Test files located in `/tests/` directory (any depth)
- Test methods start with `test` prefix
- Test classes extend `TestCase` base class
- One test class per file (matching filename)

**Rails/Laravel/Minitest Patterns:**
- xUnit-style method-based tests (not BDD specs)
- Automatic transaction rollback (Rails default)
- Minitest-style console output format
- setup/teardown lifecycle (common across all frameworks)
- Assertion library pattern (PHPUnit, Rails Minitest)
