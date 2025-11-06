# Task Breakdown: Test Helpers & Integration

## Overview
Total Tasks: 6 major task groups with 27 sub-tasks

## Task List

### Foundation Layer

#### Task Group 1: Factory System Core
**Dependencies:** None
**Complexity:** Medium

- [x] 1.0 Complete factory system foundation
  - [x] 1.1 Write 2-8 focused tests for Factory.cfc
    - Test factory registration and lookup
    - Test make() creates in-memory instance without persistence
    - Test create() persists instance via ActiveRecord save()
    - Test attribute override merging
    - Test sequence counter incrementation
  - [x] 1.2 Create Factory.cfc base component
    - Static registry for factory instances (variables.factoryRegistry)
    - Static sequence counters (variables.sequences)
    - registerFactory(name, instance) method
    - getFactory(name) method with descriptive error if not found
    - make(factoryName, attributes, traits) method
    - create(factoryName, attributes, traits) method
    - applyAttributes(model, attributes) helper
    - incrementSequence(key) helper
    - Reuse pattern: Similar to DI container registration in Framework.cfc
  - [x] 1.3 Implement factory auto-discovery
    - discoverFactories(baseDir) scans tests/factories/*.cfc
    - Support nested directories: tests/factories/models/UserFactory.cfc -> "models.User"
    - Strip "Factory" suffix from filename for factory name
    - Instantiate each factory CFC and register in static registry
    - Cache in static variables for reuse across tests
    - Call discovery on first factory usage (lazy initialization)
  - [x] 1.4 Add trait composition support
    - Traits passed as array: ["admin", "verified"]
    - Call trait methods on factory instance in array order
    - Each trait method returns attribute struct to merge
    - Apply trait overrides after definition() but before custom attributes
    - Merge order: definition() -> traits -> custom attributes
  - [x] 1.5 Implement relationship support
    - Allow nested factory calls in definition() method
    - Example: definition() returns {author_id: create("User").id}
    - Support make() and create() in relationships
    - Ensure related models persist before parent when using create()
  - [x] 1.6 Ensure factory tests pass
    - Run ONLY the 2-8 tests written in 1.1
    - Verify make() and create() work correctly
    - Verify trait composition and relationships
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- Factory.cfc implements registration, make(), create(), sequences
- Auto-discovery finds and registers factory definitions
- Trait composition applies multiple traits in order
- Relationship support allows nested factory calls
- The 2-8 tests written in 1.1 pass

---

#### Task Group 2: Database Assertion Methods
**Dependencies:** None (extends existing Assertions.cfc)
**Complexity:** Small

- [x] 2.0 Complete database assertion methods
  - [x] 2.1 Write 2-8 focused tests for database assertions
    - Test assertDatabaseHas() finds matching record
    - Test assertDatabaseMissing() verifies no match
    - Test assertDatabaseCount() verifies exact count
    - Test assertion failure messages include table and attributes
  - [x] 2.2 Add database methods to Assertions.cfc
    - assertDatabaseHas(table, attributes, message) method
    - assertDatabaseMissing(table, attributes, message) method
    - assertDatabaseCount(table, count, message) method
    - Use QueryBuilder where(attributes) for matching
    - Use existing throwAssertionFailure() for consistent errors
    - Include table name and attributes in failure messages
    - Reuse pattern: Follow existing assertion method signatures
  - [x] 2.3 Mix database assertions into TestCase.cfc
    - Add delegation methods in mixinAssertions()
    - Follow existing assertEqual/assertTrue delegation pattern
    - Expose to both variables and this scope
    - Pass datasource from TestCase to assertions
  - [x] 2.4 Ensure database assertion tests pass
    - Run ONLY the 2-8 tests written in 2.1
    - Verify database queries work correctly
    - Verify failure messages are descriptive
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- assertDatabaseHas/Missing/Count methods added to Assertions.cfc
- Methods use QueryBuilder for queries
- Failure messages include table and expected attributes
- Methods mixed into TestCase via delegation
- The 2-8 tests written in 2.1 pass

---

### Handler & Mock Layer

#### Task Group 3: Handler Testing Helpers
**Dependencies:** Task Group 2 (for database assertions in handler tests)
**Complexity:** Medium

- [x] 3.0 Complete handler testing helpers
  - [x] 3.1 Write 2-8 focused tests for handler helpers
    - Test makeRequest() creates request struct with CGI scope
    - Test handle() executes through router and returns response
    - Test GET/POST/PUT/PATCH/DELETE method support
    - Test params populate correct scope (URL vs FORM)
    - Test response struct contains statusCode, headers, body
  - [x] 3.2 Create RequestHelper.cfc component
    - makeRequest(method, path, params, headers) method
    - Simulate CGI scope with request_method, path_info, query_string
    - Populate URL scope for GET requests
    - Populate FORM scope for POST/PUT/PATCH/DELETE requests
    - Support optional headers struct
    - Return request struct matching Router expectations
  - [x] 3.3 Create ResponseHelper.cfc component
    - buildResponse(statusCode, headers, body) method
    - Normalize response format from handler execution
    - Extract status code from handler return or default 200
    - Extract headers from handler return or empty struct
    - Extract body from handler return
  - [x] 3.4 Add handler helpers to TestCase.cfc
    - Store RequestHelper and ResponseHelper instances
    - makeRequest(method, path, params) delegation method
    - handle(request) method executes via Router.match() and handler invoke
    - Leverage existing Router.cfc route matching
    - Pass application.fuse.router or create Router instance
    - Return response struct for assertion
  - [x] 3.5 Ensure handler helper tests pass
    - Run ONLY the 2-8 tests written in 3.1
    - Verify request simulation works
    - Verify handler execution and response format
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- makeRequest() creates valid request struct with CGI simulation
- handle() executes request through Router and handler
- Response struct contains statusCode, headers, body
- Supports GET/POST/PUT/PATCH/DELETE methods
- The 2-8 tests written in 3.1 pass

---

#### Task Group 4: Lightweight Mock System
**Dependencies:** None
**Complexity:** Medium

- [x] 4.0 Complete mock system
  - [x] 4.1 Write 2-8 focused tests for mocking
    - Test mock() creates mock instance with call tracking
    - Test stub() configures method to return static value
    - Test verify() asserts method called exact times
    - Test unstubbed methods throw descriptive error
    - Test verification failure shows expected vs actual
  - [x] 4.2 Create MockBuilder.cfc component
    - mock(componentPath) creates proxy component
    - Use getMetadata() to introspect component methods
    - Override public methods to intercept calls
    - Track calls in variables.callHistory array
    - Each entry: {method: "save", args: {...}, timestamp: ...}
    - Stubbed methods: variables.stubs[methodName] = returnValue
    - Non-stubbed methods: throw error "Method not stubbed"
  - [x] 4.3 Implement stub configuration
    - stub(mockInstance, methodName, returnValue) method
    - Store in mock's variables.stubs struct
    - Intercepted calls check stubs first
    - Return configured value without calling original
    - Support simple return values (no dynamic functions initially)
  - [x] 4.4 Implement call verification
    - verify(mockInstance, methodName, times) method
    - Count calls from variables.callHistory
    - Filter by methodName and compare to expected times
    - Support exact count: verify(mock, "save", 2)
    - Support min/max: verify(mock, "save", {min: 1, max: 3})
    - Throw descriptive error showing expected vs actual count
  - [x] 4.5 Add mock helpers to TestCase.cfc
    - Store MockBuilder instance in variables
    - mock(componentPath) delegation method
    - stub(mockInstance, methodName, returnValue) delegation
    - verify(mockInstance, methodName, times) delegation
    - Expose to variables and this scope
  - [x] 4.6 Ensure mock tests pass
    - Run ONLY the 2-8 tests written in 4.1
    - Verify stub and verify work correctly
    - Verify error messages are descriptive
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- mock() creates proxy with call tracking
- stub() configures method return values
- verify() asserts call counts with descriptive errors
- Unstubbed methods fail fast with clear error
- The 2-8 tests written in 4.1 pass

---

### Integration Layer

#### Task Group 5: Integration Test Framework
**Dependencies:** Task Groups 1-4 (uses all test helpers)
**Complexity:** Medium

- [x] 5.0 Complete integration test support
  - [x] 5.1 Write 2-8 focused tests for integration framework
    - Test IntegrationTestCase loads full framework
    - Test framework services accessible via variables.framework
    - Test transaction rollback works after framework load
    - Test integration tests run with same isolation as unit tests
  - [x] 5.2 Create IntegrationTestCase.cfc
    - Extend TestCase.cfc
    - Override setup() to load Framework.cfc before calling super.setup()
    - Initialize Router, DI Container, ModuleRegistry, EventService
    - Store framework instance in variables.framework
    - Make framework services accessible to tests
    - Reuse pattern: Follow Framework.cfc initialization in Application.cfc
  - [x] 5.3 Extend TestRunner for integration tests
    - Detect IntegrationTestCase vs TestCase via getMetadata()
    - Modify runTestMethod() lifecycle for integration tests:
      * Instantiate test class
      * If IntegrationTestCase: call initFramework() before transaction
      * Begin transaction
      * Call setup()
      * Call test method
      * Call teardown()
      * Rollback transaction
    - Preserve existing unit test lifecycle unchanged
    - Use same transaction management for both test types
  - [x] 5.4 Ensure integration test framework tests pass
    - Run ONLY the 2-8 tests written in 5.1
    - Verify framework loads correctly
    - Verify rollback works with framework
    - Do NOT run entire test suite at this stage

**Acceptance Criteria:**
- IntegrationTestCase loads full Framework.cfc stack
- Framework services accessible via variables.framework
- Transaction rollback works after framework initialization
- Both unit and integration tests use automatic rollback
- The 2-8 tests written in 5.1 pass

---

### Testing & Integration

#### Task Group 6: Test Coverage Review & Factory Definitions
**Dependencies:** Task Groups 1-5
**Complexity:** Small

- [x] 6.0 Review and fill critical test gaps
  - [x] 6.1 Review tests from Task Groups 1-5
    - Review 2-8 tests from factory system (Task 1.1)
    - Review 2-8 tests from database assertions (Task 2.1)
    - Review 2-8 tests from handler helpers (Task 3.1)
    - Review 2-8 tests from mock system (Task 4.1)
    - Review 2-8 tests from integration framework (Task 5.1)
    - Total existing: approximately 10-40 tests
  - [x] 6.2 Analyze critical workflow gaps
    - Identify missing end-to-end workflows for test helper features
    - Focus on integration points between components
    - Focus ONLY on this spec's test helper features
    - Do NOT assess entire framework test coverage
  - [x] 6.3 Write up to 10 additional tests maximum
    - Fill identified critical gaps only
    - Test factory + database assertions together
    - Test handler helpers + factory data creation
    - Test mock system with handler testing
    - Test integration test with all helpers combined
    - Do NOT write comprehensive coverage
  - [x] 6.4 Create example factory definitions
    - Create tests/factories/UserFactory.cfc example
    - Implement definition() method returning default attributes
    - Implement trait methods (admin, verified)
    - Document factory pattern for users
    - Create tests/factories/PostFactory.cfc with relationships
  - [x] 6.5 Run feature-specific tests only
    - Run ONLY tests for this spec's test helper features
    - Expected total: approximately 20-50 tests maximum
    - Verify all factory, assertion, handler, mock, integration tests pass
    - DO NOT run entire framework test suite

**Acceptance Criteria:**
- All feature-specific tests pass (approximately 20-50 tests)
- Critical workflow gaps filled with max 10 additional tests
- Example factory definitions document pattern
- Focus exclusively on test helper feature tests

---

## Execution Order

Recommended implementation sequence:

1. **Foundation Layer**
   - Task Group 1: Factory System Core (enables test data creation)
   - Task Group 2: Database Assertion Methods (enables database verification)

2. **Handler & Mock Layer**
   - Task Group 3: Handler Testing Helpers (enables request/response testing)
   - Task Group 4: Lightweight Mock System (enables component mocking)

3. **Integration Layer**
   - Task Group 5: Integration Test Framework (combines all helpers with full framework)

4. **Testing & Integration**
   - Task Group 6: Test Coverage Review & Factory Definitions (validates complete feature)

---

## Integration Points with Existing Code

**TestCase.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/TestCase.cfc`)
- Add factory helpers: make(), create() via delegation
- Add mock helpers: mock(), stub(), verify() via delegation
- Add handler helpers: makeRequest(), handle() via delegation
- Follow existing mixinAssertions() delegation pattern
- Store helper component instances in variables scope

**TestRunner.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/TestRunner.cfc`)
- Extend runTestMethod() to detect IntegrationTestCase
- Preserve existing transaction management unchanged
- Add framework initialization before transaction for integration tests
- Reuse existing beginTransaction()/rollbackTransaction() methods

**Assertions.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/Assertions.cfc`)
- Add assertDatabaseHas(table, attributes, message)
- Add assertDatabaseMissing(table, attributes, message)
- Add assertDatabaseCount(table, count, message)
- Use existing throwAssertionFailure() for errors
- Use existing serializeValue() for failure messages
- Follow existing assertion method patterns

**ActiveRecord.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/orm/ActiveRecord.cfc`)
- Use existing save() method for factory create() persistence
- Use existing attribute assignment for factory population
- Use existing relationship methods for factory relationships
- No modifications needed to ActiveRecord

**QueryBuilder.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/orm/QueryBuilder.cfc`)
- Use existing where(attributes) for database assertions
- Use existing get(tableName) for query execution
- Use existing prepared statement binding
- No modifications needed to QueryBuilder

**Router.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/Router.cfc`)
- Use existing route matching for handler helpers
- Leverage existing match(method, path) logic
- No modifications needed to Router

**Framework.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/Framework.cfc`)
- Reference initialization pattern for IntegrationTestCase
- Load Router, DI Container, ModuleRegistry, EventService
- No modifications needed to Framework

---

## Component Files to Create

### New Components

1. **Factory.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/Factory.cfc`)
   - Base factory component with registration and instance creation
   - Static registry and sequence tracking

2. **MockBuilder.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/MockBuilder.cfc`)
   - Mock instance creation with call tracking
   - Stub configuration and verification

3. **RequestHelper.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/RequestHelper.cfc`)
   - HTTP request simulation with CGI scope

4. **ResponseHelper.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/ResponseHelper.cfc`)
   - Response normalization from handler execution

5. **IntegrationTestCase.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/fuse/testing/IntegrationTestCase.cfc`)
   - Extended TestCase with framework initialization

### Example Factory Definitions

6. **UserFactory.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/tests/factories/UserFactory.cfc`)
   - Example factory with definition() and traits

7. **PostFactory.cfc** (`/Users/peter/Documents/Code/Active/frameworks/fuse/tests/factories/PostFactory.cfc`)
   - Example factory with relationships

---

## Notes

- **Focused testing approach**: Each task group writes 2-8 tests max during development, runs only those tests
- **Minimal test expansion**: Final test review adds max 10 tests to fill critical gaps
- **Zero external dependencies**: All components built-in, no external libraries
- **Lucee 7 features**: Use static variables for factory registry and sequences
- **Transaction isolation**: Both unit and integration tests use automatic rollback
- **Framework patterns**: Follow existing delegation, registration, and lifecycle patterns
- **Rails/Laravel influence**: Factory patterns from FactoryBot, database assertions from Laravel
- **Auto-discovery**: Factory definitions discovered automatically from tests/factories/
- **Lightweight mocking**: Method-level only, no complex spy/partial mock features
