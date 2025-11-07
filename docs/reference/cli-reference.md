# CLI Reference

Complete reference for the `lucli` command-line tool. All Fuse CLI commands for creating applications, generating components, and managing your database.

## Overview

The `lucli` CLI provides scaffolding and development tools for Fuse applications:

- **Application generation** - Create new Fuse apps with complete structure
- **Component generators** - Generate models, handlers, and migrations
- **Database management** - Run migrations, rollbacks, and seeds
- **Development tools** - Routes inspection, test runner, development server
- **Template-based** - Customizable code generation templates

## Installation

Ensure `lucli` is installed and available in your PATH:

```bash
# Verify installation
lucli --version

# Display general help
lucli help
```

See [Installation Guide](../getting-started/installation.md) for setup instructions.

## Commands

### lucli new

Create a new Fuse application with complete directory structure and configuration files.

#### Syntax

```bash
lucli new <app-name> [flags]
```

#### Parameters

- `<app-name>` - Application name (required)

#### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--database=<type>` | Database type: mysql, postgresql, sqlserver, h2 | mysql |
| `--no-git` | Skip git repository initialization | false |

#### Examples

```bash
# Create new app with MySQL (default)
lucli new my-blog-app

# Create app with PostgreSQL
lucli new my-api --database=postgresql

# Create app with H2 (embedded database)
lucli new my-test-app --database=h2

# Create app without git initialization
lucli new my-app --no-git
```

#### Generated Structure

```
my-blog-app/
├── Application.cfc
├── box.json
├── README.md
├── .gitignore
├── app/
│   ├── models/
│   ├── handlers/
│   └── views/
│       └── layouts/
├── config/
│   ├── routes.cfc
│   ├── database.cfc
│   └── templates/
├── database/
│   ├── migrations/
│   └── seeds/
├── modules/
├── public/
│   ├── css/
│   └── js/
└── tests/
    ├── fixtures/
    ├── integration/
    └── unit/
```

#### Output

```
Creating new Fuse application: my-blog-app

  ✓ Created directory structure
  ✓ Generated Application.cfc
  ✓ Generated config/routes.cfc
  ✓ Generated config/database.cfc
  ✓ Generated README.md
  ✓ Generated .gitignore
  ✓ Initialized git repository

Application created successfully!
```

---

### lucli generate

Generate models, handlers, or migrations using templates.

#### Syntax

```bash
lucli generate <type> <name> [attributes] [flags]
```

#### Types

- `model` - Generate ActiveRecord model with optional migration
- `handler` - Generate RESTful handler controller
- `migration` - Generate database migration

#### Help

```bash
# Display generator help
lucli generate help

# Type-specific help
lucli generate model --help
lucli generate handler --help
lucli generate migration --help
```

---

### lucli generate model

Generate ActiveRecord model with automatic migration creation.

#### Syntax

```bash
lucli generate model <ModelName> [attributes] [flags]
```

#### Parameters

- `<ModelName>` - Model name in PascalCase (e.g., User, BlogPost)
- `[attributes]` - Space-separated list of attributes in format `name:type[:modifier[:modifier...]]`

#### Attribute Types

| Type | Database Type | Description |
|------|--------------|-------------|
| `string` | VARCHAR(255) | Text up to 255 characters |
| `text` | TEXT | Long text content |
| `integer` | INTEGER | Whole numbers |
| `boolean` | BOOLEAN | True/false values |
| `date` | DATE | Date without time |
| `datetime` | DATETIME/TIMESTAMP | Date with time |
| `decimal` | DECIMAL | Decimal numbers |
| `references` | INTEGER + INDEX + FK | Foreign key relationship |

#### Attribute Modifiers

| Modifier | Description | Example |
|----------|-------------|---------|
| `unique` | Unique constraint | `email:string:unique` |
| `index` | Database index | `user_id:integer:index` |
| `notnull` | NOT NULL constraint | `name:string:notnull` |
| `default:value` | Default value | `active:boolean:default:1` |

#### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--no-migration` | Skip migration generation | false |
| `--no-timestamps` | Don't add timestamps() to migration | false |
| `--table=name` | Override table name | Pluralized model name |
| `--force` | Overwrite existing files | false |

