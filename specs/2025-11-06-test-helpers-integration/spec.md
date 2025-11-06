# Specification: Test Helpers & Integration

## Goal
Provide comprehensive test helpers for Fuse framework including model factories, handler testing, database assertions, basic mocking, and integration test support. Enable fast, readable tests with automatic transaction rollback and zero-config factory discovery.

## User Stories
- As a developer, I want to create test data with `make()` and `create()` factory methods so that I can quickly set up test scenarios without manual model instantiation
- As a developer, I want to test handlers with simulated requests so that I can verify full request/response cycles without running a web server

## Specific Requirements

**Model Factory System**
- Factory definitions in `tests/factories/*.cfc` with `definition()` method returning default attributes struct
- Auto-discovery of factory files at test runtime via directory scan
- `make(factoryName, attributes, traits)` creates in-memory model instance without database persistence
- `create(factoryName, attributes, traits)` persists model instance using ActiveRecord `save()` method
- Attribute overrides passed as struct merge over factory defaults: `create("User", {email: "custom@test.com"})`
- Composable traits as separate methods in factory CFC returning attribute overrides, applied in array order
- Relationship support via nested factory calls within definitions
- Sequence support for auto-incrementing values (email_1@test.com, email_2@test.com)

**Database Assertion Methods**
- `assertDatabaseHas(table, attributes)` queries table and verifies at least one record matches all attributes in struct
- `assertDatabaseMissing(table, attributes)` queries table and verifies no records match all attributes in struct
- `assertDatabaseCount(table, count)` queries table and verifies exact record count
- Add methods to Assertions.cfc component and mixin to TestCase via delegation pattern
- Use QueryBuilder WHERE hash syntax for attribute matching queries
- Include table name and expected attributes in assertion failure messages for debugging

**Handler Testing Helpers**
- `makeRequest(method, path, params)` creates request struct simulating HTTP request with CGI scope
- `handle(request)` executes request through Router matching and handler invocation, returns response struct
- Response struct contains `statusCode`, `headers`, `body` properties for verification
- Support GET, POST, PUT, PATCH, DELETE methods via method parameter
- Request params populate appropriate scope (URL for GET, FORM for POST/PUT/PATCH/DELETE)
- Add helper methods to TestCase.cfc for test access
- Leverage existing Router.cfc route matching logic for handler resolution

**Lightweight Mock System**
- `mock(componentPath)` creates mock instance of component with method call tracking
- `stub(mockInstance, methodName, returnValue)` configures method to return static value without executing original
- `verify(mockInstance, methodName, times)` asserts method was called exact number of times
- Track method calls in mock instance variables with call count and argument history
- Method-level mocking only - no property mocking or complex partial mock features
- Throw descriptive error if verification fails showing expected vs actual call count
- Add mock helper methods to TestCase.cfc via delegation to MockBuilder component

**Integration Test Framework Loading**
- Integration tests extend `fuse.testing.IntegrationTestCase` which extends TestCase
- IntegrationTestCase loads full Framework.cfc stack in `setup()` before transaction begins
- Framework loading includes Router, DI Container, ModuleRegistry, EventService initialization
- Store framework instance in `variables.framework` for test access to services
- After framework load, transaction begins for test isolation (same rollback behavior as unit tests)
- Integration test location: `tests/integration/*.cfc`, unit test location: `tests/unit/*.cfc`
- TestRunner detects integration tests and uses extended lifecycle with framework initialization

**Factory Component Architecture**
- Base Factory.cfc component handles factory registration and instance creation
- Factory definitions extend Factory.cfc and implement `definition()` returning attribute struct
- Trait methods in factory definition named with trait name returning attribute struct
- Factory.cfc maintains registry of discovered factories keyed by factory name
- `make()` instantiates model, populates attributes, returns without calling `save()`
- `create()` instantiates model, populates attributes, calls ActiveRecord `save()`, returns persisted instance
- Sequence tracking in Factory.cfc static variables to maintain counter across factory calls

