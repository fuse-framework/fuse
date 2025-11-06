# Task Breakdown: CLI Database & Dev Tools

## Overview
Total Task Groups: 5
Estimated Complexity: Small (S)
Leverage: Existing Migrator, Router, TestRunner, TestDiscovery components

## Task List

### Task Group 1: Foundation Components
**Dependencies:** None
**Complexity:** Small

- [x] 1.0 Create foundation components
  - [x] 1.1 Write 2-8 focused tests for DatabaseConnection utility
    - Test datasource resolution order (flag > application > default)
    - Test validation with valid datasource
    - Test validation throws error for invalid datasource
    - Test error message includes helpful guidance
  - [x] 1.2 Create DatabaseConnection utility (`fuse/cli/support/DatabaseConnection.cfc`)
    - `resolve(args)` method: checks args.datasource > application.datasource > "fuse" default
    - `validate(datasource)` method: tests connection with SELECT 1
    - Throw Database.DatasourceNotFound with helpful message on failure
    - Reuse pattern from TestRunner datasource handling
  - [x] 1.3 Write 2-8 focused tests for Seeder base class
    - Test init() sets datasource in variables scope
    - Test run() is overridable (abstract method pattern)
    - Test call() loads and invokes another seeder
    - Test call() passes datasource to child seeder
  - [x] 1.4 Create Seeder base class (`fuse/orm/Seeder.cfc`)
    - `init(datasource)` constructor stores datasource
    - `run()` method for override in subclasses
    - `call(seederName)` loads component from database.seeds package
    - Access datasource via variables.datasource
  - [x] 1.5 Add getRoutes() method to Router
    - Add public `getRoutes()` method to `fuse/core/Router.cfc`
    - Return variables.routes array directly
    - No tests needed (simple one-line getter)
  - [x] 1.6 Run foundation tests
    - Run ONLY the 4-16 tests written in 1.1 and 1.3
    - Verify DatabaseConnection resolution and validation
    - Verify Seeder initialization and call chain

**Acceptance Criteria:**
- DatabaseConnection tests pass (4-8 tests)
- Seeder tests pass (4-8 tests)
- Router.getRoutes() returns routes array
- All components follow existing Fuse patterns

---

### Task Group 2: Database Commands
**Dependencies:** Task Group 1
**Complexity:** Small

- [x] 2.0 Implement database CLI commands
  - [x] 2.1 Write 2-8 focused tests for MigrateCommand
    - Test basic migrate operation calls Migrator.migrate()
    - Test --status flag calls Migrator.status() and formats output
    - Test --reset flag calls Migrator.reset()
    - Test datasource resolution via DatabaseConnection
    - Test error handling for missing migrations directory
  - [x] 2.2 Create MigrateCommand (`fuse/cli/commands/Migrate.cfc`)
    - Follow New.cfc pattern with main(args) entry point
    - Default operation: call `Migrator.migrate()` and format output
    - Support --status flag: display [✓] for ran, [ ] for pending
    - Support --reset flag: call `Migrator.reset()`
    - Support --refresh flag: call `Migrator.refresh()`
    - Support --datasource flag for datasource override
    - Output format: "Migrated: [filename]" per migration with summary
    - Use DatabaseConnection.resolve() and validate()
  - [x] 2.3 Write 2-8 focused tests for RollbackCommand
    - Test basic rollback with default steps=1
    - Test --steps=N flag validates positive integer
    - Test --all flag calls Migrator.reset()
    - Test datasource resolution
  - [x] 2.4 Create RollbackCommand (`fuse/cli/commands/Rollback.cfc`)
    - Follow MigrateCommand pattern
    - Default: call `Migrator.rollback(1)`
    - Support --steps=N flag (validate positive integer)
    - Support --all flag: call `Migrator.reset()`
    - Output format: "Rolled back: [filename]" per migration
    - Use same datasource resolution as MigrateCommand
  - [x] 2.5 Write 2-8 focused tests for SeedCommand
    - Test default invokes DatabaseSeeder
    - Test --class flag runs specific seeder
    - Test error handling for missing seeder class
    - Test datasource resolution
  - [x] 2.6 Create SeedCommand (`fuse/cli/commands/Seed.cfc`)
    - Default: invoke `DatabaseSeeder.run()` from /database/seeds/
    - Support --class=SeederName flag for specific seeder
    - Use NamingConventions.pascalize() for class name formatting
    - Output shows "Running [SeederName]..." per seeder
    - Use DatabaseConnection for datasource resolution
    - Output format: "Seeding database..." with seeder names and summary
  - [x] 2.7 Run database command tests
    - Run ONLY the 6-24 tests written in 2.1, 2.3, and 2.5
    - Verify Migrator integration works correctly
    - Verify Seeder system works end-to-end
    - Do NOT run entire test suite

