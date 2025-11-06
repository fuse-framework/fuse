# Task Breakdown: ORM Relationships

## Overview
Total Tasks: 4 task groups
Feature: Add relationship definition methods (hasMany, belongsTo, hasOne) to ActiveRecord with foreign key conventions, metadata storage, and relationship query methods via onMissingMethod

## Task List

### Relationship Definition & Metadata Storage

#### Task Group 1: Relationship Definition Methods
**Dependencies:** ActiveRecord Base & CRUD (roadmap #5, completed)

- [x] 1.0 Complete relationship definition & metadata storage
  - [x] 1.1 Write 2-8 focused tests for relationship definition
    - Test hasMany() stores metadata correctly in variables.relationships
    - Test belongsTo() stores metadata with correct foreign key inference
    - Test hasOne() stores metadata correctly
    - Test relationship definition with options struct (foreignKey, className override)
    - Test metadata persists across multiple instances of same model class
    - Skip exhaustive edge case testing
  - [x] 1.2 Initialize variables.relationships in ActiveRecord.cfc init()
    - Add after line 68 (after primaryKey detection)
    - Initialize as empty struct: variables.relationships = {}
    - Ensure class-level storage following tableName pattern (line 52)
    - Structure: {relationshipName: {type, foreignKey, className}}
  - [x] 1.3 Implement hasMany() relationship definition method
    - Accept name (string) and optional options struct {foreignKey, className}
    - Infer className from relationship name (posts -> Post, blogAuthors -> BlogAuthor)
    - Infer foreignKey from current model name using tableName inference pattern (lines 47-58)
    - Format: {singular_current_model_name}_id (User -> user_id)
    - Store in variables.relationships[name] = {type: "hasMany", foreignKey, className}
    - Return this for chaining
  - [x] 1.4 Implement belongsTo() relationship definition method
    - Accept name (string) and optional options struct {foreignKey, className}
    - Infer className from relationship name (user -> User)
    - Infer foreignKey from relationship name: {singular_name}_id (user -> user_id)
    - Store in variables.relationships[name] = {type: "belongsTo", foreignKey, className}
    - Return this for chaining
  - [x] 1.5 Implement hasOne() relationship definition method
    - Accept name (string) and optional options struct {foreignKey, className}
    - Infer className from relationship name (profile -> Profile)
    - Infer foreignKey from current model name (same logic as hasMany)
    - Format: {singular_current_model_name}_id
    - Store in variables.relationships[name] = {type: "hasOne", foreignKey, className}
    - Return this for chaining
  - [x] 1.6 Ensure relationship definition tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify metadata storage structure is correct
    - Verify foreign key inference works for all relationship types
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 1.1 pass
- hasMany(), belongsTo(), hasOne() methods store metadata correctly
- Foreign key inference follows conventions for all types
- Options struct overrides work for foreignKey and className
- Metadata persists across instances at class level

**Reference:**
- Spec sections: Relationship Definition Methods, Foreign Key Conventions, Relationship Metadata Storage, Options Struct Support
- ActiveRecord metadata pattern: lines 47-68 (tableName, primaryKey inference)
- Component name extraction: lines 48-49

---

### Relationship Query Methods via onMissingMethod

#### Task Group 2: Dynamic Relationship Query Resolution
**Dependencies:** Task Group 1

- [x] 2.0 Complete relationship query method resolution
  - [x] 2.1 Write 2-8 focused tests for relationship queries
    - Test user.posts() returns ModelBuilder instance
    - Test belongsTo query constructs correct WHERE clause (post.user())
    - Test hasMany query constructs correct WHERE clause (user.posts())
    - Test hasOne query constructs correct WHERE clause (user.profile())
    - Test relationship query chaining: user.posts().where({published: true}).get()
    - Test onMissingMethod falls through to getter/setter if not relationship
    - Skip exhaustive testing of all query combinations
  - [x] 2.2 Extend onMissingMethod to check variables.relationships
    - Insert check at start of onMissingMethod (before line 224 getter detection)
    - Check if structKeyExists(variables.relationships, missingMethodName)
    - If found, call new buildRelationshipQuery(missingMethodName) helper
    - Return ModelBuilder from buildRelationshipQuery()
    - Maintain fallthrough to existing getter/setter logic if not relationship
  - [x] 2.3 Implement buildRelationshipQuery() private helper method
    - Accept relationshipName parameter
    - Retrieve relationship metadata from variables.relationships[relationshipName]
    - Extract type, foreignKey, className from metadata
    - Create related model instance using createObject("component", className).init(datasource)
    - Pattern: reuse createModelInstance() approach (lines 567-570)
  - [x] 2.4 Construct WHERE clause based on relationship type
    - belongsTo: WHERE {foreignKey} = this.attributes[foreignKey]
    - Example: post.user() -> WHERE user_id = post.attributes["user_id"]
    - hasMany: WHERE {foreignKey} = this.attributes[primaryKey]
    - Example: user.posts() -> WHERE user_id = user.attributes["id"]
    - hasOne: WHERE {foreignKey} = this.attributes[primaryKey]
    - Example: user.profile() -> WHERE user_id = user.attributes["id"]
  - [x] 2.5 Return ModelBuilder with WHERE clause applied
    - Call relatedInstance.where({foreignKey: attributeValue})
    - Pattern: use ModelBuilder.where() from QueryBuilder.cfc (lines 126-141)
    - Return ModelBuilder instance to enable chaining
    - Ensure datasource propagated to related model
  - [x] 2.6 Ensure relationship query tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify ModelBuilder instances returned with correct WHERE clauses
    - Verify query chaining works before execution
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 2.1 pass
- onMissingMethod detects relationship calls and constructs ModelBuilder
- WHERE clauses correctly match foreign key values for all relationship types
- ModelBuilder enables chaining: user.posts().where().orderBy().get()
- Existing getter/setter behavior preserved when not a relationship

**Reference:**
- Spec sections: Relationship Query Methods via onMissingMethod, ModelBuilder Integration, Return Value Consistency
- ActiveRecord.cfc onMissingMethod: lines 220-280
- createModelInstance() pattern: lines 567-570
- ModelBuilder.where() method: QueryBuilder.cfc lines 126-141

---

### Query Execution & Integration Testing

#### Task Group 3: Terminal Methods & Query Integration
**Dependencies:** Task Group 2

- [x] 3.0 Complete query execution and integration
  - [x] 3.1 Write 2-8 focused tests for terminal method execution
    - Test hasMany terminal: user.posts().get() returns array of Post instances
    - Test hasOne terminal: user.profile().first() returns Profile instance or null
    - Test belongsTo terminal: post.user().first() returns User instance or null
    - Test relationship query with chaining: user.posts().where({published: true}).get()
    - Test relationship query with orderBy: user.posts().orderBy("created_at DESC").get()
    - Test relationship count: user.posts().count() returns integer
    - Skip testing complex multi-table scenarios
  - [x] 3.2 Verify ModelBuilder integration for terminal methods
    - Confirm get() returns array of model instances (ActiveRecord.cfc lines 159-172)
    - Confirm first() returns single instance or null (ActiveRecord.cfc lines 179-192)
    - Confirm count() returns integer (inherited from QueryBuilder)
    - No code changes required - verify existing methods work with relationship queries
  - [x] 3.3 Test query chaining before execution
    - Verify where() chaining: user.posts().where({status: "published"})
    - Verify orderBy() chaining: user.posts().orderBy("created_at DESC")
    - Verify limit() chaining: user.posts().limit(10)
    - Verify offset() chaining: user.posts().offset(5)
    - Confirm ModelBuilder methods available on relationship queries
  - [x] 3.4 Test cross-relationship scenarios
    - Create test models: User hasMany Post, Post belongsTo User
    - Test bidirectional access: user.posts() and post.user()
    - Verify foreign key values match across relationships
    - Ensure datasource propagated correctly to related models
  - [x] 3.5 Ensure query integration tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify terminal methods work correctly with relationship queries
    - Verify chaining works before execution
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- The 2-8 tests written in 3.1 pass
- Terminal methods (get/first/count) work with relationship queries
- Query chaining (where/orderBy/limit) works before execution
- Bidirectional relationships function correctly
- Return types match spec: get() returns arrays, first() returns instance or null

**Reference:**
- Spec sections: Return Value Consistency, ModelBuilder Integration
- ActiveRecord.cfc get() override: lines 159-172
- ActiveRecord.cfc first() override: lines 179-192
- ModelBuilder chaining methods: inherited from QueryBuilder

---

### Test Review & Documentation

#### Task Group 4: Test Coverage Review & Gap Analysis
**Dependencies:** Task Groups 1-3

- [x] 4.0 Review existing tests and fill critical gaps only
  - [x] 4.1 Review tests from Task Groups 1-3
    - Review the 2-8 tests from metadata storage (Task 1.1)
    - Review the 2-8 tests from query resolution (Task 2.1)
    - Review the 2-8 tests from terminal methods (Task 3.1)
    - Total existing tests: approximately 6-24 tests
  - [x] 4.2 Analyze test coverage gaps for ORM relationships only
    - Identify critical workflows lacking coverage (e.g., options struct edge cases)
    - Focus ONLY on gaps related to relationship feature requirements
    - Do NOT assess entire ActiveRecord or ModelBuilder test coverage
    - Prioritize integration workflows over isolated unit tests
  - [x] 4.3 Write up to 10 additional strategic tests maximum
    - Test complete user workflow: define relationship -> query -> execute
    - Test error handling: invalid relationship name, missing foreign key value
    - Test options struct: custom foreignKey with legacy schema
    - Test options struct: custom className for non-standard models
    - Test metadata persistence: multiple instances share class-level relationships
    - Test relationship with null foreign key values
    - Do NOT write comprehensive edge case coverage
    - Skip performance tests, security tests unless business-critical
  - [x] 4.4 Add inline code documentation
    - Document hasMany(), belongsTo(), hasOne() method signatures
    - Document buildRelationshipQuery() private helper
    - Document variables.relationships structure in init()
    - Follow existing ActiveRecord.cfc documentation style
    - Keep comments concise and focused on "why" not "what"
  - [x] 4.5 Run feature-specific tests only
    - Run ONLY tests related to ORM relationships (tests from 1.1, 2.1, 3.1, and 4.3)
    - Expected total: approximately 16-34 tests maximum
    - Do NOT run entire Fuse framework test suite
    - Verify all relationship workflows pass

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 16-34 tests total)
- Critical relationship workflows covered end-to-end
- No more than 10 additional tests added when filling gaps
- Code documentation added for new public methods
- Testing focused exclusively on ORM relationships feature

