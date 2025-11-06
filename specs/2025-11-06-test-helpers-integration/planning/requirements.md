# Spec Requirements: Test Helpers & Integration

## Initial Description
Test helpers and integration utilities for the Fuse framework.

## Requirements Discussion

### Context from Roadmap
This spec implements **roadmap item #11**: "Test Helpers & Integration — Model factories (make/create methods), handler testing helpers for request/response simulation, integration test support, test database setup/teardown automation `S`"

**Prerequisite:** Roadmap item #10 (Test Framework Foundation) is complete, providing TestCase base class, test runner, Assertions component, test reporting, and database transaction rollback.

### Final Recommendations

User provided comprehensive recommendations addressing all outstanding design decisions for test helpers and integration testing.

#### **1. Model Factories: make() vs create()**

**Decision:** Implement both `make()` and `create()` with full attribute overrides and relationship support.

- `make()`: Creates in-memory model instance without persisting to database
- `create()`: Persists model instance to database
- Both support attribute overrides: `make("User", {email: "custom@example.com"})`
- Both support relationship building
- Pattern follows Rails FactoryBot and Laravel factories

**Rationale:** This is the standard in Rails FactoryBot and Laravel. Provides maximum flexibility - use `make()` for fast unit tests that don't need persistence, `create()` when you need database records or foreign keys.

#### **2. Handler Testing with Database Assertions**

**Decision:** YES - Include `assertDatabaseHas()` in handler tests.

**Rationale:** Common to verify handler actions persisted data correctly. Combines Rails controller testing patterns with Laravel's database assertions for complete verification of handler behavior.

**Example usage:**
```cfml
request = makeRequest("POST", "/users", {name: "John", email: "john@example.com"})
response = handle(request)
assertDatabaseHas("users", {email: "john@example.com"})
```

#### **3. Integration Test Rollback**

**Decision:** YES - Both integration and unit tests should auto-rollback.

**Key distinction:**
- **Integration tests:** Load full framework stack (routing, DI, modules, etc.), then run in transaction with auto-rollback
- **Unit tests:** Skip framework initialization, run in transaction with auto-rollback
- Both test types use automatic transaction rollback for database isolation
- Only difference: integration tests have full framework loaded before transaction starts

**Rationale:** Integration tests need clean state between tests just like unit tests. Transaction rollback is the mechanism for isolation, not the definition of test type.

#### **4. Fixtures vs Factories**

**Decision:** Factories only - Skip Rails fixtures entirely.

**Rationale:**
- Fixtures are static YAML files, harder to maintain than code-based factories
- Laravel and modern Rails both prefer factories
- Factories are more flexible and easier to customize per test
- No need to support legacy fixture pattern

#### **5. Composable Traits**

**Decision:** YES - Traits must be composable.

**Example:** `create("User", ["admin", "verified"])` applies both trait sets.

**Rationale:** This is how FactoryBot works and it's essential for complex test scenarios without duplication. A user might need an admin who is verified, or a regular user who is verified, without defining separate factory definitions for each combination.

#### **6. Built-in Mocking**

**Decision:** Build lightweight mock system - manual stubbing too tedious.

**Features to provide:**
- `mock(component)`: Create mock instance
- `stub(method, returnValue)`: Stub method to return value
- `verify(method, times)`: Verify method was called N times

**Keep it simple:**
- Method-level mocking only
- No full spy/partial mock complexity
- Aim for 80% of use cases with 20% of complexity

**Rationale:** Manual stubbing is too tedious for practical testing. Provide lightweight system for common cases.

#### **7. Rollback for Both Test Types**

**Decision:** Both unit and integration tests use automatic rollback.

**Implementation:**
- Every test runs in database transaction
- Auto-rollback at end of each test
- Ensures test isolation and speed
- Only difference between test types: integration tests have full framework stack loaded before transaction starts

**Rationale:** Transaction rollback is the isolation mechanism, not the test type definition.

#### **8. Patterns to Avoid and Follow**

**Avoid from TestBox:**
- Verbose BDD-style (`describe/it` with string names) - prefer simple test methods
- Complex DSL syntax - keep it straightforward

**Avoid from ColdBox:**
- Over-engineered module testing - keep simple
- Complex mock framework - lightweight approach better

**Avoid from Wheels:**
- Limited factory support - build robust factories
- Manual cleanup - auto-rollback everything

**Follow from Rails:**
- FactoryBot patterns: `make()`, `create()`, traits, associations
- RSpec simplicity: clear test methods, readable assertions
- Automatic transaction rollback for all tests

**Follow from Laravel:**
- Clean database assertions: `assertDatabaseHas()`, `assertDatabaseMissing()`
- Minimal test boilerplate
- Fluent, chainable test helpers

### Architecture Recommendations

#### **Test Helper Structure**

Extend existing test framework with new components:

```
fuse/testing/
  TestCase.cfc (existing - base class)
  TestRunner.cfc (existing - runner)
  Assertions.cfc (existing - assertions)
  Factory.cfc (NEW - factory system)
  MockBuilder.cfc (NEW - mocking)
  DatabaseHelpers.cfc (NEW - DB assertions)
  RequestHelpers.cfc (NEW - handler testing)
```

#### **Integration Points**

- Extend TestCase.cfc with new helper methods
- Hook into TestRunner.cfc transaction system (already exists)
- Use existing ORM Model methods for persistence
- Leverage existing Router for request simulation

