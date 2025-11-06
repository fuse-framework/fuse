# Specification: Schema Builder & Migrations

## Goal
Provide CFC-based migration system with fluent Schema builder API for database schema version control, enabling developers to define table structures, track schema changes, and migrate/rollback database schemas with up/down methods.

## User Stories
- As a developer, I want to define database schemas in versioned migration files so that schema changes are tracked in version control
- As a developer, I want to run pending migrations or rollback changes so that I can manage database schema evolution across environments

## Specific Requirements

**Migration Base Class**
- Component at `fuse/orm/Migration.cfc` with `init(datasource)` method that stores datasource in `variables.datasource`
- Must provide `schema` property exposing SchemaBuilder instance for table operations
- Abstract methods `up()` and `down()` for child migrations to implement
- Datasource automatically injected from `application.datasource` during Migrator execution
- Migrations extend this base class and implement up/down logic

**Migration File Structure**
- Located in `/database/migrations/` directory
- Naming convention: `YYYYMMDDHHMMSS_DescriptiveName.cfc` (timestamp prefix for ordering)
- Example: `20251105143000_CreateUsersTable.cfc`
- Each migration extends `Migration` base class
- Version extracted from filename timestamp for tracking

**SchemaBuilder Component**
- Component at `fuse/orm/SchemaBuilder.cfc` with fluent API pattern matching QueryBuilder style
- Initialize with datasource, stores in `variables.datasource`
- All methods return `this` for chaining except terminal execution methods
- Uses QueryBuilder internally for executing generated DDL SQL
- Generates SQL strings from method calls, executes via `queryExecute()`

**Table Operations**
- `create(tableName, callback)` - Create new table with callback receiving TableBuilder instance
- `drop(tableName)` - Drop table unconditionally
- `dropIfExists(tableName)` - Drop table with IF EXISTS check
- `rename(oldName, newName)` - Rename existing table
- `table(tableName, callback)` - Modify existing table structure (add/modify columns)
- `createIfNotExists(tableName, callback)` - Conditional create with IF NOT EXISTS check
- Callbacks receive TableBuilder instance for defining columns/constraints
- Operations execute immediately (no deferred execution queue)

**TableBuilder Component**
- Component at `fuse/orm/TableBuilder.cfc` for defining table structure
- Receives table name and datasource on initialization
- Column definition methods return ColumnBuilder for chaining modifiers
- Index and foreign key methods execute definitions immediately
- Tracks columns, indexes, and foreign keys internally as arrays
- Provides `toSQL()` method returning DDL statement string

**Column Types**
- `id()` - Primary key with AUTO_INCREMENT (BIGINT UNSIGNED)
- `string(length=255)` - VARCHAR with default 255 length
- `text()` - TEXT column for long content
- `integer()` - INT column
- `bigInteger()` - BIGINT column
- `boolean()` - BOOLEAN/TINYINT(1) column
- `decimal(precision=10, scale=2)` - DECIMAL with default 10,2
- `datetime()` - DATETIME column
- `date()` - DATE column
- `time()` - TIME column
- `json()` - JSON column type
- `timestamps()` - Helper adding both `created_at` and `updated_at` DATETIME columns with defaults
- Each method accepts column name as first parameter, returns ColumnBuilder instance

**ColumnBuilder Component**
- Component at `fuse/orm/ColumnBuilder.cfc` for chaining column modifiers
- Stores column definition state (name, type, constraints)
- All modifier methods return `this` for chaining
- Generates SQL fragment for column definition
- Integrates with TableBuilder for final DDL generation

**Column Modifiers**
- `notNull()` - Add NOT NULL constraint to column
- `unique()` - Add UNIQUE constraint to column
- `default(value)` - Set DEFAULT value (properly quoted based on type)
- `index()` - Create single-column index on this column
- All modifiers chainable: `table.string("email").notNull().unique().index()`
- Modifiers applied in SQL generation order (type, constraints, default, indexes)

**Index Operations**
- `table.index(columns)` - Create composite index on array of column names
- `table.index(column)` - Create single column index (alternative to column-level index())
- Generates index name automatically: `idx_{tablename}_{column1}_{column2}`
- Composite indexes passed as array: `table.index(["user_id", "created_at"])`
- Indexes created as part of table CREATE or ALTER statement

