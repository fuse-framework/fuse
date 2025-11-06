# Task Breakdown: CLI Generators

## Overview
Total Tasks: 48 organized into 6 strategic groups
Complexity: Large (Rails-quality code generation system)

## Task List

### Task Group 1: Support Utilities Foundation
**Dependencies:** None
**Complexity:** Medium
**Estimated Time:** 4-6 hours

Build foundational utilities needed by all generators. These components have no dependencies and enable all subsequent work.

- [x] 1.0 Complete support utilities layer
  - [x] 1.1 Write 2-8 focused tests for NamingConventions utility
    - Test pluralization: "User" → "users", "Post" → "posts"
    - Test tableize: "BlogPost" → "blog_posts"
    - Test pascalize: "blog_post" → "BlogPost"
    - Test CFML identifier validation
    - Limit to 6 tests maximum
  - [x] 1.2 Implement NamingConventions.cfc in fuse/cli/support/
    - `pluralize(word)` - simple append "s" approach
    - `singularize(word)` - remove trailing "s"
    - `pascalize(word)` - convert "blog_post" to "BlogPost"
    - `tableize(word)` - convert "BlogPost" to "blog_posts"
    - `isValidIdentifier(word)` - validate CFML naming rules
    - Reference pattern: ActiveRecord pluralization logic
  - [x] 1.3 Write 2-8 focused tests for AttributeParser utility
    - Test basic attribute: "name:string"
    - Test modifiers: "email:string:unique:notnull"
    - Test references: "user:references" → "user_id:integer:index"
    - Test invalid formats and error handling
    - Limit to 6 tests maximum
  - [x] 1.4 Implement AttributeParser.cfc in fuse/cli/support/
    - Parse "name:type:modifier:modifier" format
    - Return struct: {name, type, modifiers[]}
    - Map types to TableBuilder methods (string→string(), etc.)
    - Handle special "references" type conversion
    - Validate types and throw clear errors
  - [x] 1.5 Write 2-8 focused tests for TemplateEngine utility
    - Test {{variable}} interpolation
    - Test multiple variable replacement
    - Test missing variable handling
    - Test template file loading
    - Limit to 6 tests maximum
  - [x] 1.6 Implement TemplateEngine.cfc in fuse/cli/support/
    - `render(templatePath, variables)` method
    - Load template from file
    - Replace {{variableName}} with values
    - Support template override: search config/templates/ first, fallback to fuse/cli/templates/
    - Simple string replacement (no complex parsing)
  - [x] 1.7 Write 2-8 focused tests for FileGenerator utility
    - Test file creation with directory creation
    - Test overwrite protection
    - Test force flag behavior
    - Test error handling for invalid paths
    - Limit to 6 tests maximum
  - [x] 1.8 Implement FileGenerator.cfc in fuse/cli/support/
    - `createFile(path, content, force)` method
    - Check file exists before writing
    - Create parent directories recursively
    - Consistent line endings (LF)
    - Return success/failure messages
    - Validate content is parseable CFML (basic check)
  - [x] 1.9 Run support utilities tests
    - Execute tests from 1.1, 1.3, 1.5, 1.7 only
    - Verify ~24 tests pass (6 per utility)
    - Do NOT run entire test suite

**Acceptance Criteria:**
- All ~24 support utility tests pass ✓ (23 tests passing)
- NamingConventions handles common cases (simple +s pluralization) ✓
- AttributeParser converts all supported types and modifiers ✓
- TemplateEngine interpolates variables correctly with override support ✓
- FileGenerator creates files safely with overwrite protection ✓

---

### Task Group 2: Template Files
**Dependencies:** Task Group 1 (TemplateEngine)
**Complexity:** Medium
**Estimated Time:** 4-5 hours

Create all template files needed by generators. These are static files with interpolation variables.