#### **Key Features to Deliver**

1. **Zero-config factories** - Define in `tests/factories/*.cfc`, auto-discovered by framework
2. **Automatic rollback** - No cleanup code needed in tests
3. **Fluent API** - Chainable, readable test code
4. **Fast execution** - Transactions keep tests fast, minimal overhead
5. **Clear failures** - Show expected vs actual with context

## Existing Code to Reference

User did not provide specific similar features to reference. This is new testing functionality building on the Test Framework Foundation (roadmap #10).

**Related existing code:**
- `fuse/testing/TestCase.cfc` - Base test class to extend with factory/mock helpers
- `fuse/testing/TestRunner.cfc` - Runner that already handles transaction rollback
- `fuse/testing/Assertions.cfc` - Assertion library to extend with database assertions
- `fuse/orm/Model.cfc` - ActiveRecord base class used by factories for persistence

## Visual Assets

No visual assets provided. Testing framework is API-level functionality without UI components.

## Requirements Summary

### Functional Requirements

**Model Factories:**
- `make(factoryName, attributes, traits)` - Create in-memory model instance
- `create(factoryName, attributes, traits)` - Persist model instance to database
- Support for attribute overrides as struct
- Support for traits (composable, can apply multiple)
- Support for relationships/associations in factory definitions
- Auto-discovery of factory definitions from `tests/factories/*.cfc`
- Factory definitions use simple CFC format with `definition()` method

**Database Assertions:**
- `assertDatabaseHas(table, attributes)` - Verify record exists with attributes
- `assertDatabaseMissing(table, attributes)` - Verify record does not exist
- `assertDatabaseCount(table, count)` - Verify record count in table
- Available in both unit and integration tests

**Handler Testing Helpers:**
- `makeRequest(method, path, params)` - Create simulated HTTP request
- `handle(request)` - Execute request through handler system
- Access to response object with status, headers, body
- Simulate GET/POST/PUT/PATCH/DELETE requests
- Support for request headers, body, query params

**Mock System:**
- `mock(component)` - Create mock of component
- `stub(method, returnValue)` - Configure method stub
- `verify(method, times)` - Verify method call count
- Method-level mocking only (not property mocking)
- Simple API for 80% of mocking use cases

**Integration Test Support:**
- Load full framework stack (routing, DI, modules, events, ORM)
- Run tests in transaction with auto-rollback (same as unit tests)
- Access to full application.fuse framework instance
- Ability to test full request/response cycle through framework

### Reusability Opportunities

**Existing Components to Extend:**
- TestCase.cfc - Add factory helper methods (`make()`, `create()`)
- TestCase.cfc - Add mock helper methods (`mock()`, `stub()`, `verify()`)
- Assertions.cfc - Add database assertion methods
- TestRunner.cfc - Already handles transaction rollback, extend for integration test initialization

**Existing Patterns to Follow:**
- Model.cfc patterns for factory persistence (use `save()`, `create()` methods)
- Router patterns for request simulation
- DI container patterns for component mocking
- Module system for test helper auto-discovery

### Scope Boundaries

**In Scope:**
- Model factories with make/create methods
- Trait system for factories (composable)
- Relationship support in factories
- Database assertion methods
- Handler request/response simulation
- Basic method-level mocking
- Integration test framework loading
- Automatic transaction rollback for both test types
- Factory auto-discovery from tests/factories/

**Out of Scope:**
- Fixtures (YAML-based test data) - using factories only
- Full spy/partial mock system - lightweight only
- Complex BDD syntax (describe/it blocks) - simple test methods
- Browser/JavaScript testing - pure backend testing
- Parallel test execution - sequential only
- Test coverage reporting - future enhancement
- Snapshot testing - future enhancement
- Time mocking/freezing - future enhancement

### Technical Considerations

**Integration with Existing Framework:**
- Use existing TestCase.cfc as base for new helpers
- Hook into TestRunner.cfc transaction management
- Leverage existing ORM Model.cfc for factory persistence
- Use existing Router for request simulation
- Extend existing Assertions.cfc with database methods

**Factory Implementation:**
- Factory definitions as CFCs with `definition()` method returning struct
- Traits as separate methods returning attribute overrides
- Auto-discovery via directory scan of `tests/factories/*.cfc`
- Use Model.cfc methods for actual persistence
- Support for sequences (auto-incrementing values in factories)

**Mock Implementation:**
- Simple method interception at component level
- Track method calls and return values
- No complex proxy/partial mock system
- Focus on common use cases: stubbing service calls, verifying method calls

**Integration Test Loading:**
- Initialize full Application.cfc/Fuse framework
- Load all modules, routes, DI container
- Then start transaction for test isolation
- Rollback transaction after each test (same as unit tests)

**Performance Targets:**
- Factory creation: <10ms per instance (make or create)
- Database assertions: <5ms per assertion
- Mock creation/verification: <1ms overhead
- Integration test framework load: <200ms (one-time per suite)
- Transaction rollback: <10ms per test

**Alignment with Standards:**
- Follow existing Fuse coding conventions (see agent-os/standards/global/coding-style.md)
- Use Lucee 7 static methods where appropriate
- Maintain zero external dependencies (built-in only)
- Follow Rails/Laravel testing patterns for familiarity
