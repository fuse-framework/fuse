# Task Breakdown: Test Framework Foundation

## Overview
Total Tasks: 23 core implementation tasks
Foundation phase - minimal testing infrastructure for Fuse framework with xUnit-style tests, assertions, discovery, sequential runner, transaction rollback, and colorized console output.

## Task List

### Foundation Layer: Assertions & Base Classes

#### Task Group 1: Assertion Library
**Dependencies:** None

- [x] 1.0 Complete Assertions.cfc component
  - [x] 1.1 Create `/fuse/testing/Assertions.cfc` with component structure
    - Reference ActiveRecord.cfc for base component patterns
    - Implement init() method
    - Add descriptive header comment with usage examples
  - [x] 1.2 Implement 15 core assertion methods
    - `assertEqual(expected, actual, message?)` - equality check
    - `assertNotEqual(expected, actual, message?)` - inequality check
    - `assertTrue(value, message?)` - boolean true check
    - `assertFalse(value, message?)` - boolean false check
    - `assertNull(value, message?)` - null check
    - `assertNotNull(value, message?)` - not null check
    - `assertThrows(callable, exceptionType?, message?)` - exception thrown
    - `assertCount(expected, collection, message?)` - array/query size
    - `assertContains(needle, haystack, message?)` - membership test
    - `assertNotContains(needle, haystack, message?)` - non-membership test
    - `assertMatches(pattern, string, message?)` - regex match
    - `assertEmpty(value, message?)` - empty check
    - `assertNotEmpty(value, message?)` - not empty check
    - `assertInstanceOf(expected, actual, message?)` - type check
    - `assertGreaterThan(expected, actual, message?)` - numeric comparison
    - `assertLessThan(expected, actual, message?)` - numeric comparison
  - [x] 1.3 Create custom exception type AssertionFailedException
    - Define in Assertions.cfc or separate component
    - Include expected/actual/message fields
    - Format: "Expected: [value], Actual: [value] - [message]"
  - [x] 1.4 Write 5-8 focused tests for Assertions.cfc
    - Test only critical assertion behaviors (1-2 tests per category):
      - Equality assertions (assertEqual, assertNotEqual)
      - Boolean assertions (assertTrue, assertFalse)
      - Null assertions (assertNull, assertNotNull)
      - Exception handling (assertThrows)
      - Collection assertions (assertCount, assertContains)
    - Limit to 5-8 tests maximum
    - Skip exhaustive edge case testing
  - [x] 1.5 Ensure assertion tests pass
    - Run ONLY the 5-8 tests written in 1.4
    - Verify assertion methods work correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Assertions.cfc implements all 15 assertion methods
- AssertionFailedException thrown on failure with clear message
- The 5-8 tests written in 1.4 pass
- Each assertion stops on first failure

#### Task Group 2: TestCase Base Class
**Dependencies:** Task Group 1 (needs Assertions)

- [x] 2.0 Complete TestCase.cfc base class
  - [x] 2.1 Create `/fuse/testing/TestCase.cfc` component structure
    - Reference ActiveRecord.cfc for base class patterns
    - Follow CallbackManager pattern for lifecycle hooks
    - Add descriptive header with usage examples
  - [x] 2.2 Implement init() method
    - Accept optional datasource parameter
    - Initialize variables scope
    - Mix in Assertions component methods
  - [x] 2.3 Add lifecycle hook methods
    - `setup()` - empty default implementation, overrideable
    - `teardown()` - empty default implementation, overrideable
    - Document that subclasses override these methods
  - [x] 2.4 Implement test method discovery
    - Create `getTestMethods()` method
    - Use `getMetadata(this)` to introspect methods (follow ActiveRecord pattern)
    - Find public methods starting with "test" prefix
    - Return array of method name strings
  - [x] 2.5 Mix in assertion methods from Assertions.cfc
    - Use mixin pattern to expose assertions in test classes
    - Consider: extend Assertions vs include() vs delegation
    - Ensure all 15 assertions available in test methods
  - [x] 2.6 Write 5-8 focused tests for TestCase.cfc
    - Test only critical TestCase behaviors:
      - Test method discovery (1-2 tests)
      - Setup/teardown execution order (1-2 tests)
      - Assertion access in tests (1-2 tests)
      - Metadata introspection (1 test)
    - Limit to 5-8 tests maximum
    - Use existing assertion methods to validate
  - [x] 2.7 Ensure TestCase tests pass
    - Run ONLY the 5-8 tests written in 2.6
    - Verify lifecycle hooks and method discovery work
    - Do NOT run entire test suite

