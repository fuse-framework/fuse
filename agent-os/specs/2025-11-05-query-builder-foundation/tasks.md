# Task Breakdown: Query Builder Foundation

## Overview
Total Tasks: 4 major task groups
Implementation Order: QueryBuilder Core -> QueryBuilder Methods -> ModelBuilder -> Testing

## Task List

### QueryBuilder Foundation

#### Task Group 1: QueryBuilder Core Structure & SQL Generation
**Dependencies:** None

- [x] 1.0 Complete QueryBuilder core infrastructure
  - [x] 1.1 Write 2-8 focused tests for QueryBuilder core
    - Test init() with datasource parameter
    - Test internal state initialization (selectedColumns, whereClauses, bindings arrays)
    - Test basic method chaining returns `this`
    - Test toSQL() generates correct SQL structure
    - Do NOT test exhaustive SQL generation scenarios yet
  - [x] 1.2 Create QueryBuilder.cfc at `fuse/orm/QueryBuilder.cfc`
    - Component with no dependencies on ActiveRecord
    - init() accepts datasource name, stores in variables.datasource
    - Initialize internal state arrays: variables.selectedColumns, variables.whereClauses, variables.joinClauses, variables.orderByClauses, variables.groupByClauses, variables.havingClauses, variables.bindings
    - Initialize variables.limitValue and variables.offsetValue to null
    - Return `this` from init()
    - Reference pattern: Framework.cfc init() method
  - [x] 1.3 Implement private toSQL() method
    - Build SQL string from internal state
    - Format: SELECT [columns] FROM [table] [joins] WHERE [conditions] GROUP BY [columns] HAVING [condition] ORDER BY [columns] LIMIT [n] OFFSET [n]
    - Omit clauses if not specified (no empty WHERE, etc.)
    - Join WHERE conditions with AND
    - Return struct with sql and bindings keys
  - [x] 1.4 Ensure QueryBuilder core tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify init() and basic structure work
    - Do NOT run entire test suite

**Acceptance Criteria:**
- QueryBuilder.cfc exists at correct path
- init() accepts datasource and returns this
- Internal state arrays initialized correctly
- toSQL() generates basic SQL structure
- The 2-8 tests from 1.1 pass

### QueryBuilder Query Building Methods

#### Task Group 2: Builder & Terminal Methods
**Dependencies:** Task Group 1

