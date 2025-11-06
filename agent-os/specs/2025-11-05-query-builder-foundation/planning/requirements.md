# Spec Requirements: Query Builder Foundation

## Initial Description
Two-layer query builder (QueryBuilder for raw SQL, ModelBuilder for ORM features), hash-based where() with operator structs ({gte:, like:, in:}), orderBy/limit/offset, raw SQL support (whereRaw, selectRaw)

This layer sits between the database and the ActiveRecord models, providing a fluent interface for query construction.

## Requirements Discussion

### Architecture Decisions

**Q: How should QueryBuilder and ModelBuilder relate?**
**Answer:**
- QueryBuilder: Standalone component usable for complex raw queries
- ModelBuilder: Extends QueryBuilder, adds ORM-specific features
- QueryBuilder returns raw arrays of structs
- ModelBuilder returns hydrated model instances

**Q: What hash-based operators should be included?**
**Answer:** Include: `{gte:, gt:, lte:, lt:, ne:, like:, between:, in:, notIn:, isNull:, notNull:}`

**Q: SQL placeholder strategy?**
**Answer:** Positional `?` only for foundation. Named parameters deferred to future iteration.

**Q: Foundation methods to include?**
**Answer:**
- Builder methods: `select()`, `where()`, `whereRaw()`, `orderBy()`, `groupBy()`, `having()`, `limit()`, `offset()`
- Join methods: `join()`, `leftJoin()`, `rightJoin()`
- Terminal methods: `get()`, `first()`, `count()`
- All builder methods return `this` except terminal methods

**Q: Explicitly out of scope?**
**Answer:**
- Subqueries
- Unions
- Aggregate methods beyond count() (avg, sum, min, max)
- Window functions
- Database-specific features
- Query caching
- Soft deletes

### Existing Code to Reference

No similar existing features identified for reference. This is foundational ORM infrastructure.

### Follow-up Questions

No follow-up questions were needed.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
N/A - No visual assets for infrastructure component.

## Requirements Summary

### Functional Requirements

**QueryBuilder Component:**
- Standalone usable for complex raw SQL queries
- Returns raw arrays of structs from database
- Fluent builder pattern with method chaining
- Prepared statement support with positional placeholders (`?`)
- Raw SQL escape hatches for complex queries

**ModelBuilder Component:**
- Extends QueryBuilder
- Adds ORM-specific features
- Returns hydrated model instances
- Inherits all QueryBuilder capabilities

**Core Builder Methods (return `this`):**
- `select()` - Specify columns to select
- `where()` - Add WHERE conditions with hash-based operators
- `whereRaw()` - Add raw SQL WHERE clause
- `orderBy()` - Add ORDER BY clause
- `groupBy()` - Add GROUP BY clause
- `having()` - Add HAVING clause
- `limit()` - Set result limit
- `offset()` - Set result offset

**Join Methods (return `this`):**
- `join()` - Inner join
- `leftJoin()` - Left outer join
- `rightJoin()` - Right outer join

**Terminal Methods:**
- `get()` - Execute query, return all results
- `first()` - Execute query, return first result
- `count()` - Execute query, return count

**Hash-Based Operator Support:**
- `gte:` - Greater than or equal
- `gt:` - Greater than
- `lte:` - Less than or equal
- `lt:` - Less than
- `ne:` - Not equal
- `like:` - SQL LIKE pattern
- `between:` - Between two values
- `in:` - In array of values
- `notIn:` - Not in array of values
- `isNull:` - IS NULL
- `notNull:` - IS NOT NULL

**Example Usage:**
```cfml
// QueryBuilder - returns array of structs
qb = new QueryBuilder(datasource="myDS")
users = qb.select("id, name, email")
          .where({active: true, age: {gte: 18}})
          .orderBy("name ASC")
          .limit(10)
          .get()

// ModelBuilder - returns model instances
User::where({status: "active", role: {in: ["admin", "moderator"]}})
    .orderBy("created_at DESC")
    .limit(25)
    .get()
```

### Reusability Opportunities

No existing features identified for reuse. This is foundational infrastructure that future ORM features will build upon.

Future components that will extend this foundation:
- ActiveRecord base class (roadmap item #5)
- ORM relationships (roadmap item #7)
- Smart eager loading (roadmap item #8)

### Scope Boundaries

**In Scope:**
- QueryBuilder component with raw SQL query building
- ModelBuilder component extending QueryBuilder
- Hash-based where() conditions with operator structs
- Basic query modifiers: select, where, whereRaw, orderBy, groupBy, having, limit, offset
- Join operations: join, leftJoin, rightJoin
- Terminal operations: get, first, count
- Positional placeholder support (`?`)
- Prepared statement execution
- Result set hydration (arrays of structs for QueryBuilder)

**Out of Scope:**
- Subqueries (deferred)
- Unions (deferred)
- Aggregate methods beyond count: avg, sum, min, max (deferred)
- Window functions (deferred)
- Database-specific features (deferred)
- Query caching (deferred)
- Soft deletes (deferred)
- Named parameters (deferred to future iteration)
- Model instance hydration (deferred to ActiveRecord implementation)
- Relationship queries (deferred to ORM Relationships roadmap item)
- Eager loading (deferred to Smart Eager Loading roadmap item)

**Future Enhancements:**
- Named parameter support (:paramName syntax)
- Additional aggregate methods
- Subquery support
- Union/union all support
- Window function support
- Database-specific optimizations
- Query result caching
- Soft delete query scoping

### Technical Considerations

**Integration Points:**
- Database connection via Lucee datasource
- JDBC prepared statements for security
- Foundation for ActiveRecord models (roadmap item #5)
- Foundation for ORM relationships (roadmap item #7)
- Foundation for eager loading (roadmap item #8)

**Technology Stack Alignment:**
- Lucee 7+ static method support for ModelBuilder
- Component-based architecture (CFC)
- Prepared statements for all queries
- JDBC-compatible database support (MySQL, PostgreSQL, SQL Server, etc)
- Hash-based query syntax (CFML native structs)

**Architecture Constraints:**
- QueryBuilder must be standalone (not require ActiveRecord)
- ModelBuilder extends QueryBuilder (inheritance)
- Builder methods must return `this` for chaining
- Terminal methods execute query and return results
- All queries must use prepared statements (security)
- Two-layer return strategy: QueryBuilder returns arrays of structs, ModelBuilder returns model instances

**Framework Conventions:**
- Hash-based query syntax aligns with product differentiator
- Fluent interface matches Rails/Laravel builder patterns
- Prepared statements align with security best practices
- Component-based design aligns with CFML conventions
- Static methods on ModelBuilder enable clean ActiveRecord syntax