**Acceptance Criteria:**
- TestCase provides setup() and teardown() hooks
- getTestMethods() discovers all test* methods
- Assertion methods available in test classes
- The 5-8 tests written in 2.6 pass

### Core Infrastructure: Discovery & Execution

#### Task Group 3: Test Discovery
**Dependencies:** Task Group 2 (needs TestCase)

- [x] 3.0 Complete TestDiscovery.cfc component
  - [x] 3.1 Create `/fuse/testing/TestDiscovery.cfc` component structure
    - Reference ActiveRecord metadata inspection patterns
    - Add descriptive header comment
  - [x] 3.2 Implement init() method
    - Accept testPath parameter (defaults to "/tests")
    - Initialize registry storage
  - [x] 3.3 Build file discovery with DirectoryList()
    - Scan recursively: `/tests/**/*Test.cfc`
    - Use filter="*.cfc" and recurse=true
    - Return array of absolute file paths
  - [x] 3.4 Implement component instantiation check
    - For each file, attempt to createObject("component", path)
    - Check if extends fuse.testing.TestCase (via getMetadata)
    - Skip non-TestCase CFCs
    - Handle instantiation errors gracefully
  - [x] 3.5 Build test registry structure
    - Create `discover()` method returning array of structs
    - Each struct: {filePath, componentName, testMethods[]}
    - Use TestCase.getTestMethods() to discover test methods
    - Store complete registry for runner consumption
  - [x] 3.6 Write 4-6 focused tests for TestDiscovery.cfc
    - Test only critical discovery behaviors:
      - File pattern matching (1 test)
      - TestCase filtering (1 test)
      - Test method discovery (1-2 tests)
      - Registry structure (1 test)
    - Limit to 4-6 tests maximum
    - Create fixture test files for testing
  - [x] 3.7 Ensure discovery tests pass
    - Run ONLY the 4-6 tests written in 3.6
    - Verify discovery finds all test files
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Discovers all *Test.cfc files in /tests recursively
- Filters to only TestCase subclasses
- Builds registry with file paths and test method names
- The 4-6 tests written in 3.6 pass

#### Task Group 4: Test Runner with Transaction Management
**Dependencies:** Task Group 3 (needs TestDiscovery)

- [x] 4.0 Complete TestRunner.cfc component
  - [x] 4.1 Create `/fuse/testing/TestRunner.cfc` component structure
    - Add descriptive header comment with usage
    - Reference CallbackManager execution patterns
  - [x] 4.2 Implement init() method
    - Accept datasource parameter
    - Initialize result storage: passes[], failures[], errors[]
    - Track total execution time
  - [x] 4.3 Implement run() method accepting test registry
    - Accept array of test descriptors from TestDiscovery
    - Loop through each test file sequentially
    - Return results struct: {passes, failures, errors, totalTime}
  - [x] 4.4 Build per-test execution lifecycle
    - For each test method:
      1. Begin database transaction
      2. Instantiate test class
      3. Call setup()
      4. Call test method
      5. Call teardown()
      6. Rollback transaction (in finally block)
    - Use try/catch/finally for transaction guarantee
  - [x] 4.5 Implement transaction management with Lucee syntax
    - Use `transaction action="begin" { }` before test
    - Use `transaction action="rollback" { }` in finally block
    - Access datasource from init() parameter or application scope
    - Ensure rollback happens even on exceptions
  - [x] 4.6 Add exception handling and result collection
    - Try/catch around test method execution
    - Catch AssertionFailedException -> record as failure
    - Catch any other exception -> record as error
    - Store: testName, message, expected/actual (failures), stackTrace
    - Continue executing remaining tests after failures
  - [x] 4.7 Write 5-8 focused tests for TestRunner.cfc
    - Test only critical runner behaviors:
      - Sequential execution (1 test)
      - Transaction rollback (1-2 tests)
      - Exception handling (1-2 tests)
      - Result collection (1-2 tests)
    - Limit to 5-8 tests maximum
    - Create fixture tests that intentionally fail/error
  - [x] 4.8 Ensure runner tests pass
    - Run ONLY the 5-8 tests written in 4.7
    - Verify transaction rollback works
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Executes tests sequentially with full lifecycle
- Begins transaction before each test, rolls back after
- Distinguishes assertion failures from unexpected errors
- Continues execution after failures
- The 5-8 tests written in 4.7 pass

