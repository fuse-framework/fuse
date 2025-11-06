# Spec Requirements: ORM Relationships

## Initial Description
Relationship definition methods (hasMany, belongsTo, hasOne) in ActiveRecord, relationship metadata storage, foreign key conventions, relationship query methods (user.posts())

**Roadmap Item #7** - Size: L (Large)

**Dependencies:** Item #5: ActiveRecord Base & CRUD (completed), Item #4: Query Builder Foundation (completed)

## Requirements Discussion

### Relationship Definition API

**Decision:** Define relationships in model's init() method, call super.init() first

**Syntax:**
- `this.hasMany("posts")` - One-to-many relationship
- `this.belongsTo("user")` - Many-to-one relationship
- `this.hasOne("profile")` - One-to-one relationship

**Example:**
```cfml
component extends="fuse.orm.ActiveRecord" {
    function init() {
        super.init();
        this.hasMany("posts");
        this.belongsTo("user");
        this.hasOne("profile");
        return this;
    }
}
```

**Rationale:** Clean, explicit, Rails-like pattern with natural CFML component initialization

---

### Foreign Key Conventions

**Decision:** Smart defaults with override capability

**belongsTo convention:**
- Relationship name → `{singular_model}_id`
- `this.belongsTo("user")` → expects `user_id` column
- Model name inferred from relationship name (user → User component)

**hasMany/hasOne convention:**
- Foreign key stored on related model
- `User.hasMany("posts")` → Post model has `user_id` column
- Foreign key name inferred from current model name

**Override syntax:**
```cfml
this.hasMany("posts", {foreignKey: "author_id"})
this.belongsTo("user", {foreignKey: "author_id", className: "BlogUser"})
```

**Rationale:** Convention handles 90% of cases, options struct handles edge cases

---

### Relationship Query Syntax

**Decision:** Return ModelBuilder for chaining, not immediate execution

**Usage pattern:**
```cfml
// Returns ModelBuilder, not results
posts = user.posts();

// Chain query methods before execution
published = user.posts().where({published: true}).orderBy("created_at").get();

// Consistent with static query methods
User::where({active: true}).get()
```

**Rationale:**
- Consistency with existing ActiveRecord query API
- Enables filtering/sorting relationships before execution
- Natural chaining pattern

---

### Relationship Metadata Storage

**Decision:** Class-level storage in `variables.relationships`

**Implementation:**
- Shared across all instances (not per-instance)
- Similar to existing `tableName` and `primaryKey` storage
- Structure: `variables.relationships = {posts: {type: "hasMany", foreignKey: "user_id", ...}}`

**Access pattern:**
- Defined once in init()
- Referenced by all instances
- Checked via onMissingMethod

**Rationale:** Memory efficient, follows existing pattern for class-level metadata

---

### Access Pattern

**Decision:** Instance-only access, defer static relationship queries

**Supported:**
- `user.posts()` - Returns ModelBuilder for user's posts
- `user.posts().where({published: true}).get()` - Filtered relationship query

