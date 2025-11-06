# Spec Requirements: CLI Database & Dev Tools

## Initial Description
Implement essential database and development CLI commands for Fuse framework: MigrateCommand, RollbackCommand, SeedCommand, RoutesCommand, ServeCommand, and TestCommand. These commands integrate with existing Fuse components (Migrator, Router, TestRunner) and follow lucli module conventions established in roadmap #12.

## Research Findings

### Existing Fuse Components

**Migrator (`fuse/orm/Migrator.cfc`):**
- Methods: `migrate()`, `rollback(steps)`, `status()`, `reset()`, `refresh()`
- Returns structs with `{success, messages[]}` format
- Tracks migrations in `schema_migrations` table
- Discovers migrations from `/database/migrations/` directory
- Transaction-wrapped with detailed error messages
- Already handles all core migration operations

**Router (`fuse/core/Router.cfc`):**
- Stores routes in `variables.routes` array
- Route structure: `{pattern, method, handler, patternObj, name?}`
- Named routes stored in `variables.namedRoutes` struct
- Supports resource routes with `resource()` method
- Route patterns use `:param` syntax for parameters

**TestRunner (`fuse/testing/TestRunner.cfc`):**
- Methods: `run(tests)` returns `{passes[], failures[], errors[], totalTime}`
- Requires TestDiscovery to find tests first
- Supports datasource injection for transaction management
- Distinguishes assertion failures from errors
- Sequential execution with transaction rollback per test

