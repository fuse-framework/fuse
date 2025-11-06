# Spec Requirements: Smart Eager Loading

## Initial Description
Implement smart eager loading system for Fuse ORM to eliminate N+1 query problems with automatic strategy selection (JOIN vs separate queries) based on relationship type, Rails-style `includes()` API with support for nested relationships, and optional manual override methods.

## Requirements Discussion

### Approved Design Decisions

**Q1: API Design - includes() method**
**Answer:** Rails-style `includes()` method, chainable with queries like `User::where({active: true}).includes("posts").get()`

**Q2: Strategy Selection**
**Answer:**
- belongsTo/hasOne: Use JOIN (efficient, no duplication)
- hasMany: Use separate queries (avoids row explosion)
- Exception: Filtered/limited hasMany may use JOIN with subquery

**Q3: Nested Syntax**
**Answer:**
- Multiple relations: `includes(["posts", "profile"])`
- Nested relations: `includes(["posts.comments"])`

**Q4: Manual Override Methods**
**Answer:**
- `joins("posts")` - force JOIN strategy
- `preload("posts")` - force separate queries
- `includes("posts")` - auto-select strategy

**Q5: Result Hydration**
**Answer:**
- Loaded relationships return cached array/object
- Unloaded relationships trigger lazy load
- Add `isRelationshipLoaded("posts")` for introspection
- Transparent to developer

**Q6: Invalid Relationships**
**Answer:** Throw immediate error (fail fast)

**Q7: N+1 Detection**
**Answer:** Dev mode logging - warn when relationship accessed without eager loading

**Q8: Out of Scope for v1**
**Answer:**
- Polymorphic relationships
- Through relationships (has-many-through)
- Eager loading counts

### Existing Code to Reference

**Relationship System Integration Points:**

1. **ActiveRecord.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/orm/ActiveRecord.cfc`)
   - Lines 109-208: Relationship definition methods (hasMany, belongsTo, hasOne)
   - Line 86: `variables.relationships` struct stores metadata
   - Relationship metadata structure: `{type: "hasMany/belongsTo/hasOne", foreignKey: "user_id", className: "Post"}`
   - Lines 578-614: `buildRelationshipQuery()` method constructs relationship queries
   - Lines 349-414: `onMissingMethod()` handles relationship method calls like `user.posts()`

2. **ModelBuilder.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/orm/ModelBuilder.cfc`)
   - Extends QueryBuilder, provides table-bound query interface
   - Lines 80-94: `get()`, `first()`, `count()` terminal methods
   - Returns to ActiveRecord which converts structs to model instances (ActiveRecord lines 288-321)