- [x] 2.0 Complete QueryBuilder query building methods
  - [x] 2.1 Write 2-8 focused tests for builder methods
    - Test select() with string and array inputs
    - Test where() with simple equality struct
    - Test where() with hash-based operators (gte, in, isNull)
    - Test whereRaw() with raw SQL and bindings
    - Test orderBy(), groupBy(), limit(), offset()
    - Test join(), leftJoin(), rightJoin()
    - Test get(), first(), count() terminal methods
    - Limit to critical behaviors only
  - [x] 2.2 Implement select() method
    - Accept comma-separated string or array of column names
    - Default to "*" if never called
    - Multiple calls append to variables.selectedColumns array (not replace)
    - Parse input and store in array format
    - Return `this` for chaining
  - [x] 2.3 Implement where() method with hash-based operators
    - Accept struct of column/value pairs
    - Simple equality: `{active: true}` generates `WHERE active = ?`
    - Detect operator hash when value is struct
    - Supported operators: gte(>=), gt(>), lte(<=), lt(<), ne(<>), like(LIKE)
    - Supported operators: between(BETWEEN ? AND ?), in(IN(?,...)), notIn(NOT IN(?,...))
    - Supported operators: isNull(IS NULL), notNull(IS NOT NULL)
    - Validate exactly one operator key, throw QueryBuilder.InvalidOperator if multiple/zero
    - Add values to variables.bindings array in order
    - isNull/notNull generate SQL with no binding
    - between expects two-element array
    - Multiple where() calls append with AND logic
    - Return `this` for chaining
  - [x] 2.4 Implement whereRaw() method
    - Accept raw SQL string and optional bindings array
    - Append bindings to variables.bindings array
    - Wrap raw SQL in parentheses when added to WHERE clause
    - Return `this` for chaining
  - [x] 2.5 Implement join methods
    - join(table, condition) for INNER JOIN
    - leftJoin(table, condition) for LEFT OUTER JOIN
    - rightJoin(table, condition) for RIGHT OUTER JOIN
    - Store in variables.joinClauses array with type and details
    - Return `this` for chaining
  - [x] 2.6 Implement orderBy(), groupBy(), having() methods
    - orderBy(column, direction) accepts column and optional direction ("ASC"/"DESC"), defaults to ASC
    - Multiple orderBy() calls append to variables.orderByClauses
    - groupBy(columns) accepts comma-separated string or array, stores in variables.groupByClauses
    - having(condition) accepts raw SQL string, stores in variables.havingClauses
    - All return `this` for chaining
  - [x] 2.7 Implement limit() and offset() methods
    - Accept numeric value, validate positive integer
    - Throw QueryBuilder.InvalidValue for non-numeric or negative values
    - Store in variables.limitValue and variables.offsetValue
    - Only most recent call matters (not cumulative)
    - Return `this` for chaining
  - [x] 2.8 Implement terminal methods: get(), first(), count()
    - get() executes query via queryExecute(), returns array of structs
    - first() executes with LIMIT 1, returns single struct or null
    - count() executes COUNT(*) query, returns numeric count
    - All use toSQL() to generate SQL and bindings
    - Pass bindings as positional parameters to queryExecute()
    - Handle empty result sets: empty array for get(), null for first(), 0 for count()
    - Do NOT return `this` (these are terminal methods)
  - [x] 2.9 Update toSQL() for complete SQL generation
    - Generate correct IN clause with proper number of `?` placeholders
    - Handle all operator types correctly in WHERE clause
    - Apply joins before WHERE clause
    - Apply LIMIT and OFFSET at end
  - [x] 2.10 Implement error handling
    - Throw QueryBuilder.InvalidColumn for invalid column references
    - Throw QueryBuilder.InvalidOperator for unknown operators
    - Throw QueryBuilder.InvalidValue for invalid limit/offset values
    - All errors include type, message, and actionable detail
    - Reference pattern: Container.cfc error handling
    - Database errors from queryExecute() bubble up with original context
  - [x] 2.11 Ensure QueryBuilder method tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify all builder methods work correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- select() accepts string/array, appends correctly
- where() handles simple equality and all hash-based operators
- whereRaw() accepts raw SQL and bindings
- join/leftJoin/rightJoin store join clauses correctly
- orderBy/groupBy/having store clauses correctly
- limit/offset validate and store values
- get/first/count execute queries and return correct result types
- All errors follow typed exception pattern
- The 2-8 tests from 2.1 pass

### ModelBuilder Extension

#### Task Group 3: ModelBuilder Component
**Dependencies:** Task Group 2 (completed)

- [x] 3.0 Complete ModelBuilder component
  - [x] 3.1 Write 2-8 focused tests for ModelBuilder
    - Test ModelBuilder extends QueryBuilder
    - Test init() accepts datasource and table name
    - Test tableName stored correctly for FROM clause
    - Test inherited methods work (select, where, get)
    - Test method chaining still works
    - Limit to critical inheritance behaviors
  - [x] 3.2 Create ModelBuilder.cfc at `fuse/orm/ModelBuilder.cfc`
    - Extends QueryBuilder
    - init() accepts datasource and tableName parameters
    - Call super.init(datasource)
    - Store tableName in variables.tableName
    - Return `this`
  - [x] 3.3 Verify method inheritance
    - All QueryBuilder methods inherited unchanged
    - Same method signatures maintained
    - Builder methods still return `this`
    - Terminal methods still execute queries
  - [x] 3.4 Update toSQL() to use tableName
    - Override toSQL() or modify QueryBuilder toSQL() to accept tableName
    - Use variables.tableName in FROM clause
    - Maintain compatibility with QueryBuilder
  - [x] 3.5 Add documentation for future roadmap
    - Comment noting: Terminal methods will be overridden in ActiveRecord implementation
    - Comment noting: Future versions will return model instances instead of structs
    - Reference: Roadmap item #5 (ActiveRecord base class)
  - [x] 3.6 Ensure ModelBuilder tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify inheritance works correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- ModelBuilder.cfc extends QueryBuilder