**Foreign Key Operations**
- `table.foreignKey(column)` - Start foreign key definition, returns ForeignKeyBuilder
- `references(table, column)` - Define reference table and column
- `onDelete(action)` - Set ON DELETE behavior (CASCADE, RESTRICT, SET NULL, NO ACTION)
- `onUpdate(action)` - Set ON UPDATE behavior (CASCADE, RESTRICT, SET NULL, NO ACTION)
- Chaining example: `table.foreignKey("user_id").references("users", "id").onDelete("CASCADE")`
- Default behavior: RESTRICT for both onDelete and onUpdate if not specified
- Generates CONSTRAINT with automatic naming: `fk_{tablename}_{column}`

**Migrator Component**
- Component at `fuse/orm/Migrator.cfc` for running and tracking migrations
- Initialize with datasource from `application.datasource`
- Discovers migration files in `/database/migrations/` by scanning directory
- Creates `schema_migrations` table automatically if not exists (single `version` BIGINT column)
- Executes migrations in timestamp order (ascending for up, descending for down)
- Each migration wrapped in database transaction for rollback on error

**Migrator Methods**
- `migrate()` - Run all pending migrations (not in schema_migrations table)
- `rollback(steps=1)` - Rollback last N migrations by running down() methods
- `status()` - Return struct with arrays of pending and ran migration versions
- `reset()` - Rollback all migrations (clear database schema)
- `refresh()` - Reset then migrate (useful for development/testing)
- All methods return status struct with success boolean and messages array

**Migration Tracking**
- Table: `schema_migrations` with single column `version` BIGINT
- Insert row after successful up() execution
- Delete row after successful down() execution
- Query table to determine pending vs ran migrations
- No tracking of rollback-ability or migration batches (Rails-style batching out of scope)

**QueryBuilder Integration**
- SchemaBuilder uses QueryBuilder pattern of returning `this` for chaining
- DDL execution via `queryExecute(sql, {datasource: variables.datasource})`
- No prepared statement bindings needed for DDL (values properly escaped in SQL generation)
- Leverage existing datasource access pattern from ActiveRecord
- Schema operations executed immediately, not deferred

**Error Handling**
- Throw specific exception types: `Migration.InvalidDefinition`, `Migration.ExecutionError`, `Schema.InvalidColumnType`
- Migration failures rollback transaction and leave schema_migrations unchanged
- Clear error messages indicating which migration failed and SQL that caused error
- Validate column types and modifiers before SQL generation
- Fail fast on invalid table/column names or unsupported operations

## Visual Design
No visual assets provided.

## Existing Code to Leverage

**QueryBuilder (fuse/orm/QueryBuilder.cfc)**
- Fluent API pattern with method chaining returning `this`
- Datasource initialization and storage in `variables.datasource`
- SQL generation via `toSQL()` method returning struct with sql/bindings
- Execution via `queryExecute()` with datasource parameter
- Array-based internal state tracking (whereClauses, joinClauses, etc.)

**ActiveRecord datasource access pattern**
- Datasource passed to `init()` and stored in `variables.datasource`
- Access from `application.datasource` convention
- Component initialization pattern for dependency injection
- Table name conventions (plural, lowercase)

**ModelBuilder component structure**
- Extends QueryBuilder for ORM-specific functionality
- Demonstrates pattern for building on QueryBuilder foundation
- Shows how to add higher-level abstractions over SQL generation

**Component initialization patterns**
- Constructor accepting datasource parameter
- Storing dependencies in variables scope
- Returning `this` from init() for chaining
- Using `super.init()` for inheritance

**Array-based SQL building**
- Building SQL from array elements joined with delimiters
- Internal state tracking with arrays (clauses, bindings)
- Terminal method pattern (toSQL, get, first) that executes accumulated state

## Out of Scope
- Schema dumping to file or loading from schema file
- Seed data management system (separate feature)
- Database-specific optimizations (fulltext indexes, partitioning, spatial indexes)
- Column renaming operations (ALTER TABLE RENAME COLUMN)
- Data migrations or transformations of existing data
- Multiple datasource support (single datasource per application)
- Migration file generation via CLI (deferred to roadmap #12)
- Migration squashing or combining multiple migrations
- Database-specific column types beyond core 11 types
- Advanced index types (partial, expression-based, covering indexes)
- Check constraints (CHECK clauses)
- Views, stored procedures, triggers, or functions
- Database schema comparison or diffing tools
- Migration dependencies or branching (linear ordering only)
- Reversible migration detection (no automatic down() generation)
