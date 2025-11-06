# Query Builder Foundation

**From Roadmap Item #4:**

Two-layer query builder (QueryBuilder for raw SQL, ModelBuilder for ORM features), hash-based where() with operator structs ({gte:, like:, in:}), orderBy/limit/offset, raw SQL support (whereRaw, selectRaw)

**Size:** Large

**Description:**
Implement the foundational query builder layer that will power both raw SQL queries and ORM operations. This includes:
- QueryBuilder component for building and executing raw SQL queries
- ModelBuilder component that extends QueryBuilder with ORM-specific features
- Hash-based where() conditions with operator structs
- Query modifiers: orderBy, limit, offset
- Raw SQL escape hatches: whereRaw, selectRaw

This layer sits between the database and the ActiveRecord models, providing a fluent interface for query construction.
