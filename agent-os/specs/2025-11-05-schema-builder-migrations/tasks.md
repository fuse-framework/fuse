# Task Breakdown: Schema Builder & Migrations

## Overview
Total Tasks: 35
Total Task Groups: 6

## Task List

### Core Foundation

#### Task Group 1: ColumnBuilder Component
**Dependencies:** None

- [x] 1.0 Complete ColumnBuilder component
  - [x] 1.1 Write 2-8 focused tests for ColumnBuilder
    - Test column definition state storage
    - Test modifier chaining (notNull, unique, default)
    - Test SQL fragment generation for different types
    - Skip exhaustive testing of all type combinations
  - [x] 1.2 Create ColumnBuilder.cfc at `fuse/orm/ColumnBuilder.cfc`
    - Initialize with column name, type, and datasource
    - Store definition state in variables scope (name, type, constraints, defaultValue)
    - Follow QueryBuilder initialization pattern
  - [x] 1.3 Implement column modifier methods
    - `notNull()` - sets NOT NULL constraint flag
    - `unique()` - sets UNIQUE constraint flag
    - `default(value)` - stores default value
    - `index()` - sets index flag for column
    - All methods return `this` for chaining
  - [x] 1.4 Implement toSQL() method
    - Generate SQL fragment: type, constraints, default
    - Properly quote default values based on type
    - Return string fragment for column definition
  - [x] 1.5 Ensure ColumnBuilder tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify modifier chaining works
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- Modifiers chain correctly
- SQL fragments generated accurately
- Follows QueryBuilder fluent pattern

#### Task Group 2: TableBuilder Component
**Dependencies:** Task Group 1

- [x] 2.0 Complete TableBuilder component
  - [x] 2.1 Write 2-8 focused tests for TableBuilder
    - Test column type method creation (id, string, integer)
    - Test index and foreign key tracking
    - Test toSQL() for CREATE and ALTER statements
    - Skip exhaustive testing of all column types
  - [x] 2.2 Create TableBuilder.cfc at `fuse/orm/TableBuilder.cfc`
    - Initialize with table name, datasource, and mode (create/alter)
    - Track columns array, indexes array, foreignKeys array
    - Follow QueryBuilder array-based state pattern
  - [x] 2.3 Implement 11 column type methods
    - `id()` - BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY
    - `string(name, length=255)` - VARCHAR
    - `text(name)` - TEXT
    - `integer(name)` - INT
    - `bigInteger(name)` - BIGINT
    - `boolean(name)` - BOOLEAN/TINYINT(1)
    - `decimal(name, precision=10, scale=2)` - DECIMAL
    - `datetime(name)` - DATETIME
    - `date(name)` - DATE
    - `time(name)` - TIME
    - `json(name)` - JSON
    - Each returns ColumnBuilder instance
  - [x] 2.4 Implement timestamps() helper
    - Add created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    - Add updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    - No return value (terminal operation)
  - [x] 2.5 Implement index operations
    - `index(columns)` - accepts string or array
    - Generate index name: `idx_{tablename}_{column1}_{column2}`
    - Store in indexes array
  - [x] 2.6 Implement foreign key operations
    - `foreignKey(column)` - returns ForeignKeyBuilder instance
    - ForeignKeyBuilder stores column, refTable, refColumn, onDelete, onUpdate
    - Methods: `references(table, column)`, `onDelete(action)`, `onUpdate(action)`
    - Default: RESTRICT for both delete/update
    - Generate constraint name: `fk_{tablename}_{column}`
  - [x] 2.7 Implement toSQL() method
    - For CREATE: generate full CREATE TABLE statement
    - For ALTER: generate ALTER TABLE ADD COLUMN statements
    - Include all columns, indexes, and foreign keys
    - Return SQL string
  - [x] 2.8 Ensure TableBuilder tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify column definitions work
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- All 11 column types work correctly
- Indexes and foreign keys tracked
- SQL generation accurate for CREATE/ALTER

### Schema Operations

#### Task Group 3: SchemaBuilder Component
**Dependencies:** Task Group 2

