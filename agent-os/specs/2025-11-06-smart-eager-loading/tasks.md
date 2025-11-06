# Task Breakdown: Smart Eager Loading

## Overview
Total Tasks: 31 subtasks across 4 task groups

## Task List

### ORM Core Layer

#### Task Group 1: Core Eager Loading Infrastructure
**Dependencies:** None (builds on existing relationship system)

- [x] 1.0 Complete eager loading core infrastructure
  - [x] 1.1 Write 2-8 focused tests for EagerLoader strategy selection
    - Test belongsTo/hasOne -> JOIN strategy selection
    - Test hasMany -> separate query strategy selection
    - Test nested relationship parsing (dot notation)
    - Test invalid relationship name detection
    - Skip exhaustive edge cases
  - [x] 1.2 Create EagerLoader.cfc component
    - Location: `fuse/orm/EagerLoader.cfc`
    - Method: `load(modelInstance, eagerLoadConfig)` - orchestrates loading
    - Method: `selectStrategy(relationshipName, relationshipMetadata)` - returns "join" or "separate"
    - Method: `parseRelationshipPath(dotNotation)` - converts "posts.comments" to hierarchy
    - Method: `validateRelationship(modelClass, relationshipName)` - fail fast on invalid names
    - Use existing `variables.relationships` from ActiveRecord for metadata
  - [x] 1.3 Add loadedRelationships tracking to ActiveRecord
    - Initialize `variables.loadedRelationships = {}` in init()
    - Structure: `loadedRelationships["posts"] = [array]` or `loadedRelationships["profile"] = instance`
    - Add `isRelationshipLoaded(relationshipName)` method to ActiveRecord
    - Returns boolean checking `structKeyExists(variables.loadedRelationships, relationshipName)`
  - [x] 1.4 Implement strategy selection logic in EagerLoader
    - belongsTo -> return "join"
    - hasOne -> return "join"
    - hasMany -> return "separate"
    - Read relationship type from metadata struct
  - [x] 1.5 Implement relationship path parsing
    - Parse "posts.comments.author" into hierarchical array
    - Validate each level against model's relationships struct
    - Throw `ActiveRecord.InvalidRelationship` on invalid path with detail message
  - [x] 1.6 Ensure eager loading core tests pass
    - Run ONLY the 2-8 tests from 1.1
    - Verify strategy selection logic works
    - Do NOT run entire test suite

**Acceptance Criteria:**
- EagerLoader component created with strategy selection logic
- belongsTo/hasOne select JOIN strategy, hasMany selects separate query
- Nested dot notation parsed into hierarchy
- Invalid relationships throw immediate errors
- Tests from 1.1 pass

### Query Builder Integration

#### Task Group 2: ModelBuilder API & Query Execution
**Dependencies:** Task Group 1

- [x] 2.0 Complete ModelBuilder API integration
  - [x] 2.1 Write 2-8 focused tests for includes/joins/preload APIs
    - Test includes() chainability with where/orderBy/limit
    - Test joins() forcing JOIN strategy
    - Test preload() forcing separate query strategy
    - Test array and string syntax variants
    - Skip exhaustive method combination testing
  - [x] 2.2 Add eagerLoad state tracking to ModelBuilder
    - Initialize `variables.eagerLoad = []` in init()
    - Structure: `[{name: "posts", strategy: "auto/join/separate", nested: []}]`
    - Track manually overridden strategies vs auto-selected
  - [x] 2.3 Implement includes() method in ModelBuilder
    - Accept string: `includes("posts")` or array: `includes(["posts", "profile"])`
    - Parse dot notation via EagerLoader.parseRelationshipPath()
    - Validate relationships immediately via EagerLoader.validateRelationship()
    - Store in eagerLoad array with strategy: "auto"
    - Return this for chaining
  - [x] 2.4 Implement joins() method in ModelBuilder
    - Same signature as includes()
    - Store in eagerLoad with strategy: "join" (override auto-selection)
    - Return this for chaining
  - [x] 2.5 Implement preload() method in ModelBuilder
    - Same signature as includes()
    - Store in eagerLoad with strategy: "separate" (override auto-selection)
    - Return this for chaining
  - [x] 2.6 Ensure ModelBuilder API tests pass
    - Run ONLY the 2-8 tests from 2.1
    - Verify methods chain correctly
    - Verify eagerLoad state populated correctly
    - Do NOT run entire test suite

**Acceptance Criteria:**
- includes(), joins(), preload() methods added to ModelBuilder
- All three accept string, array, and dot notation
- Methods validate relationships immediately (fail fast)
- eagerLoad state tracks requested relationships and strategies
- Methods chain with existing query methods
- Tests from 2.1 pass

### Loading Strategy Implementation

#### Task Group 3: JOIN & Separate Query Strategies
**Dependencies:** Task Group 2

