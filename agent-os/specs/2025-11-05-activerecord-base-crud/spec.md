# Specification: ActiveRecord Base & CRUD

## Goal
Create ActiveRecord base class with static query methods (where, find, all) and instance CRUD methods (save, update, delete, reload) plus dirty tracking for change detection and automatic timestamps.

## User Stories
- As a developer, I want to define model classes that extend ActiveRecord so I can use ORM patterns instead of writing raw SQL
- As a developer, I want instance methods like save() and update() so I can persist model changes with simple method calls

## Specific Requirements

**ActiveRecord Base Class**
- Create `fuse.orm.ActiveRecord` component with init() that stores datasource reference
- Support `this.tableName` override (defaults to plural of component name with 's' appended)
- Support `this.primaryKey` override (defaults to 'id')
- Detect timestamp columns (created_at/updated_at) at initialization for auto-population
- Store datasource from DI container injection
- Provide static method support via Lucee 7 double-colon syntax (User::find)
- Initialize attributes struct and original struct for dirty tracking

**Static where() Method**
- Return ModelBuilder instance initialized with model's tableName and datasource
- Accept struct of conditions matching QueryBuilder hash syntax
- Enable chaining pattern: User::where({active: true}).orderBy("name").get()
- ModelBuilder terminal methods (get/first) return model instances not structs

**Static find() Method**
- Single ID input: find(1) returns User instance or null if not found
- Array ID input: find([1,2,3]) returns array of User instances
- Single-element array: find([1]) returns array with one instance
- Use QueryBuilder WHERE id IN for array lookups
- Null return for single ID when no record exists

**Static all() Method**
- Return ModelBuilder instance for SELECT * FROM table
- No automatic ordering (developer adds orderBy() explicitly)
- Terminal get() returns array of model instances
- Example: User::all().orderBy("created_at DESC").get()

**Instance save() Method**
- Detect INSERT vs UPDATE by checking if primary key value exists in attributes
- INSERT: populate created_at if column detected during init
- UPDATE: populate updated_at if column detected, update only dirty attributes
- Return model instance (this) for method chaining
- Throw exception with clear message on database errors
- Reset dirty tracking after successful save

**Instance update() Method**
- Accept struct of attribute changes: user.update({name: "John", email: "john@example.com"})
- Merge changes into attributes struct
- Mark changed attributes as dirty
- Call save() to persist changes
- Return model instance for chaining

**Instance delete() Method**
- Execute DELETE FROM table WHERE primaryKey = ? using current instance ID
- Return boolean: true on success, false if no rows affected
- Throw exception on database errors
- Instance remains in memory but detached from database

**Instance reload() Method**
- Query database for current record by primary key
- Refresh attributes struct with database values
- Reset original struct to match current database state (clear dirty tracking)
- Return model instance for chaining
- Throw exception if record no longer exists in database

**Dirty Tracking System**
- Store original attribute values in variables.original on load/save
- Compare variables.attributes to variables.original to detect changes
- UPDATE queries include only changed columns not all columns
- Provide getDirty() method returning struct of changed attributes
- Reset dirty tracking after successful save() or reload()

**Attribute Handling**
- Getter/setter methods for dot notation access: user.name, user.name = "John"
- Store all attributes in variables.attributes struct
- onMissingMethod() intercepts get/set calls for attribute names
- Type preservation (no automatic casting in foundation)
- Track changes via dirty tracking when attributes are set

**Table Name Convention**
- Default: append 's' to component name (User -> users, Post -> posts)
- Override via this.tableName = "people" for irregular plurals
- Extract component name from metadata for default calculation
- Case handling: preserve case from override, lowercase default plural

**Primary Key Convention**
- Default to 'id' column name
- Override via this.primaryKey = "user_id" for legacy tables
- Use primary key for find(), save() detection, delete(), reload()
- No schema introspection (developer specifies if not 'id')

**Timestamp Auto-Population**
- Check for created_at column existence at model initialization
- Check for updated_at column existence at model initialization
- INSERT: set created_at = now() if column exists
- UPDATE: set updated_at = now() if column exists
- Store detection flags in variables scope to avoid per-query checks

**ModelBuilder Integration**
- Override ModelBuilder get() to return array of model instances
- Override ModelBuilder first() to return single model instance or null
- Pass struct data to model's populate() method for hydration
- Model instances track datasource and table for instance methods
- Maintain QueryBuilder chaining capabilities (where, orderBy, limit)

**Model Instance Hydration**
- Provide populate(struct) method to fill attributes from database row
- Set both variables.attributes and variables.original to same values
- Mark instance as persisted (primary key exists)
- Called by ModelBuilder terminal methods when creating instances

**Error Handling**
- Throw descriptive exceptions for invalid operations (save without datasource, etc)
- Use type prefix "ActiveRecord." for exception types
- Fail fast on configuration errors (invalid table name, etc)
- Database errors bubble up with clear context about which operation failed

## Existing Code to Leverage

**QueryBuilder (fuse/orm/QueryBuilder.cfc)**
- Hash-based WHERE syntax with operators (gte, in, isNull, etc)
- Prepared statement binding with positional placeholders
- SQL generation via toSQL() method
- Terminal methods (get, first, count) for query execution
- Method chaining pattern returns this from builder methods

**ModelBuilder (fuse/orm/ModelBuilder.cfc)**
- Extends QueryBuilder with stored tableName
- Terminal methods (get, first, count) without tableName parameter
- toSQL() delegates to parent with stored tableName
- Comments indicate future ActiveRecord will override get/first for model instances
- Provides foundation for static query methods

**Container (fuse/core/Container.cfc)**
- DI pattern with bind() and singleton() registration
- resolve() method for service instantiation
- Circular dependency detection
- Singleton caching for datasource and shared services
- Models will receive datasource via constructor injection

**Naming Conventions from Existing Code**
- CamelCase for component and method names
- Lowercase with underscores for database columns
- Exception types use dot notation (Container.BindingNotFound)
- Private methods prefix not used (CFML scope controls visibility)

**Comment Style from QueryBuilder/ModelBuilder**
- JSDoc-style block comments for public methods
- @param and @return tags for method signatures
- Usage examples in component header block
- Inline comments for complex logic explanation

## Out of Scope
- Relationships (hasMany, belongsTo, hasOne) - deferred to roadmap item #7
- Eager loading (with relationships) - deferred to roadmap item #8
- Validations (validates DSL, custom validators) - deferred to roadmap item #9
- Callbacks (beforeSave, afterCreate, afterUpdate, etc) - deferred to roadmap item #9
- Named scopes (User::active() shortcut methods)
- Attribute casting/type coercion (keep attributes as-is from database)
- Mass assignment protection (attr_accessible pattern)
- Query caching at ORM layer
- Transaction support in model methods (use database transactions directly)
- Soft deletes (deleted_at timestamp instead of hard delete)
- Polymorphic associations
- Single table inheritance
- Complex pluralization library (only simple 's' append)
- Schema introspection for column types or primary key detection
- Multi-column primary keys (compound keys)
- Model observers or event broadcasting
- Automatic foreign key constraint handling