**Reference:**
- Spec sections: All sections (comprehensive feature coverage)
- ActiveRecord documentation style: lines 1-37
- Test writing standards: agent-os/standards/testing/test-writing.md

---

## Execution Order

Recommended implementation sequence:
1. **Relationship Definition & Metadata Storage** (Task Group 1) - Foundation for storing relationship configuration
2. **Relationship Query Methods via onMissingMethod** (Task Group 2) - Enable user.posts() syntax with ModelBuilder return
3. **Query Execution & Integration Testing** (Task Group 3) - Verify terminal methods and chaining work correctly
4. **Test Review & Documentation** (Task Group 4) - Fill critical gaps and document new API

## Implementation Notes

**Dependency Chain:**
- Task Group 1 establishes metadata storage required by Task Group 2
- Task Group 2 creates query resolution required by Task Group 3
- Task Group 3 validates integration before Task Group 4 gap analysis

**Key Design Patterns:**
- Follow existing metadata storage pattern (tableName, primaryKey)
- Reuse createModelInstance() pattern for related model instantiation
- Extend onMissingMethod without breaking existing getter/setter logic
- Leverage ModelBuilder chaining for relationship queries

**Testing Strategy:**
- Each task group writes 2-8 focused tests first
- Tests verify critical behavior only, not exhaustive coverage
- Final task group adds maximum 10 strategic tests for gaps
- Total expected tests: 16-34 tests for entire feature

**Foreign Key Schema:**
- Relationships define foreign key logic only
- Developers create foreign key columns via Schema Builder migrations
- No automatic schema introspection or column creation
- Follows explicit schema control from roadmap #6

**Out of Scope:**
- Eager loading (deferred to roadmap #8 - Smart Eager Loading)
- Polymorphic associations
- Through associations (has_many :through)
- Dependent destroy/delete cascades
- Counter caches
- Static relationship queries like User::with("posts").get()