- [x] 3.0 Complete SchemaBuilder component
  - [x] 3.1 Write 2-8 focused tests for SchemaBuilder
    - Test create() with callback
    - Test drop() and dropIfExists()
    - Test table() for modifications
    - Test SQL execution via QueryBuilder
    - Skip exhaustive testing of all operations
  - [x] 3.2 Create SchemaBuilder.cfc at `fuse/orm/SchemaBuilder.cfc`
    - Initialize with datasource
    - Store datasource in variables.datasource
    - Follow QueryBuilder initialization pattern
  - [x] 3.3 Implement table creation operations
    - `create(tableName, callback)` - create new table
    - `createIfNotExists(tableName, callback)` - conditional create
    - Both invoke callback with TableBuilder instance (mode: create)
    - Execute SQL immediately via queryExecute()
  - [x] 3.4 Implement table modification operations
    - `table(tableName, callback)` - modify existing table
    - Invoke callback with TableBuilder instance (mode: alter)
    - Execute SQL immediately via queryExecute()
  - [x] 3.5 Implement table deletion operations
    - `drop(tableName)` - unconditional drop
    - `dropIfExists(tableName)` - conditional drop
    - Execute SQL immediately via queryExecute()
  - [x] 3.6 Implement rename operation
    - `rename(oldName, newName)` - rename table
    - Generate: ALTER TABLE oldName RENAME TO newName
    - Execute SQL immediately via queryExecute()
  - [x] 3.7 Integrate QueryBuilder for execution
    - Use queryExecute(sql, {}, {datasource: variables.datasource})
    - No prepared statement bindings needed for DDL
    - Handle database exceptions with clear error messages
  - [x] 3.8 Ensure SchemaBuilder tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify table operations execute
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- All 6 table operations work
- Callbacks receive TableBuilder correctly
- SQL executes via queryExecute()

### Migration System

#### Task Group 4: Migration Base Class & Migrator
**Dependencies:** Task Group 3

- [x] 4.0 Complete Migration base class and Migrator
  - [x] 4.1 Write 2-8 focused tests for Migration and Migrator
    - Test Migration init() with datasource
    - Test schema property access
    - Test Migrator.migrate() with pending migrations
    - Test schema_migrations table creation
    - Test migration version tracking
    - Skip exhaustive testing of all methods
  - [x] 4.2 Create Migration.cfc at `fuse/orm/Migration.cfc`
    - `init(datasource)` - stores in variables.datasource
    - Property: `schema` - lazy-init SchemaBuilder instance
    - Abstract methods: `up()` and `down()` (empty implementations)
    - Returns this from init()
  - [x] 4.3 Create Migrator.cfc at `fuse/orm/Migrator.cfc`
    - Initialize with datasource from application.datasource
    - Store datasource in variables.datasource
    - Create migrations directory reference: `/database/migrations/`
  - [x] 4.4 Implement schema_migrations table management
    - Method: `ensureMigrationsTable()` - private
    - Create if not exists: schema_migrations (version BIGINT PRIMARY KEY)
    - Run on Migrator initialization
  - [x] 4.5 Implement migration discovery
    - Method: `discoverMigrations()` - private
    - Scan /database/migrations/ for *.cfc files
    - Extract version from filename: YYYYMMDDHHMMSS prefix
    - Return array of structs: {version, filename, path}
    - Sort by version ascending
  - [x] 4.6 Implement migration tracking queries
    - Method: `getRanMigrations()` - private
    - Query schema_migrations table
    - Return array of version numbers
  - [x] 4.7 Implement migrate() method
    - Get all migrations from directory
    - Get ran migrations from database
    - Filter to pending (not in ran)
    - Sort by version ascending
    - For each pending migration:
      - Start transaction
      - Instantiate migration CFC with datasource
      - Call up() method
      - Insert version into schema_migrations
      - Commit transaction
    - Return struct: {success: true/false, messages: []}
    - Rollback transaction on error
  - [x] 4.8 Ensure Migration and Migrator tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify migrate() runs pending migrations
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 4.1 pass
- Migration base class provides schema access
- Migrator discovers and runs migrations
- Transactions wrap migration execution
- Version tracking works correctly

### Advanced Migration Operations

#### Task Group 5: Rollback, Status, and Utility Methods
**Dependencies:** Task Group 4