#### Examples

```bash
# Basic model
lucli generate model User name:string email:string

# With unique constraint
lucli generate model User name:string email:string:unique

# With foreign key relationship
lucli generate model Post title:string body:text user:references

# Multiple modifiers
lucli generate model Product name:string:unique:notnull price:decimal

# Skip migration generation
lucli generate model Article title:string --no-migration

# Skip timestamps in migration
lucli generate model Category name:string --no-timestamps

# Override table name
lucli generate model BlogPost title:string --table=posts
```

#### Generated Files

**Model:** `app/models/User.cfc`

```cfml
component extends="fuse.orm.ActiveRecord" {
    function init() {
        super.init();

        // Define relationships here
        // belongsTo: User

        // Define validations here

        return this;
    }
}
```

**Migration:** `database/migrations/20251106123045_CreateUsers.cfc`

```cfml
component extends="fuse.orm.Migration" {
    function up() {
        var schema = getSchema();
        schema.create("users", function(table) {
            table.id();
            table.string("name");
            table.string("email").unique();
            table.timestamps();
        });
    }

    function down() {
        var schema = getSchema();
        schema.drop("users");
    }
}
```

#### Output

```
Generating model: User

  ✓ Created app/models/User.cfc
  ✓ Created tests/models/UserTest.cfc
  ✓ Created database/migrations/20251106123045_CreateUsers.cfc

Model created successfully!
```

---

### lucli generate handler

Generate RESTful handler controller with standard CRUD actions.

#### Syntax

```bash
lucli generate handler <HandlerName> [flags]
```

#### Parameters

- `<HandlerName>` - Handler name in PascalCase (e.g., Users, Api/V1/Products)

#### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--api` | Generate API-only handler (no new/edit actions) | false |
| `--actions=list` | Generate only specified actions (comma-separated) | All actions |
| `--force` | Overwrite existing files | false |

#### Generated Actions

**Full RESTful (default):**

| Action | HTTP Method | Route | Description |
|--------|------------|-------|-------------|
| `index()` | GET | /users | List all records |
| `show(id)` | GET | /users/:id | Show single record |
| `new()` | GET | /users/new | Show new form |
| `create()` | POST | /users | Create new record |
| `edit(id)` | GET | /users/:id/edit | Show edit form |
| `update(id)` | PUT/PATCH | /users/:id | Update record |
| `destroy(id)` | DELETE | /users/:id | Delete record |

**API Mode (--api):**

Excludes `new()` and `edit()` form actions, includes only data endpoints:

- `index()`, `show()`, `create()`, `update()`, `destroy()`

#### Examples

```bash
# Full RESTful handler (7 actions)
lucli generate handler Users

# API-only handler (5 actions)
lucli generate handler Users --api

# Specific actions only
lucli generate handler Posts --actions=index,show,create

# Namespaced handler
lucli generate handler Api/V1/Users

# API handler with namespace
lucli generate handler Api/V1/Products --api
```

#### Generated File

**Handler:** `app/handlers/Users.cfc`

```cfml
component {
    /**
     * List all users
     * @route GET /users
     */
    function index() {
        return {
            data: [],
            message: "List all users"
        };
    }

    /**
     * Show single user
     * @route GET /users/:id
     */
    function show(required numeric id) {
        return {
            data: {},
            message: "Show user ##arguments.id##"
        };
    }

    /**
     * Show new user form
     * @route GET /users/new
     */
    function new() {
        return {
            message: "New user form"
        };
    }

    /**
     * Create new user
     * @route POST /users
     */
    function create() {
        return {
            created: true,
            message: "User created"
        };
    }

    /**
     * Show edit user form
     * @route GET /users/:id/edit
     */
    function edit(required numeric id) {
        return {
            message: "Edit user ##arguments.id## form"
        };
    }

    /**
     * Update user
     * @route PUT/PATCH /users/:id
     */
    function update(required numeric id) {
        return {
            updated: true,
            message: "User ##arguments.id## updated"
        };
    }

    /**
     * Delete user
     * @route DELETE /users/:id
     */
    function destroy(required numeric id) {
        return {
            deleted: true,
            message: "User ##arguments.id## deleted"
        };
    }
}
```

