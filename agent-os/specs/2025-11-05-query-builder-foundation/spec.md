# Specification: Query Builder Foundation

## Goal
Build two-layer query builder system (QueryBuilder for raw SQL, ModelBuilder for ORM) with fluent interface, hash-based operators, and prepared statement support to provide foundation for ActiveRecord models.

## User Stories
- As a developer, I want to use QueryBuilder to build complex raw SQL queries with a fluent interface so that I can avoid writing brittle string-concatenated SQL
- As a framework developer, I want ModelBuilder to extend QueryBuilder so that future ActiveRecord models can inherit query building capabilities

## Specific Requirements

**QueryBuilder Component - Core Structure**
- Standalone CFC at `fuse/orm/QueryBuilder.cfc` with no dependencies on ActiveRecord
- `init()` accepts datasource name, stores in variables scope
- All builder methods return `this` for chaining (select, where, whereRaw, orderBy, groupBy, having, join, leftJoin, rightJoin, limit, offset)
- Terminal methods execute query and return results (get, first, count)
- Internal state tracked in variables: selectedColumns, whereClauses, joinClauses, orderByClauses, groupByClauses, havingClauses, limitValue, offsetValue, bindings array
- Must follow Fuse conventions: fluent interfaces return `this`, descriptive method names, clear error messages with type/message/detail

**QueryBuilder Component - select() Method**
- Accepts comma-separated string or array of column names
- Defaults to "*" if never called
- Multiple calls append to selection (not replace)
- Stores parsed column list in variables.selectedColumns array
- Example: `select("id, name")` or `select(["id", "name"])`

**QueryBuilder Component - where() Method**
- Accepts struct of column/value pairs for conditions
- Simple equality: `{active: true, status: "published"}` generates `WHERE active = ? AND status = ?`
- Hash-based operators: `{age: {gte: 18}, role: {in: ["admin", "mod"]}}` generates `WHERE age >= ? AND role IN (?, ?)`
- Supported operators: gte, gt, lte, lt, ne, like, between, in, notIn, isNull, notNull
- All values added to bindings array in order for prepared statements
- Multiple calls to where() append with AND logic
- isNull/notNull operators ignore value, check only presence: `{deleted_at: {isNull: true}}`
- between operator expects two-element array: `{age: {between: [18, 65]}}`

**QueryBuilder Component - whereRaw() Method**
- Accepts raw SQL string and optional bindings array
- SQL string uses `?` for positional placeholders
- Bindings appended to main bindings array in order
- Example: `whereRaw("DATE(created_at) = ?", [now()])` or `whereRaw("price > cost * 1.5")`
- Wraps raw SQL in parentheses when added to WHERE clause
- Provides escape hatch for complex conditions not supported by hash syntax

**QueryBuilder Component - Join Methods**
- `join(table, condition)` for INNER JOIN
- `leftJoin(table, condition)` for LEFT OUTER JOIN
- `rightJoin(table, condition)` for RIGHT OUTER JOIN
- Condition string like "users.id = posts.user_id"
- Multiple joins supported, stored in variables.joinClauses array
- Joins applied in order before WHERE clause in final SQL

**QueryBuilder Component - orderBy/groupBy/having Methods**
- `orderBy(column, direction)` accepts column and optional direction ("ASC" or "DESC"), defaults to ASC
- Multiple orderBy calls append to sort order
- `groupBy(columns)` accepts comma-separated string or array
- `having(condition)` accepts raw SQL string for HAVING clause
- All stored in respective variables arrays

**QueryBuilder Component - limit/offset Methods**
- `limit(count)` accepts numeric value, stores in variables.limitValue
- `offset(count)` accepts numeric value, stores in variables.offsetValue
- Only most recent call to each method matters (not cumulative)
- Applied at end of SQL generation
- Must validate positive integers, throw error for invalid values

**QueryBuilder Component - Terminal Methods**
- `get()` executes query, returns array of structs (one per row)
- `first()` executes query with LIMIT 1, returns single struct or null
- `count()` executes COUNT(*) query, returns numeric count
- All use JDBC prepared statements via queryExecute()
- Bindings passed as positional parameters to queryExecute()
- Must handle empty result sets gracefully (empty array for get, null for first, 0 for count)