**Acceptance Criteria:**
- MigrateCommand tests pass (2-8 tests)
- RollbackCommand tests pass (2-8 tests)
- SeedCommand tests pass (2-8 tests)
- Commands integrate with existing Migrator
- Output matches spec examples
- Datasource resolution works consistently

---

### Task Group 3: Development Tool Commands
**Dependencies:** Task Group 1
**Complexity:** Small

- [x] 3.0 Implement development CLI commands
  - [x] 3.1 Write 2-8 focused tests for RoutesCommand
    - Test requires framework initialization (application.fuse exists)
    - Test displays routes in ASCII table format
    - Test --method filter works case-insensitively
    - Test --name filter uses contains match
    - Test sorting by URI then method
  - [x] 3.2 Create RoutesCommand (`fuse/cli/commands/Routes.cfc`)
    - Check application.fuse exists, throw FrameworkNotInitialized if not
    - Access router via application.fuse.router
    - Call router.getRoutes() to retrieve routes array
    - Display as ASCII table: Method, URI, Name, Handler columns
    - Support --method=GET flag for filtering (case-insensitive)
    - Support --name=users flag for filtering (contains match)
    - Support --handler=Users flag for filtering (contains match)
    - Sort by URI alphabetically, then by method
    - Auto-adjust column widths based on data
  - [x] 3.3 Write 2-8 focused tests for ServeCommand
    - Test default host and port (127.0.0.1:8080)
    - Test --host flag overrides default
    - Test --port flag overrides default
    - Test output displays friendly message
  - [x] 3.4 Create ServeCommand (`fuse/cli/commands/Serve.cfc`)
    - Wrapper around lucli server start command
    - Default host: 127.0.0.1, default port: 8080
    - Support --host flag for binding to different address
    - Support --port flag for custom port
    - Use CFML execute() to invoke lucli with args array
    - Set timeout=0 for infinite run
    - Output: "Starting Fuse development server..." with URL
  - [x] 3.5 Write 2-8 focused tests for TestCommand
    - Test default runs all tests using TestDiscovery
    - Test --filter flag matches component name patterns
    - Test --type=unit discovers only from /tests/unit/
    - Test --verbose flag displays detailed output
    - Test exit code 0 for passes, 1 for failures/errors
  - [x] 3.6 Create TestCommand (`fuse/cli/commands/Test.cfc`)
    - Use TestDiscovery.discover() to find test files
    - Support --filter=pattern flag (case-insensitive component name)
    - Support --type=unit flag (discover from /tests/unit/ only)
    - Support --type=integration flag (discover from /tests/integration/ only)
    - Support --verbose flag for detailed test-by-test output
    - Default output: dots (.) for pass, F for failure, E for error
    - Summary line: total count, passes, failures, errors, time
    - Display failure details: expected vs actual
    - Display error details: message and location
    - Return exit code 0 for all passed, 1 for any failures/errors
    - Use DatabaseConnection for datasource resolution
  - [x] 3.7 Run development tool tests
    - Run ONLY the 6-24 tests written in 3.1, 3.3, and 3.5
    - Verify RoutesCommand table formatting
    - Verify TestCommand filtering and output
    - Do NOT run entire test suite

**Acceptance Criteria:**
- RoutesCommand tests pass (2-8 tests)
- ServeCommand tests pass (2-8 tests)
- TestCommand tests pass (2-8 tests)
- Commands match output formats from spec
- Filtering options work correctly
- TestCommand integrates with TestRunner/TestDiscovery

---

### Task Group 4: Integration Testing
**Dependencies:** Task Groups 2, 3
**Complexity:** Small

- [x] 4.0 Integration testing and gap analysis
  - [x] 4.1 Review existing tests
    - Review foundation tests (Task 1.1, 1.3) - approximately 4-16 tests
    - Review database command tests (Task 2.1, 2.3, 2.5) - approximately 6-24 tests
    - Review dev tool tests (Task 3.1, 3.3, 3.5) - approximately 6-24 tests
    - Total existing: approximately 16-64 tests
  - [x] 4.2 Identify critical workflow gaps
    - Analyze end-to-end command workflows
    - Identify integration points between commands
    - Focus ONLY on CLI Database & Dev Tools feature scope
    - Prioritize command error handling and edge cases
  - [x] 4.3 Write up to 10 integration tests maximum
    - Test full migrate -> seed workflow
    - Test rollback after partial migration failure
    - Test routes command with empty routes
    - Test test command with no test files found
    - Test error messages are user-friendly
    - Test commands work with non-default datasource
    - Skip comprehensive edge case coverage
  - [x] 4.4 Run feature-specific tests only
    - Run ONLY tests related to CLI Database & Dev Tools
    - Expected total: approximately 26-74 tests maximum
    - Verify all commands work end-to-end
    - Verify error handling is robust
    - Do NOT run entire Fuse framework test suite

