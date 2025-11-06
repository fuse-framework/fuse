# Specification: CLI Database & Dev Tools

## Goal
Provide essential CLI commands for database operations (migrate, rollback, seed) and development workflow (routes display, dev server, test runner) that integrate with existing Fuse components and follow established CLI conventions.

## User Stories
- As a developer, I want to run migrations from CLI so that I can manage database schema changes without web interface
- As a developer, I want to view all registered routes in readable table format so that I can verify routing configuration
- As a developer, I want to run tests from CLI with filtering options so that I can execute test suites in CI/CD environments

## Specific Requirements

**MigrateCommand - Database Migration Execution**
- Wrap `Migrator.migrate()` to execute pending migrations
- Support `--status` flag to display visual migration status (checkmarks for ran, empty for pending)
- Support `--reset` flag to call `Migrator.reset()` for full rollback
- Support `--refresh` flag to call `Migrator.refresh()` for reset then re-run
- Resolve datasource via: `--datasource` flag > `application.datasource` > "fuse" default
- Output format shows "Migrated: [filename]" per migration with summary line showing count and time
- Status output uses `[✓]` for ran, `[ ]` for pending with summary count
- Handle Migrator error structs directly, display messages array
- Validate datasource exists via test query before running operations

**RollbackCommand - Migration Rollback Control**
- Wrap `Migrator.rollback(steps)` with default steps=1
- Support `--steps=N` flag to rollback N migrations
- Support `--all` flag as alias for reset (calls `Migrator.reset()`)
- Validate steps is positive integer, throw InvalidArguments if not
- Output format shows "Rolled back: [filename]" per migration with summary
- Use same datasource resolution as MigrateCommand
- No confirmation prompts (user knows what rollback does)

**SeedCommand - Seeder System Implementation**
- Create `Seeder` base class at `fuse/orm/Seeder.cfc` with `init(datasource)`, `run()`, and `call(seederName)` methods
- By default, invoke `DatabaseSeeder.run()` from `/database/seeds/` directory
- Support `--class=SeederName` flag to run specific seeder instead
- Seeder `call()` method loads and runs another seeder by name from database.seeds package
- Seeders access datasource via `variables.datasource` set in init
- Output shows "Running [SeederName]..." per seeder called
- No seed tracking table in Phase 1 - seeders are designed to be idempotent
- Use same datasource resolution pattern as migration commands

**RoutesCommand - Route Display Utility**
- Check `application.fuse` exists, throw FrameworkNotInitialized if not
- Access router via `application.fuse.router` and call `getRoutes()` method
- Add `getRoutes()` public method to Router.cfc returning `variables.routes` array
- Display as ASCII table with columns: Method, URI, Name, Handler
- Support `--method=GET` flag to filter by HTTP method (case-insensitive)
- Support `--name=users` flag to filter by route name using contains match
- Support `--handler=Users` flag to filter by handler using contains match
- Sort output by URI alphabetically, then by method
- Column widths auto-adjust based on longest value in dataset

**ServeCommand - Development Server Wrapper**
- Wrapper around lucli's built-in `server start` command
- Default host: 127.0.0.1, default port: 8080
- Support `--host` flag to bind to different address (e.g., 0.0.0.0 for all interfaces)
- Support `--port` flag to use custom port
- Use CFML `execute()` to invoke lucli with arguments array: ["server", "start", "--host=X", "--port=Y", "--openbrowser=false"]
- Set timeout=0 for infinite run (server runs until Ctrl+C)
- Display "Starting Fuse development server..." with URL and "Press Ctrl+C to stop"

**TestCommand - Test Execution Runner**
- Use `TestDiscovery.discover()` to find all test files
- Support `--filter=pattern` flag for case-insensitive component name matching
- Support `--type=unit` flag to discover only from `/tests/unit/`
- Support `--type=integration` flag to discover only from `/tests/integration/`
- Support `--verbose` flag to display each test name with result as it runs
- Default output shows dots (.) for pass, F for failure, E for error
- Summary line shows total count, passes, failures, errors, and total time
- Display failure details showing expected vs actual
- Display error details showing message and location
- Return exit code 0 for all passed, 1 for any failures or errors

**Datasource Resolution Utility**
- Create `DatabaseConnection.cfc` in `fuse/cli/support/`
- `resolve(args)` method checks: args.datasource > application.datasource > "fuse" default
- `validate(datasource)` method tests connection with SELECT 1, throws Database.DatasourceNotFound with helpful message if fails
- All database commands (migrate, rollback, seed, test) use this utility

**Command Structure Consistency**
- All commands implement `main(required struct args)` entry point
- Parse positional arguments from `args.__arguments` array
- Parse flags directly from args struct keys
- Use `writeOutput(message & chr(10))` for console output
- Throw with structured types (InvalidArguments, Database.ConnectionFailed, etc.) and clear detail messages
- Return struct with `{success: boolean, message: string, ...additionalData}`

## Visual Design

**CLI Output Example - MigrateCommand**
```
Running pending migrations...

  Migrated: 20251106120000_CreateUsers.cfc
  Migrated: 20251106120100_CreatePosts.cfc

Migrations complete! (2 migrations, 0.45s)
```