**Test Transaction Management**
- Extend existing TestRunner.cfc transaction wrapping to support integration test initialization
- Transaction lifecycle: initialize framework (integration only), begin transaction, setup(), test(), teardown(), rollback
- Use TestRunner's existing `beginTransaction()` and `rollbackTransaction()` methods unchanged
- Integration tests run in same transaction isolation as unit tests - only difference is framework loading timing
- Datasource resolution follows existing TestRunner pattern: init param, application scope, or default "fuse"

**Factory Auto-Discovery Process**
- On first factory usage, scan `tests/factories/` directory for `*.cfc` files
- Instantiate each factory CFC and register by filename without "Factory" suffix (UserFactory.cfc -> "User")
- Cache factory instances in Factory.cfc static registry for reuse across tests
- Support nested factory directories: `tests/factories/models/UserFactory.cfc` registers as "models.User"
- Throw descriptive error if factory not found listing available factory names

**Mock Implementation Details**
- MockBuilder.cfc creates proxy component with original component metadata
- Override each public method in proxy to intercept calls and track to variables.callHistory array
- Stubbed methods return configured value without calling original implementation
- Non-stubbed methods throw error indicating method not stubbed (fail-fast for test clarity)
- Verification compares expected call count to actual from callHistory array
- Support wildcard call count verification: `verify(mock, "save", {min: 1})` or `verify(mock, "delete", {max: 2})`

## Visual Design
No visual assets - API-level testing framework functionality.

## Existing Code to Leverage

**TestCase.cfc (fuse/testing/TestCase.cfc)**
- Extend with factory helper methods (`make()`, `create()`) via delegation to Factory component
- Extend with mock helper methods (`mock()`, `stub()`, `verify()`) via delegation to MockBuilder
- Follow existing `mixinAssertions()` pattern to mix in new database assertion methods
- Preserve existing `setup()` and `teardown()` lifecycle hooks for backward compatibility
- Reuse `init(datasource)` pattern for datasource passing to factories and database assertions

**TestRunner.cfc (fuse/testing/TestRunner.cfc)**
- Leverage existing transaction management (`beginTransaction()`, `rollbackTransaction()`) unchanged
- Extend `runTestMethod()` to detect IntegrationTestCase and load framework before transaction
- Reuse existing `resolveDatasource()` logic for consistent datasource resolution
- Maintain existing exception handling distinguishing AssertionFailedException from errors
- Preserve sequential test execution pattern without parallel execution complexity

**Assertions.cfc (fuse/testing/Assertions.cfc)**
- Add database assertion methods following existing assertion patterns
- Use existing `throwAssertionFailure()` private method for consistent error reporting
- Follow existing method signatures with optional `message` parameter for custom context
- Reuse existing `serializeValue()` helper for displaying query results in failures
- Maintain existing delegation pattern from TestCase to Assertions instance

**ActiveRecord.cfc (fuse/orm/ActiveRecord.cfc)**
- Use existing `save()` method for factory `create()` persistence without modification
- Leverage existing attribute assignment pattern for factory attribute population
- Reuse existing relationship methods (`hasMany`, `belongsTo`, `hasOne`) for factory relationship building
- Follow existing dirty tracking to ensure only changed attributes persist on factory save
- Utilize existing timestamp auto-population for `created_at` and `updated_at` on factory creates

**QueryBuilder.cfc (fuse/orm/QueryBuilder.cfc)**
- Use existing `where(attributes)` hash syntax for database assertion queries
- Leverage existing `get(tableName)` method for executing assertion queries
- Reuse existing prepared statement binding for safe attribute value comparison
- Follow existing query result structure for record count and attribute access
- Utilize existing datasource passing pattern for assertion query execution

## Out of Scope
- YAML fixtures (factories only, no static data files)
- Full spy/partial mock complexity (method-level mocking only)
- BDD syntax (`describe`/`it` blocks - simple test methods only)
- Browser/JavaScript testing (backend testing only)
- Parallel test execution (sequential execution only)
- Test coverage reporting (future enhancement)
- Snapshot testing (future enhancement)
- Time mocking/freezing (future enhancement)
- Database seeding beyond factories (factories handle all test data)
- Custom assertion DSL beyond provided methods (use standard assertions)