#### Output

```
Generating handler: Users

  ✓ Created app/handlers/Users.cfc
  ✓ Created tests/handlers/UsersTest.cfc

Handler created successfully!
```

---

### lucli generate migration

Generate standalone database migrations without models.

#### Syntax

```bash
lucli generate migration <MigrationName> [attributes] [flags]
```

#### Parameters

- `<MigrationName>` - Migration name in PascalCase (e.g., CreateProducts, AddEmailToUsers)
- `[attributes]` - Space-separated list of attributes (same format as model generator)

#### Migration Name Patterns

The generator detects patterns in migration names to generate appropriate code:

| Pattern | Purpose | Example |
|---------|---------|---------|
| `Create*` | Create new table | `CreateProducts` |
| `Add*To*` | Add columns to existing table | `AddEmailToUsers` |
| `Remove*From*` | Remove columns from table | `RemovePhoneFromUsers` |
| Custom | Empty up/down methods | `UpdateUserStatuses` |

#### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--no-timestamps` | Don't add timestamps() for create migrations | false |
| `--table=name` | Override inferred table name | Inferred from name |
| `--force` | Overwrite existing files | false |

#### Examples

```bash
# Create table migration
lucli generate migration CreateProducts name:string price:decimal stock:integer

# Add columns migration
lucli generate migration AddPhoneToUsers phone:string

# Remove columns migration (creates placeholder)
lucli generate migration RemoveAgeFromUsers age:integer

# Skip timestamps
lucli generate migration CreateCategories name:string --no-timestamps

# Override table name
lucli generate migration CreateArticles title:string --table=blog_posts

# Custom migration (empty template)
lucli generate migration UpdateUserStatuses
```

#### Generated Files

**Create Table:** `database/migrations/20251106123045_CreateProducts.cfc`

```cfml
component extends="fuse.orm.Migration" {
    function up() {
        var schema = getSchema();
        schema.create("products", function(table) {
            table.id();
            table.string("name");
            table.decimal("price");
            table.integer("stock");
            table.timestamps();
        });
    }

    function down() {
        var schema = getSchema();
        schema.drop("products");
    }
}
```

**Add Columns:** `database/migrations/20251106123045_AddPhoneToUsers.cfc`

```cfml
component extends="fuse.orm.Migration" {
    function up() {
        var schema = getSchema();
        schema.table("users", function(table) {
            table.string("phone");
        });
    }

    function down() {
        var schema = getSchema();
        schema.table("users", function(table) {
            table.dropColumn("phone");
        });
    }
}
```

#### Output

```
Generating migration: AddPhoneToUsers

  ✓ Created database/migrations/20251106123045_AddPhoneToUsers.cfc

Migration created successfully!
```

---

### lucli migrate

Run pending database migrations to update schema.

#### Syntax

```bash
lucli migrate [flags]
```

#### Flags

| Flag | Description |
|------|-------------|
| `--status` | Display migration status without running |
| `--reset` | Rollback all migrations then re-run |
| `--refresh` | Alias for --reset |
| `--datasource=name` | Use specific datasource |

#### Examples

```bash
# Run pending migrations
lucli migrate

# Check migration status
lucli migrate --status

# Reset and re-run all migrations
lucli migrate --reset

# Use specific datasource
lucli migrate --datasource=secondary_db
```

#### Output

**Running migrations:**

```
Running pending migrations...

  Migrated: 20251106120001_CreateUsers.cfc
  Migrated: 20251106120002_CreatePosts.cfc

Migrations complete! (2 migrations)
```

**Migration status:**

```
Migration Status:

  [✓] 20251106120001_CreateUsers.cfc
  [✓] 20251106120002_CreatePosts.cfc
  [ ] 20251106120003_AddPhoneToUsers.cfc

2 migrations run, 1 pending
```

#### Related Topics

See [Migrations Guide](../guides/migrations.md) for detailed migration documentation.

---

### lucli rollback

Rollback database migrations.

#### Syntax

```bash
lucli rollback [flags]
```

#### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--steps=n` | Number of migrations to rollback | 1 |
| `--all` | Rollback all migrations | false |
| `--datasource=name` | Use specific datasource | default |

#### Examples