- init() accepts datasource and tableName
- All QueryBuilder methods inherited and functional
- tableName used correctly in SQL generation
- Documentation notes added for future enhancements
- The 2-8 tests from 3.1 pass

### Testing & Integration

#### Task Group 4: Test Review & Integration Testing
**Dependencies:** Task Groups 1-3

- [x] 4.0 Review tests and add integration tests only
  - [x] 4.1 Review existing tests from Task Groups 1-3
    - Review 2-8 tests from QueryBuilder core (1.1)
    - Review 2-8 tests from QueryBuilder methods (2.1)
    - Review 2-8 tests from ModelBuilder (3.1)
    - Total existing tests: approximately 6-24 tests
  - [x] 4.2 Analyze test coverage gaps for Query Builder Foundation
    - Identify critical query building workflows lacking coverage
    - Focus on integration between components (select + where + orderBy + get)
    - Focus on complex operator combinations
    - Do NOT assess entire application test coverage
    - Prioritize end-to-end query building workflows
  - [x] 4.3 Write up to 10 integration tests maximum
    - Test complete query chain: select().where().orderBy().limit().get()
    - Test complex where() with multiple operator types
    - Test join operations with where conditions
    - Test whereRaw() integration with where()
    - Test first() and count() with complex queries
    - Test error conditions: invalid operators, invalid limit values
    - Test binding order correctness for prepared statements
    - Test IN clause with multiple values
    - Test between operator with array values
    - Test isNull/notNull operators
    - Add maximum 10 tests total
  - [x] 4.4 Run Query Builder Foundation test suite
    - Run all tests for QueryBuilder and ModelBuilder
    - Expected total: approximately 16-34 tests maximum
    - Verify all critical workflows pass
    - Do NOT run entire application test suite
  - [x] 4.5 Create usage examples and documentation
    - Add code examples demonstrating QueryBuilder usage
    - Add code examples demonstrating ModelBuilder usage
    - Document all supported hash-based operators
    - Document method chaining patterns
    - Add examples to component documentation

**Acceptance Criteria:**
- All Query Builder Foundation tests pass (16-34 tests total)
- Integration tests cover complex query building workflows
- No more than 10 additional tests added
- Critical operator combinations tested
- Usage examples documented in component files
- Testing focused on Query Builder Foundation only

## Execution Order

Recommended implementation sequence:
1. QueryBuilder Core Structure (Task Group 1)
2. QueryBuilder Methods (Task Group 2)
3. ModelBuilder Extension (Task Group 3)
4. Test Review & Integration Testing (Task Group 4)

## Notes

**Framework Patterns to Follow:**
- Container.cfc: Fluent interface pattern (return `this`)
- Container.cfc: Error handling with typed exceptions
- Framework.cfc: init() pattern with dependencies
- ICacheProvider.cfc: Documentation style

**Key Technical Details:**
- Use queryExecute() for all database operations
- Positional `?` placeholders for prepared statements
- Store all bindings in order in variables.bindings array
- Validate input early and throw typed exceptions
- Database errors bubble up with original context

**Out of Scope (Deferred):**
- Subqueries in WHERE or SELECT
- UNION operations
- Aggregate methods beyond count() (avg, sum, min, max)
- Window functions
- Database-specific optimizations
- Query result caching
- Soft delete query scoping
- Named parameter placeholders
- Model instance hydration (deferred to roadmap item #5)
- Relationship query methods (deferred to roadmap item #7)
- Eager loading (deferred to roadmap item #8)