### Reporting Layer: Console Output

#### Task Group 5: Console Reporter
**Dependencies:** Task Group 4 (needs TestRunner results)

- [x] 5.0 Complete TestReporter.cfc component
  - [x] 5.1 Create `/fuse/testing/TestReporter.cfc` component structure
    - Add descriptive header comment
  - [x] 5.2 Implement init() method
    - Detect ANSI color support (check terminal capability)
    - Store color codes as variables
    - Green: chr(27) & "[32m"
    - Red: chr(27) & "[31m"
    - Yellow: chr(27) & "[33m"
    - Reset: chr(27) & "[0m"
  - [x] 5.3 Build real-time progress output
    - Create `reportProgress(status)` method
    - Output: "." for pass, "F" for fail, "E" for error
    - Use writeOutput() without newline
    - Apply colors: green dot, red F, yellow E
  - [x] 5.4 Build summary report formatter
    - Create `reportSummary(results)` method
    - Accept results struct from TestRunner
    - Format Minitest-style output:
      ```

      Failures:
      1) TestName::methodName
         Expected: X, Actual: Y
         at /path/to/file.cfc:123

      15 tests, 13 passed, 1 failure, 1 error
      Finished in 2.34 seconds
      ```
  - [x] 5.5 Implement failure detail formatter
    - Show test name with :: separator
    - Show expected vs actual values
    - Show file path and line number from stack trace
    - Apply red color to failure section
  - [x] 5.6 Implement error detail formatter
    - Show test name with :: separator
    - Show exception message
    - Show abbreviated stack trace (top 5 frames)
    - Apply yellow color to error section
  - [x] 5.7 Add color fallback for non-ANSI terminals
    - Detect if terminal supports colors
    - Strip ANSI codes if not supported
    - Maintain readable plain text output
  - [x] 5.8 Write 3-5 focused tests for TestReporter.cfc
    - Test only critical reporter behaviors:
      - Progress output format (1 test)
      - Summary format (1 test)
      - Failure/error formatting (1-2 tests)
    - Limit to 3-5 tests maximum
    - Verify output structure, not exact formatting
  - [x] 5.9 Ensure reporter tests pass
    - Run ONLY the 3-5 tests written in 5.8
    - Verify output format matches Minitest style
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Real-time progress dots with colors
- Minitest-style summary with failure/error details
- Graceful ANSI color fallback
- The 3-5 tests written in 5.8 pass

### Integration & Validation

#### Task Group 6: End-to-End Integration
**Dependencies:** Task Groups 1-5

