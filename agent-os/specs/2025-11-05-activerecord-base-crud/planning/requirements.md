# Spec Requirements: ActiveRecord Base & CRUD

## Initial Description
Model base class with static query methods (where, find, all), instance methods (save, update, delete), attribute handling with dirty tracking, table name conventions, primary key handling

**Roadmap Item #5** - Size: L (Large)

**Dependencies:** Item #4: Query Builder Foundation (completed)

## Requirements Discussion

### Static Query Methods

**Decision:** `where()`, `find()`, `all()` return ModelBuilder instances for chaining

**Rationale:** Enables fluent query building pattern

**Examples:**
- `User::where({active: true}).orderBy("name").get()` returns array of User instances
- Terminal methods (get/first/count) return model instances
- QueryBuilder methods chain before terminal execution

---

### find() Method Behavior

**Decision:** Type-aware return values based on input

**Single ID:** `User::find(1)` returns User instance or null

**Array IDs:** `User::find([1,2,3])` returns array of User instances

**Single-element array:** `User::find([1])` returns array (not instance)

**Rationale:** Predictable return types based on input structure

---

### save() Method

**Decision:** Smart INSERT/UPDATE with instance return

**Return value:** Model instance for chaining

**Detection logic:** Detects new vs existing via primary key presence
- No primary key value → INSERT
- Primary key value exists → UPDATE

**Error handling:** Throws exception on failure

**Rationale:** Chainable API, clear save semantics

---

### Dirty Tracking

**Decision:** Track original attributes for change detection

**Implementation:**
- Store original attributes in `variables.original`
- Compare to `variables.attributes` on save
- UPDATE only changed columns (not all columns)

**Benefits:**
- Performance: only update changed fields
- Audit trails: know what changed
- Database load reduction

---

### Table Name Conventions

**Decision:** Simple pluralization with override capability

**Convention:**
- Singular model name → plural table name with 's' append
- User → users
- Post → posts

**Override:** `this.tableName = "people"` for irregular plurals

**Explicitly NOT included:** Complex pluralization library

**Rationale:** Convention covers 90% of cases, override handles exceptions

---

### Primary Key Handling

**Decision:** Convention-based with override

**Convention:** Defaults to 'id'

**Override:** `this.primaryKey = "user_id"`

**Explicitly NOT included:** Schema auto-detection

**Rationale:** Simple convention, explicit override for legacy tables

---

### Timestamp Auto-Population

**Decision:** Convention-based automatic timestamps

**INSERT behavior:** Auto-populate `created_at` if column exists

**UPDATE behavior:** Auto-populate `updated_at` if column exists

**Configuration:** None needed, pure convention

**Detection:** Check if column exists at model initialization

**Rationale:** Rails-like convention, zero config

---

### delete() Method

**Decision:** Hard delete only

**Behavior:** DELETE FROM table WHERE id = ?

**Explicitly NOT included:** Soft delete support in foundation

**Rationale:** Simple foundation, soft deletes are advanced feature (future roadmap)

---

### all() Method

**Decision:** Return all records unsorted

**Behavior:** Simple `SELECT * FROM table`

**Ordering:** Developers add `orderBy()` explicitly

**Example:** `User::all().orderBy("created_at DESC").get()`

**Rationale:** Explicit > implicit for query behavior

---

### Instance Methods to Include

**Core methods:**
- `save()` - INSERT or UPDATE based on primary key
- `update()` - Update specific attributes
- `delete()` - Hard delete record
- `reload()` - Refresh from database

**Rationale:** Standard ActiveRecord instance API

---

### Attribute Handling

**Decision:** Dot notation access with dirty tracking

**Get:** `user.name`
**Set:** `user.name = "John"`

**Behind the scenes:**
- Getters/setters update `variables.attributes`
- Track changes in dirty tracking system

**Rationale:** Natural CFML syntax

---

### Existing Code to Reference

No similar existing features identified for reference. This is foundational ORM implementation.

---

## Visual Assets

### Files Provided:
No visual assets provided.

### Visual Insights:
N/A - Backend ORM feature requires no UI.

---

## Requirements Summary

### Functional Requirements

**Static Query Methods:**
- `where(struct)` - Returns ModelBuilder for chaining
- `find(id)` - Returns instance or null (single ID) or array (array IDs)
- `all()` - Returns ModelBuilder for unsorted collection

**Instance Methods:**
- `save()` - Smart INSERT/UPDATE, returns instance
- `update(struct)` - Update attributes, returns instance
- `delete()` - Hard delete, returns boolean
- `reload()` - Refresh from database, returns instance

**Dirty Tracking:**
- Track original attribute values
- Detect changes on save
- UPDATE only changed columns

**Conventions:**
- Table names: singular model → plural table (User → users)
- Primary key: defaults to 'id'
- Timestamps: auto-populate created_at/updated_at
- Override: `this.tableName`, `this.primaryKey`

**Attribute Access:**
- Dot notation get/set
- Automatic dirty tracking
- Type preservation

### Reusability Opportunities

**Existing Foundation:**
- ModelBuilder from roadmap #4 (completed) - extend for terminal method model instance returns
- QueryBuilder from roadmap #4 (completed) - underlying SQL generation

**Integration Points:**
- ModelBuilder terminal methods return model instances instead of raw structs
- Models extend from ActiveRecord base class
- DI container integration for model injection

### Scope Boundaries

**In Scope:**
- ActiveRecord base class
- Static query methods (where/find/all)
- Instance CRUD methods (save/update/delete/reload)
- Dirty tracking system
- Table name conventions
- Primary key handling
- Automatic timestamps
- Attribute get/set

**Out of Scope (Explicitly Excluded from Foundation):**
- Relationships (hasMany/belongsTo) - roadmap #7
- Validations (validates DSL) - roadmap #9
- Callbacks (beforeSave/afterSave) - roadmap #9
- Scopes (named query shortcuts)
- Attribute casting
- Mass assignment protection
- Query caching
- Transaction support in models
- Polymorphic associations
- Single table inheritance
- Soft deletes

### Technical Considerations

**Framework Context:**
- Lucee 7 exclusive (static methods support)
- Extends completed Query Builder Foundation (roadmap #4)
- Integrates with DI container (roadmap #1)
- Enables future ORM features (relationships #7, eager loading #8, validations #9)

**Technology Stack:**
- Lucee 7 static methods for clean syntax (`User::find(1)`)
- Component-based inheritance (models extend ActiveRecord)
- Hash-based query syntax matching QueryBuilder conventions

**Performance:**
- Dirty tracking reduces UPDATE column count
- Timestamp auto-detection at model init (not per-query)
- Lazy loading by default (eager loading in #8)

**Rails/Laravel Pattern Alignment:**
- Static finders (Rails: `User.find(1)`, Fuse: `User::find(1)`)
- Instance CRUD (Rails: `user.save`, Fuse: `user.save()`)
- Convention-based tables/keys (matches Rails conventions)
- Dirty tracking (Rails: `user.changed?`, Fuse: internal tracking)

**Migration Path:**
- Wheels users: familiar instance methods, different static syntax
- FW/1 users: ActiveRecord pattern vs service layer
- ColdBox users: simpler than EntityService, convention-driven