3. **QueryBuilder.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/orm/QueryBuilder.cfc`)
   - Lines 163-211: JOIN methods (join, leftJoin, rightJoin) already exist
   - Line 81: `variables.joinClauses` array stores join definitions
   - Lines 78-85: Core state management (whereClauses, bindings, etc.)
   - Lines 312-327: `get()` executes query and returns array of structs
   - Lines 396-448: `toSQL()` builds SQL from internal state

4. **Test Fixtures** (`/Users/peter/Documents/Code/Active/frameworks/fuse/tests/fixtures/`)
   - UserWithRelationships.cfc: hasMany("posts"), hasOne("profile")
   - PostWithRelationships.cfc: belongsTo("user")
   - ProfileWithRelationships.cfc: Referenced in tests

**Key Patterns to Follow:**
- Relationship metadata stored in `variables.relationships` struct at model level
- Foreign key inference: hasMany/hasOne use `{singular_table}_id`, belongsTo uses `{relationship_name}_id`
- Class name inference: Strip 's' from relationship name, capitalize (posts -> Post)
- QueryBuilder fluent interface returns `this` for chaining
- Terminal methods (`get()`, `first()`) execute queries
- ActiveRecord overrides ModelBuilder terminal methods to hydrate model instances

### Existing Code Reuse
No similar eager loading features exist. This is new functionality building on established relationship and query builder systems.

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
N/A - Backend ORM feature with no UI component.

## Requirements Summary

### Functional Requirements

**Core API Methods:**
1. `includes(relationshipNames)` - Auto-select strategy based on relationship type
   - Accepts string for single relationship: `includes("posts")`
   - Accepts array for multiple relationships: `includes(["posts", "profile"])`
   - Accepts dot notation for nested relationships: `includes(["posts.comments"])`
   - Chainable with existing query methods (where, orderBy, limit, etc.)

2. `joins(relationshipNames)` - Force JOIN strategy
   - Same syntax as includes()
   - Always uses INNER/LEFT JOIN regardless of relationship type
   - Useful for filtered hasMany relationships

3. `preload(relationshipNames)` - Force separate query strategy
   - Same syntax as includes()
   - Always uses separate queries regardless of relationship type
   - Useful for large hasMany collections

4. `isRelationshipLoaded(relationshipName)` - Check if relationship is loaded
   - Returns boolean indicating if relationship data is cached
   - Called on model instance: `user.isRelationshipLoaded("posts")`

**Strategy Selection Logic:**
- belongsTo: Use LEFT JOIN (parent may not exist, no row duplication)
- hasOne: Use LEFT JOIN (related record may not exist, no row duplication)
- hasMany: Use separate query (avoids Cartesian product row explosion)
- Exception: Filtered hasMany with WHERE/LIMIT may benefit from JOIN with subquery (future optimization)

**Result Hydration:**
- Eager loaded relationships populate `variables.loadedRelationships` struct on model instance
- Structure: `variables.loadedRelationships["posts"] = [array of Post instances]`
- Accessing relationship via `user.posts()` checks loadedRelationships first:
  - If loaded: Return cached array/object
  - If not loaded: Execute lazy query (log N+1 warning in dev mode)
- Hydration happens in ActiveRecord `get()` and `first()` methods after query execution

**Error Handling:**
- Invalid relationship name: Throw `ActiveRecord.InvalidRelationship` immediately (fail fast)
- Nested relationship with invalid path: Throw `ActiveRecord.InvalidRelationship` with path details
- Attempting to join through unrelated model: Throw `ActiveRecord.InvalidRelationshipPath`

**N+1 Detection (Dev Mode):**
- Log warning when relationship accessed via lazy load after batch query
- Message format: "N+1 Query Detected: Accessed relationship 'posts' on User without eager loading. Consider using includes(['posts'])"
- Only log in development mode (check environment config)
- Track query count per request to identify problematic patterns

**Nested Eager Loading:**
- Parse dot notation: `includes(["posts.comments"])` → load posts, then comments for all posts
- Execute in sequence: First load posts for all users, then load comments for all loaded posts
- Avoid nested loops by batching: Collect all post IDs, then query comments WHERE post_id IN (...)
- Support arbitrary depth: `includes(["posts.comments.author"])`

### Reusability Opportunities

**Leverage Existing Components:**
1. **QueryBuilder JOIN methods** - Use existing `join()`, `leftJoin()` for JOIN strategy
2. **Relationship metadata** - Use `variables.relationships` struct already populated by hasMany/belongsTo/hasOne
3. **Foreign key inference** - Reuse `singularizeTableName()` and `inferClassNameFromRelationship()` helpers
4. **Model hydration** - Extend existing `populate()` and `createModelInstance()` patterns
5. **Query execution** - Use established `queryExecute()` wrapper with datasource management

**New Components to Create:**
1. **EagerLoader.cfc** - Strategy selection, query building, result hydration
2. **JoinStrategy.cfc** - Build JOIN-based eager loading SQL
3. **PreloadStrategy.cfc** - Build separate query-based eager loading
4. **N+1Detector.cfc** - Track and log N+1 query patterns in dev mode

### Scope Boundaries

**In Scope for v1:**
- includes(), joins(), preload() API methods
- Automatic strategy selection (JOIN vs separate queries)
- Single-level eager loading (direct relationships)
- Nested eager loading with dot notation
- Multiple relationship loading in one call
- Result hydration with loaded relationship caching
- isRelationshipLoaded() introspection method
- Invalid relationship error handling (fail fast)
- N+1 detection logging in dev mode
- belongsTo, hasOne, hasMany relationship types

**Out of Scope for v1:**
- Polymorphic relationships (e.g., commentable_type/commentable_id)
- Through relationships (has-many-through, e.g., user has many tags through posts)
- Eager loading counts (e.g., user with posts_count)
- Conditional eager loading (load relationship only if condition met)
- Eager loading with aggregates (e.g., latest post per user)
- Selective column loading for relationships (always loads all columns)
- Custom loading strategies (only JOIN and separate queries supported)

**Future Enhancements (Deferred):**
- Smart subquery strategy for filtered hasMany (WHERE/LIMIT applied to relationship)
- Eager loading with relationship constraints passed as blocks/closures
- Relationship presence checking (e.g., users who have posts)
- Inverse relationship caching (if user.posts loaded, set post.user automatically)
- Query caching for repeated eager loads within request

### Technical Considerations

**Integration Points:**
1. **ModelBuilder extension** - Add includes(), joins(), preload() methods to ModelBuilder.cfc
2. **ActiveRecord get()/first() override** - Modify to detect eager loading state and trigger EagerLoader
3. **Relationship query interception** - Modify onMissingMethod() to check loadedRelationships before building query
4. **Query state tracking** - Add `variables.eagerLoad` struct to track requested relationships and strategies

**Database Compatibility:**
- Use standard SQL JOIN syntax (compatible with MySQL, PostgreSQL, SQL Server)
- LIMIT/OFFSET in subqueries may vary by database (defer advanced strategies to future version)
- Rely on existing QueryBuilder database abstraction

**Performance Targets:**
- JOIN strategy: Single query for belongsTo/hasOne (same performance as manual join)
- Separate query strategy: N+1 queries for hasMany where N = number of relationships + 1 base query (acceptable tradeoff vs row explosion)
- Nested loading: 1 query per relationship level (linear, not exponential)
- Memory overhead: Loaded relationships cached in model instance (acceptable for typical result sets <1000 records)

**Code Organization:**
- Place eager loading components in `fuse/orm/` directory alongside ActiveRecord, ModelBuilder, QueryBuilder
- Follow existing naming conventions (PascalCase for classes, camelCase for methods)
- Maintain fluent interface pattern (all builder methods return `this`)
- Use private helper methods for internal logic (strategy selection, hydration)

**Testing Strategy:**
- Unit tests for EagerLoader component (strategy selection logic)
- Integration tests for includes() with actual database (test fixtures already exist)
- N+1 detection tests (verify warnings logged in dev mode)
- Nested loading tests (verify correct number of queries executed)
- Invalid relationship tests (verify fail-fast error handling)

**Standards Compliance:**
- Follow existing error handling patterns (throw with type, message, detail)
- Use hash-based query syntax for consistency with QueryBuilder
- Maintain convention-over-configuration philosophy (foreign keys, class names inferred)
- Document public API methods with usage examples in code comments