- [x] 6.0 Complete integration and validate full test framework
  - [x] 6.1 Create example test suite in `/tests/examples/`
    - ExampleUserTest.cfc with passing tests
    - ExampleValidationTest.cfc with intentional failure
    - ExampleErrorTest.cfc with intentional error
    - Demonstrate setup/teardown, assertions, database rollback
  - [x] 6.2 Create test runner entry point script
    - `/fuse/testing/run.cfm` or CLI script
    - Instantiate TestDiscovery, TestRunner, TestReporter
    - Wire components together
    - Execute full pipeline: discover → run → report
  - [x] 6.3 Test database transaction rollback end-to-end
    - Create test that inserts record
    - Verify record does NOT persist after test
    - Confirm rollback works with actual database
    - Test with multiple databases (H2, MySQL, PostgreSQL)
  - [x] 6.4 Review and fill critical test gaps (maximum 10 additional tests)
    - Review existing tests from Task Groups 1-5 (approximately 22-35 tests)
    - Identify critical integration gaps for THIS feature only
    - Add maximum 10 new integration tests if needed:
      - Full pipeline execution (discovery → run → report)
      - Cross-component interactions
      - Transaction isolation between tests
      - Error propagation through layers
    - Focus on end-to-end workflows, not unit coverage
    - Skip edge cases unless business-critical
  - [x] 6.5 Run feature-specific tests only
    - Run ONLY tests related to test framework feature
    - Expected total: approximately 32-45 tests maximum
    - Verify all critical workflows pass
    - Do NOT run entire application test suite
  - [x] 6.6 Manual validation of console output
    - Run example test suite
    - Verify colorized output displays correctly
    - Confirm progress dots appear in real-time
    - Check failure/error formatting matches spec
  - [x] 6.7 Update documentation
    - Add usage examples to `/fuse/testing/README.md`
    - Document test file conventions (*Test.cfc, test* methods)
    - Show setup/teardown usage
    - List all 15 assertion methods with examples
    - Explain transaction rollback behavior

**Acceptance Criteria:**
- Example tests run successfully through full pipeline
- Database transactions roll back correctly
- Console output matches Minitest style with colors
- All feature-specific tests pass (approximately 32-45 tests)
- No more than 10 additional integration tests added
- Documentation complete and accurate

## Execution Order

Recommended implementation sequence:
1. Foundation Layer (Task Groups 1-2): Build assertions and base class
2. Core Infrastructure (Task Groups 3-4): Build discovery and runner with transactions
3. Reporting Layer (Task Group 5): Build console reporter
4. Integration & Validation (Task Group 6): Wire everything together and validate

## Important Notes

**Test Framework Self-Testing:**
- Framework uses itself for testing (bootstrap problem)
- Initial tests may use simple assertions before full framework available
- Consider temporary test harness for validating core components
- Full self-hosted testing available after Task Group 2 complete

**Transaction Management:**
- Use Lucee's `transaction` construct with action="begin" and action="rollback"
- Datasource resolution: init parameter → application scope → default "fuse"
- Ensure rollback in finally block to handle all exceptions
- Test with H2 (dev), MySQL, and PostgreSQL for compatibility

**Existing Fuse Patterns:**
- Follow ActiveRecord.cfc metadata introspection approach
- Follow CallbackManager.cfc registration/execution patterns
- Use consistent component structure and documentation style
- Reference existing error handling with typed exceptions

**Code Organization:**
- All test framework code in `/fuse/testing/` directory
- Keep components focused and single-responsibility
- Use descriptive method names and clear comments
- Follow existing Fuse naming conventions (camelCase methods, PascalCase components)

**Testing Strategy:**
- Each task group writes 3-8 focused tests maximum during development
- Tests verify only critical behaviors, not exhaustive coverage
- Task 6.4 adds maximum 10 integration tests to fill gaps
- Final test count: approximately 32-45 tests for entire feature
- Run only feature-specific tests, not entire application suite

**Minitest Output Format Reference:**
```
Running tests...
.....F.....E...

Failures:
1) UserTest::testValidationFailsWithoutEmail
   Expected: false
   Actual: true
   at /tests/UserTest.cfc:23

Errors:
1) PostTest::testCreatePost
   Division by zero
   at /tests/PostTest.cfc:45

15 tests, 13 passed, 1 failure, 1 error
Finished in 2.34 seconds
```