**CLI Output Example - MigrateCommand --status**
```
Migration Status:

  [✓] 20251106120000_CreateUsers.cfc
  [✓] 20251106120100_CreatePosts.cfc
  [ ] 20251106120200_AddEmailToUsers.cfc

2 migrations run, 1 pending
```

**CLI Output Example - RoutesCommand**
```
+--------+------------------+------------------+------------------+
| Method | URI              | Name             | Handler          |
+--------+------------------+------------------+------------------+
| GET    | /users           | users_index      | Users.index      |
| POST   | /users           | users_create     | Users.create     |
| GET    | /users/new       | users_new        | Users.new        |
| GET    | /users/:id       | users_show       | Users.show       |
| GET    | /users/:id/edit  | users_edit       | Users.edit       |
| PUT    | /users/:id       | users_update     | Users.update     |
| PATCH  | /users/:id       |                  | Users.update     |
| DELETE | /users/:id       | users_destroy    | Users.destroy    |
+--------+------------------+------------------+------------------+
```

**CLI Output Example - TestCommand (default)**
```
Running tests...

....F..E............

15 tests, 13 passed, 1 failure, 1 error (2.34s)

FAILURES:

  UserTest::testValidation
    Expected: true
    Actual: false

ERRORS:

  PostTest::testCreate
    Division by zero error
    /app/models/Post.cfc:45
```

**CLI Output Example - TestCommand --verbose**
```
Running tests...

  UserTest::testCreate ... PASS (0.045s)
  UserTest::testUpdate ... PASS (0.038s)
  UserTest::testValidation ... FAIL (0.012s)
  PostTest::testCreate ... ERROR (0.002s)

15 tests, 13 passed, 1 failure, 1 error (2.34s)

[Same failure/error details as default output...]
```

**CLI Output Example - SeedCommand**
```
Seeding database...

  Running DatabaseSeeder...
  Running UserSeeder...
  Running PostSeeder...

Database seeded successfully! (0.68s)
```

## Existing Code to Leverage

**Migrator Component (fuse/orm/Migrator.cfc)**
- `migrate()` returns `{success, messages[]}` - wrap directly and format output
- `rollback(steps)` handles transaction-wrapped rollback with same return structure
- `status()` returns `{pending[], ran[]}` with migration metadata arrays
- `reset()` and `refresh()` provide advanced migration operations
- All methods discover migrations from `/database/migrations/` automatically
- Tracks migrations in `schema_migrations` table (already created by ensureMigrationsTable)

**Router Component (fuse/core/Router.cfc)**
- Routes stored in `variables.routes` array with structure: `{pattern, method, handler, name?, patternObj}`
- Named routes in `variables.namedRoutes` struct for fast lookup
- Need to add simple `getRoutes()` getter returning routes array
- Routes already sorted by registration order (correct precedence)
- Pattern uses `:param` syntax for parameters

**TestRunner Component (fuse/testing/TestRunner.cfc)**
- `run(tests)` returns `{passes[], failures[], errors[], totalTime}`
- Accepts datasource in `init(datasource)` for transaction management
- Each result array contains structs with testName, message, detail, stackTrace, time
- Distinguishes AssertionFailedException (failures) from unexpected errors
- Sequential execution with per-test transaction rollback

**TestDiscovery Component (fuse/testing/TestDiscovery.cfc)**
- `discover()` returns array of test descriptors: `{filePath, componentName, testMethods[]}`
- Accepts custom `testPath` in init (e.g., "/tests/unit" for filtering)
- Recursively scans for *Test.cfc files
- Validates components extend TestCase before including

**CLI Command Pattern (New.cfc, Generate.cfc)**
- `main(args)` entry with args.__arguments array and flag properties
- Use `writeOutput(message & chr(10))` for all console output
- Throw with type, message, detail for structured errors
- Return struct with success, message, and operation data
- Support `--silent` flag pattern for suppressing output

**NamingConventions Support (fuse/cli/support/NamingConventions.cfc)**
- `pascalize(word)` converts snake_case to PascalCase for seeder class names
- `isValidIdentifier(word)` validates command arguments
- Use for converting `--class=user_seeder` to UserSeeder component name

## Out of Scope

**Database Creation/Destruction Commands**
- No `db:create` or `db:drop` - too database-specific, defer to Phase 3
- No schema dump/load commands
- No migrate to specific version (up/down targeting)

**Advanced Seeding Features**
- No seed tracking table (designed for idempotency instead)
- No factory integration with seeds
- No CSV/JSON import utilities
- No seed rollback or versioning

**Route Management Advanced Features**
- No route caching for performance
- No route validation (checking handler methods exist)
- No JSON output format
- No middleware column (middleware not yet implemented)

**Test Runner Advanced Features**
- No ANSI color output (lucli support unclear)
- No code coverage reporting
- No parallel test execution
- No watch mode for re-running tests
- No test result caching

**Serve Command Advanced Features**
- No SSL/HTTPS support
- No custom rewrite rules
- No hot reloading configuration
- Only basic pass-through to lucli server

**Additional Dev Tools**
- No console/REPL command
- No code generation beyond existing generators
- No database seeding scaffolding generator
- No benchmark/profiling commands

**Help System**
- No `--help` flag implementation (defer to lucli help system)
- No command-specific usage documentation
- No examples in command output