```bash
# Rollback last migration
lucli rollback

# Rollback last 3 migrations
lucli rollback --steps=3

# Rollback all migrations
lucli rollback --all

# Use specific datasource
lucli rollback --datasource=secondary_db
```

#### Output

```
Rolling back migrations...

  Rolled back: 20251106120003_AddPhoneToUsers.cfc

Rollback complete! (1 migration)
```

#### Notes

- Executes `down()` method for each migration in reverse order
- Migrations must have valid `down()` methods to rollback
- Use `--all` to reset database to empty state

---

### lucli seed

Run database seeders to populate tables with data.

#### Syntax

```bash
lucli seed [seeder] [flags]
```

#### Parameters

- `[seeder]` - Optional seeder name to run (runs all if omitted)

#### Flags

| Flag | Description |
|------|-------------|
| `--datasource=name` | Use specific datasource |

#### Examples

```bash
# Run all seeders
lucli seed

# Run specific seeder
lucli seed UserSeeder

# Use specific datasource
lucli seed --datasource=test_db
```

#### Output

```
Running database seeders...

  Seeded: UserSeeder
  Seeded: PostSeeder
  Seeded: CommentSeeder

Seeding complete! (3 seeders)
```

#### Seeder File

**Location:** `database/seeds/UserSeeder.cfc`

```cfml
component extends="fuse.orm.Seeder" {
    function run() {
        // Create seed data
        queryExecute("
            INSERT INTO users (name, email, created_at, updated_at)
            VALUES
                ('Admin User', 'admin@example.com', NOW(), NOW()),
                ('Test User', 'test@example.com', NOW(), NOW())
        ", {}, {datasource: variables.datasource});
    }
}
```

#### Notes

- Seeders populate database with test/demo data
- Use migrations for schema, seeders for data
- Seeders can be re-run safely (consider using truncate or checking for existing data)

---

### lucli routes

Display all registered application routes.

#### Syntax

```bash
lucli routes [flags]
```

#### Flags

| Flag | Description |
|------|-------------|
| `--format=table|json` | Output format (default: table) |
| `--filter=pattern` | Filter routes by pattern |

#### Examples

```bash
# Display all routes
lucli routes

# Display routes as JSON
lucli routes --format=json

# Filter routes
lucli routes --filter=users
```

#### Output

**Table format:**

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

**JSON format:**

```json
[
  {
    "method": "GET",
    "uri": "/users",
    "name": "users_index",
    "handler": "Users.index"
  },
  {
    "method": "POST",
    "uri": "/users",
    "name": "users_create",
    "handler": "Users.create"
  }
]
```

#### Notes

- Displays routes from `config/routes.cfc`
- Useful for debugging route conflicts
- Shows route names for use with `urlFor()` helper

---

### lucli serve

Start development server for testing application.

#### Syntax

```bash
lucli serve [flags]
```

#### Flags

| Flag | Description | Default |
|------|-------------|---------|
| `--port=n` | Port number | 8080 |
| `--host=address` | Host address | 127.0.0.1 |
| `--open` | Open browser automatically | false |

#### Examples

```bash
# Start server on default port
lucli serve

# Use specific port
lucli serve --port=3000

# Bind to all interfaces
lucli serve --host=0.0.0.0

# Open browser automatically
lucli serve --open
```

#### Output

```
Starting Fuse development server...
Server running at http://127.0.0.1:8080
Press Ctrl+C to stop
```

#### Notes

- Development server only - not for production use
- Automatically reloads on code changes
- Press Ctrl+C to stop server
- Check if port is available before starting

---

### lucli test

Run application tests.

#### Syntax

```bash
lucli test [path] [flags]
```

#### Parameters

- `[path]` - Optional path to specific test file or directory

#### Flags

| Flag | Description |
|------|-------------|
| `--verbose` | Display detailed output |
| `--coverage` | Generate code coverage report |
| `--filter=pattern` | Run tests matching pattern |

#### Examples

```bash
# Run all tests
lucli test

# Run specific test file
lucli test tests/models/UserTest.cfc

# Run tests in directory
lucli test tests/models/

# Run with verbose output
lucli test --verbose

# Generate coverage report
lucli test --coverage

# Filter tests by name
lucli test --filter=User
```

