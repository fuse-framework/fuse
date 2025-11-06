# Task Breakdown: ActiveRecord Base & CRUD

## Overview
Total Tasks: 4 task groups
Estimated Complexity: Large
Dependencies: Roadmap #4 (Query Builder Foundation) - completed

## Task List

### Foundation Layer

#### Task Group 1: ActiveRecord Base Class & Conventions
**Dependencies:** None (builds on completed QueryBuilder/ModelBuilder from roadmap #4)

- [x] 1.0 Complete ActiveRecord base class foundation
  - [x] 1.1 Write 2-8 focused tests for base class initialization
    - Limit to 2-8 highly focused tests maximum
    - Test only critical init behaviors: datasource storage, table name defaulting, primary key defaulting, timestamp column detection
    - Skip exhaustive coverage of edge cases
  - [x] 1.2 Create ActiveRecord.cfc base class
    - Location: `fuse/orm/ActiveRecord.cfc`
    - Component extends ModelBuilder for static method inheritance
    - init(datasource) - store datasource reference in variables scope
  - [x] 1.3 Implement table name convention
    - Default: append 's' to component name (User -> users, Post -> posts)
    - Extract component name from getMetadata(this).name
    - Lowercase the default plural: variables.tableName = lcase(componentName & "s")
    - Support override: read this.tableName if defined, use before default
    - Call parent ModelBuilder init with datasource and resolved tableName
  - [x] 1.4 Implement primary key convention
    - Default: variables.primaryKey = "id"
    - Support override: read this.primaryKey if defined
    - Store in variables scope for use by instance methods
  - [x] 1.5 Implement timestamp column detection
    - Query database schema for created_at column existence at init
    - Query database schema for updated_at column existence at init
    - Store detection flags: variables.hasCreatedAt and variables.hasUpdatedAt
    - Use flags to avoid per-query schema checks
  - [x] 1.6 Initialize attribute storage for dirty tracking
    - Create variables.attributes = {} for current attribute values
    - Create variables.original = {} for tracking changes
    - Create variables.isPersisted = false flag for new vs existing records
  - [x] 1.7 Ensure base class tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify table name convention works (default and override)
    - Verify primary key convention works (default and override)
    - Verify timestamp detection stores flags correctly
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- ActiveRecord.cfc exists at fuse/orm/ActiveRecord.cfc
- Table name defaults to plural (User -> users), respects this.tableName override
- Primary key defaults to 'id', respects this.primaryKey override
- Timestamp columns detected at init, flags stored in variables scope
- Attribute structs initialized (attributes, original, isPersisted flag)
- The 2-8 tests written in 1.1 pass

---

### Static Query Methods

#### Task Group 2: Static Finders (where, find, all)
**Dependencies:** Task Group 1

- [x] 2.0 Complete static query methods
  - [x] 2.1 Write 2-8 focused tests for static finders
    - Limit to 2-8 highly focused tests maximum
    - Test only critical finder behaviors: where() returns ModelBuilder, find(id) returns instance, find([ids]) returns array, all() returns ModelBuilder
    - Skip exhaustive coverage of complex query combinations
  - [x] 2.2 Implement static where() method
    - Signature: public function where(struct conditions)
    - Create new ModelBuilder instance with model's datasource and tableName when called without init
    - Call where(conditions) on builder instance
    - Return ModelBuilder for method chaining
    - Example: User::where({active: true}).orderBy("name").get()
  - [x] 2.3 Implement static find() method
    - Signature: public function find(required id)
    - Single ID input: find(1) queries WHERE primaryKey = ? and returns model instance or null
    - Array ID input: find([1,2,3]) queries WHERE primaryKey IN (?,?,?) and returns array of model instances
    - Single-element array: find([1]) returns array with one instance (not unwrapped)
    - Use ModelBuilder with where({primaryKey: {in: ids}}) for array lookups
    - Return null for single ID when no record found
    - Return empty array for array input when no records found
  - [x] 2.4 Implement static all() method
    - Signature: public function all()
    - Return new ModelBuilder instance with model's datasource and tableName
    - No WHERE clause, no ORDER BY (developer adds explicitly)
    - Terminal get() returns array of model instances
    - Example: User::all().orderBy("created_at DESC").get()
  - [x] 2.5 Override ModelBuilder terminal methods
    - Override get() to return array of model instances (not structs)
    - Override first() to return single model instance or null (not struct)
    - Keep count() unchanged (returns numeric)
    - Call super.get()/super.first() to get struct data
    - Map struct data to model instances via populate() method
  - [x] 2.6 Ensure static finder tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify where() returns chainable ModelBuilder
    - Verify find(id) returns instance or null
    - Verify find([ids]) returns array of instances
    - Verify all() returns chainable ModelBuilder
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- where(conditions) returns ModelBuilder for chaining, terminal methods return model instances
- find(id) returns model instance or null for single ID
- find([ids]) returns array of model instances for array input
- all() returns ModelBuilder for chaining
- ModelBuilder get() and first() overridden to return model instances
- The 2-8 tests written in 2.1 pass

---

### Instance CRUD Methods

#### Task Group 3: Instance Methods (save, update, delete, reload) & Dirty Tracking
**Dependencies:** Task Group 2

- [x] 3.0 Complete instance CRUD methods
  - [x] 3.1 Write 2-8 focused tests for instance methods
    - Limit to 2-8 highly focused tests maximum
    - Test only critical instance behaviors: save() INSERT, save() UPDATE, update() merges attributes, delete() removes record, reload() refreshes data
    - Skip exhaustive testing of all dirty tracking edge cases
  - [x] 3.2 Implement populate() method for hydration
    - Signature: public function populate(required struct data)
    - Set variables.attributes = arguments.data (shallow copy)
    - Set variables.original = duplicate(arguments.data) for dirty tracking baseline
    - Set variables.isPersisted = true (record exists in database)
    - Return this for chaining
    - Called by ModelBuilder terminal methods when creating instances from query results
  - [x] 3.3 Implement attribute getter/setter via onMissingMethod
    - Signature: public function onMissingMethod(required string missingMethodName, required struct missingMethodArguments)
    - Detect getter pattern: method starts with "get" or has zero arguments
    - Getter: return variables.attributes[attributeName] or null if not exists
    - Detect setter pattern: method starts with "set" or has one argument
    - Setter: set variables.attributes[attributeName] = value, return this
    - Support dot notation: user.name (getter), user.name = "John" (setter)
    - Mark attribute as dirty when set (track in dirty tracking system)
  - [x] 3.4 Implement getDirty() method for dirty tracking
    - Signature: public struct function getDirty()
    - Compare variables.attributes to variables.original
    - Return struct of changed attributes: {name: "John", email: "john@example.com"}
    - Only include attributes where current value differs from original
    - Return empty struct if no changes detected
  - [x] 3.5 Implement save() method
    - Signature: public function save()
    - Detect INSERT vs UPDATE: check if variables.attributes[primaryKey] exists and variables.isPersisted == true
    - INSERT path:
      - Add created_at = now() if variables.hasCreatedAt == true
      - Use QueryBuilder to INSERT INTO tableName with all attributes
      - Retrieve last inserted ID and set variables.attributes[primaryKey]
      - Set variables.isPersisted = true
    - UPDATE path:
      - Get dirty attributes via getDirty()
      - Add updated_at = now() to dirty attributes if variables.hasUpdatedAt == true
      - Use QueryBuilder to UPDATE tableName SET dirty_columns WHERE primaryKey = ?
      - Only update changed columns (not all columns)
    - Reset dirty tracking: variables.original = duplicate(variables.attributes)
    - Return this for method chaining
    - Throw exception with type "ActiveRecord.SaveFailed" on database errors
  - [x] 3.6 Implement update() method
    - Signature: public function update(required struct changes)
    - Merge arguments.changes into variables.attributes
    - Dirty tracking automatically updated by attribute setters
    - Call save() to persist changes to database
    - Return this for method chaining
    - Example: user.update({name: "John", email: "john@example.com"})
  - [x] 3.7 Implement delete() method
    - Signature: public boolean function delete()
    - Execute DELETE FROM tableName WHERE primaryKey = ? with current instance ID
    - Use QueryBuilder for SQL generation and execution
    - Return true if rows affected > 0, false if no rows affected
    - Throw exception with type "ActiveRecord.DeleteFailed" on database errors
    - Instance remains in memory but detached from database (variables.isPersisted = false)
  - [x] 3.8 Implement reload() method
    - Signature: public function reload()
    - Query database for current record: SELECT * FROM tableName WHERE primaryKey = ?
    - Use ModelBuilder.first() to get fresh data
    - Throw exception with type "ActiveRecord.RecordNotFound" if record no longer exists
    - Refresh variables.attributes with database values
    - Reset variables.original = duplicate(variables.attributes) to clear dirty tracking
    - Return this for method chaining
  - [x] 3.9 Ensure instance method tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify save() INSERT creates new record with timestamps
    - Verify save() UPDATE updates only dirty attributes with updated_at
    - Verify update() merges attributes and persists via save()
    - Verify delete() removes record and returns boolean
    - Verify reload() refreshes attributes from database
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- populate() hydrates model instances from struct data, sets original for dirty tracking
- Attribute getters/setters work via onMissingMethod (user.name, user.name = "John")
- getDirty() returns struct of changed attributes only
- save() detects INSERT vs UPDATE, handles timestamps, updates only dirty columns
- update() merges changes and calls save()
- delete() executes hard delete, returns boolean, detaches instance
- reload() refreshes from database, resets dirty tracking
- The 2-8 tests written in 3.1 pass

---

### Testing & Integration

#### Task Group 4: Test Review & Integration Testing
**Dependencies:** Task Groups 1-3

- [x] 4.0 Review tests and fill critical gaps only
  - [x] 4.1 Review tests from Task Groups 1-3
    - Review the 2-8 tests written for base class (Task 1.1)
    - Review the 2-8 tests written for static finders (Task 2.1)
    - Review the 2-8 tests written for instance methods (Task 3.1)
    - Total existing tests: approximately 6-24 tests
  - [x] 4.2 Analyze test coverage gaps for ActiveRecord feature only
    - Identify critical workflows lacking coverage: end-to-end CRUD operations, static + instance method integration
    - Focus ONLY on gaps related to ActiveRecord CRUD feature requirements
    - Do NOT assess entire application test coverage
    - Prioritize integration workflows: find() -> update() -> save(), all() -> get() returns model instances, dirty tracking across save/reload cycle
  - [x] 4.3 Write up to 10 additional strategic tests maximum
    - Add maximum of 10 new tests to fill identified critical gaps
    - Focus on integration workflows across static and instance methods
    - Example workflows: User::find(1).update({name: "New"}).save(), User::all().get() returns instances with working instance methods
    - Do NOT write comprehensive coverage for all edge cases
    - Skip performance tests, complex error scenarios unless business-critical
  - [x] 4.4 Run feature-specific tests only
    - Run ONLY tests related to ActiveRecord CRUD feature (tests from 1.1, 2.1, 3.1, and 4.3)
    - Expected total: approximately 16-34 tests maximum
    - Do NOT run entire application test suite
    - Verify critical workflows pass: static finders return model instances, instance CRUD methods work, dirty tracking functions correctly
  - [x] 4.5 Create example model for documentation
    - Create tests/fixtures/User.cfc as example model extending ActiveRecord
    - Override this.tableName = "users" explicitly (for documentation clarity)
    - Override this.primaryKey = "id" explicitly (for documentation clarity)
    - Add JSDoc comments showing usage: User::find(1), user.save(), etc.
    - This fixture serves as reference for developers creating their own models

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 16-34 tests total)
- Critical CRUD workflows covered: find/all return model instances, save/update/delete work, dirty tracking functions, reload refreshes data
- No more than 10 additional tests added when filling gaps
- Testing focused exclusively on ActiveRecord CRUD feature requirements
- Example User.cfc fixture created for documentation reference