- [x] 3.0 Complete loading strategy implementations
  - [x] 3.1 Write 2-8 focused tests for loading strategies
    - Test JOIN strategy with belongsTo relationship
    - Test JOIN strategy with hasOne relationship
    - Test separate query strategy with hasMany relationship
    - Test result hydration populates loadedRelationships
    - Skip exhaustive relationship type combinations
  - [x] 3.2 Create JoinStrategy.cfc component
    - Location: `fuse/orm/strategies/JoinStrategy.cfc`
    - Method: `execute(queryBuilder, relationshipConfig, results)` - builds JOIN and executes
    - Use existing QueryBuilder.leftJoin() method
    - Build join condition: `foreign_table.id = primary_table.foreign_key_id`
    - Handle column name prefixing to avoid collisions
    - Return hydrated results with relationship data
  - [x] 3.3 Create SeparateQueryStrategy.cfc component
    - Location: `fuse/orm/strategies/SeparateQueryStrategy.cfc`
    - Method: `execute(queryBuilder, relationshipConfig, results)` - executes separate query
    - Collect foreign key values from results array
    - Build WHERE IN query: `WHERE foreign_key IN (1,2,3...)`
    - Execute query for related records
    - Map results back to parent records by foreign key
  - [x] 3.4 Implement result hydration in EagerLoader
    - Method: `hydrateRelationships(results, relationshipData, relationshipName)`
    - For hasMany: populate array of model instances
    - For belongsTo/hasOne: populate single model instance or null
    - Use ActiveRecord.createModelInstance() pattern
    - Store in `loadedRelationships[relationshipName]`
  - [x] 3.5 Integrate strategies into EagerLoader.load()
    - Determine strategy (auto-select or manual override)
    - Instantiate JoinStrategy or SeparateQueryStrategy
    - Call strategy.execute() with appropriate config
    - Hydrate results with relationship data
  - [x] 3.6 Override get() in ActiveRecord to trigger eager loading
    - Check if `variables.eagerLoad` is populated
    - If yes: execute query, pass results to EagerLoader.load()
    - If no: execute query normally (existing behavior)
    - Return array of model instances with loadedRelationships populated
  - [x] 3.7 Override first() in ActiveRecord to trigger eager loading
    - Same logic as get() override but for single result
    - Ensure loadedRelationships populated on single instance
  - [x] 3.8 Ensure loading strategy tests pass
    - Run ONLY the 2-8 tests from 3.1
    - Verify JOIN strategy executes correctly
    - Verify separate query strategy executes correctly
    - Verify loadedRelationships populated
    - Do NOT run entire test suite

**Acceptance Criteria:**
- JoinStrategy builds LEFT JOIN queries using existing QueryBuilder methods
- SeparateQueryStrategy executes WHERE IN queries for batched loading
- EagerLoader.load() orchestrates strategy execution and hydration
- get() and first() in ActiveRecord trigger eager loading when eagerLoad populated
- loadedRelationships struct populated with relationship data
- Tests from 3.1 pass

### Integration & Advanced Features

#### Task Group 4: Nested Loading, N+1 Detection & Lazy Load Integration
**Dependencies:** Task Group 3

- [x] 4.0 Complete integration and advanced features
  - [x] 4.1 Write 2-8 focused tests for nested loading and N+1 detection
    - Test nested eager loading: includes(["posts.comments"])
    - Test arbitrary depth: includes(["posts.comments.author"])
    - Test N+1 warning logged when relationship accessed without eager loading
    - Test isRelationshipLoaded() introspection
    - Skip exhaustive nesting combinations
  - [x] 4.2 Implement nested eager loading in EagerLoader
    - Method: `loadNested(results, nestedConfig)` - recursive loading
    - First level: load "posts" for all users
    - Second level: collect all post IDs, load "comments" WHERE post_id IN (...)
    - Third level: repeat pattern for next level
    - Each level uses own strategy selection logic
    - Avoid nested loops by batching IDs at each level
  - [x] 4.3 Modify buildRelationshipQuery() in ActiveRecord
    - Check `structKeyExists(variables.loadedRelationships, relationshipName)` first
    - If loaded: return cached value immediately (no query)
    - If not loaded: execute lazy query (existing behavior)
    - Add N+1 detection hook (call detectN1())
  - [x] 4.4 Create N1Detector.cfc component
    - Location: `fuse/orm/N1Detector.cfc`
    - Method: `detect(modelClass, relationshipName, context)` - logs warning
    - Check environment config for dev mode
    - If dev: log "N+1 Query Detected: Accessed relationship 'X' on Y without eager loading. Consider using includes(['X'])"
    - If prod: silent (no logging)
  - [x] 4.5 Integrate N1Detector into buildRelationshipQuery()
    - Call N1Detector.detect() when relationship not in loadedRelationships
    - Pass model class name and relationship name
    - Only log in development environment
  - [x] 4.6 Add integration tests for full workflow
    - Test: User::includes(["posts"]).get() - verify single query for hasMany via separate strategy
    - Test: User::includes(["profile"]).get() - verify JOIN for hasOne
    - Test: Post::includes(["user"]).get() - verify JOIN for belongsTo
    - Test: User::includes(["posts.comments"]).get() - verify nested loading with correct query count
    - Test: Access user.posts() without includes - verify N+1 warning logged
    - Test: Access user.posts() after includes - verify no warning, uses cache
  - [x] 4.7 Ensure integration tests pass
    - Run ONLY the 2-8 tests from 4.1 plus integration tests from 4.6
    - Verify full workflow works end-to-end
    - Verify N+1 detection triggers appropriately
    - Do NOT run entire test suite