#### Output

```
Running tests...

✓ UserTest.test_creates_user
✓ UserTest.test_requires_name
✓ PostTest.test_creates_post
✓ PostTest.test_belongs_to_user

4 tests passed, 0 failed

Tests completed in 1.23s
```

#### Notes

- Tests run in transactions (automatic rollback)
- See [Testing Guide](../guides/testing.md) for test writing patterns
- Use `--coverage` to identify untested code

---

## Generator Attribute Syntax

All generators support a consistent attribute syntax for defining fields.

### Format

```
name:type[:modifier[:modifier...]]
```

### Components

1. **Name** - Field/column name (e.g., `email`, `user_id`)
2. **Type** - Data type (e.g., `string`, `integer`, `boolean`)
3. **Modifiers** - Optional constraints (e.g., `unique`, `index`, `notnull`)

### Examples

```bash
# Simple attribute
name:string

# With single modifier
email:string:unique

# With multiple modifiers
price:decimal:notnull:index

# Foreign key reference
user:references  # Creates user_id:integer:index with FK constraint

# With default value
active:boolean:default:1
status:string:default:pending
```

### Modifier Chaining

Modifiers are applied in order:

```bash
email:string:unique:notnull:index
```

Generates:

```cfml
table.string("email").unique().notNull().index();
```

### Special Types

**references** - Creates foreign key relationship:

```bash
user:references
```

Generates:

```cfml
table.bigInteger("user_id").notNull().index();
table.foreignKey("user_id").references("users", "id").onDelete("CASCADE");
```

### Type Reference

| Type | SQL Type | Length | Example |
|------|----------|--------|---------|
| string | VARCHAR | 255 | `name:string` |
| text | TEXT | - | `body:text` |
| integer | INTEGER | - | `age:integer` |
| boolean | BOOLEAN | - | `active:boolean` |
| date | DATE | - | `birth_date:date` |
| datetime | DATETIME | - | `published_at:datetime` |
| decimal | DECIMAL | 10,2 | `price:decimal` |
| references | INTEGER + FK | - | `user:references` |

### Modifier Reference

| Modifier | SQL Constraint | Example |
|----------|---------------|---------|
| unique | UNIQUE | `email:string:unique` |
| index | INDEX | `user_id:integer:index` |
| notnull | NOT NULL | `name:string:notnull` |
| default:value | DEFAULT | `active:boolean:default:1` |

---

## Common Workflows

### New Blog Application

```bash
# Create new blog app
lucli new my-blog --database=mysql
cd my-blog

# Generate User model
lucli generate model User name:string email:string:unique password:string

# Generate Post model with user relationship
lucli generate model Post title:string body:text user:references published:boolean

# Generate Comment model
lucli generate model Comment body:text user:references post:references

# Generate handlers
lucli generate handler Users
lucli generate handler Posts
lucli generate handler Comments

# Run migrations
lucli migrate

# Start server
lucli serve
```

### REST API Application

```bash
# Create API app
lucli new my-api --database=postgresql
cd my-api

# Generate models
lucli generate model Product name:string description:text price:decimal
lucli generate model Order total:decimal status:string

# Generate API handlers
lucli generate handler Api/V1/Products --api
lucli generate handler Api/V1/Orders --api

# Run migrations
lucli migrate

# View routes
lucli routes

# Start server
lucli serve
```

### Adding Features to Existing App

```bash
# Add new column to existing table
lucli generate migration AddAvatarToUsers avatar:string

# Generate new model
lucli generate model Category name:string slug:string:unique

# Generate handler for new model
lucli generate handler Categories

# Run new migrations
lucli migrate

# Verify routes
lucli routes
```

---

## Troubleshooting

### File Already Exists

**Problem:** Trying to generate a file that already exists.

```
Error: app/models/User.cfc already exists
```

**Solution:** Use `--force` flag to overwrite:

```bash
lucli generate model User name:string --force
```

### Invalid Component Name

**Problem:** Component name doesn't follow CFML naming rules.

```
Error: Invalid component name: 123User
```

**Solution:** Ensure names start with a letter and contain only alphanumeric characters:

```bash
# Bad
lucli generate model 123User

# Good
lucli generate model User123
```