---

## Execution Order

Recommended implementation sequence:

1. **Task Group 1: Foundation Layer** - Base class, conventions, attribute storage
2. **Task Group 2: Static Query Methods** - where(), find(), all() with ModelBuilder integration
3. **Task Group 3: Instance CRUD Methods** - save(), update(), delete(), reload(), dirty tracking
4. **Task Group 4: Testing & Integration** - Test review, gap analysis, integration testing

## Implementation Notes

**Leverage Existing Code:**
- QueryBuilder (fuse/orm/QueryBuilder.cfc) - hash-based WHERE syntax, SQL generation, prepared statements
- ModelBuilder (fuse/orm/ModelBuilder.cfc) - table-specific query building, terminal methods
- Container (fuse/core/Container.cfc) - DI pattern for datasource injection

**Coding Style:**
- Follow QueryBuilder/ModelBuilder comment style: JSDoc blocks, @param/@return tags, usage examples
- Exception types use dot notation: ActiveRecord.SaveFailed, ActiveRecord.RecordNotFound
- CamelCase for methods and components, lowercase_underscores for database columns
- Method chaining pattern: return this from builder methods

**Key Design Decisions:**
- Static methods use Lucee 7 double-colon syntax: User::find(1), User::all()
- ModelBuilder terminal methods (get/first) overridden to return model instances not structs
- Dirty tracking stores original attributes, UPDATE only changed columns
- Timestamp auto-population uses convention: created_at on INSERT, updated_at on UPDATE
- Table names default to simple pluralization: append 's' (User -> users, Post -> posts)
- Primary key defaults to 'id', override via this.primaryKey for legacy tables

**Out of Scope:**
- Relationships (hasMany, belongsTo) - deferred to roadmap #7
- Validations (validates DSL) - deferred to roadmap #9
- Callbacks (beforeSave, afterCreate) - deferred to roadmap #9
- Named scopes, attribute casting, soft deletes, complex pluralization library
