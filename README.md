# Fuse Framework

Modern CFML framework for Lucee 7 with Rails-inspired routing, ActiveRecord ORM, DI container, testing framework, and powerful CLI tools.

---

## 📚 Documentation

**[Complete Documentation →](/docs)**

- **[Getting Started](/docs/getting-started/quickstart.md)** - Build your first app in 5 minutes
- **[Core Guides](/docs#core-guides)** - Learn routing, models, handlers, validations
- **[Blog Tutorial](/docs/tutorials/blog-application.md)** - Step-by-step complete application
- **[API Reference](/docs/reference/api-reference.md)** - Complete API documentation
- **[CLI Reference](/docs/reference/cli-reference.md)** - lucli command reference

---

## Features

### Bootstrap Core & DI Container
- Lightweight dependency injection container with auto-wiring
- Singleton and transient bindings
- Constructor and property injection
- Thread-safe initialization
- Modular architecture with two-phase initialization (register/boot)

### Routing & Event System
- Rails-inspired routing DSL
- RESTful resource routes with full CRUD support
- Named routes and URL generation
- Pattern matching (static, named params, wildcards)
- Event service with interceptor lifecycle hooks
- Request dispatcher with handler conventions

## Quick Start

### Routing Examples

#### Define Routes in `/config/routes.cfm`

```cfml
// Static route
router.get("/", "Home.index", {name: "home"});

// Named route
router.get("/about", "Pages.about", {name: "about_page"});

// RESTful resource routes (generates 7 standard routes)
router.resource("users");
// Creates: index, new, create, show, edit, update, destroy

// Resource routes with filtering
router.resource("posts", {only: ["index", "show"]});
router.resource("comments", {except: ["new", "edit"]});

// Named parameters
router.get("/users/:id", "Users.show", {name: "users_show"});
router.get("/posts/:post_id/comments/:id", "Comments.show", {name: "post_comments"});

// Wildcard parameters
router.get("/files/*path", "Files.serve", {name: "files"});
```

#### Create Handler at `/app/handlers/Users.cfc`

```cfml
component {

    // Constructor injection (optional)
    public function init(any logger) {
        if (structKeyExists(arguments, "logger")) {
            variables.logger = arguments.logger;
        }
        return this;
    }

    // GET /users
    public struct function index() {
        return {
            users: getUserList()
        };
    }

    // GET /users/:id
    public struct function show(required string id) {
        return {
            user: getUserById(arguments.id)
        };
    }

    // POST /users
    public struct function create() {
        var newUser = createUser(form);
        return {
            created: true,
            user: newUser
        };
    }

    // PUT/PATCH /users/:id
    public struct function update(required string id) {
        updateUser(arguments.id, form);
        return {
            updated: true
        };
    }

    // DELETE /users/:id
    public struct function destroy(required string id) {
        deleteUser(arguments.id);
        return {
            deleted: true
        };
    }

}
```

#### URL Generation in Handlers

```cfml
// Use urlFor helper (injected via interceptor or request scope)
public struct function dashboard() {
    return {
        links: {
            home: urlFor("home"),
            users: urlFor("users_index"),
            user_detail: urlFor("users_show", {id: 5}),
            about: urlFor("about_page")
        }
    };
}
```

### Event Interceptors

Register interceptors during module initialization to hook into request lifecycle:

```cfml
component implements="IModule" {

    public function register(required container) {
        // Get event service from container
        var eventService = arguments.container.resolve("eventService");

        // Register authentication interceptor
        eventService.registerInterceptor("onBeforeRequest", function(event) {
            // Check authentication
            event.authenticated = checkAuth(event.request);
            if (!event.authenticated) {
                event.abort = true; // Short-circuit request
            }
        });

        // Register logging interceptor
        eventService.registerInterceptor("onAfterHandler", function(event) {
            // Log request details
            logRequest(event.route, event.handler, event.result);
        });
    }

    public function boot(required container) {
        // Boot logic here
    }

}
```

### Interceptor Points

Six lifecycle points available:
- `onBeforeRequest` - Before routing
- `onAfterRouting` - After route matched
- `onBeforeHandler` - Before handler action
- `onAfterHandler` - After handler action
- `onBeforeRender` - Before view rendering (future)
- `onAfterRender` - After view rendering (future)

### Complete Request Lifecycle

```
1. Request received
2. onBeforeRequest interceptors
3. Route matching
4. onAfterRouting interceptors
5. Handler instantiation (transient, auto-wired)
6. onBeforeHandler interceptors
7. Handler action execution
8. onAfterHandler interceptors
9. Response rendering
```

## Handler Conventions

- Location: `/app/handlers/{HandlerName}.cfc`
- Scope: Transient (new instance per request)
- Injection: Constructor auto-wiring via DI container
- Actions: Public methods matching route actions
- Parameters: Route params passed as method arguments
- Return values:
  - Struct for JSON responses
  - String for view names
  - Void for default view rendering

## Development

### Running Tests

```bash
box testbox run
```

### Project Structure

```
fuse/
├── fuse/core/          # Framework core components
│   ├── Bootstrap.cfc   # Framework initialization
│   ├── Container.cfc   # DI container
│   ├── Router.cfc      # Routing DSL
│   ├── RoutePattern.cfc# Pattern matching engine
│   ├── Dispatcher.cfc  # Request dispatcher
│   ├── EventService.cfc# Event/interceptor service
│   ├── Config.cfc      # Configuration loader
│   └── ...
├── config/             # Application configuration
│   └── routes.cfm      # Route definitions
├── app/
│   └── handlers/       # Request handlers
├── tests/              # Test suites
│   ├── core/          # Core component tests
│   └── fixtures/      # Test fixtures
└── README.md
```

## CLI Database & Dev Tools

Fuse provides CLI commands for database management and development workflow.

### Database Commands

#### Migrate - Run Database Migrations

Execute pending migrations:

```bash
lucli fuse.cli.commands.Migrate
```

Common options:

```bash
# Show migration status
lucli fuse.cli.commands.Migrate --status

# Reset all migrations (rollback everything)
lucli fuse.cli.commands.Migrate --reset

# Refresh migrations (reset + re-run)
lucli fuse.cli.commands.Migrate --refresh

# Use specific datasource
lucli fuse.cli.commands.Migrate --datasource=mydb
```

Output example:

```
Running pending migrations...

  Migrated: 20251106120000_CreateUsers.cfc
  Migrated: 20251106120100_CreatePosts.cfc

Migrations complete! (2 migrations)
```

Status output shows checkmarks for ran migrations:

```
Migration Status:

  [✓] 20251106120000_CreateUsers.cfc
  [✓] 20251106120100_CreatePosts.cfc
  [ ] 20251106120200_AddEmailToUsers.cfc

2 migrations run, 1 pending
```

#### Rollback - Rollback Migrations

Rollback migrations:

```bash
# Rollback 1 migration (default)
lucli fuse.cli.commands.Rollback

# Rollback N migrations
lucli fuse.cli.commands.Rollback --steps=3

# Rollback all migrations
lucli fuse.cli.commands.Rollback --all

# Use specific datasource
lucli fuse.cli.commands.Rollback --datasource=mydb
```

Output example:

```
Rolling back 1 migration...

  Rolled back: 20251106120100_CreatePosts.cfc

Rollback complete! (1 migration)
```

#### Seed - Populate Database

Seed database with test/default data:

```bash
# Run DatabaseSeeder (default)
lucli fuse.cli.commands.Seed

# Run specific seeder
lucli fuse.cli.commands.Seed --class=UserSeeder

# Use specific datasource
lucli fuse.cli.commands.Seed --datasource=mydb
```

Output example:

```
Seeding database...

  Running DatabaseSeeder...
  Running UserSeeder...
  Running PostSeeder...

Database seeded successfully!
```

**Seeder Best Practices:**

Seeders should be idempotent (safe to run multiple times). Check before inserting:

```cfml
component extends="fuse.orm.Seeder" {
    public function run() {
        // Check if data exists first
        var count = queryExecute("
            SELECT COUNT(*) as total FROM users
        ", [], {datasource: variables.datasource}).total;

        if (count == 0) {
            // Insert data
            queryExecute("
                INSERT INTO users (name, email)
                VALUES ('Admin', 'admin@example.com')
            ", [], {datasource: variables.datasource});
        }
    }
}
```

Use `call()` to invoke other seeders:

```cfml
component extends="fuse.orm.Seeder" {
    public function run() {
        call("UserSeeder");
        call("PostSeeder");
    }
}
```

**Datasource Resolution:**

All database commands resolve datasource in this order:
1. `--datasource` flag
2. `application.datasource`
3. "fuse" (default)

### Development Commands

#### Routes - Display Registered Routes

Show all registered routes:

```bash
lucli fuse.cli.commands.Routes
```

Output displays ASCII table:

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

Filter options:

```bash
# Filter by HTTP method
lucli fuse.cli.commands.Routes --method=GET

# Filter by route name (contains match)
lucli fuse.cli.commands.Routes --name=users

# Filter by handler (contains match)
lucli fuse.cli.commands.Routes --handler=Users
```

#### Serve - Start Development Server

Start local development server:

```bash
# Default: http://127.0.0.1:8080
lucli fuse.cli.commands.Serve

# Custom host and port
lucli fuse.cli.commands.Serve --host=0.0.0.0 --port=3000
```

Output:

```
Starting Fuse development server...
Server running at http://127.0.0.1:8080
Press Ctrl+C to stop
```

#### Test - Run Test Suite

Run tests with TestBox:

```bash
# Run all tests
lucli fuse.cli.commands.Test

# Run specific tests (filter by component name)
lucli fuse.cli.commands.Test --filter=User

# Run only unit tests
lucli fuse.cli.commands.Test --type=unit

# Run only integration tests
lucli fuse.cli.commands.Test --type=integration

# Verbose output (show each test)
lucli fuse.cli.commands.Test --verbose

# Use specific datasource for test transactions
lucli fuse.cli.commands.Test --datasource=test_db
```

Default output (dots):

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

Verbose output:

```
Running tests...

  UserTest::testCreate ... PASS (0.045s)
  UserTest::testUpdate ... PASS (0.038s)
  UserTest::testValidation ... FAIL (0.012s)
  PostTest::testCreate ... ERROR (0.002s)

15 tests, 13 passed, 1 failure, 1 error (2.34s)

[failure/error details...]
```

## Roadmap

- [x] #1: Bootstrap Core & DI Container
- [x] #2: Routing & Event System
- [x] #5: Database Layer & ORM (ActiveRecord)
- [x] #7: Form Validation (Model Validations)
- [x] #8: CLI & Tooling (Generators, Migrations)
- [x] #9: Validations & Lifecycle Hooks
- [x] #10: Test Framework Foundation
- [x] #11: Test Helpers & Integration
- [x] #12: CLI Generators (Model, Handler, Migration)
- [x] #13: CLI Database & Dev Tools (Migrate, Rollback, Seed, Routes, Test)
- [ ] #3: View Layer & Rendering
- [ ] #4: Middleware Chain
- [ ] #6: Session & Authentication

## Need Help?

- **Documentation:** [/docs](/docs)
- **Troubleshooting:** Check "Common Errors" sections in each guide
- **Error Reference:** [fuse-planning/error-reference.md](/fuse-planning/error-reference.md)
- **Issues:** Report bugs and request features on GitHub

## License

TBD
