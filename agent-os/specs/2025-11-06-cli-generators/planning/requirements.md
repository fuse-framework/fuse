# Spec Requirements: CLI Generators

## Initial Description
Implement code generators for Fuse framework integrated with lucli CLI. Includes NewCommand for app scaffolding and GenerateCommand for models/handlers/migrations/modules with template system.

## Research Context

### lucli Architecture Analysis
**Module System:**
- lucli loads CFML modules from `~/.lucli/modules/` and project-level module directories
- Modules are CFCs with a `main()` function that receives `__arguments` array
- Module invocation: `lucli <module-name> <args>` or `lucli modules run <module-name> <args>`
- Direct execution without "modules" prefix for convenience
- Arguments passed as array via special `__arguments` variable

**Command Pattern:**
- Java-based core commands (server, modules, cfml, prompt)
- CFML extension modules for framework-specific commands
- StringOutput system with emoji support and placeholder substitution
- Template-based script execution from `src/main/resources/script_engine/`

**Integration Point:**
Fuse CLI commands should be CFML modules loaded by lucli, NOT Java commands. Place in `fuse/cli/` directory and symlink/load into lucli module path.

### Fuse Framework Patterns

**ActiveRecord Models:**
- Extend `fuse.orm.ActiveRecord`
- Convention: Component name → table name (User → users)
- Optional overrides: `this.tableName`, `this.primaryKey`
- Relationships defined in `init()`: `this.hasMany()`, `this.belongsTo()`, `this.hasOne()`
- Validations: `this.validates("field", {rules})`
- Callbacks: `this.beforeSave()`, `this.afterCreate()`, etc.

**Migrations:**
- Extend `fuse.orm.Migration`
- Filename format: `YYYYMMDDHHMMSS_DescriptiveName.cfc`
- `up()` and `down()` methods
- Schema builder DSL: `schema.create()`, `schema.table()`, `schema.drop()`
- Column types: `id()`, `string()`, `text()`, `integer()`, `boolean()`, `timestamps()`
- Modifiers: `notNull()`, `unique()`, `default()`, `index()`

**Handlers:**
- Plain CFCs (no base class required)
- Convention: Filename matches handler name (Users.cfc)
- RESTful actions: `index()`, `show(id)`, `new()`, `create()`, `edit(id)`, `update(id)`, `destroy(id)`
- Constructor DI supported: `init(logger, userService)`
- Return struct for JSON/data or string for view name

**Modules:**
- Implement `fuse.core.IModule` interface
- Methods: `register(container)`, `boot(container)`, `getDependencies()`, `getConfig()`
- Register services in DI container during `register()`
- Set up interceptors/hooks during `boot()`
- Convention: Module.cfc in module directory

**Directory Structure:**
```
/app
  /models          - ActiveRecord models
  /handlers        - Request handlers (controllers)
  /views           - CFM templates
/database
  /migrations      - Migration CFCs
  /seeds           - Seed data (future)
/modules           - Application modules
/config            - Configuration files
/tests             - Test files
/fuse              - Framework code
  /cli             - CLI command modules
Application.cfc    - Bootstrap
```

### Reference Framework Patterns

**Rails Generator Intelligence:**
- Attribute parsing: `name:string email:string:unique age:integer active:boolean`
- Type inference: Generates appropriate migration column types
- Relationship detection: `user:references` creates foreign key + belongs_to
- Template interpolation with ERB: `<%= class_name %>`, `<%= table_name %>`
- Timestamp injection: Auto-adds created_at/updated_at
- Migration numbering: UTC timestamp prefix (20251106123045)

**Laravel Artisan Patterns:**
- Stub-based templates: Stubs in framework, overridable in app
- Command syntax: `php artisan make:model User --migration --controller`
- Namespace resolution: Automatically adds correct namespace paths
- Test generation: Optional `--test` flag generates matching test
- Force overwrite: `--force` flag to overwrite existing files