**QueryBuilder Component - SQL Generation**
- Private method `toSQL()` builds final SQL from internal state
- Format: SELECT [columns] FROM [table] [joins] WHERE [conditions] GROUP BY [columns] HAVING [condition] ORDER BY [columns] LIMIT [n] OFFSET [n]
- Omit clauses if not specified (no empty WHERE, etc)
- WHERE conditions joined with AND
- Properly format IN clause with correct number of `?` placeholders
- Return struct with sql and bindings keys for queryExecute()

**ModelBuilder Component - Structure**
- Extends QueryBuilder at `fuse/orm/ModelBuilder.cfc`
- `init()` accepts datasource and table name, calls super.init()
- Inherits all QueryBuilder methods unchanged
- Sets variables.tableName for FROM clause
- Future roadmap: Override terminal methods to return model instances instead of structs (deferred to ActiveRecord implementation)
- Must maintain same method signatures as QueryBuilder for compatibility

**Error Handling**
- Throw typed exceptions: QueryBuilder.InvalidColumn, QueryBuilder.InvalidOperator, QueryBuilder.InvalidValue
- All errors include type, message, and actionable detail following Fuse error handling standards
- Validate operator keys against whitelist, throw if unknown operator
- Validate numeric values for limit/offset, throw if non-numeric or negative
- Database errors from queryExecute() should bubble up with original context

**Hash-Based Operator Implementation**
- When struct value is another struct, treat as operator hash
- Validate exactly one operator key exists, throw if multiple or zero
- Operator translation: gte=>=, gt=>, lte=<=, lt=<, ne=<>, like=LIKE
- Special handling: in/notIn expand to IN (?,...), between expands to BETWEEN ? AND ?
- isNull/notNull generate IS NULL / IS NOT NULL with no binding
- All operator values added to bindings except isNull/notNull

## Visual Design
No visual assets provided for infrastructure component.

## Existing Code to Leverage

**Container.cfc - Fluent Interface Pattern**
- Methods like bind() and singleton() return `this` for chaining
- Follow same pattern for all QueryBuilder builder methods
- Validates input early and throws typed exceptions with clear messages
- Uses variables scope for internal state management

**Container.cfc - Error Handling Pattern**
- Typed exceptions: Container.BindingNotFound, Container.CircularDependency, Container.InvalidBinding
- Each throw includes type, message, and actionable detail
- Replicate structure for QueryBuilder errors: QueryBuilder.InvalidColumn, etc

**ICacheProvider.cfc - Interface Documentation Style**
- Clear method documentation with @param and @return tags
- Description of behavior for each method
- Use same documentation approach for QueryBuilder public methods

**Framework.cfc - init() Pattern**
- Accept dependencies in init(), store in variables scope, return this
- QueryBuilder init() should follow: accept datasource, store it, return this
- ModelBuilder init() should accept datasource and table name, call super, return this

**Container.cfc - Metadata Inspection Pattern**
- Uses getComponentMetadata() to introspect CFCs
- Not needed for QueryBuilder foundation but reference for future ActiveRecord introspection
- QueryBuilder focuses on explicit method calls, not metadata-driven behavior

## Out of Scope
- Subqueries in WHERE or SELECT clauses (future enhancement)
- UNION or UNION ALL operations (future enhancement)
- Aggregate methods beyond count(): avg(), sum(), min(), max() (future enhancement)
- Window functions (OVER, PARTITION BY) (future enhancement)
- Database-specific SQL features or optimizations (future enhancement)
- Query result caching (future enhancement)
- Soft delete query scoping (future feature, depends on ActiveRecord)
- Named parameter placeholders (:paramName syntax) - only positional ? supported in foundation
- Model instance hydration from results (deferred to ActiveRecord base class implementation in roadmap item 5)
- Relationship query methods (deferred to ORM relationships roadmap item 7)
- Automatic N+1 prevention and eager loading (deferred to smart eager loading roadmap item 8)
