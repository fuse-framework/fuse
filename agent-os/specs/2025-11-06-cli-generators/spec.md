# Specification: CLI Generators

## Goal
Implement Rails-quality code generators for Fuse framework as CFML lucli modules, enabling developers to scaffold applications and generate models, handlers, and migrations with intelligent attribute parsing and template-based file generation.

## User Stories
- As a developer, I want to scaffold a new Fuse application with `lucli new my-app` so that I can start building immediately with proper structure
- As a developer, I want to generate models with `lucli generate model User name:string email:string:unique` so that I get both the ActiveRecord model and migration without manual setup

## Specific Requirements

**NewCommand - Application Scaffolding**
- Create complete app skeleton with directories: `/app/{models,handlers,views}`, `/database/migrations`, `/config`, `/tests`, `/modules`, `/public`
- Generate `Application.cfc` extending from `/fuse/templates/Application.cfc` pattern with datasource config and framework bootstrap
- Generate `.gitignore` with Lucee-specific ignores (WEB-INF/, lucee-server/, .env, logs/)
- Generate `box.json` with app metadata and dependencies
- Generate `README.md` with quickstart instructions for running migrations and dev server
- Support `--database` flag (mysql|postgresql|sqlserver|h2, default: mysql) and `--no-git` flag
- Output "create" messages for each file/directory created with path relative to app root

**Model Generator with Migration**
- Parse attribute syntax `name:type:modifier` where type = string|text|integer|boolean|date|datetime|decimal|references
- Generate ActiveRecord model in `app/models/` extending `fuse.orm.ActiveRecord` with relationships/validations placeholders
- Auto-generate migration in `database/migrations/YYYYMMDDHHMMSS_CreateTableName.cfc` unless `--no-migration` flag
- Use Migration.getSchema() pattern for DSL access (schema.create, schema.table)
- Auto-add `table.timestamps()` unless `--no-timestamps` flag
- Detect `user:references` → generate `table.integer("user_id").index()` and relationship comment
- Pluralize model name to table name (User → users) using simple +s approach
- Support `--table=custom_name` override flag

**Migration Generator Standalone**
- Detect "Create*" pattern in name → generate create table migration with `schema.create()`
- Detect "Add*To*" pattern → generate alter table migration with `schema.table()` adding columns
- Detect "Remove*From*" pattern → generate alter table migration with column removal comment (not implemented in SchemaBuilder yet)
- Generate timestamp prefix using `dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss")` matching Migrator pattern
- Parse attributes and generate appropriate TableBuilder column definitions
- Include `up()` and `down()` methods with reversible operations where possible
- Support `--table=name` to override table name inference

**Handler Generator RESTful**
- Generate handler CFC in `app/handlers/` with 7 RESTful actions: index(), show(id), new(), create(), edit(id), update(id), destroy(id)
- Follow pattern from `/tests/fixtures/handlers/Users.cfc` with optional constructor DI
- Include JSDoc-style comments for each action with HTTP method and route
- Support `--api` flag to skip new() and edit() actions, all methods return structs instead of view names
- Support `--actions=index,show,create` to generate only specified actions
- Support namespace syntax `Api/V1/Users` creating nested directories automatically
- Use consistent return format: struct for data actions, string view name for form actions

**Template Engine**
- Implement `{{variable}}` interpolation in `.tmpl` files to avoid conflict with CFML syntax
- Support template override: search `config/templates/` first, fallback to `fuse/cli/templates/`
- Variables: {{componentName}}, {{tableName}}, {{timestamp}}, {{date}}, {{columns}}, {{relationships}}, {{actions}}
- Simple string replacement approach (no complex parsing needed)

**Attribute Parser**
- Parse `name:type:modifier:modifier` format into struct with name, type, modifiers array
- Map types to TableBuilder methods: string→string(), text→text(), integer→integer(), boolean→boolean(), date→date(), datetime→datetime(), decimal→decimal()
- Handle modifiers: unique→.unique(), index→.index(), notnull→.notNull(), default:value→.default(value)
- Handle special type `references` → convert "user:references" to "user_id:integer:index" and track relationship
- Throw clear validation errors for unknown types or invalid attribute format

**File Generator Utility**
- Check if file exists before writing, prompt error if exists without `--force` flag
- Create parent directories recursively if they don't exist
- Write files with consistent line endings (LF)
- Return success/failure messages for CLI output