**Django manage.py Patterns:**
- App-scoped generation: `python manage.py startapp <name>`
- Migration auto-detection: Detects model changes and generates migrations
- Template discovery: Multiple template directory search paths
- Admin registration: Auto-generates admin.py with model registration

### Key Recommendations

**Command Structure Decision:**
Use lucli module approach (CFML CFCs), NOT Java commands. Reasoning:
- Faster iteration (no Maven rebuild)
- Access to Fuse framework code directly
- Consistent with lucli extension model
- Easy for community to extend

**Module Location:**
- Framework commands: `fuse/cli/commands/*.cfc`
- lucli loads via symlink or direct path mapping
- Each command is a CFC with `main()` function

**NewCommand Scaffolding:**
Generate complete Rails-style application skeleton:
- `/app` directory structure (models, handlers, views)
- `/database/migrations` directory
- `/modules` directory for app modules
- `/config` directory with defaults
- `/tests` directory structure
- `Application.cfc` with Fuse bootstrap
- `.gitignore` with CFML-specific ignores
- `box.json` for dependencies
- `README.md` with quickstart

**Generator Command Syntax:**
```bash
lucli generate model User name:string email:string:unique
lucli generate handler Users
lucli generate migration AddPhoneToUsers phone:string
lucli generate module Search
```

**Intelligent Features:**
- Migration naming inference: "Add...To..." → alter table, "Create..." → create table
- Timestamp columns: Auto-add `created_at`/`updated_at` unless `--no-timestamps`
- Foreign key detection: `user:references` → `user_id:integer` + index + relationship
- Plural/singular conventions: Handler "Users" → routes for plural, Model "User" → singular table inference
- Interactive prompts: If name missing, prompt with defaults

**Template System:**
- Template location: `fuse/cli/templates/*.cfc.tmpl` and `*.cfm.tmpl`
- Interpolation syntax: `{{variableName}}` (CFML-friendly, no conflict with CFML syntax)
- Variables available: `{{componentName}}`, `{{tableName}}`, `{{attributes}}`, `{{timestamp}}`
- Custom templates: Override by placing in `/config/templates/` in app
- Template helpers: Functions for pluralization, case conversion, attribute parsing

**Generator Priorities (Phase 1 - Medium Scope):**
MUST HAVE:
1. NewCommand - Full app scaffolding
2. Model generator - With optional migration
3. Migration generator - Standalone migrations
4. Handler generator - RESTful actions

