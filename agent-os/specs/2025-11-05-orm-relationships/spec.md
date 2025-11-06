# Specification: ORM Relationships

## Goal
Add relationship definition methods (hasMany, belongsTo, hasOne) to ActiveRecord with smart foreign key conventions, instance-level relationship queries returning ModelBuilder for chaining, and metadata storage enabling dynamic method resolution via onMissingMethod.

## User Stories
- As a developer, I want to define model relationships in init() so that I can express associations between models using familiar Rails-like syntax
- As a developer, I want to call relationship methods like user.posts() so that I can query related records with chaining support before execution

## Specific Requirements

**Relationship Definition Methods**
- Add hasMany(name, options), belongsTo(name, options), hasOne(name, options) methods to ActiveRecord base class
- Methods called in model's init() after super.init() to register relationships
- Store relationship metadata in class-level variables.relationships struct with structure: {name: {type, foreignKey, className}}
- Follow existing metadata pattern from tableName and primaryKey storage in ActiveRecord.cfc
- Support options struct with foreignKey and className keys for override capability
- Default className inferred from relationship name (posts -> Post, blogAuthor -> BlogAuthor)
- Return this from relationship definition methods for potential chaining in init()

**Foreign Key Conventions**
- belongsTo: foreign key on current model's table, format {singular_relationship_name}_id
- hasMany/hasOne: foreign key on related model's table, format {singular_current_model_name}_id
- Infer current model name from component metadata (same pattern as tableName inference in ActiveRecord.cfc lines 47-58)
- Override via options: {foreignKey: "custom_column_id"}
- No automatic column creation - developers use Schema Builder migrations to create foreign key columns manually
- Follow explicit schema control pattern established in roadmap item #6

**Relationship Query Methods via onMissingMethod**
- Extend existing onMissingMethod in ActiveRecord.cfc (lines 220-280) to check variables.relationships
- When user calls user.posts() and method doesn't exist, check if "posts" exists in variables.relationships
- If relationship found, construct ModelBuilder with WHERE clause matching foreign key
- For belongsTo: WHERE {foreign_key} = this.attributes[foreign_key_value]
- For hasMany/hasOne: WHERE {foreign_key} = this.attributes[primary_key_value]
- Return ModelBuilder instance to enable query chaining before execution
- Fall through to existing getter/setter logic if not a relationship name

**ModelBuilder Integration**
- Reuse ModelBuilder instantiation pattern from createModelInstance() in ActiveRecord.cfc (lines 567-570)
- Construct WHERE clause using ModelBuilder.where() method (QueryBuilder.cfc lines 126-141)
- Foreign key WHERE conditions use simple equality: {user_id: 5}
- Return ModelBuilder configured with datasource and related model's table name
- Related model instance created via createObject with inferred or specified className

**Relationship Metadata Storage**
- Store at class level in variables.relationships struct (not per-instance)
- Structure: {relationshipName: {type: "hasMany"|"belongsTo"|"hasOne", foreignKey: "column_name", className: "ComponentName"}}
- Shared across all instances of model class like tableName and primaryKey
- Initialized during first init() call, reused by subsequent instances
- Accessed via onMissingMethod for all relationship query calls

**Return Value Consistency**
- All relationship methods (hasMany, belongsTo, hasOne) return ModelBuilder
- Developers choose terminal method: get() for arrays, first() for single instance, count() for scalar
- hasMany example: user.posts().get() returns array of Post instances
- hasOne example: user.profile().first() returns Profile instance or null
- belongsTo example: post.user().first() returns User instance or null
- Consistent with existing ActiveRecord query API (User::where().get() pattern)

**Options Struct Support**
- Accept optional second parameter: hasMany(name, {foreignKey, className})
- foreignKey option: override default foreign key column name
- className option: override inferred model component name
- Example: this.hasMany("articles", {foreignKey: "author_id", className: "BlogPost"})
- Example: this.belongsTo("author", {foreignKey: "created_by_id", className: "User"})
- Enables legacy schemas, self-referential associations, and non-standard naming

## Existing Code to Leverage

**ActiveRecord.cfc onMissingMethod (lines 220-280)**
- Extend existing getter/setter logic to check variables.relationships first
- Reuse pattern of checking structKeyExists before processing
- Maintain fallthrough to getter/setter if not relationship
- Follow existing error throwing pattern for unrecognized methods

**ActiveRecord.cfc metadata inference (lines 47-58)**
- Reuse component name extraction from getMetadata(this)
- Apply same lowercase + pluralization logic for foreign key inference
- Use listLast(metadata.name, ".") pattern for component name
- Maintain consistency with tableName inference

**ActiveRecord.cfc createModelInstance() (lines 567-570)**
- Reuse pattern for instantiating related model components
- Use createObject("component", className).init(datasource)
- Apply to relationship target models with inferred or explicit className
- Ensure datasource propagated to related model instances

**ModelBuilder.cfc where() method (lines 126-141)**
- Leverage existing WHERE clause construction for relationship queries
- Use struct-based conditions: {user_id: 5}
- Reuse prepared statement binding from QueryBuilder parent
- Follow established pattern for query building

**ActiveRecord.cfc variables storage pattern**
- Follow tableName (line 52) and primaryKey (line 65) class-level storage
- Initialize variables.relationships in same scope
- Ensure metadata persists across instances
- Maintain memory-efficient class-level approach

## Out of Scope
- Eager loading and N+1 query prevention (deferred to roadmap #8 - Smart Eager Loading)
- Static relationship queries like User::with("posts").get()
- Polymorphic associations (commentable relationships)
- Through associations (has_many :through for join tables)
- Dependent destroy/delete cascade options
- Counter cache columns (posts_count on User)
- inverse_of relationship declarations
- Relationship presence validation
- Many-to-many join table support (could add via through later)
- Automatic foreign key column creation or schema introspection
