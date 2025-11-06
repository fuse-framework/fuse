# CLI Generators Usage Guide

Complete guide to using Fuse CLI generators for scaffolding applications, models, handlers, and migrations.

## Table of Contents

- [Installation](#installation)
- [New Application Command](#new-application-command)
- [Generate Command](#generate-command)
  - [Model Generator](#model-generator)
  - [Handler Generator](#handler-generator)
  - [Migration Generator](#migration-generator)
- [Common Workflows](#common-workflows)
- [Flags and Options](#flags-and-options)
- [Troubleshooting](#troubleshooting)

---

## Installation

Ensure you have `lucli` CLI tool installed and available in your PATH.

```bash
# Verify lucli is installed
lucli --version
```

---

## New Application Command

Create a complete Fuse application scaffold with all necessary directories and configuration files.

### Syntax

```bash
lucli new <app-name> [flags]
```

### Examples

```bash
# Create new app with MySQL (default)
lucli new my-blog-app

# Create app with PostgreSQL
lucli new my-api --database=postgresql

# Create app with H2 database
lucli new my-test-app --database=h2

# Create app without git initialization
lucli new my-app --no-git
```

### Flags

- `--database=<type>` - Database type: mysql (default), postgresql, sqlserver, h2
- `--no-git` - Skip git repository initialization

### Generated Structure

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

---

## Generate Command

Generate specific components: models, handlers, or migrations.

### General Syntax

```bash
lucli generate <type> <name> [attributes] [flags]
```

### Help

```bash
lucli generate help
```

---

## Model Generator

Generate ActiveRecord models with automatic migration creation.

### Syntax

```bash
lucli generate model <ModelName> [attributes] [flags]
```

### Attribute Format

```
name:type[:modifier[:modifier...]]
```

**Supported Types:**
- `string` - VARCHAR(255)
- `text` - TEXT
- `integer` - INTEGER
- `boolean` - BOOLEAN
- `date` - DATE
- `datetime` - DATETIME/TIMESTAMP
- `decimal` - DECIMAL
- `references` - Foreign key (creates integer column with index)

**Supported Modifiers:**
- `unique` - Adds unique constraint
- `index` - Adds index
- `notnull` - NOT NULL constraint
- `default:value` - Default value

### Examples

```bash
# Basic model
lucli generate model User name:string email:string

# With unique constraint
lucli generate model User name:string email:string:unique

# With foreign key relationship
lucli generate model Post title:string body:text user:references

# Multiple modifiers
lucli generate model Product name:string:unique price:decimal:notnull

# Skip migration generation
lucli generate model Article title:string --no-migration

# Skip timestamps in migration
lucli generate model Category name:string --no-timestamps

# Override table name
lucli generate model BlogPost title:string --table=posts
```

### Generated Files

1. **Model File:** `app/models/User.cfc`
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

2. **Migration File:** `database/migrations/20251106123045_CreateUsers.cfc`
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

### Model Flags

- `--no-migration` - Skip migration generation
- `--no-timestamps` - Don't add timestamps() to migration
- `--table=name` - Override table name
- `--force` - Overwrite existing files

---

## Handler Generator

Generate RESTful handler controllers with standard CRUD actions.

### Syntax

```bash
lucli generate handler <HandlerName> [flags]
```

### Examples

```bash
# Full RESTful handler (7 actions)
lucli generate handler Users

# API-only handler (no new/edit actions)
lucli generate handler Users --api

# Specific actions only
lucli generate handler Posts --actions=index,show,create

# Namespaced handler
lucli generate handler Api/V1/Users

# API handler with namespace
lucli generate handler Api/V1/Products --api
```

### Generated Actions

**Full RESTful (default):**
- `index()` - GET /users - List all
- `show(id)` - GET /users/:id - Show one
- `new()` - GET /users/new - New form
- `create()` - POST /users - Create
- `edit(id)` - GET /users/:id/edit - Edit form
- `update(id)` - PUT/PATCH /users/:id - Update
- `destroy(id)` - DELETE /users/:id - Delete

**API Mode (--api):**
- `index()` - GET /users - List all
- `show(id)` - GET /users/:id - Show one
- `create()` - POST /users - Create
- `update(id)` - PUT/PATCH /users/:id - Update
- `destroy(id)` - DELETE /users/:id - Delete

### Generated File

`app/handlers/Users.cfc`
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

    // ... other actions
}
```

### Handler Flags

- `--api` - Generate API-only handler (skip new/edit actions)
- `--actions=list` - Generate only specified actions (comma-separated)
- `--force` - Overwrite existing files

---

## Migration Generator

Generate standalone database migrations without models.

### Syntax

```bash
lucli generate migration <MigrationName> [attributes] [flags]
```

### Migration Name Patterns

The generator detects patterns in migration names:

- **`Create*`** - Creates new table
  ```bash
  lucli generate migration CreateProducts name:string price:decimal
  ```

- **`Add*To*`** - Adds columns to existing table
  ```bash
  lucli generate migration AddEmailToUsers email:string:unique
  ```

- **`Remove*From*`** - Removes columns from table (placeholder only)
  ```bash
  lucli generate migration RemovePhoneFromUsers phone:string
  ```

### Examples

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
```

### Generated File

`database/migrations/20251106123045_AddEmailToUsers.cfc`
```cfml
component extends="fuse.orm.Migration" {
    function up() {
        var schema = getSchema();
        schema.table("users", function(table) {
            table.string("email").unique();
        });
    }

    function down() {
        var schema = getSchema();
        // TODO: Add column removal when SchemaBuilder supports dropColumn()
        // schema.table("users", function(table) {
        //     table.dropColumn("email");
        // });
    }
}
```

### Migration Flags

- `--no-timestamps` - Don't add timestamps() for create migrations
- `--table=name` - Override inferred table name
- `--force` - Overwrite existing files

---

## Common Workflows

### 1. Blog Application Setup

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
```

### 2. REST API Application

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
```

### 3. Adding Features to Existing App

```bash
# Add new column to existing table
lucli generate migration AddAvatarToUsers avatar:string

# Generate new model
lucli generate model Category name:string slug:string:unique

# Generate handler for new model
lucli generate handler Categories

# Run new migrations
lucli migrate
```

---

## Flags and Options

### Global Flags

- `--force` - Overwrite existing files without prompting
- `--help` - Display help information

### Model Specific

- `--no-migration` - Don't generate migration file
- `--no-timestamps` - Don't add timestamps() to migration
- `--table=name` - Specify custom table name

### Handler Specific

- `--api` - Generate API-only handler (5 actions instead of 7)
- `--actions=list` - Comma-separated list of actions to generate

### New Command Specific

- `--database=type` - Database type (mysql, postgresql, sqlserver, h2)
- `--no-git` - Skip git initialization

---

## Troubleshooting

### Common Issues

#### Error: "File already exists"

**Problem:** Trying to generate a file that already exists.

**Solution:** Use `--force` flag to overwrite:
```bash
lucli generate model User name:string --force
```

#### Error: "Invalid component name"

**Problem:** Component name doesn't follow CFML naming rules.

**Solution:** Ensure names start with a letter and contain only alphanumeric characters and underscores:
```bash
# Bad
lucli generate model 123User

# Good
lucli generate model User123
```

#### Error: "Unknown generator type"

**Problem:** Invalid generator type specified.

**Solution:** Use one of the supported types: `model`, `handler`, `migration`:
```bash
lucli generate model User  # Correct
lucli generate controller User  # Wrong - use 'handler' instead
```

#### Generated Files Not Working

**Problem:** Generated code has syntax errors or doesn't run.

**Solution:** Verify:
1. Fuse framework is properly installed and mapped
2. Datasource is configured in `config/database.cfc`
3. Application.cfc has correct extends path

#### Migrations Not Running

**Problem:** Generated migrations fail when running `lucli migrate`.

**Solution:**
1. Check database connection in `config/database.cfc`
2. Verify migration file timestamp format (14 digits)
3. Ensure migration extends `fuse.orm.Migration`
4. Check migration SQL syntax for your database type

### Getting Help

```bash
# Display general help
lucli help

# Display generate command help
lucli generate help

# Display new command help
lucli new --help
```

### Debug Mode

To see more detailed output during generation, check the CLI output for:
- File creation messages
- Error stack traces
- Validation warnings

### Template Customization Issues

If custom templates aren't being used:
1. Verify template file is in `config/templates/`
2. Check template filename matches exactly (e.g., `model.cfc.tmpl`)
3. Ensure template has proper variable placeholders (`{{variableName}}`)

---

## Next Steps

After generating your application components:

1. **Configure Database** - Edit `config/database.cfc` with your connection details
2. **Run Migrations** - `lucli migrate` to create database tables
3. **Customize Code** - Add business logic to generated models and handlers
4. **Add Routes** - Configure routes in `config/routes.cfc`
5. **Write Tests** - Create tests for your generated components
6. **Start Server** - `lucli server start` to run your application

## Additional Resources

- [Fuse ORM Documentation](../../../README.md)
- [Migration Guide](../../../database/migrations/README.md)
- [ActiveRecord Guide](../../../fuse/orm/README.md)
- [Handler Patterns](../../../tests/fixtures/handlers/README.md)