DEFER to CLI Database & Dev Tools (roadmap #13):
- Module generator (simpler, lower priority)
- Scaffold generator (combines model + handler + views)
- Test generators (depends on test framework maturity)

### Existing Code to Leverage

**Fuse Components:**
- `fuse.orm.Migration` - Base class for migrations
- `fuse.orm.ActiveRecord` - Base class for models
- `fuse.orm.SchemaBuilder` - Schema DSL already exists
- `fuse.orm.Migrator` - Migration runner (has timestamping logic)
- `fuse.core.ModuleLoader` - Module discovery patterns
- `fuse.testing.TestCase` - Base test class (for future test generators)

**Template Reference:**
- Existing migration examples in `database/migrations/`
- Handler examples in `tests/fixtures/handlers/`
- Model examples in `tests/fixtures/`
- Module examples in `fuse/modules/` and `tests/fixtures/modules/`
- Application.cfc template in `fuse/templates/`

## Command Structure Decisions

### Architecture
**Approach:** CFML lucli modules in `fuse/cli/commands/`, NOT Java commands

**Rationale:**
- Faster development cycle (no Maven build required)
- Direct access to Fuse framework classes
- Community-extensible (pure CFML)
- Consistent with lucli's module extension pattern

### Module Structure
Each generator is a CFC module with:
```cfml
component {
    public function main() {
        var args = __arguments ?: [];
        // Parse arguments
        // Validate inputs
        // Generate files from templates
        // Output success/error messages
    }
}
```

### Invocation
```bash
lucli new my-blog-app
lucli generate model User name:string email:string
lucli generate handler Posts
lucli generate migration AddStatusToPosts status:string
```

### File Organization
```
/fuse
  /cli
    /commands
      New.cfc                    # App scaffolding
      Generate.cfc               # Dispatcher for sub-generators
    /generators
      ModelGenerator.cfc         # Model generation logic
      HandlerGenerator.cfc       # Handler generation logic
      MigrationGenerator.cfc     # Migration generation logic
    /templates
      model.cfc.tmpl
      handler.cfc.tmpl
      create_migration.cfc.tmpl
      alter_migration.cfc.tmpl
      Application.cfc.tmpl
    /support
      AttributeParser.cfc        # Parse "name:string:unique" syntax
      TemplateEngine.cfc         # {{variable}} interpolation
      FileGenerator.cfc          # File writing utilities
      NamingConventions.cfc      # Pluralization, case conversion
```

### Integration with lucli
Options:
1. **Symlink approach:** lucli config points to `fuse/cli/commands/`
2. **Copy approach:** Fuse install copies commands to `~/.lucli/modules/fuse/`
3. **Project approach:** lucli auto-discovers commands in `./fuse/cli/commands/` when run from Fuse app

**Recommendation:** Project approach - lucli discovers Fuse commands when CWD is Fuse app. Simplest, no installation step needed.

## NewCommand Scaffolding

### Purpose
Bootstrap complete Fuse application with Rails-like conventions and structure.

### Invocation
```bash
lucli new my-blog-app [options]
lucli new my-blog-app --database=mysql --no-git
```

### Generated Structure
```
my-blog-app/
├── .gitignore
├── Application.cfc
├── box.json
├── README.md
├── server.json
├── app/
│   ├── handlers/
│   │   └── .gitkeep
│   ├── models/
│   │   └── .gitkeep
│   └── views/
│       ├── layouts/
│       │   └── application.cfm
│       └── .gitkeep
├── config/
│   ├── application.cfc
│   ├── database.cfc
│   ├── routes.cfc
│   └── templates/
│       └── .gitkeep
├── database/
│   ├── migrations/
│   │   └── .gitkeep
│   └── seeds/
│       └── .gitkeep
├── modules/
│   └── .gitkeep
├── public/
│   ├── css/
│   │   └── app.css
│   ├── js/
│   │   └── app.js
│   └── index.cfm
├── tests/
│   ├── fixtures/
│   │   └── .gitkeep
│   ├── integration/
│   │   └── .gitkeep
│   └── unit/
│       └── .gitkeep
└── fuse -> [symlink to framework]
```

### Key Files Generated

**Application.cfc:**
- Standard Fuse bootstrap
- Datasource configuration
- Mapping to `/fuse` framework path
- `onApplicationStart()` with `Bootstrap.initFramework()`
- `onRequestStart()` with framework initialization check

**config/routes.cfc:**
- Empty routing configuration with example commented out
- Instructions for adding routes

**config/database.cfc:**
- Datasource configuration based on --database flag
- Environment-based configuration (dev/test/prod)

**README.md:**
- Quickstart instructions
- How to run migrations
- How to start dev server
- How to run tests
- Links to Fuse documentation

**.gitignore:**
```
# Lucee
WEB-INF/
lucee-server/

# Environment
.env
.env.local

# Logs
logs/
*.log

# OS
.DS_Store
Thumbs.db

# IDE
.idea/
.vscode/
*.sublime-*
```

**box.json:**
```json
{
    "name": "my-blog-app",
    "version": "0.1.0",
    "type": "app",
    "dependencies": {}
}
```

### Options
- `--database=mysql|postgresql|sqlserver|h2` - Database type (default: mysql)
- `--no-git` - Skip git initialization
- `--minimal` - Skip public/, tests/, example files (bare minimum)
- `--api` - API-only structure (no views/, public/ directories)

### Output
```
Creating new Fuse application: my-blog-app

   create  my-blog-app/
   create  my-blog-app/Application.cfc
   create  my-blog-app/app/handlers/
   create  my-blog-app/app/models/
   create  my-blog-app/app/views/layouts/application.cfm
   create  my-blog-app/config/routes.cfc
   create  my-blog-app/database/migrations/
   create  my-blog-app/README.md
   ...

Application created successfully!

Next steps:
  cd my-blog-app
  lucli server start
  lucli migrate

Documentation: https://fusecfml.com/getting-started
```

## Generator Commands

### Generate Command Structure

**Main entry point:** `Generate.cfc` dispatches to specific generators

```bash
lucli generate <type> <name> [attributes] [options]
```

**Supported types:** model, handler, migration, module (future)

### Model Generator

**Syntax:**
```bash
lucli generate model User name:string email:string:unique age:integer active:boolean
lucli generate model Post title:string body:text user:references published:boolean --timestamps
lucli generate model Article title:string --no-migration
```

**Attribute Format:** `name:type:modifier:modifier`
- Types: `string`, `text`, `integer`, `boolean`, `date`, `datetime`, `decimal`, `references`
- Modifiers: `unique`, `index`, `notnull`, `default:value`

**Generated Files:**
1. Model CFC: `app/models/User.cfc`
2. Migration (unless `--no-migration`): `database/migrations/YYYYMMDDHHMMSS_CreateUsers.cfc`

**Model Template Output:**
```cfml
/**
 * User Model
 *
 * Generated by Fuse CLI
 */
component extends="fuse.orm.ActiveRecord" {

    // Optional: Override conventions
    // this.tableName = "users";
    // this.primaryKey = "id";

    public function init(required string datasource) {
        super.init(arguments.datasource);

        // Define relationships
        // this.hasMany("posts");
        // this.belongsTo("team");

        // Define validations
        // this.validates("email", {required: true, email: true});
        // this.validates("name", {required: true, length: {min: 2}});

        return this;
    }

}
```

**Migration Template Output (Create Table):**
```cfml
/**
 * Migration: Create Users Table
 *
 * Generated by Fuse CLI
 */
component extends="fuse.orm.Migration" {

    public function up() {
        schema.create("users", function(table) {
            table.id();
            table.string("name").notNull();
            table.string("email").notNull().unique();
            table.integer("age");
            table.boolean("active").default(1);
            table.timestamps();
        });
    }

    public function down() {
        schema.drop("users");
    }

}
```

**Intelligence:**
- `user:references` generates:
  - Migration: `table.integer("user_id").index()`
  - Model: `this.belongsTo("user")` in comment
- Pluralization: "User" model → "users" table
- Timestamps: Auto-added unless `--no-timestamps`

**Options:**
- `--no-migration` - Generate model only, skip migration
- `--no-timestamps` - Skip created_at/updated_at columns
- `--table=custom_name` - Override table name convention

### Handler Generator

**Syntax:**
```bash
lucli generate handler Users
lucli generate handler Posts --actions=index,show,create
lucli generate handler Api/V1/Users --api
```

**Generated File:** `app/handlers/Users.cfc`

**Handler Template Output (Full RESTful):**
```cfml
/**
 * Users Handler
 *
 * Generated by Fuse CLI
 */
component {

    public function init() {
        return this;
    }

    /**
     * List all users (GET /users)
     */
    public struct function index() {
        return {
            success: true,
            users: []
        };
    }

    /**
     * Show single user (GET /users/:id)
     */
    public struct function show(required string id) {
        return {
            success: true,
            id: arguments.id
        };
    }

    /**
     * Show new user form (GET /users/new)
     */
    public string function new() {
        return "users/new";
    }

    /**
     * Create new user (POST /users)
     */
    public struct function create() {
        return {
            success: true
        };
    }

    /**
     * Show edit user form (GET /users/:id/edit)
     */
    public string function edit(required string id) {
        return "users/edit";
    }

    /**
     * Update user (PUT/PATCH /users/:id)
     */
    public struct function update(required string id) {
        return {
            success: true,
            id: arguments.id
        };
    }

    /**
     * Delete user (DELETE /users/:id)
     */
    public struct function destroy(required string id) {
        return {
            success: true,
            id: arguments.id
        };
    }

}
```

**Options:**
- `--actions=index,show,create` - Generate only specified actions
- `--api` - API-only handler (no `new()` or `edit()` actions, all return structs)
- `--no-comments` - Skip documentation comments

**Namespace Support:**
```bash
lucli generate handler Api/V1/Users
# Creates: app/handlers/Api/V1/Users.cfc
# With proper directory structure
```

### Migration Generator

**Syntax:**
```bash
lucli generate migration CreatePosts title:string body:text
lucli generate migration AddEmailToUsers email:string:unique
lucli generate migration AddIndexToPostsTitle --table=posts --index=title
lucli generate migration RemovePhoneFromUsers
```

**Intelligence - Create Table Detection:**
- Pattern: `Create*` or `CreateTable*` → create table migration
- Example: `CreatePosts` → `schema.create("posts", ...)`

**Intelligence - Alter Table Detection:**
- Pattern: `Add*To*` or `Remove*From*` → alter table migration
- Example: `AddEmailToUsers` → `schema.table("users", ...)` with add column
- Example: `RemovePhoneFromUsers` → `schema.table("users", ...)` with drop column

**Generated File:** `database/migrations/YYYYMMDDHHMMSS_CreatePosts.cfc`

**Create Migration Template:**
```cfml
/**
 * Migration: Create Posts Table
 *
 * Generated by Fuse CLI
 */
component extends="fuse.orm.Migration" {

    public function up() {
        schema.create("posts", function(table) {
            table.id();
            table.string("title").notNull();
            table.text("body");
            table.timestamps();
        });
    }

    public function down() {
        schema.drop("posts");
    }

}
```

**Alter Migration Template (Add Columns):**
```cfml
/**
 * Migration: Add Email To Users
 *
 * Generated by Fuse CLI
 */
component extends="fuse.orm.Migration" {

    public function up() {
        schema.table("users", function(table) {
            table.string("email").unique();
        });
    }

    public function down() {
        schema.table("users", function(table) {
            // Note: Column dropping not implemented in current schema builder
            // table.dropColumn("email");
        });
    }

}
```

**Options:**
- `--table=name` - Explicitly specify table name (overrides inference)
- `--no-timestamps` - Skip timestamps for create table
- `--create=table` - Force create table migration
- `--alter=table` - Force alter table migration

**Timestamp Generation:**
Use `now()` formatted as `YYYYMMDDHHMMSS`:
```cfml
var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
var filename = timestamp & "_" & migrationName & ".cfc";
```

## Template System

### Template Location
**Primary:** `fuse/cli/templates/*.tmpl`
**Override:** `config/templates/*.tmpl` (project-specific customization)

**Search order:**
1. Project templates: `config/templates/`
2. Framework templates: `fuse/cli/templates/`

### Template Files
```
fuse/cli/templates/
├── model.cfc.tmpl
├── handler.cfc.tmpl
├── handler_api.cfc.tmpl
├── create_migration.cfc.tmpl
├── alter_migration.cfc.tmpl
├── module.cfc.tmpl
├── app/
│   ├── Application.cfc.tmpl
│   ├── routes.cfc.tmpl
│   ├── database.cfc.tmpl
│   └── README.md.tmpl
└── views/
    └── layout.cfm.tmpl
```

### Interpolation Syntax
Use `{{variableName}}` for clarity and no conflict with CFML syntax.

**Supported in all templates:**
- `{{componentName}}` - Component name (e.g., "User")
- `{{tableName}}` - Table name (e.g., "users")
- `{{timestamp}}` - Current timestamp (YYYYMMDDHHMMSS format)
- `{{date}}` - Current date (YYYY-MM-DD format)

**Model-specific:**
- `{{relationships}}` - Generated relationship definitions (if any)
- `{{validations}}` - Generated validation rules (if any)

**Migration-specific:**
- `{{migrationName}}` - Descriptive name (e.g., "CreateUsersTable")
- `{{columns}}` - Generated column definitions
- `{{tableName}}` - Table name for schema operations

**Handler-specific:**
- `{{actions}}` - Generated action methods
- `{{namespace}}` - Namespace/directory path if nested

### Template Engine Implementation

**Core component:** `fuse/cli/support/TemplateEngine.cfc`

```cfml
component {
    public function render(required string templatePath, required struct variables) {
        // Read template file
        var template = fileRead(arguments.templatePath);

        // Replace {{variable}} with values
        for (var key in arguments.variables) {
            var placeholder = "{{" & key & "}}";
            template = replace(template, placeholder, variables[key], "ALL");
        }

        return template;
    }
}
```

**Variable escaping:** Not needed - templates are code, not HTML

### Template Customization

**Override templates per project:**
1. Copy template from `fuse/cli/templates/` to `config/templates/`
2. Modify as needed
3. Generator automatically uses project template if exists

**Example use case:**
- Team wants different model structure
- Copy `fuse/cli/templates/model.cfc.tmpl` → `config/templates/model.cfc.tmpl`
- Add team-specific comments, methods, or structure
- All future `generate model` commands use custom template

### Template Helpers

**Component:** `fuse/cli/support/NamingConventions.cfc`

```cfml
component {
    // Pluralize: "User" -> "users"
    public string function pluralize(required string word) {
        // Simple implementation for Phase 1
        return lcase(arguments.word & "s");
    }

    // Singularize: "users" -> "user"
    public string function singularize(required string word) {
        if (right(arguments.word, 1) == "s") {
            return left(arguments.word, len(arguments.word) - 1);
        }
        return arguments.word;
    }

    // Pascalize: "blog_post" -> "BlogPost"
    public string function pascalize(required string word) {
        var parts = listToArray(arguments.word, "_");
        var result = "";
        for (var part in parts) {
            result &= ucase(left(part, 1)) & lcase(mid(part, 2, len(part)));
        }
        return result;
    }

    // Tableize: "BlogPost" -> "blog_posts"
    public string function tableize(required string word) {
        // Convert PascalCase to snake_case and pluralize
        var snakeCase = reReplace(arguments.word, "([A-Z])", "_\1", "ALL");
        snakeCase = lcase(trim(snakeCase, "_"));
        return pluralize(snakeCase);
    }
}
```

## Scope & Priorities

### Phase 1: CLI Generators (Roadmap #12 - Medium Scope)

**MUST HAVE - Core Generators:**
1. **NewCommand** - Complete app scaffolding with all directories/files
2. **Model Generator** - ActiveRecord models with optional migrations
3. **Migration Generator** - Standalone create/alter table migrations
4. **Handler Generator** - RESTful handlers with standard actions

**MUST HAVE - Support Components:**
1. **TemplateEngine** - `{{variable}}` interpolation system
2. **AttributeParser** - Parse `name:string:unique` syntax
3. **FileGenerator** - Safe file creation with overwrite protection
4. **NamingConventions** - Pluralization, tableize, pascalize helpers

**MUST HAVE - Templates:**
1. App scaffold templates (Application.cfc, routes, README, etc.)
2. Model template with relationships/validations placeholders
3. Handler template (full RESTful + API-only variant)
4. Migration templates (create table + alter table)

**QUALITY REQUIREMENTS:**
- Overwrite protection: Prompt before overwriting existing files
- Validation: Ensure names are valid CFML identifiers
- Error handling: Clear error messages for invalid input
- Help text: `--help` for all commands shows usage and examples
- Output: Colored/emoji output using lucli StringOutput conventions

### DEFER to Phase 2: CLI Database & Dev Tools (Roadmap #13)

**Module Generator:**
- Lower priority than models/handlers/migrations
- Simpler pattern (just implement IModule interface)
- Less frequently used by developers

**Scaffold Generator:**
- Combines model + handler + views + migration
- Depends on mature model/handler generators first
- More complex template coordination

**Test Generators:**
- Requires test framework maturity (roadmap #10-11 just completed)
- Needs TestCase patterns to stabilize
- Lower urgency than core generators

**Resource Generator:**
- Rails-style resource generator (model + handler + routes + views)
- Combines multiple generators
- Phase 2 enhancement

### OUT OF SCOPE (Future)

**Advanced Features:**
- Interactive prompts for missing arguments (basic validation only in Phase 1)
- Undo/rollback of generators (manual deletion in Phase 1)
- Custom generator creation (users can't define their own generators yet)
- Template variables from config (static variables only in Phase 1)
- Multi-database support in NewCommand (single datasource only)
- Foreign key constraint generation in migrations (simple references only)

**Nice-to-Have Enhancements:**
- Pluralization edge cases (person/people, mouse/mice) - simple +s in Phase 1
- Namespace auto-registration in routes (manual route setup required)
- View generation with handlers (handlers only in Phase 1)
- Factory generation with models (manual factory creation)

## Existing Code Integration

### Fuse Components to Leverage

**Migration System:**
- `fuse.orm.Migration` - Base class, already stable
- `fuse.orm.SchemaBuilder` - Schema DSL exists, use in templates
- `fuse.orm.Migrator` - Has timestamp generation logic to reuse

**Model System:**
- `fuse.orm.ActiveRecord` - Base class for generated models
- `fuse.orm.ModelBuilder` - Query builder (no direct generator use)
- `fuse.orm.Validator` - Validation system (reference for template comments)

**Module System:**
- `fuse.core.IModule` - Interface for module generators (Phase 2)
- `fuse.core.ModuleLoader` - Module discovery patterns (no direct use)

**Testing System:**
- `fuse.testing.TestCase` - Base for test generators (Phase 2)
- `fuse.testing.ModelFactory` - Factory patterns (Phase 2)

### Template Reference Code

**Existing Files to Reference:**
- Migration examples: `database/migrations/*.cfc` - Real migration patterns
- Handler examples: `tests/fixtures/handlers/*.cfc` - RESTful action patterns
- Model examples: `tests/fixtures/*.cfc` - Simple model patterns
- Module examples: `fuse/modules/*.cfc` - IModule implementations
- Application template: `fuse/templates/Application.cfc` - Bootstrap pattern

**Conventions to Follow:**
- Migration filenames: Timestamp prefix from existing migrations
- Handler actions: Match patterns in `tests/fixtures/handlers/Users.cfc`
- Model structure: Follow `tests/fixtures/PostWithRelationships.cfc` pattern
- Comments: Match documentation style in existing Fuse components

### Code Reuse Opportunities

**SchemaBuilder Introspection:**
```cfml
// Get available column types from SchemaBuilder
var schemaBuilder = new fuse.orm.SchemaBuilder("datasource");
// Reference existing table operations for migration templates
```

**Migrator Timestamp Logic:**
```cfml
// Reuse timestamp generation from Migrator
var migrator = new fuse.orm.Migrator("datasource", "/path");
// Check if similar timestamp generation method exists
```

**Naming Conventions:**
- ActiveRecord already does pluralization (name → names + "s")
- Reuse or mirror this logic in NamingConventions helper

## Reference Patterns from Rails/Laravel

### Rails Patterns to Adopt

**Attribute Parsing:**
- `name:string:index` syntax (clear, concise)
- `user:references` creates foreign key + relationship hint
- Type inference and smart defaults

**Migration Intelligence:**
- Name-based detection: "CreateUsers" vs "AddEmailToUsers"
- Automatic timestamp column inclusion
- Reversible migrations with `up()` and `down()`

**Template System:**
- ERB-style interpolation (adapted to `{{}}` for CFML)
- Template override via project directories
- Built-in helpers for naming (pluralize, tableize)

**Generator Output:**
- Clear "create" messages showing each file
- Color-coded success/error output
- Next steps guide after generation

### Laravel Patterns to Adopt

**Stub System:**
- Templates in framework, overridable in project
- Simple search path: project first, then framework

**Command Options:**
- Boolean flags: `--no-migration`, `--api`
- Value options: `--table=custom_name`
- Consistent `--help` across all generators

**Namespace Support:**
- Generate nested handlers: `Api/V1/Users`
- Automatic directory creation
- Namespace in component metadata (if needed in future)

### Django Patterns to Consider

**App-Scoped Generation:**
- Not applicable to Fuse (no app concept yet)
- But consider for future module-scoped generators

**Migration Auto-Detection:**
- Out of scope for Phase 1
- Future enhancement: Detect model changes, generate migrations

## Technical Considerations

### CFML-Specific Challenges

**Component Instantiation:**
- Generated models must be in correct path for `new app.models.User()`
- Mapping to `/app` may be needed in Application.cfc
- Document in README for new apps

**Case Sensitivity:**
- Lucee is case-insensitive for component names
- But filesystem may be case-sensitive (Linux/Mac)
- Recommendation: Use PascalCase for components, enforce in validation

**Static Method Syntax:**
- Lucee 7 double-colon: `User::find(1)`
- Ensure generated models work with static calls
- ActiveRecord base class already supports this

### File System Operations

**Safe File Writing:**
```cfml
component {
    public boolean function createFile(required string path, required string content, boolean force = false) {
        // Check if file exists
        if (fileExists(arguments.path) && !arguments.force) {
            // Prompt user or throw error
            return false;
        }

        // Ensure directory exists
        var directory = getDirectoryFromPath(arguments.path);
        if (!directoryExists(directory)) {
            directoryCreate(directory);
        }

        // Write file
        fileWrite(arguments.path, arguments.content);
        return true;
    }
}
```

**Overwrite Protection:**
- Default behavior: Refuse to overwrite existing files
- `--force` flag: Allow overwrite without prompt
- Output: "File exists: app/models/User.cfc (use --force to overwrite)"

**Atomic Operations:**
- Write to temp file first
- Validate generated content (parseable CFML?)
- Move to final location only if valid
- Prevents partial/corrupted files

### Error Handling

**Validation Errors:**
```
Error: Invalid component name "123User"
Component names must start with a letter and contain only letters, numbers, and underscores.

Usage: lucli generate model <ModelName> [attributes]
Example: lucli generate model User name:string email:string
```

**File System Errors:**
```
Error: Cannot create file /app/models/User.cfc
File already exists. Use --force to overwrite.
```

**Template Errors:**
```
Error: Template not found: model.cfc.tmpl
Expected location: /fuse/cli/templates/model.cfc.tmpl
```

**Attribute Parsing Errors:**
```
Error: Invalid attribute format "name:string:badmodifier"
Unknown modifier: badmodifier
Valid modifiers: unique, index, notnull, default:value

Example: name:string:unique:notnull
```

### Performance Considerations

**File I/O:**
- Templates loaded once per generator run
- No need for caching (generators run infrequently)
- Keep template files small and focused

**String Operations:**
- Pluralization/naming conventions called per entity
- Simple implementations fine for Phase 1
- Optimize in Phase 2 if needed (unlikely bottleneck)

**lucli Integration:**
- No performance concerns with CFML modules
- Lucee already loaded, fast execution
- Generator runs in milliseconds

## Summary

CLI Generators implementation provides Rails-quality code generation for Fuse framework:

**Architecture:**
- CFML modules in `fuse/cli/commands/` loaded by lucli
- Template-based generation with `{{variable}}` interpolation
- Intelligent naming conventions and attribute parsing

**Core Generators:**
1. NewCommand - Full app scaffolding
2. Model generator - ActiveRecord models + migrations
3. Migration generator - Create/alter table migrations
4. Handler generator - RESTful handlers

**Key Features:**
- Smart migration naming detection (Create/Add/Remove patterns)
- Foreign key syntax (`user:references`)
- Template override system (project > framework)
- Overwrite protection with `--force` flag
- Clean, colored output following lucli conventions

**Integration:**
- Leverages existing Fuse components (Migration, ActiveRecord, SchemaBuilder)
- Follows patterns from `tests/fixtures/` examples
- Uses Migrator timestamp generation
- Compatible with lucli module system

**Scope:**
Phase 1 delivers essential generators. Module/scaffold/test generators deferred to Phase 2 (Roadmap #13).