**NOT in scope (deferred to roadmap #8):**
- `User::with("posts").get()` - Eager loading (roadmap #8)
- Static relationship traversal

**Rationale:** Instance access covers primary use case, eager loading requires advanced query planning

---

### Foreign Key Column Creation

**Decision:** Manual via migrations - relationships define logic only

**Implementation:**
- Relationships define foreign key name and logic
- Developers create foreign key columns via Schema Builder migrations
- No automatic schema changes or introspection

**Example migration:**
```cfml
schema.table("posts", function(t) {
    t.integer("user_id").notNull().index();
});
```

**Rationale:**
- Explicit schema control
- Follows existing Schema Builder pattern (roadmap #6)
- Predictable, no magic schema changes

---

### HasOne vs BelongsTo Semantics

**Decision:** Follow exact Rails pattern

**belongsTo:** "I have the foreign key"
- Post model: `this.belongsTo("user")` - Post has `user_id` column
- Foreign key stored on current model's table

**hasOne:** "They have the foreign key pointing to me"
- User model: `this.hasOne("profile")` - Profile has `user_id` column
- Foreign key stored on related model's table

**hasMany:** "They have the foreign key pointing to me" (multiple records)
- User model: `this.hasMany("posts")` - Post has `user_id` column
- Foreign key stored on related model's table

**Rationale:** Clear semantic distinction, matches Rails conventions exactly

---

### Method Resolution via onMissingMethod

**Decision:** Intercept relationship calls dynamically

**Flow:**
1. User calls `user.posts()`
2. Method doesn't exist, triggers `onMissingMethod`
3. Check `variables.relationships` for "posts" entry
4. If found, construct ModelBuilder with WHERE clause
5. Return ModelBuilder for chaining

**Implementation pattern:**
```cfml
function onMissingMethod(missingMethodName, missingMethodArguments) {
    if (structKeyExists(variables.relationships, missingMethodName)) {
        // Build and return ModelBuilder with relationship WHERE clause
        return buildRelationshipQuery(missingMethodName);
    }
    // Fall through to parent or throw error
}
```

**Rationale:**
- Reuses existing onMissingMethod pattern from attribute access
- No need to generate methods at init time
- Dynamic, flexible approach

---

### Foreign Key Inference

**Decision:** Smart defaults from relationship name

**belongsTo inference:**
- `this.belongsTo("user")` → foreign key: `user_id`, model: `User`
- `this.belongsTo("blogAuthor")` → foreign key: `blog_author_id`, model: `BlogAuthor`

**hasMany/hasOne inference:**
- `User.hasMany("posts")` → Post model has `user_id`
- Current model name (User) → singular lowercase + _id → `user_id`

**Override when needed:**
```cfml
this.belongsTo("author", {foreignKey: "author_id", className: "User"})
this.hasMany("articles", {foreignKey: "author_id", className: "BlogPost"})
```

**Rationale:** Convention reduces boilerplate, options handle legacy/custom schemas

---

### Relationship Options Struct

**Decision:** Support options struct for edge cases

**Supported options:**
- `foreignKey` - Override default foreign key name
- `className` - Override inferred model class name

**Example usage:**
```cfml
// Legacy table with non-standard foreign key
this.belongsTo("author", {foreignKey: "created_by_user_id", className: "User"})

// Self-referential relationship
this.hasMany("children", {foreignKey: "parent_id", className: "Category"})
```

**Rationale:** Handles edge cases without complicating simple default cases

---

### Return Value Consistency

**Decision:** All relationship methods return ModelBuilder

**hasMany:**
- `user.posts()` → ModelBuilder
- `user.posts().get()` → Array of Post instances

**hasOne:**
- `user.profile()` → ModelBuilder
- `user.profile().first()` → Profile instance or null

**belongsTo:**
- `post.user()` → ModelBuilder
- `post.user().first()` → User instance or null

**Rationale:**
- Consistent API across all relationship types
- Enables query chaining before execution
- Developers choose terminal method (get/first/count)

---

### Existing Code to Reference

**Similar Features Identified:**

- Feature: ActiveRecord Base & CRUD (roadmap #5)
  - Path: Completed foundation
  - Reuse: Model base class, static query methods pattern

- Feature: Query Builder Foundation (roadmap #4)
  - Path: Completed foundation
  - Reuse: ModelBuilder for relationship queries, where() clause construction

**Integration points:**
- Extend ActiveRecord base class with relationship support
- Leverage ModelBuilder for relationship query construction
- Follow existing metadata storage pattern (tableName, primaryKey)

---

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
N/A - Backend ORM feature requires no UI.

---

## Requirements Summary

### Functional Requirements

**Relationship Definition:**
- `hasMany(name, options)` - Define one-to-many relationship
- `belongsTo(name, options)` - Define many-to-one relationship
- `hasOne(name, options)` - Define one-to-one relationship
- Called in model's init() method after super.init()

**Foreign Key Conventions:**
- belongsTo: `{singular_relationship_name}_id` on current table
- hasMany/hasOne: `{singular_current_model_name}_id` on related table
- Override via options: `{foreignKey: "custom_id"}`

**Relationship Access:**
- Instance method calls: `user.posts()` returns ModelBuilder
- Query chaining: `user.posts().where({published: true}).orderBy("created_at").get()`
- Terminal methods return model instances (get/first) or scalars (count)

**Metadata Storage:**
- Class-level `variables.relationships` struct
- Stores: type, foreignKey, className for each relationship
- Shared across all instances

**Method Resolution:**
- onMissingMethod intercepts relationship calls
- Checks `variables.relationships` for match
- Constructs ModelBuilder with appropriate WHERE clause
- Returns ModelBuilder for chaining

**Options Support:**
- `foreignKey` - Override default foreign key name
- `className` - Override inferred model class name
- Example: `this.hasMany("posts", {foreignKey: "author_id", className: "BlogPost"})`

### Reusability Opportunities

**Existing Foundation:**
- ActiveRecord base class (roadmap #5) - extend with relationship support
- ModelBuilder (roadmap #4) - reuse for relationship queries
- onMissingMethod pattern - already used for attribute access
- Metadata storage pattern - follows tableName/primaryKey pattern

**Integration Points:**
- Models extend ActiveRecord, gain relationship methods
- ModelBuilder constructs relationship WHERE clauses
- Schema Builder creates foreign key columns (roadmap #6)
- Future eager loading uses relationship metadata (roadmap #8)

### Scope Boundaries

**In Scope:**
- hasMany, belongsTo, hasOne relationship types
- Relationship definition in init()
- Foreign key conventions with override
- Relationship query methods returning ModelBuilder
- Metadata storage in variables.relationships
- onMissingMethod for method resolution
- Options struct for foreignKey and className

**Out of Scope (Explicitly Excluded):**
- Eager loading / N+1 prevention (roadmap #8 - Smart Eager Loading)
- Polymorphic associations (user has many commentable)
- Through associations (has_many :through for join models)
- Dependent destroy/delete cascades
- Counter caches (post_count on User)
- inverse_of declarations
- Relationship validation (validates associated presence)
- Self-referential associations (deferred, but options struct enables)
- Many-to-many join tables (could add via through later)
- Static relationship queries (User::with("posts") deferred to #8)

### Technical Considerations

**Framework Context:**
- Lucee 7 exclusive (leverages static methods, modern ORM patterns)
- Builds on ActiveRecord Base & CRUD (roadmap #5 completed)
- Uses ModelBuilder for queries (roadmap #4 completed)
- Foreign keys created via Schema Builder migrations (roadmap #6 completed)
- Enables future Smart Eager Loading (roadmap #8)

**Technology Stack:**
- Component-based relationship definitions
- onMissingMethod for dynamic method resolution
- Struct-based options for configuration
- ModelBuilder integration for query construction

**Performance:**
- Lazy loading by default (N+1 query potential)
- Relationship metadata stored at class level (not per-instance)
- ModelBuilder reuse avoids query construction overhead
- Eager loading optimization deferred to roadmap #8

**Rails/Laravel Pattern Alignment:**
- Rails syntax: `has_many :posts`, Fuse: `this.hasMany("posts")`
- Rails query: `user.posts.where(published: true)`, Fuse: `user.posts().where({published: true})`
- Rails semantics: belongsTo/hasOne/hasMany match exactly
- Foreign key conventions match Rails defaults

**Migration Path:**
- Wheels users: familiar relationship syntax, ModelBuilder return value difference
- FW/1 users: ActiveRecord relationships vs service layer joins
- ColdBox users: simpler than entity relationships, pure convention

**Design Decisions:**
- Instance-only access keeps implementation simple for foundation
- Manual foreign key creation via migrations maintains explicit schema control
- Options struct handles edge cases without API complexity
- onMissingMethod enables clean syntax without code generation