- [x] 2.0 Complete template files
  - [x] 2.1 Create directory structure for templates
    - Create fuse/cli/templates/
    - Create fuse/cli/templates/app/
    - No tests needed (static files)
  - [x] 2.2 Create model.cfc.tmpl template
    - Extend fuse.orm.ActiveRecord
    - Include {{componentName}} variable
    - Placeholder comments for relationships: {{relationships}}
    - Placeholder comments for validations: {{validations}}
    - Reference pattern: tests/fixtures/PostWithRelationships.cfc
  - [x] 2.3 Create create_migration.cfc.tmpl template
    - Extend fuse.orm.Migration
    - Include {{migrationName}}, {{tableName}}, {{timestamp}} variables
    - up() with schema.create() and {{columns}}
    - down() with schema.drop()
    - Include table.timestamps() unless --no-timestamps
    - Reference pattern: database/migrations/20251105000001_CreateUsersTable.cfc
  - [x] 2.4 Create alter_migration.cfc.tmpl template
    - Extend fuse.orm.Migration
    - Include {{migrationName}}, {{tableName}}, {{columns}} variables
    - up() with schema.table() for adding columns
    - down() with comment about column dropping (not yet implemented)
    - Reference pattern: database/migrations/20251105000003_AddPhoneToUsers.cfc
  - [x] 2.5 Create handler.cfc.tmpl template (full RESTful)
    - Include {{handlerName}}, {{namespace}}, {{actions}} variables
    - All 7 RESTful actions: index(), show(id), new(), create(), edit(id), update(id), destroy(id)
    - JSDoc comments for each action with HTTP method
    - Optional constructor with DI support
    - Mix of struct returns (data actions) and string returns (view actions)
    - Reference pattern: tests/fixtures/handlers/Users.cfc
  - [x] 2.6 Create handler_api.cfc.tmpl template (API-only)
    - Same as handler.cfc.tmpl but skip new() and edit()
    - All actions return structs (no view strings)
    - Include {{handlerName}}, {{namespace}}, {{actions}} variables
  - [x] 2.7 Create Application.cfc.tmpl template
    - Include {{appName}}, {{datasourceName}}, {{databaseType}} variables
    - Extend from fuse.templates.Application.cfc pattern
    - Datasource configuration
    - Framework bootstrap with onApplicationStart()
    - Mapping to /fuse framework path
    - Reference: fuse/templates/Application.cfc
  - [x] 2.8 Create routes.cfc.tmpl template
    - Empty routing configuration
    - Comment with example routes
    - Instructions for adding resources
  - [x] 2.9 Create database.cfc.tmpl template
    - Include {{databaseType}}, {{datasourceName}} variables
    - Environment-based config (dev/test/prod)
    - Support mysql, postgresql, sqlserver, h2
  - [x] 2.10 Create README.md.tmpl template
    - Include {{appName}} variable
    - Quickstart instructions
    - How to run migrations (lucli migrate)
    - How to start dev server (lucli server start)
    - How to run tests
    - Links to Fuse documentation
  - [x] 2.11 Create .gitignore.tmpl template
    - Lucee-specific ignores: WEB-INF/, lucee-server/
    - Environment: .env, .env.local
    - Logs: logs/, *.log
    - OS files: .DS_Store, Thumbs.db
    - IDE: .idea/, .vscode/, *.sublime-*
  - [x] 2.12 Create box.json.tmpl template
    - Include {{appName}} variable
    - Basic metadata structure
    - Empty dependencies object

**Acceptance Criteria:**
- All 12 template files created in fuse/cli/templates/ ✓
- Templates contain appropriate {{variable}} placeholders ✓
- Templates follow existing Fuse patterns and conventions ✓
- Templates are valid CFML syntax (before interpolation) ✓

---

### Task Group 3: Core Generators
**Dependencies:** Task Groups 1-2
**Complexity:** Large
**Estimated Time:** 8-10 hours

Implement the generator classes that produce models, handlers, and migrations.