**CLI Command Pattern (from roadmap #12):**
- CFCs in `fuse/cli/commands/` with `main(args)` function
- Args structure: `{__arguments: [], ...flags}`
- Support components in `fuse/cli/support/`
- Console output via `writeOutput()` with newlines
- Error handling via throw() with type/message/detail

### Reference Framework Patterns

**Rails rake db:**
- `rake db:migrate` - Run pending migrations
- `rake db:rollback STEP=3` - Rollback N migrations
- `rake db:migrate:status` - Show migration status table
- `rake db:reset` - Drop, create, migrate, seed
- `rake db:seed` - Load seed data from `db/seeds.rb`
- Output: Timestamped migration names with up/down status

**Laravel artisan:**
- `artisan migrate` - Run migrations
- `artisan migrate:rollback --step=3` - Rollback with steps
- `artisan migrate:status` - Table format: Ran?, Migration, Batch
- `artisan db:seed --class=UserSeeder` - Run specific seeder
- `artisan route:list` - Table with Method, URI, Name, Action
- `artisan serve --host=0.0.0.0 --port=8000` - Dev server
- `artisan test --filter=UserTest` - Run tests with filtering

**Django manage.py:**
- `manage.py migrate` - Apply migrations
- `manage.py migrate --fake` - Mark migrations as run without executing
- `manage.py showmigrations` - List migrations with [X] for applied
- `manage.py loaddata fixture.json` - Load seed data
- `manage.py runserver 0.0.0.0:8000` - Dev server
- `manage.py test --pattern="test_*.py"` - Test discovery patterns

## Command Structure Decisions

### Architecture Consistency
Follow CLI Generators pattern (roadmap #12):
- CFML modules in `fuse/cli/commands/`
- Each command is CFC with `main(required struct args)` function
- Args parsing: `args.__arguments` array + flag properties
- Console output via `writeOutput(message & chr(10))`
- Error handling via throw() with structured types
- Help text via `--help` flag or no arguments

### Command Naming
Use single-word verbs matching Rails/Laravel conventions:
- `migrate` (not `db:migrate` - simpler for CFML)
- `rollback` (separate command, clearer intent)
- `seed` (future-focused naming)
- `routes` (plural noun, standard across frameworks)
- `serve` (not `server start` - lucli handles that)
- `test` (not `tests` - verb form)

### File Organization
```
/fuse/cli/commands/
  Migrate.cfc
  Rollback.cfc
  Seed.cfc
  Routes.cfc
  Serve.cfc
  Test.cfc
```

No subdirectories needed - flat structure cleaner for small command count.

## MigrateCommand Features

### Core Operations
Leverage existing `Migrator` component:
- `lucli migrate` - Run pending migrations (calls `migrator.migrate()`)
- `lucli migrate --status` - Show migration status (calls `migrator.status()`)
- `lucli migrate --reset` - Reset all migrations (calls `migrator.reset()`)
- `lucli migrate --refresh` - Reset and re-run (calls `migrator.refresh()`)

### Output Format
```
Running pending migrations...

  Migrated: 20251106120000_CreateUsers.cfc
  Migrated: 20251106120100_CreatePosts.cfc

Migrations complete! (2 migrations, 0.45s)
```

Status output:
```
Migration Status:

  [✓] 20251106120000_CreateUsers.cfc
  [✓] 20251106120100_CreatePosts.cfc
  [ ] 20251106120200_AddEmailToUsers.cfc

2 migrations run, 1 pending
```

### Datasource Resolution
Follow TestRunner pattern:
1. Check for `--datasource=name` flag
2. Fall back to `application.datasource` if available
3. Default to "fuse" datasource
4. Throw clear error if datasource not found in Lucee admin

### Error Handling
- Migration failures: Display Migrator error messages directly
- Missing migrations directory: "No migrations directory found at /database/migrations/"
- No datasource: "Datasource 'name' not found. Configure in Lucee admin or use --datasource flag"
- Transaction rollback: Migrator handles this, just report failure

## RollbackCommand Features

### Core Operations
Wrap `Migrator.rollback(steps)`:
- `lucli rollback` - Rollback last migration (default steps=1)
- `lucli rollback --steps=3` - Rollback N migrations
- `lucli rollback --all` - Rollback all (calls `migrator.reset()`)

### Output Format
```
Rolling back migrations...

  Rolled back: 20251106120200_AddEmailToUsers.cfc
  Rolled back: 20251106120100_CreatePosts.cfc

Rollback complete! (2 migrations, 0.32s)
```

### Validation
- Ensure steps is positive integer
- Warn if steps exceeds run migrations count
- Confirm for `--all` flag: "This will rollback all migrations. Continue? (y/n)"

## Seed System Design

### Architecture Decision
Follow Rails/Laravel pattern with seeder classes, NOT Django fixtures:

**Rationale:**
- Seeder CFCs are programmable (loops, conditionals, logic)
- Type-safe: IDE autocomplete, compile-time checks
- Reusable: Call seeders from tests or other seeders
- Flexible: Generate fake data, import CSVs, call APIs
- CFML-native: No JSON/XML parsing overhead

### File Structure
```
/database/seeds/
  DatabaseSeeder.cfc        # Main entry point
  UserSeeder.cfc            # Specific seeders
  PostSeeder.cfc

/fuse/orm/
  Seeder.cfc                # Base class (new component)
```

### Seeder Base Class
```cfml
// fuse/orm/Seeder.cfc
component {
    public function init(required string datasource) {
        variables.datasource = arguments.datasource;
        return this;
    }

    public void function run() {
        // Override in subclasses
    }

    public void function call(required string seederName) {
        // Load and run another seeder
        var seeder = createObject("component", "database.seeds.#arguments.seederName#")
            .init(variables.datasource);
        seeder.run();
    }
}
```

### DatabaseSeeder Pattern
```cfml
// database/seeds/DatabaseSeeder.cfc
component extends="fuse.orm.Seeder" {
    public void function run() {
        // Call specific seeders in order
        this.call("UserSeeder");
        this.call("PostSeeder");
    }
}
```

### UserSeeder Example
```cfml
// database/seeds/UserSeeder.cfc
component extends="fuse.orm.Seeder" {
    public void function run() {
        // Create users using ActiveRecord
        var User = new app.models.User(variables.datasource);

        User.create({
            name: "Admin User",
            email: "admin@example.com",
            role: "admin"
        });

        User.create({
            name: "Test User",
            email: "test@example.com",
            role: "user"
        });
    }
}
```

### SeedCommand Features
- `lucli seed` - Run DatabaseSeeder (default)
- `lucli seed --class=UserSeeder` - Run specific seeder
- `lucli seed --reset` - Reset database then seed (migrate:refresh + seed)

### Seed Tracking
**Decision:** No tracking in Phase 1 (roadmap #13 is "S" scope)

**Rationale:**
- Seeds are idempotent by design (developers ensure this)
- Seeds run manually, not automatically like migrations
- Tracking adds complexity (new table, state management)
- Can be added in future phase if needed

**Best Practice Guidance:**
- Document in README: Make seeds idempotent (check before insert)
- Use `User::where({email: "admin@example.com"}).first() ?: User::create(...)`
- Or truncate tables at start of seeder for clean slate

### SeedCommand Output
```
Seeding database...

  Running DatabaseSeeder...
  Running UserSeeder... (2 records)
  Running PostSeeder... (10 records)

Database seeded successfully! (12 records, 0.68s)
```

## RoutesCommand Design

### Output Format
Follow Laravel `route:list` table format - most readable:

```
+--------+------------------+------------------+------------------+
| Method | URI              | Name             | Handler          |
+--------+------------------+------------------+------------------+
| GET    | /users           | users_index      | Users.index      |
| POST   | /users           | users_create     | Users.create     |
| GET    | /users/new       | users_new        | Users.new        |
| GET    | /users/:id       | users_show       | Users.show       |
| GET    | /users/:id/edit  | users_edit       | Users.edit       |
| PUT    | /users/:id       | users_update     | Users.update       |
| PATCH  | /users/:id       |                  | Users.update     |
| DELETE | /users/:id       | users_destroy    | Users.destroy    |
| GET    | /posts           | posts_index      | Posts.index      |
+--------+------------------+------------------+------------------+
```

### Implementation
Access router from application scope:
```cfml
// Migrate.cfc main()
if (!structKeyExists(application, "fuse")) {
    throw(
        type = "FrameworkNotInitialized",
        message = "Fuse framework not initialized",
        detail = "Run 'lucli serve' or access app in browser first"
    );
}

var router = application.fuse.router;
var routes = router.getRoutes(); // Need to add this method to Router
```

### Router Enhancement Needed
Add public getter to Router.cfc:
```cfml
public array function getRoutes() {
    return variables.routes;
}
```

### Filtering Options
- `lucli routes` - Show all routes
- `lucli routes --method=GET` - Filter by HTTP method
- `lucli routes --name=users` - Filter by route name (contains)
- `lucli routes --handler=Users` - Filter by handler (contains)

### Output Details
- Sort by URI then method (consistent ordering)
- Align columns for readability
- Empty name shows as blank (not "N/A")
- Show parameter syntax `:id` in URI column

## ServeCommand Approach

### Decision: Wrapper Around lucli server
Provide convenience command that delegates to lucli's built-in server:

**Rationale:**
- lucli already has robust server implementation (Java-based)
- No need to duplicate HTTP server code in CFML
- Consistent with Rails/Laravel (artisan serve wraps PHP built-in server)
- Simple pass-through with Fuse-friendly defaults

### Implementation
```cfml
// Serve.cfc
public struct function main(required struct args) {
    var host = structKeyExists(args, "host") ? args.host : "127.0.0.1";
    var port = structKeyExists(args, "port") ? args.port : "8080";

    writeOutput("Starting Fuse development server..." & chr(10));
    writeOutput("Server running at http://#host#:#port#" & chr(10));
    writeOutput("Press Ctrl+C to stop" & chr(10) & chr(10));

    // Delegate to lucli server
    execute(
        name = "lucli",
        arguments = ["server", "start", "--host=#host#", "--port=#port#", "--openbrowser=false"],
        timeout = 0, // Infinite - server runs until stopped
        variable = "serverOutput"
    );

    return {success: true, message: "Server stopped"};
}
```

### Alternative: Direct Invocation
User can still use `lucli server start` directly - ServeCommand just adds convenience and Fuse branding.

### Features
- `lucli serve` - Start on 127.0.0.1:8080 (Fuse defaults)
- `lucli serve --host=0.0.0.0` - Bind to all interfaces
- `lucli serve --port=3000` - Custom port
- `lucli serve --open` - Open browser after start

### Output
```
Starting Fuse development server...
Server running at http://127.0.0.1:8080
Press Ctrl+C to stop

[lucli server output follows...]
```

## TestCommand Features

### Core Operations
Leverage existing TestRunner + TestDiscovery:
- `lucli test` - Run all tests
- `lucli test --filter=UserTest` - Run tests matching pattern
- `lucli test --type=unit` - Run only unit tests
- `lucli test --type=integration` - Run only integration tests
- `lucli test --verbose` - Show individual test names as they run

### Implementation Pattern
```cfml
// Test.cfc main()
var discovery = new fuse.testing.TestDiscovery();
var tests = discovery.discover();

// Filter tests based on flags
if (structKeyExists(args, "filter")) {
    tests = filterTests(tests, args.filter);
}

var runner = new fuse.testing.TestRunner(
    datasource = resolveDatasource(args)
);
var results = runner.run(tests);

// Format and display results
displayResults(results);
```

### Output Format (Default)
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

### Output Format (Verbose)
```
Running tests...

  UserTest::testCreate ... PASS (0.045s)
  UserTest::testUpdate ... PASS (0.038s)
  UserTest::testValidation ... FAIL (0.012s)
  PostTest::testCreate ... ERROR (0.002s)
  PostTest::testUpdate ... PASS (0.041s)

15 tests, 13 passed, 1 failure, 1 error (2.34s)

[Same failure/error details...]
```

### Test Filtering
Pattern matching against component name:
- `--filter=User` matches `UserTest`, `UserServiceTest`
- `--filter=UserTest` matches only `UserTest`
- Case-insensitive matching
- Use `findNoCase()` on component name

Type filtering by directory:
- `--type=unit` discovers only from `/tests/unit/`
- `--type=integration` discovers only from `/tests/integration/`
- Default: Discover from both

### Exit Codes
- 0: All tests passed
- 1: Test failures or errors
- Follow Unix convention for CI/CD integration

### Color Support (Future Enhancement)
Defer to Phase 2 - requires ANSI color code support in lucli output.
Phase 1: Plain text output only.

## Scope & Priorities

### MUST HAVE (Phase 1 - Roadmap #13)

**MigrateCommand:**
- Basic migrate operation
- `--status` flag for migration status
- `--reset` flag to rollback all
- `--refresh` flag to reset + migrate
- Datasource resolution
- Clear error messages

**RollbackCommand:**
- Basic rollback (default 1 step)
- `--steps=N` flag
- `--all` flag as alias for reset
- Confirmation prompt for --all

**SeedCommand:**
- Seeder base class
- DatabaseSeeder pattern
- Run default or specific seeder
- `--class` flag for specific seeder
- Basic output (seeder names + record counts)

**RoutesCommand:**
- Table format output
- All route data (method, URI, name, handler)
- Basic filtering (method, name, handler)
- Framework initialization check

**ServeCommand:**
- Wrapper around lucli server
- Host/port configuration
- Friendly output with Fuse branding

**TestCommand:**
- Run all tests
- Basic test filtering (--filter)
- Type filtering (--type=unit/integration)
- Verbose output flag
- Pass/fail/error counts
- Exit codes for CI

### NICE TO HAVE (Phase 2)

**MigrateCommand:**
- `--pretend` flag (show SQL without executing)
- `--force` flag (run in production without prompt)
- Batch tracking (group migrations by run)

**SeedCommand:**
- `--reset` flag (reset database then seed)
- Seed tracking table (record what's been seeded)
- Progress bars for large seed operations

**RoutesCommand:**
- JSON output format (`--json`)
- Middleware column (when middleware implemented)
- Route verification (check handler methods exist)

**TestCommand:**
- Color-coded output (green/red)
- Code coverage reporting
- Parallel test execution
- Watch mode (re-run on file change)
- Test result caching (only re-run failures)

### OUT OF SCOPE

**Database Management:**
- `db:create` / `db:drop` - Complex, database-specific
- `db:schema:dump` - Schema export feature
- `db:migrate:up/down` - Migrate to specific version
- Defer to Phase 3 or standalone tools

**Advanced Seeding:**
- Factory integration for seeds
- CSV/JSON import commands
- Seed rollback/versioning
- Defer to Phase 3

**Route Management:**
- Route caching (performance optimization)
- Route validation (dead routes, missing handlers)
- Route generation from annotations
- Defer to later phases

**Test Management:**
- Test scaffolding (generate test files)
- Test coverage thresholds
- Mutation testing
- Defer - covered by Generator phase if needed

## Existing Code Integration

### Components to Leverage

**Migrator (fuse/orm/Migrator.cfc):**
- Use `migrate()` directly - returns `{success, messages[]}`
- Use `rollback(steps)` - returns same structure
- Use `status()` - returns `{pending[], ran[]}`
- Use `reset()` for rollback all
- Use `refresh()` for reset + migrate
- All methods handle transactions and errors

**Router (fuse/core/Router.cfc):**
- Add `getRoutes()` public method to expose `variables.routes`
- Routes structure: `{pattern, method, handler, name?}`
- Already sorted by registration order (correct precedence)

**TestRunner (fuse/testing/TestRunner.cfc):**
- Use `run(tests)` - returns `{passes[], failures[], errors[], totalTime}`
- Pass datasource in init: `new TestRunner(datasource)`
- Result arrays have full test details

**TestDiscovery (fuse/testing/TestDiscovery.cfc):**
- Use `discover()` to find all tests
- Returns array of test descriptors
- Supports custom base paths for filtering

**CLI Support (fuse/cli/support/):**
- NamingConventions for pluralization (seed class names)
- FileGenerator patterns for creating seed files (future)
- Error handling patterns from generators

### New Components to Create

**Seeder Base Class (fuse/orm/Seeder.cfc):**
- `init(datasource)` constructor
- `run()` method (override in subclasses)
- `call(seederName)` helper to invoke other seeders
- Access to datasource for ActiveRecord models

**Router Enhancement:**
- Add `getRoutes()` method (one-liner getter)

### Pattern Consistency

**Command Structure:**
Follow New.cfc and Generate.cfc patterns:
- `main(required struct args)` entry point
- Parse `args.__arguments` array for positional arguments
- Parse flag properties directly from args struct
- Validate inputs before processing
- Use `writeOutput(message & chr(10))` for console output
- Return struct with `{success, message, ...data}`
- Use structured throw() for errors

**Error Handling:**
Follow Migrator error patterns:
- Catch specific exceptions
- Provide detailed error messages with context
- Include "did you mean" suggestions where applicable
- Return meaningful error types (e.g., "Migration.NotFound")

**Output Formatting:**
Follow lucli conventions from CLI Generators:
- Use `chr(10)` for newlines explicitly
- Align output for readability (tables, lists)
- Show progress indicators (dots, names)
- Summary line with counts and timing

## Database Connection Resolution

### Resolution Order
Standard pattern across all commands:

1. **Command flag:** `--datasource=name`
2. **Application scope:** `application.datasource`
3. **Default:** "fuse"

### Implementation Helper
Create shared utility in support/:

```cfml
// fuse/cli/support/DatabaseConnection.cfc
component {
    public string function resolve(required struct args) {
        // Check command flag
        if (structKeyExists(args, "datasource")) {
            return args.datasource;
        }

        // Check application scope
        if (isDefined("application.datasource") && len(application.datasource)) {
            return application.datasource;
        }

        // Default
        return "fuse";
    }

    public void function validate(required string datasource) {
        // Verify datasource exists in Lucee
        try {
            queryExecute("SELECT 1", {}, {datasource: arguments.datasource});
        } catch (any e) {
            throw(
                type = "Database.DatasourceNotFound",
                message = "Datasource '#arguments.datasource#' not configured",
                detail = "Configure datasource in Lucee Administrator or use --datasource flag"
            );
        }
    }
}
```

### Usage in Commands
```cfml
// In any command
var dbConnection = new fuse.cli.support.DatabaseConnection();
var datasource = dbConnection.resolve(arguments.args);
dbConnection.validate(datasource);

// Now safe to use datasource
var migrator = new fuse.orm.Migrator(datasource);
```

## Technical Considerations

### Framework Initialization
Some commands need framework loaded (routes, serve), others don't (migrate, test):

**Requires Framework:**
- RoutesCommand - needs application scope router
- ServeCommand - starts server which loads framework

**Standalone:**
- MigrateCommand - direct Migrator use
- RollbackCommand - direct Migrator use
- SeedCommand - direct Seeder use
- TestCommand - direct TestRunner use

**Pattern:**
```cfml
// For commands needing framework
if (!structKeyExists(application, "fuse")) {
    throw(
        type = "FrameworkNotInitialized",
        message = "Fuse framework not initialized",
        detail = "Start server with 'lucli serve' or access application in browser first"
    );
}
```

### Transaction Management
Migrator and TestRunner handle transactions internally:
- Migrator: Wraps each migration in transaction
- TestRunner: Wraps each test in transaction
- Seeder: Should handle own transactions (user responsibility)

**Seeder Best Practice:**
```cfml
component extends="fuse.orm.Seeder" {
    public void function run() {
        transaction {
            // Seed operations
            // Roll back on error automatically
        }
    }
}
```

### File System Operations
All commands operate on conventional paths:
- Migrations: `/database/migrations/`
- Seeds: `/database/seeds/`
- Tests: `/tests/unit/` and `/tests/integration/`

**Path Resolution:**
Use `expandPath()` relative to application root:
```cfml
var migrationsDir = expandPath("/database/migrations/");
var seedsDir = expandPath("/database/seeds/");
```

### Error Handling Strategy

**Validation Errors (User Input):**
- Throw with clear message and usage example
- Type: `InvalidArguments`
- Exit gracefully, don't show stack trace

**System Errors (File Not Found, DB Connection):**
- Throw with detailed diagnostic information
- Include "how to fix" guidance in detail
- Type: Specific to error (e.g., `Database.ConnectionFailed`)

**Operation Errors (Migration Failed, Test Failed):**
- Catch and format nicely
- Show error message + context
- Don't exit on first failure - complete operation
- Return failure status code

### Performance Considerations

**Migration Operations:**
- Already optimized in Migrator
- Transaction per migration prevents partial states
- No performance concerns for CLI usage

**Test Execution:**
- Sequential execution in Phase 1 (simplest)
- Parallel execution deferred to Phase 2
- Transaction rollback overhead acceptable for CLI

**Route Listing:**
- Router stores routes in memory array
- O(n) iteration acceptable (typical apps < 100 routes)
- No caching needed

## Reference Framework Patterns Summary

### From Rails
**Adopt:**
- `db:migrate:status` table format showing applied migrations
- Seeder pattern with DatabaseSeeder entry point
- `call()` method to invoke other seeders
- Migration step parameter for rollback

**Adapt:**
- Simplified command names (migrate vs db:migrate)
- CFML-friendly seeder syntax (CFCs vs Ruby classes)

### From Laravel
**Adopt:**
- Table-based route listing format
- `--filter` flag for test filtering
- Seeder `--class` flag for specific seeders
- Color-coded test output (Phase 2)

**Adapt:**
- Direct command dispatch vs namespace prefixes
- CFML component loading vs PHP namespaces

### From Django
**Skip:**
- Fixture-based seeding (too rigid for CFML)
- Migration auto-generation (Phase 3 feature)
- App-scoped commands (no app concept in Fuse yet)

## Summary

CLI Database & Dev Tools implementation provides essential development workflow commands:

**Architecture:**
- CFML modules in `fuse/cli/commands/` following roadmap #12 patterns
- Leverage existing Migrator, Router, TestRunner components
- Shared database connection resolution
- Consistent error handling and output formatting

**Core Commands:**
1. **MigrateCommand** - Wraps Migrator for migration operations
2. **RollbackCommand** - Migration rollback with step control
3. **SeedCommand** - Seeder system with DatabaseSeeder pattern
4. **RoutesCommand** - Table-formatted route listing
5. **ServeCommand** - Convenience wrapper for lucli server
6. **TestCommand** - Test execution with filtering and verbose output

**Key Features:**
- Migration status display with visual indicators
- Seeder base class with `call()` helper
- Route filtering by method/name/handler
- Test filtering by pattern and type
- Datasource resolution with clear error messages
- Exit codes for CI/CD integration

**Scope:**
Small scope (roadmap #13 "S") focusing on essential commands. Advanced features (color output, parallel tests, coverage) deferred to Phase 2.
