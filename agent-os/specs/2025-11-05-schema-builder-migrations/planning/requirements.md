# Spec Requirements: Schema Builder & Migrations

## Initial Description
CFC-based Migration base class, Schema builder for table operations (create/drop/rename), column types (id/string/text/integer/boolean/timestamps), column modifiers (notNull/unique/default/index), Migrator for tracking and running migrations with up/down support.

## Requirements Discussion

### Migration File Structure

**Q:** What naming convention for migration files?
**Answer:** Timestamp prefix naming: `20251105143000_CreateUsersTable.cfc`

**Q:** What base class and method structure?
**Answer:**
- Extends `Migration` base class
- Implements `up()` and `down()` methods
- Location: `/database/migrations/`

### Schema Builder API

**Q:** Fluent API or struct-based configuration?
**Answer:** Fluent API with anonymous functions matching QueryBuilder chaining pattern

**Example:**
```cfml
schema.create("users", function(table) {
    table.id();
    table.string("name");
})
```

### Column Types

**Q:** Which column types to support?
**Answer:** Core types with sensible defaults:
- `id()` - Primary key
- `string()` - VARCHAR(255) default, accepts parameter: `string(100)`
- `text()` - TEXT column
- `integer()` - Integer
- `bigInteger()` - Big integer
- `boolean()` - Boolean
- `decimal()` - DECIMAL(10,2) default, accepts parameters: `decimal(8,2)`
- `datetime()` - Datetime
- `date()` - Date
- `time()` - Time
- `json()` - JSON column
- `timestamps()` - Adds `created_at` and `updated_at` columns

### Column Modifiers

**Q:** How to handle constraints and indexes?
**Answer:** Chaining support with dedicated index methods:

**Column-level modifiers:**
```cfml
table.string("email").notNull().unique().index()
```

**Composite indexes:**
```cfml
table.index(["user_id", "created_at"])
```

**Foreign keys:**
```cfml
table.foreignKey("user_id").references("users", "id").onDelete("cascade")
```

**Supported modifiers:**
- `notNull()` - NOT NULL constraint
- `unique()` - UNIQUE constraint
- `default()` - Default value
- `index()` - Create index on column

### Migration Tracking

**Q:** How to track migration state?
**Answer:** Simple `schema_migrations` table with `version` column (timestamp)
- Track which migrations ran, not rollback-ability
- Down methods handle rollback logic

### Migrator Methods

**Q:** What methods for running migrations?
**Answer:**
- `migrate()` - Run pending migrations
- `rollback(steps=1)` - Revert X migrations
- `status()` - Show pending/ran migrations
- `reset()` - Rollback all migrations
- `refresh()` - Reset + migrate (useful for dev/test)

### Table Operations

**Q:** What table-level operations?
**Answer:**
- `create(tableName, callback)` - Create new table
- `drop(tableName)` - Drop table
- `dropIfExists(tableName)` - Drop table if exists
- `rename(oldName, newName)` - Rename table
- `table(tableName, callback)` - Modify existing table
- `createIfNotExists(tableName, callback)` - Create if not exists

### Datasource Access

**Q:** How to access datasource?
**Answer:**
- Automatic injection from `application.datasource`
- Set `variables.datasource` in Migration base class `init()`
- Consistent with ActiveRecord pattern

### Framework Reference

**Q:** Base on existing CFML framework migrations or Rails/Laravel?
**Answer:** Start fresh with Rails/Laravel patterns, not CFML framework migrations. Adapt for CFML idioms.

### Integration

**Q:** How does this integrate with other framework components?
**Answer:**
- Builds on QueryBuilder for SQL execution
- No direct ActiveRecord integration needed

### Scope Boundaries

