# Specification: Smart Eager Loading

## Goal
Implement smart eager loading for Fuse ORM to eliminate N+1 query problems with automatic strategy selection (JOIN vs separate queries) based on relationship type, Rails-style includes() API with nested relationships, and manual override methods.

## User Stories
- As a developer, I want to eager load relationships using includes() so that I avoid N+1 queries without manual JOIN construction
- As a developer, I want automatic strategy selection so that I get optimal performance without understanding JOIN vs separate query tradeoffs

## Specific Requirements

**includes() API Method**
- Add includes() method to ModelBuilder, chainable with existing query methods (where, orderBy, limit)
- Accept single string: `User::where({active: true}).includes("posts").get()`
- Accept array for multiple: `User::includes(["posts", "profile"]).get()`
- Accept dot notation for nested: `User::includes(["posts.comments"]).get()`
- Store requested relationships in `variables.eagerLoad` struct with strategy metadata
- Parse dot notation into hierarchical structure for nested loading
- Validate relationship names immediately (fail fast if invalid)
- Return this for chaining

**Automatic Strategy Selection**
- belongsTo relationships: Use LEFT JOIN (parent may not exist, no row duplication)
- hasOne relationships: Use LEFT JOIN (related may not exist, no row duplication)
- hasMany relationships: Use separate queries (avoids Cartesian product row explosion)
- Decision made at query execution time based on relationship type from `variables.relationships`
- Strategy stored in eagerLoad metadata: `{relationshipName: "posts", strategy: "separate"}` or `{relationshipName: "profile", strategy: "join"}`

**Manual Override Methods**
- Add joins() method: Force JOIN strategy regardless of relationship type
- Add preload() method: Force separate query strategy regardless of relationship type
- Same signature as includes(): accepts string, array, or dot notation
- Override automatic strategy selection in eagerLoad metadata
- Useful for: Filtered hasMany (joins), large collections (preload)

**Result Hydration & Caching**
- Add `variables.loadedRelationships` struct to ActiveRecord instances
- Structure: `loadedRelationships["posts"] = [array of Post instances]` or `loadedRelationships["profile"] = Profile instance`
- Populate loadedRelationships in ActiveRecord get()/first() after query execution
- Modify buildRelationshipQuery() in ActiveRecord to check loadedRelationships before building query
- If loaded: Return cached array/object immediately
- If not loaded: Execute lazy query and log N+1 warning in dev mode

**isRelationshipLoaded() Introspection**
- Add isRelationshipLoaded(relationshipName) method to ActiveRecord
- Return boolean indicating if relationship data is cached in loadedRelationships
- Usage: `user.isRelationshipLoaded("posts")` returns true/false
- Used for debugging and conditional logic

**Nested Eager Loading**
- Parse dot notation: `includes(["posts.comments"])` → load posts, then comments for all posts
- Execute sequentially: Load posts for all users, collect post IDs, query comments WHERE post_id IN (...)
- Avoid nested loops by batching IDs
- Support arbitrary depth: `includes(["posts.comments.author"])`
- Each level uses its own strategy selection logic

**Error Handling (Fail Fast)**
- Invalid relationship name: Throw `ActiveRecord.InvalidRelationship` with relationship name in detail
- Nested relationship with invalid path: Throw `ActiveRecord.InvalidRelationship` with full path details
- Validation happens in includes()/joins()/preload() before storing in eagerLoad
- Check against `variables.relationships` keys immediately

**N+1 Detection (Dev Mode)**
- Log warning when relationship accessed via lazy load after batch query (get() with multiple records)
- Message format: "N+1 Query Detected: Accessed relationship 'posts' on User without eager loading. Consider using includes(['posts'])"
- Only log in development environment (check application.environment or similar config)
- Add detection logic to buildRelationshipQuery() when loadedRelationships not present

## Visual Design
No visual assets provided - backend ORM feature.

## Existing Code to Leverage

**ActiveRecord.cfc relationship system**
- `variables.relationships` struct stores metadata: `{type: "hasMany/belongsTo/hasOne", foreignKey: "user_id", className: "Post"}`
- buildRelationshipQuery() constructs WHERE clause based on relationship type and foreign key
- inferClassNameFromRelationship() and singularizeTableName() helpers for convention-over-configuration
- onMissingMethod() intercepts relationship method calls like `user.posts()`
- populate() and createModelInstance() patterns for hydrating model instances

**QueryBuilder.cfc JOIN methods**
- join(), leftJoin(), rightJoin() methods already exist with `variables.joinClauses` array storage
- Fluent interface pattern returns `this` for chaining
- toSQL() builds SQL from internal state including JOIN clauses
- Prepared statement binding with `variables.bindings` array

**ModelBuilder.cfc terminal methods**
- get(), first(), count() execute queries and delegate to QueryBuilder
- ActiveRecord overrides get()/first() to convert structs to model instances
- Integration point for eager loading: trigger hydration after query execution

**Relationship metadata inference**
- hasMany/hasOne: foreignKey = `{singular_table}_id` (user_id)
- belongsTo: foreignKey = `{relationship_name}_id` (user_id)
- className inference: Strip 's', capitalize (posts -> Post)

**Test fixtures**
- UserWithRelationships.cfc: hasMany("posts"), hasOne("profile")
- PostWithRelationships.cfc: belongsTo("user")
- Use for integration testing with actual database

## Out of Scope
- Polymorphic relationships (commentable_type/commentable_id)
- Through relationships (has-many-through)
- Eager loading counts (posts_count)
- Conditional eager loading (load only if condition met)
- Eager loading with aggregates (latest post per user)
- Selective column loading for relationships (always loads all columns)
- Custom loading strategies beyond JOIN and separate queries
- Smart subquery strategy for filtered hasMany
- Eager loading with relationship constraints via blocks/closures
- Relationship presence checking (users who have posts)
- Inverse relationship caching (auto-set post.user when user.posts loaded)
- Query caching for repeated eager loads within request