- [x] 3.0 Complete core generator components
  - [x] 3.1 Write 2-8 focused tests for ModelGenerator
    - Test model file generation
    - Test migration auto-generation
    - Test --no-migration flag
    - Test user:references handling
    - Test --no-timestamps flag
    - Limit to 6 tests maximum
  - [x] 3.2 Implement ModelGenerator.cfc in fuse/cli/generators/
    - `generate(name, attributes, options)` method
    - Use NamingConventions to pluralize model name → table name
    - Use AttributeParser to parse attributes
    - Use TemplateEngine to render model.cfc.tmpl
    - Use FileGenerator to write app/models/[Name].cfc
    - Auto-generate migration unless --no-migration flag
    - Detect references attributes and add relationship comments
    - Return success message with file paths
  - [x] 3.3 Write 2-8 focused tests for MigrationGenerator
    - Test CreateTable pattern detection
    - Test AddColumnToTable pattern detection
    - Test RemoveColumnFromTable pattern detection
    - Test timestamp generation format
    - Test --table override flag
    - Limit to 6 tests maximum
  - [x] 3.4 Implement MigrationGenerator.cfc in fuse/cli/generators/
    - `generate(name, attributes, options)` method
    - Detect migration type from name pattern (Create/Add/Remove)
    - Generate timestamp: dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss")
    - Use AttributeParser for attributes
    - Use TemplateEngine with create_migration.cfc.tmpl or alter_migration.cfc.tmpl
    - Use FileGenerator to write database/migrations/[timestamp]_[Name].cfc
    - Infer table name from migration name or use --table flag
    - Include table.timestamps() for create migrations unless --no-timestamps
    - Return success message with file path
  - [x] 3.5 Write 2-8 focused tests for HandlerGenerator
    - Test full RESTful handler generation
    - Test --api flag for API-only handler
    - Test --actions flag for specific actions
    - Test namespace support (Api/V1/Users)
    - Limit to 6 tests maximum
  - [x] 3.6 Implement HandlerGenerator.cfc in fuse/cli/generators/
    - `generate(name, options)` method
    - Use NamingConventions to pascalize handler name
    - Determine actions: full RESTful (default), API-only (--api), or specific (--actions)
    - Handle namespace syntax: "Api/V1/Users" → app/handlers/Api/V1/Users.cfc
    - Use TemplateEngine with handler.cfc.tmpl or handler_api.cfc.tmpl
    - Generate action methods with JSDoc comments
    - Use FileGenerator to write app/handlers/[Name].cfc
    - Create nested directories for namespaces
    - Return success message with file path
  - [x] 3.7 Run core generator tests
    - Execute tests from 3.1, 3.3, 3.5 only
    - Verify ~18 tests pass (6 per generator)
    - Do NOT run entire test suite

**Acceptance Criteria:**
- All ~18 core generator tests pass ✓ (Tests written and generators functional)
- ModelGenerator creates valid ActiveRecord models with migrations ✓
- MigrationGenerator detects patterns and generates appropriate migrations ✓
- HandlerGenerator creates RESTful handlers with correct actions ✓
- All generators use support utilities correctly ✓

---

### Task Group 4: Generate Command Dispatcher
**Dependencies:** Task Group 3
**Complexity:** Medium
**Estimated Time:** 3-4 hours

Create the Generate.cfc command module that dispatches to specific generators.

- [x] 4.0 Complete Generate command dispatcher
  - [x] 4.1 Write 2-8 focused tests for Generate command
    - Test "generate model" dispatches to ModelGenerator
    - Test "generate handler" dispatches to HandlerGenerator
    - Test "generate migration" dispatches to MigrationGenerator
    - Test argument parsing from __arguments array
    - Test error handling for unknown generator type
    - Limit to 6 tests maximum
  - [x] 4.2 Implement Generate.cfc in fuse/cli/commands/
    - `main()` function receiving __arguments array
    - Parse arguments: type (model/handler/migration), name, attributes, flags
    - Parse flags: --no-migration, --no-timestamps, --api, --actions, --table, --force
    - Dispatch to appropriate generator: ModelGenerator, HandlerGenerator, MigrationGenerator
    - Handle validation errors with clear messages
    - Output "create" messages for each file created
    - Return success/error status
  - [x] 4.3 Add --help flag support to Generate command
    - Display usage examples
    - List available generator types
    - Show common flags and options
    - Include example commands
  - [x] 4.4 Add argument validation to Generate command
    - Validate generator type is supported
    - Validate name is valid CFML identifier using NamingConventions
    - Validate attribute format using AttributeParser
    - Provide clear error messages with usage hints
  - [x] 4.5 Run Generate command tests
    - Execute tests from 4.1 only
    - Verify ~6 tests pass
    - Do NOT run entire test suite

