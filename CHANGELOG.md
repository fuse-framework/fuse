# Changelog

All notable changes to Fuse Framework will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - CLI Database & Dev Tools (Roadmap #13)

**Database Management Commands:**
- `Migrate.cfc` - Execute database migrations with status, reset, and refresh options
- `Rollback.cfc` - Rollback migrations with step control and reset all capability
- `Seed.cfc` - Populate database using programmable seeder classes

**Development Workflow Commands:**
- `Routes.cfc` - Display registered routes in ASCII table with filtering by method, name, and handler
- `Serve.cfc` - Start development server with configurable host and port
- `Test.cfc` - Run test suite with filtering, verbose output, and type selection (unit/integration)

**New Components:**
- `DatabaseConnection.cfc` - Datasource resolution utility supporting flag > application > default pattern
- `Seeder.cfc` - Base class for database seeders with idempotent patterns and seeder composition via call() method

**Key Features:**
- Consistent datasource resolution across all database commands (--datasource flag > application.datasource > "fuse" default)
- Migration status display with checkmarks for ran migrations and brackets for pending
- Seeder system with no tracking table (designed for idempotency)
- Routes command with auto-adjusting column widths and multiple filter options
- Test command with dots/verbose output modes and exit code support for CI/CD
- Comprehensive CLI command documentation in README with examples

**Documentation:**
- Added CLI Database & Dev Tools section to README
- Created DatabaseSeeder.cfc template with idempotency best practices
- Created UserSeeder.cfc.example showing check-before-insert pattern
- Documented all 6 commands with usage examples and output formats

## [0.1.0] - 2025-11-06

### Added - Test Framework Foundation (Roadmap #10)

**Test Infrastructure:**
- `TestCase.cfc` - Base class for all tests with assertion methods
- `TestRunner.cfc` - Sequential test execution with transaction rollback per test
- `TestDiscovery.cfc` - Recursive test file discovery from /tests directory

**Assertions:**
- `assertEqual()` - Compare expected vs actual values
- `assertTrue()` / `assertFalse()` - Boolean assertions
- `assertStructHasKey()` / `assertStructNotHasKey()` - Struct key assertions
- `assertArrayContains()` - Array membership assertion
- Custom exception: `AssertionFailedException` for test failures

**Features:**
- Transaction-wrapped test execution (automatic rollback after each test)
- Distinction between test failures (assertions) and errors (unexpected exceptions)
- Test results include passes, failures, errors with timing information
- Convention: Test files end with `Test.cfc` and extend TestCase

### Added - Validations & Lifecycle (Roadmap #9)

**Model Validations:**
- `validates()` - Declare validation rules in model
- `isValid()` - Run validations and populate errors collection
- Built-in validators: required, unique, minLength, maxLength, pattern, email, range
- Custom validators via closure/component
- Lifecycle integration: validations run before save/create operations

**Model Lifecycle Hooks:**
- `beforeValidation()` / `afterValidation()`
- `beforeSave()` / `afterSave()`
- `beforeCreate()` / `afterCreate()`
- `beforeUpdate()` / `afterUpdate()`
- `beforeDelete()` / `afterDelete()`

**Error Handling:**
- `errors` struct with `add()`, `get()`, `has()`, `clear()`, `all()`, `count()`, `isEmpty()`
- Save/create operations throw `ValidationException` on failure
- Automatic error population from validation failures

### Added - Smart Eager Loading (Roadmap #8)

**Eager Loading:**
- `with()` - Eagerly load associations to avoid N+1 queries
- Supports all relationship types: hasMany, belongsTo, hasOne, hasManyThrough
- Single query per association (2 queries for belongsTo+hasMany, not N+1)
- Automatic relationship assignment to loaded records

**Features:**
- Query optimization: uses `IN (?)` for batch loading
- Works seamlessly with existing relationship APIs
- Maintains all relationship options (foreignKey, primaryKey, through, etc.)
- Results are identical to lazy loading, just more efficient

### Added - ORM Relationships (Roadmap #7)

**Relationship Types:**
- `hasMany()` - One-to-many relationships
- `belongsTo()` - Many-to-one inverse relationships
- `hasOne()` - One-to-one relationships
- `hasManyThrough()` - Many-to-many through join models

**Relationship Features:**
- Lazy loading via dynamic methods (e.g., `post.comments()`)
- Association proxies: `has()`, `add()`, `remove()`, `create()`
- Configurable foreign keys and primary keys
- Through relationships for complex associations
- Join model access in many-to-many relationships

**Query Interface:**
- Relationships return Query objects supporting where(), orderBy(), limit()
- Association methods enable record manipulation
- Consistent API across all relationship types

## [0.0.1] - 2025-11-05

### Added - Bootstrap Core & DI Container (Roadmap #1)

**Core Components:**
- `Bootstrap.cfc` - Framework initialization with two-phase module loading
- `Container.cfc` - Dependency injection container with auto-wiring
- `Config.cfc` - Configuration file loader for CFML config files

**DI Container Features:**
- Singleton and transient bindings
- Constructor and property injection (via `setters` option)
- Auto-wiring based on constructor parameter names
- Thread-safe initialization with double-checked locking
- Closure-based lazy initialization

**Module System:**
- Two-phase initialization: `register()` then `boot()`
- Modules can bind services and access other services during boot
- Module interface: `IModule` with register/boot methods

### Added - Routing & Event System (Roadmap #2)

**Router:**
- Rails-inspired routing DSL
- RESTful resource routes with `resource()` helper
- Named routes and URL generation via `urlFor()`
- Pattern matching: static, named params (`:param`), wildcards (`*param`)
- Route filtering: `only` and `except` options for resources

**Request Dispatcher:**
- Handler instantiation via DI container (transient per request)
- Constructor injection for handler dependencies
- Route parameter extraction and injection into handler methods
- Response handling for struct/string/void return values

**Event System:**
- Event service with six lifecycle hooks:
  - `onBeforeRequest`, `onAfterRouting`
  - `onBeforeHandler`, `onAfterHandler`
  - `onBeforeRender`, `onAfterRender`
- Interceptor registration via closures/components
- Event context with request/route/handler data
- Short-circuit capability via `event.abort = true`

**Handler Conventions:**
- Location: `/app/handlers/{HandlerName}.cfc`
- Transient scope (new instance per request)
- Public action methods matching route actions
- Route params passed as method arguments

[Unreleased]: https://github.com/username/fuse/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/username/fuse/compare/v0.0.1...v0.1.0
[0.0.1]: https://github.com/username/fuse/releases/tag/v0.0.1