**Q:** What should be excluded from initial implementation?
**Answer:** Explicitly OUT OF SCOPE:
- Schema dumping/loading
- Seed data management
- Database-specific optimizations (fulltext, partitioning)
- Column renaming
- Data migrations (transformations)
- Multiple datasource support
- Migration file generation (deferred to CLI roadmap #12)

### Existing Code Reuse

No similar existing features identified for reference. This is new functionality building on top of QueryBuilder foundation (roadmap #4).

### Visual Assets

No visual assets provided.

## Requirements Summary

### Functional Requirements

**Migration Files:**
- CFC files extending Migration base class
- Timestamp prefix naming convention: `YYYYMMDDHHMMSS_DescriptiveName.cfc`
- Location: `/database/migrations/`
- Required methods: `up()` and `down()`
- Access to Schema builder via `schema` variable
- Access to datasource via `variables.datasource`

**Schema Builder:**
- Fluent API with method chaining
- Anonymous function callbacks for table definitions
- Column type methods returning chainable column objects
- Column modifier methods for constraints
- Separate index/foreignKey methods for complex definitions
- SQL generation for table operations

**Column Types (11 core types + timestamps helper):**
- Primary key: `id()`
- String types: `string(length=255)`, `text()`
- Numeric types: `integer()`, `bigInteger()`, `decimal(precision=10, scale=2)`
- Boolean: `boolean()`
- Temporal: `datetime()`, `date()`, `time()`
- JSON: `json()`
- Helper: `timestamps()` (created_at + updated_at)

**Column Modifiers:**
- `notNull()` - NOT NULL constraint
- `unique()` - UNIQUE constraint
- `default(value)` - DEFAULT value
- `index()` - Single column index

**Index Operations:**
- `table.index(columns)` - Composite index
- `table.index(column)` - Single column index

**Foreign Key Operations:**
- `table.foreignKey(column).references(table, column)` - FK definition
- `onDelete(action)` - Cascade/restrict/set null
- `onUpdate(action)` - Cascade/restrict/set null

**Table Operations:**
- `schema.create(name, callback)` - Create table
- `schema.drop(name)` - Drop table
- `schema.dropIfExists(name)` - Conditional drop
- `schema.rename(old, new)` - Rename table
- `schema.table(name, callback)` - Modify existing table
- `schema.createIfNotExists(name, callback)` - Conditional create

**Migrator:**
- Track migrations in `schema_migrations` table (version column)
- `migrate()` - Run all pending migrations in order
- `rollback(steps=1)` - Rollback X migrations
- `status()` - Display pending vs ran migrations
- `reset()` - Rollback all migrations
- `refresh()` - Reset + migrate (dev/test utility)

**SQL Execution:**
- Use QueryBuilder for executing generated SQL
- Support for datasource from `application.datasource`
- Transaction support for migration batches

### Reusability Opportunities

**QueryBuilder Integration:**
- Leverage existing QueryBuilder (roadmap #4) for SQL execution
- Reuse datasource access patterns from ActiveRecord (roadmap #5)
- Follow similar fluent API chaining patterns as QueryBuilder

**Conventions:**
- Table naming conventions align with ActiveRecord (plural tables)
- Timestamp columns (`created_at`, `updated_at`) match ActiveRecord expectations
- Primary key defaults (`id`) align with ActiveRecord conventions

### Scope Boundaries

**In Scope:**
- Migration base class with up/down methods
- Schema builder with fluent API
- 11 core column types + timestamps helper
- 4 column modifiers (notNull, unique, default, index)
- Composite indexes and foreign keys
- 6 table operations (create/drop/rename/modify/conditional)
- Migrator with 5 commands (migrate/rollback/status/reset/refresh)
- Migration tracking in `schema_migrations` table
- QueryBuilder integration for SQL execution

**Out of Scope:**
- Schema dumping/loading to file
- Seed data management system
- Database-specific optimizations (fulltext indexes, partitioning, spatial indexes)
- Column renaming operations
- Data migrations (transforming existing data)
- Multiple datasource support
- Migration file generation (CLI deferred to roadmap #12)
- Migration squashing/combining
- Database-specific column types beyond core 11
- Advanced index types (partial, expression-based)
- Check constraints
- Views, stored procedures, triggers
- Database schema comparison/diffing

### Technical Considerations

**Integration Points:**
- QueryBuilder component for SQL generation and execution
- `application.datasource` for database connection
- File system for migration discovery in `/database/migrations/`
- Migration base class initialization for datasource injection

**Existing System Constraints:**
- Lucee 7 exclusive (can use static methods, Jakarta EE)
- Must work with existing QueryBuilder implementation
- Follows ActiveRecord conventions for table/column names
- Part of batteries-included framework (no external dependencies)

**Technology Preferences:**
- Rails/Laravel migration patterns (not CFML framework patterns)
- Fluent API matching QueryBuilder style
- Convention-over-configuration approach
- CFML idioms (struct literals, anonymous functions)

**Similar Code Patterns:**
- QueryBuilder fluent chaining for Schema builder
- ActiveRecord datasource access for Migration base class
- Module loading patterns for migration discovery
- Convention-based file naming (timestamps)

### Design Philosophy

**Rails/Laravel Inspiration:**
- Migration files as version control for schema
- Up/down methods for reversibility
- Fluent schema builder API
- Timestamp-based migration ordering
- Simple tracking table (version only)

**CFML Adaptations:**
- Anonymous function callbacks (CFML closures)
- Struct literals for hash-based operations
- CFC-based migrations (type-safe, IDE support)
- Component initialization for datasource injection

**Convention Alignment:**
- Plural table names (users, posts, comments)
- Underscore column names (created_at, user_id)
- `id` as default primary key
- `timestamps()` helper for created_at/updated_at
- Foreign key naming: `{table}_id`

**Framework Integration:**
- Builds on QueryBuilder (roadmap #4)
- Supports ActiveRecord models (roadmap #5)
- Enables relationship foreign keys (roadmap #7)
- CLI integration deferred (roadmap #12)
- Part of cohesive batteries-included toolchain