**Acceptance Criteria:**
- All feature-specific tests pass (26-74 tests total)
- Critical command workflows covered
- Error messages are clear and actionable
- Commands integrate smoothly with existing Fuse components
- No more than 10 additional integration tests added

---

### Task Group 5: Documentation
**Dependencies:** Task Groups 1-4
**Complexity:** Small

- [ ] 5.0 Create documentation
  - [ ] 5.1 Document command usage in README
    - Add CLI Database & Dev Tools section to main Fuse README
    - Document each command with examples
    - Include common flags and options
    - Reference output format examples from spec
    - Note datasource resolution pattern
  - [ ] 5.2 Create DatabaseSeeder template example
    - Create example /database/seeds/DatabaseSeeder.cfc
    - Show call() pattern for invoking other seeders
    - Include comments on idempotency best practices
    - Reference in documentation
  - [ ] 5.3 Document seeder best practices
    - Explain seeder idempotency pattern
    - Show examples of check-before-insert
    - Document call() method usage
    - Explain no seed tracking in Phase 1
  - [ ] 5.4 Add CHANGELOG entries
    - Document new CLI commands added
    - List key features: migrate, rollback, seed, routes, serve, test
    - Note new components: DatabaseConnection, Seeder
    - Reference roadmap item #13

**Acceptance Criteria:**
- README includes comprehensive CLI command documentation
- DatabaseSeeder example demonstrates best practices
- Documentation covers all commands and common use cases
- CHANGELOG reflects new features

---

## Execution Order

Recommended implementation sequence:

1. **Foundation Components** (Task Group 1) - Core utilities needed by all commands
2. **Database Commands** (Task Group 2) - Migrate, Rollback, Seed commands
3. **Development Tools** (Task Group 3) - Routes, Serve, Test commands
4. **Integration Testing** (Task Group 4) - End-to-end verification
5. **Documentation** (Task Group 5) - Usage guides and examples

## Implementation Notes

### Code Reuse Patterns

**From Existing Fuse Components:**
- MigrateCommand/RollbackCommand: Wrap `fuse/orm/Migrator.cfc` methods directly
- TestCommand: Use `fuse/testing/TestRunner.cfc` and `fuse/testing/TestDiscovery.cfc`
- RoutesCommand: Access `application.fuse.router` and call new getRoutes() method
- All commands: Follow `fuse/cli/commands/New.cfc` pattern for structure

**From CLI Generators (roadmap #12):**
- Command structure: main(args) with __arguments array
- Console output: writeOutput(message & chr(10))
- Error handling: throw with type, message, detail
- Validation: NamingConventions for identifier validation
- Return struct: {success, message, ...data}

### Testing Strategy

**Focus:** Minimal strategic tests per component (2-8 tests each)
- Test critical behaviors only
- Skip exhaustive edge case coverage
- Verify integration with existing components
- Max 10 additional integration tests at end

**Test Execution:**
- Run ONLY feature-specific tests during development
- Do NOT run entire Fuse framework test suite
- Verify critical workflows in integration phase

### Key Technical Decisions

**Datasource Resolution:** Consistent pattern across all database commands
- Command flag (--datasource) > application.datasource > "fuse" default
- Centralized in DatabaseConnection utility

**Seeder Architecture:** Rails/Laravel pattern with base class
- Programmable CFCs, not static fixtures
- call() method for seeder composition
- No seed tracking in Phase 1 (idempotent by design)

**Output Formatting:** Match spec examples exactly
- ASCII table format for routes (Laravel-style)
- Migration status with checkmarks [✓] / [ ]
- Test output with dots/F/E for pass/fail/error
- Friendly error messages with "how to fix" guidance

### Dependencies on Existing Code

**Requires:**
- `fuse/orm/Migrator.cfc` - Already complete
- `fuse/core/Router.cfc` - Need to add getRoutes() method
- `fuse/testing/TestRunner.cfc` - Already complete
- `fuse/testing/TestDiscovery.cfc` - Already complete
- `fuse/cli/support/NamingConventions.cfc` - Already complete

**Creates:**
- `fuse/cli/support/DatabaseConnection.cfc` - New utility
- `fuse/orm/Seeder.cfc` - New base class
- `fuse/cli/commands/Migrate.cfc` - New command
- `fuse/cli/commands/Rollback.cfc` - New command
- `fuse/cli/commands/Seed.cfc` - New command
- `fuse/cli/commands/Routes.cfc` - New command
- `fuse/cli/commands/Serve.cfc` - New command
- `fuse/cli/commands/Test.cfc` - New command

## Success Metrics

- All 6 CLI commands implemented and functional
- Approximately 26-74 focused tests (max)
- Commands integrate seamlessly with existing Fuse components
- Output matches spec examples
- Error messages are clear and actionable
- Documentation covers all commands with examples