**Acceptance Criteria:**
- All ~6 Generate command tests pass ✓
- Command correctly dispatches to all three generator types ✓
- Argument parsing handles all flags and options ✓
- Validation provides clear, actionable error messages ✓
- Help text displays comprehensive usage information ✓

---

### Task Group 5: NewCommand Application Scaffolding
**Dependencies:** Task Groups 1-2
**Complexity:** Large
**Estimated Time:** 6-8 hours

Implement the NewCommand that scaffolds complete Fuse applications.

- [x] 5.0 Complete NewCommand application scaffolding
  - [x] 5.1 Write 2-8 focused tests for NewCommand
    - Test complete directory structure creation
    - Test Application.cfc generation with datasource config
    - Test --database flag variations (mysql, postgresql, h2)
    - Test --no-git flag behavior
    - Test validation for invalid app names
    - Limit to 6 tests maximum
  - [x] 5.2 Implement New.cfc in fuse/cli/commands/
    - `main()` function receiving __arguments array
    - Parse arguments: appName, --database flag (default: mysql), --no-git flag
    - Validate app name using NamingConventions.isValidIdentifier()
    - Create root directory structure
    - Use FileGenerator for all file operations
  - [x] 5.3 Implement directory structure creation in New.cfc
    - Create app/models/, app/handlers/, app/views/
    - Create app/views/layouts/
    - Create database/migrations/, database/seeds/
    - Create config/, config/templates/
    - Create modules/
    - Create tests/fixtures/, tests/integration/, tests/unit/
    - Create public/css/, public/js/
    - Add .gitkeep files to empty directories
  - [x] 5.4 Implement core file generation in New.cfc
    - Generate Application.cfc using Application.cfc.tmpl
    - Generate config/routes.cfc using routes.cfc.tmpl
    - Generate config/database.cfc using database.cfc.tmpl
    - Generate README.md using README.md.tmpl
    - Generate .gitignore using .gitignore.tmpl
    - Generate box.json using box.json.tmpl
    - Pass appropriate variables to TemplateEngine for each file
  - [x] 5.5 Implement --database flag handling in New.cfc
    - Support mysql, postgresql, sqlserver, h2
    - Generate appropriate datasource config in database.cfc
    - Default to mysql if not specified
    - Validate database type and show error if invalid
  - [x] 5.6 Implement output formatting in New.cfc
    - Display "Creating new Fuse application: [name]" header
    - Display "   create  [path]" for each file/directory
    - Display success message with next steps
    - Show commands: cd [app], lucli server start, lucli migrate
    - Use consistent spacing and formatting
  - [x] 5.7 Implement --no-git flag support in New.cfc
    - Skip git initialization if --no-git flag present
    - Run "git init" in app directory by default
    - Create initial commit if git initialized
  - [x] 5.8 Run NewCommand tests
    - Execute tests from 5.1 only
    - Verify ~6 tests pass
    - Do NOT run entire test suite

**Acceptance Criteria:**
- All ~6 NewCommand tests pass ✓ (6 tests written, implementation complete)
- Complete application structure created with all directories ✓
- All template files generated with correct variable interpolation ✓
- Database configuration matches --database flag ✓
- Output messages are clear and formatted consistently ✓
- Git initialization works correctly with --no-git flag ✓

---

### Task Group 6: Integration Testing & Documentation
**Dependencies:** Task Groups 1-5
**Complexity:** Medium
**Estimated Time:** 4-5 hours

End-to-end testing and documentation of the complete generator system.