- [x] 5.0 Complete rollback and utility methods
  - [x] 5.1 Write 2-8 focused tests for rollback operations
    - Test rollback(steps=1)
    - Test status() method output
    - Test reset() operation
    - Skip exhaustive testing of edge cases
  - [x] 5.2 Implement rollback(steps=1) method
    - Get ran migrations from database
    - Sort by version descending
    - Take first N steps
    - For each migration:
      - Start transaction
      - Instantiate migration CFC with datasource
      - Call down() method
      - Delete version from schema_migrations
      - Commit transaction
    - Return struct: {success: true/false, messages: []}
    - Rollback transaction on error
  - [x] 5.3 Implement status() method
    - Get all migrations from directory
    - Get ran migrations from database
    - Separate into pending and ran arrays
    - Return struct: {pending: [], ran: []}
  - [x] 5.4 Implement reset() method
    - Get count of ran migrations
    - Call rollback(count)
    - Return result struct
  - [x] 5.5 Implement refresh() method
    - Call reset()
    - Call migrate()
    - Combine results into single struct
    - Return struct: {success: true/false, messages: []}
  - [x] 5.6 Ensure rollback tests pass
    - Run ONLY the 2-8 tests written in 5.1
    - Verify rollback removes migrations
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 5.1 pass
- Rollback reverses migrations correctly
- Status shows accurate state
- Reset and refresh work end-to-end

### Error Handling & Integration

#### Task Group 6: Error Handling, Validation & Complete Integration
**Dependencies:** Task Groups 1-5

- [x] 6.0 Complete error handling and validation
  - [x] 6.1 Write 2-8 focused tests for error conditions
    - Test invalid column type throws Schema.InvalidColumnType
    - Test migration execution error throws Migration.ExecutionError
    - Test invalid definition throws Migration.InvalidDefinition
    - Test transaction rollback on error
    - Skip exhaustive error testing
  - [x] 6.2 Implement column type validation
    - Validate column types before SQL generation in TableBuilder
    - Throw Schema.InvalidColumnType for unknown types
    - Include supported types in error message
  - [x] 6.3 Implement migration execution error handling
    - Wrap SQL execution in try/catch
    - Catch database errors and re-throw as Migration.ExecutionError
    - Include failing SQL and original error in detail
    - Ensure transaction rollback on error
  - [x] 6.4 Implement definition validation
    - Validate table names (alphanumeric + underscore)
    - Validate column names (alphanumeric + underscore)
    - Throw Migration.InvalidDefinition for invalid names
    - Validate foreign key references
  - [x] 6.5 Add clear error messages
    - All exceptions include type, message, and detail
    - Error messages indicate which migration failed
    - SQL that caused error included in detail
    - Validation errors show what's invalid and why
  - [x] 6.6 Create /database/migrations/ directory structure
    - Create directory if not exists
    - Add .gitkeep or README.md to directory
    - Document migration file naming convention
  - [x] 6.7 Ensure error handling tests pass
    - Run ONLY the 2-8 tests written in 6.1
    - Verify exceptions thrown correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- The 2-8 tests written in 6.1 pass
- Validation prevents invalid definitions
- Errors provide clear debugging information
- Transactions rollback on failure
- Migration directory exists and documented

## Execution Order

Recommended implementation sequence:
1. Core Foundation - ColumnBuilder (Task Group 1)
2. Core Foundation - TableBuilder (Task Group 2)
3. Schema Operations - SchemaBuilder (Task Group 3)
4. Migration System - Base & Migrator (Task Group 4)
5. Advanced Operations - Rollback & Utilities (Task Group 5)
6. Error Handling & Integration (Task Group 6)

## Implementation Notes

**Build on QueryBuilder:**
- Reuse fluent API pattern (return `this` for chaining)
- Reuse datasource initialization pattern
- Reuse array-based state tracking
- Use queryExecute() for SQL execution
- Follow toSQL() pattern for SQL generation

**Follow ActiveRecord Conventions:**
- Datasource from application.datasource
- Plural table names (users, posts)
- Underscore column names (created_at, user_id)
- Primary key defaults to id
- Timestamps helper for created_at/updated_at

**Migration File Pattern:**
- Location: /database/migrations/
- Naming: YYYYMMDDHHMMSS_DescriptiveName.cfc
- Extends: fuse.orm.Migration
- Methods: up() and down()
- Access: schema property and variables.datasource

**Testing Strategy:**
- Each task group writes 2-8 focused tests maximum
- Tests verify critical behaviors only
- Final verification runs only new tests, not entire suite
- Task Group 6 adds max 10 additional tests for error handling
- Total expected tests: approximately 20-30

**SQL Generation:**
- Generate DDL strings from method calls
- No prepared statement bindings (DDL doesn't use them)
- Properly escape/quote values in SQL
- Execute immediately (no deferred execution)
- Wrap migrations in transactions

**Error Recovery:**
- Transaction per migration (rollback on failure)
- Clear exception types (Schema.*, Migration.*)
- Fail fast on validation errors
- Include SQL in error messages for debugging