### Unknown Generator Type

**Problem:** Invalid generator type specified.

```
Error: Unknown generator type: controller
```

**Solution:** Use one of the supported types: `model`, `handler`, `migration`:

```bash
lucli generate handler User  # Correct
lucli generate controller User  # Wrong - use 'handler'
```

### Migration Fails

**Problem:** Generated migrations fail when running `lucli migrate`.

**Solution:**

1. Check database connection in `config/database.cfc`
2. Verify migration file timestamp format (14 digits: YYYYMMDDHHMMSS)
3. Ensure migration extends `fuse.orm.Migration`
4. Check migration SQL syntax for your database type
5. Verify referenced tables exist for foreign keys

### Server Won't Start

**Problem:** `lucli serve` fails with port error.

```
Error: Port 8080 already in use
```

**Solution:**

```bash
# Check if port is in use
lsof -i :8080

# Use different port
lucli serve --port=3000
```

### Model Not Found

**Problem:** "Component not found" error when using models.

**Solution:** Verify Application.cfc has correct mappings:

```cfml
// Application.cfc
this.mappings["/app"] = expandPath("./app/");
this.mappings["/fuse"] = expandPath("../fuse/");
```

### Template Customization Not Working

**Problem:** Custom templates in `config/templates/` aren't being used.

**Solution:**

1. Verify template file is in correct directory: `config/templates/`
2. Check filename matches exactly: `model.cfc.tmpl`, `handler.cfc.tmpl`, `migration.cfc.tmpl`
3. Ensure template has proper variable placeholders: `{{modelName}}`, `{{tableName}}`, etc.
4. Restart CLI or clear template cache

---

## Getting Help

### Command Help

```bash
# General help
lucli help

# Command-specific help
lucli new --help
lucli generate --help
lucli migrate --help

# Generator help
lucli generate help
lucli generate model --help
```

### Debug Mode

For detailed output during command execution:

```bash
# Enable verbose output
lucli generate model User name:string --verbose

# Check CLI logs
lucli --debug migrate
```

### Version Information

```bash
# Display CLI version
lucli --version

# Display Fuse framework version
lucli version
```

---

## Template Customization

### Custom Templates

Override default generator templates by placing custom templates in `config/templates/`:

```
config/templates/
├── model.cfc.tmpl
├── handler.cfc.tmpl
└── migration.cfc.tmpl
```

### Template Variables

Available variables in templates:

**Model Template (`model.cfc.tmpl`):**

- `{{modelName}}` - Model name (e.g., User)
- `{{tableName}}` - Table name (e.g., users)
- `{{primaryKey}}` - Primary key column (e.g., id)

**Handler Template (`handler.cfc.tmpl`):**

- `{{handlerName}}` - Handler name (e.g., Users)
- `{{resourceName}}` - Resource name lowercase (e.g., users)
- `{{singularName}}` - Singular form (e.g., user)

**Migration Template (`migration.cfc.tmpl`):**

- `{{migrationName}}` - Migration name (e.g., CreateUsers)
- `{{tableName}}` - Table name (e.g., users)
- `{{timestamp}}` - Migration timestamp

### Example Custom Template

**config/templates/model.cfc.tmpl:**

```cfml
/**
 * {{modelName}} Model
 * Generated: {{timestamp}}
 */
component extends="fuse.orm.ActiveRecord" {

    function init() {
        super.init();

        // Custom initialization
        this.tableName = "{{tableName}}";
        this.primaryKey = "{{primaryKey}}";

        return this;
    }

}
```

See [Advanced Topics: Generator Templates](../advanced/generator-templates.md) for more customization options.

---

## Related Topics

- [Getting Started: Installation](../getting-started/installation.md) - Install lucli CLI
- [Getting Started: Quickstart](../getting-started/quickstart.md) - Build first app with CLI
- [Guides: Models & ORM](../guides/models-orm.md) - Generated model usage
- [Guides: Migrations](../guides/migrations.md) - Migration commands and patterns
- [Guides: Handlers](../handlers.md) - Generated handler usage
- [Guides: Testing](../guides/testing.md) - Test generated components
- [Reference: API Reference](api-reference.md) - Framework API documentation