**Naming Conventions Helper**
- Pluralize: simple append "s" (User→users, Post→posts) for Phase 1
- Pascalize: convert "blog_post" to "BlogPost" for component names
- Tableize: convert "BlogPost" to "blog_posts" (snake case + pluralize)
- Validate CFML identifier rules: start with letter, alphanumeric + underscore only

## Visual Design

**CLI Command Syntax**
```bash
# New application
lucli new my-blog-app
lucli new my-api --database=postgresql --no-git

# Model generation
lucli generate model User name:string email:string:unique age:integer
lucli generate model Post title:string body:text user:references --no-timestamps
lucli generate model Article title:string --no-migration

# Handler generation
lucli generate handler Users
lucli generate handler Posts --actions=index,show,create
lucli generate handler Api/V1/Users --api

# Migration generation
lucli generate migration CreatePosts title:string body:text
lucli generate migration AddEmailToUsers email:string:unique
lucli generate migration RemovePhoneFromUsers phone:string
```

**Output Format**
```
Creating new Fuse application: my-blog-app

   create  my-blog-app/
   create  my-blog-app/Application.cfc
   create  my-blog-app/app/models/
   create  my-blog-app/app/handlers/
   create  my-blog-app/config/routes.cfc
   create  my-blog-app/database/migrations/
   create  my-blog-app/README.md

Application created successfully!

Next steps:
  cd my-blog-app
  lucli server start
  lucli migrate
```

**Error Output**
```
Error: Invalid component name "123User"
Component names must start with letter, alphanumeric + underscore only.

Usage: lucli generate model <ModelName> [attributes]
Example: lucli generate model User name:string email:string
```

## Existing Code to Leverage

**fuse.orm.Migration base class**
- Use `getSchema()` method to access SchemaBuilder instance
- Extend this class for all generated migrations
- Follow up()/down() pattern from `/database/migrations/20251105000001_CreateUsersTable.cfc`

**fuse.orm.ActiveRecord base class**
- Extend for all generated models
- Leverages automatic pluralization: component name + "s" → table name
- Supports `this.tableName` and `this.primaryKey` overrides
- Call `super.init(datasource)` in model init, define relationships/validations after

**fuse.orm.SchemaBuilder DSL**
- Already provides schema.create(), schema.table(), schema.drop()
- Use in migration templates for up()/down() implementations

**fuse.orm.TableBuilder column types**
- Available methods: id(), string(name, length), text(name), integer(name), bigInteger(name), boolean(name), decimal(name, precision, scale), date(name), datetime(name), timestamps()
- Modifiers: notNull(), unique(), default(value), index()
- Use these methods in generated migration column definitions

**fuse.orm.Migrator timestamp logic**
- Filename format: 14-digit timestamp prefix (YYYYMMDDHHMMSS)
- Use `dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss")` to match pattern
- Migrator.discoverMigrations() expects this exact format (lines 245-254)

**Existing example files for template patterns**
- Handler: `/tests/fixtures/handlers/Users.cfc` shows RESTful actions, constructor DI, JSDoc comments
- Model: `/tests/fixtures/PostWithRelationships.cfc` shows relationship definitions in init()
- Migration create: `/database/migrations/20251105000001_CreateUsersTable.cfc` shows schema.create pattern
- Migration alter: `/database/migrations/20251105000003_AddPhoneToUsers.cfc` shows schema.table pattern
- Application.cfc: `/fuse/templates/Application.cfc` shows bootstrap pattern to replicate

## Out of Scope

**Deferred to Phase 2 (Roadmap #13 CLI Database & Dev Tools)**
- Module generator (IModule interface implementation)
- Scaffold generator combining model + handler + views + migration
- Test generators for models and handlers
- Resource generator (Rails-style combined generation)
- View/template generation with handlers

**Advanced Features Not in Phase 1**
- Interactive prompts for missing arguments (validate only, no prompts)
- Undo/rollback of generated files (manual deletion required)
- Custom generator creation by users (framework generators only)
- Template variables from config files (static variables only)
- Multi-database support in NewCommand (single datasource only)
- Foreign key constraint generation in migrations (simple references tracking only)
- Advanced pluralization rules (person→people, mouse→mice) - simple +s only
- View generation alongside handlers (handler-only generation)
- Namespace auto-registration in routes (manual route setup)
- Factory generation with models (manual factory creation)
- Automatic migration generation from model changes (explicit migration generation only)
- Column dropping in down() migrations (comment placeholder until SchemaBuilder supports it)