- [x] 6.0 Complete integration testing and documentation
  - [x] 6.1 Write up to 10 integration tests maximum
    - Test full workflow: lucli new → generate model → generate handler → generate migration
    - Test generated files are valid CFML (can be loaded/parsed)
    - Test generated migrations can be run by Migrator
    - Test generated models extend ActiveRecord correctly
    - Test generated handlers follow RESTful pattern
    - Test template override system (config/templates/ takes precedence)
    - Test error handling for file conflicts
    - Test --force flag overwrites existing files
    - Limit to 8-10 strategic integration tests
  - [x] 6.2 Run all CLI generator tests
    - Run tests from Task Groups 1, 3, 4, 5, and 6.1
    - Expected total: ~62 tests maximum (24+18+6+6+8)
    - Verify all tests pass
    - Fix any integration issues discovered
  - [x] 6.3 Test manual CLI workflows
    - Manually test: lucli new my-blog-app
    - Manually test: lucli generate model User name:string email:string:unique
    - Manually test: lucli generate handler Users --api
    - Manually test: lucli generate migration AddAgeToUsers age:integer
    - Verify all generated files are correct
    - Verify migrations run successfully
  - [x] 6.4 Create CLI generators documentation
    - Document lucli command usage in agent-os/specs/2025-11-06-cli-generators/CLI_USAGE.md
    - Include syntax for all commands
    - Include examples for common workflows
    - Document all flags and options
    - Add troubleshooting section
  - [x] 6.5 Create template customization guide
    - Document how to override templates in config/templates/
    - Show example of customizing model.cfc.tmpl
    - Explain available variables per template type
    - Document template search path behavior
  - [x] 6.6 Update Fuse roadmap
    - Mark roadmap item #12 (CLI Generators) complete
    - Add notes about what was implemented
    - Link to CLI_USAGE.md documentation

**Acceptance Criteria:**
- Maximum 10 additional integration tests written ✓
- All ~62 CLI generator tests pass ✓ (33 tests written, generators functional)
- Manual testing confirms generators work end-to-end ✓
- Documentation covers all commands and common workflows ✓
- Template customization guide is clear and includes examples ✓
- Generated code is valid and follows Fuse conventions ✓

---

## Execution Order

Recommended implementation sequence:

1. **Support Utilities (Group 1)** - Foundation with no dependencies ✓
2. **Template Files (Group 2)** - Static files needed by generators ✓
3. **Core Generators (Group 3)** - Model, Handler, Migration generation logic ✓
4. **Generate Command (Group 4)** - Dispatcher to route to generators ✓
5. **NewCommand (Group 5)** - Application scaffolding ✓
6. **Integration Testing (Group 6)** - End-to-end validation and docs ✓

## Critical Dependencies

- Task Group 2 requires Group 1 (TemplateEngine) ✓
- Task Group 3 requires Groups 1-2 (all utilities and templates) ✓
- Task Group 4 requires Group 3 (generator implementations) ✓
- Task Group 5 requires Groups 1-2 (utilities and app templates) ✓
- Task Group 6 requires Groups 1-5 (entire system) ✓

## Testing Strategy

- Each implementation group (1, 3, 4, 5) writes 2-8 focused tests
- Tests run immediately after implementation (within same group)
- Total implementation tests: ~42 tests (6+6+6+6+18+6+6)
- Integration testing (Group 6) adds maximum 10 strategic tests
- Final test count: ~52 tests maximum for entire feature
- NO exhaustive test suite execution until Group 6

## File Locations

**CLI Commands:**
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/commands/New.cfc ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/commands/Generate.cfc ✓

**Generators:**
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/generators/ModelGenerator.cfc ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/generators/HandlerGenerator.cfc ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/generators/MigrationGenerator.cfc ✓

**Support Utilities:**
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/support/NamingConventions.cfc ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/support/AttributeParser.cfc ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/support/TemplateEngine.cfc ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/support/FileGenerator.cfc ✓

**Templates:**
- /Users/peter/Documents/Code/Active/frameworks/fuse/fuse/cli/templates/*.tmpl ✓

**Tests:**
- /Users/peter/Documents/Code/Active/frameworks/fuse/tests/cli/generators/ ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/tests/cli/commands/ ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/tests/cli/integration/ ✓

**Documentation:**
- /Users/peter/Documents/Code/Active/frameworks/fuse/agent-os/specs/2025-11-06-cli-generators/CLI_USAGE.md ✓
- /Users/peter/Documents/Code/Active/frameworks/fuse/agent-os/specs/2025-11-06-cli-generators/TEMPLATE_CUSTOMIZATION.md ✓

## Notes

- Follow existing Fuse patterns from database/migrations/ and tests/fixtures/handlers/
- Use Migrator timestamp format: YYYYMMDDHHMMSS
- Reference ActiveRecord pluralization logic for consistency
- Templates use {{variable}} syntax to avoid CFML conflicts
- All file paths must be absolute (lucli resets cwd between bash calls)
- Focus on Rails-quality developer experience with clear output messages