**Acceptance Criteria:**
- Nested eager loading works with arbitrary depth using dot notation
- Each nesting level uses appropriate strategy (JOIN vs separate)
- buildRelationshipQuery() checks loadedRelationships cache before querying
- N+1 warnings logged in dev mode when relationships accessed without eager loading
- isRelationshipLoaded() returns correct boolean
- Integration tests demonstrate full feature working
- Tests from 4.1 and 4.6 pass

### Test Review & Documentation

#### Task Group 5: Test Gap Analysis & Final Verification
**Dependencies:** Task Groups 1-4

- [x] 5.0 Review existing tests and fill critical gaps only
  - [x] 5.1 Review tests from Task Groups 1-4
    - Review 2-8 tests from orm-engineer (Task 1.1)
    - Review 2-8 tests from query-builder-engineer (Task 2.1)
    - Review 2-8 tests from strategy-engineer (Task 3.1)
    - Review 2-8 tests from integration-engineer (Task 4.1)
    - Total existing: approximately 8-32 tests
  - [x] 5.2 Analyze test coverage gaps for smart eager loading only
    - Identify missing critical user workflows
    - Focus ONLY on gaps related to eager loading feature
    - Prioritize end-to-end workflows over unit test gaps
    - Do NOT assess entire ORM test coverage
  - [x] 5.3 Write up to 10 additional strategic tests maximum
    - Add maximum 10 tests to fill identified critical gaps
    - Focus on integration points between strategies and ModelBuilder
    - Test error scenarios (invalid relationships, missing foreign keys)
    - Test edge cases only if business-critical (e.g., empty result sets)
    - Skip performance tests, stress tests, and non-critical edge cases
  - [x] 5.4 Run feature-specific tests only
    - Run ONLY tests related to smart eager loading (tests from 1.1, 2.1, 3.1, 4.1, 5.3)
    - Expected total: approximately 18-42 tests maximum
    - Do NOT run entire framework test suite
    - Verify all critical workflows pass
  - [x] 5.5 Add code documentation
    - Document public API methods (includes, joins, preload) with usage examples
    - Document EagerLoader component with strategy selection explanation
    - Document isRelationshipLoaded() usage for debugging
    - Follow existing ActiveRecord documentation style

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 18-42 tests total)
- Critical eager loading workflows covered by tests
- No more than 10 additional tests added when filling gaps
- Testing focused exclusively on smart eager loading feature
- Public API methods documented with clear examples

## Execution Order

Recommended implementation sequence:
1. ORM Core Layer (Task Group 1) - EagerLoader foundation, strategy selection logic
2. Query Builder Integration (Task Group 2) - includes/joins/preload API methods
3. Loading Strategy Implementation (Task Group 3) - JOIN and separate query execution
4. Integration & Advanced Features (Task Group 4) - Nested loading, N+1 detection, lazy load integration
5. Test Review & Documentation (Task Group 5) - Gap analysis, final verification, documentation

## Key Integration Points

**Existing Components to Extend:**
- `ModelBuilder.cfc` - Add includes(), joins(), preload() methods
- `ActiveRecord.cfc` - Override get()/first(), modify buildRelationshipQuery(), add loadedRelationships tracking
- `QueryBuilder.cfc` - Reuse existing leftJoin() for JOIN strategy

**New Components to Create:**
- `fuse/orm/EagerLoader.cfc` - Strategy selection and orchestration
- `fuse/orm/strategies/JoinStrategy.cfc` - JOIN-based loading
- `fuse/orm/strategies/SeparateQueryStrategy.cfc` - Separate query loading
- `fuse/orm/N1Detector.cfc` - N+1 detection logging

**Reusable Patterns:**
- Relationship metadata from `variables.relationships`
- Model instance hydration via `createModelInstance()`
- Foreign key inference via `inferClassNameFromRelationship()` and `singularizeTableName()`
- Fluent interface pattern (return `this` for chaining)

## Testing Strategy

**Test Distribution:**
- Task Group 1: 2-8 tests (strategy selection, parsing, validation)
- Task Group 2: 2-8 tests (API methods, chaining, state management)
- Task Group 3: 2-8 tests (JOIN strategy, separate query strategy, hydration)
- Task Group 4: 2-8 tests (nested loading, N+1 detection, integration workflows)
- Task Group 5: Up to 10 additional tests (gap filling only)
- **Total: Approximately 18-42 tests maximum**

**Test Focus:**
- Strategy selection correctness
- API method chaining and validation
- Query execution and result hydration
- Nested loading with correct query count
- N+1 detection triggering
- End-to-end user workflows

**Out of Scope for Testing:**
- Performance benchmarking
- Stress tests with large datasets
- All possible relationship type combinations
- Exhaustive edge case coverage
- Polymorphic relationships (not in spec)
- Through relationships (not in spec)
