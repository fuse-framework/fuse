# Fuse Test Framework

xUnit-style testing framework for Fuse with automatic database transaction rollback and colorized console output.

## Quick Start

### 1. Create a Test

```cfml
// tests/models/UserTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        // Runs before each test
        variables.user = {name: "Test User", email: "test@example.com"};
    }

    public function teardown() {
        // Runs after each test
        variables.user = "";
    }

    public function testUserHasName() {
        assertEqual("Test User", variables.user.name);
    }

    public function testEmailFormat() {
        assertMatches("^[^@]+@[^@]+$", variables.user.email);
    }
}
```

### 2. Run Tests

**Web Interface:**
```
http://localhost:8080/fuse/testing/run.cfm
```

**Command Line:**
```bash
lucee fuse/testing/cli-runner.cfm
```

**Run Specific Path:**
```
http://localhost:8080/fuse/testing/run.cfm?path=/tests/models
```

## Test File Conventions

- **Location:** `/tests/` directory with any subdirectory structure
- **Naming:** Files must end with `Test.cfc` (e.g., `UserTest.cfc`, `PostTest.cfc`)
- **Base Class:** Extend `fuse.testing.TestCase`
- **Test Methods:** Public functions starting with `test` prefix (e.g., `testUserCreation()`)
- **One Test Class Per File:** Matching filename

Example structure:
```
/tests
  /models
    UserTest.cfc
    PostTest.cfc
  /handlers
    HomeHandlerTest.cfc
  /integration
    UserFlowTest.cfc
```

## Lifecycle Methods

### setup()
Runs **before each test method**. Use for preparing test data and state.

```cfml
public function setup() {
    variables.testData = {...};
    variables.service = new UserService();
}
```

### teardown()
Runs **after each test method**. Use for cleanup.

```cfml
public function teardown() {
    structDelete(variables, "testData");
}
```

## Assertion Methods

All assertions accept optional message parameter for custom failure messages.

### Equality Assertions

**assertEqual(expected, actual, [message])**
```cfml
assertEqual(10, user.id);
assertEqual("active", user.status, "User should be active");
```

**assertNotEqual(expected, actual, [message])**
```cfml
assertNotEqual("", user.email);
```

### Boolean Assertions

**assertTrue(value, [message])**
```cfml
assertTrue(user.isActive());
assertTrue(arrayLen(users) > 0, "Should have users");
```

**assertFalse(value, [message])**
```cfml
assertFalse(user.isDeleted());
```

### Null Assertions

**assertNull(value, [message])**
```cfml
assertNull(user.deletedAt);
```

**assertNotNull(value, [message])**
```cfml
assertNotNull(user.createdAt);
```

### Exception Assertions

**assertThrows(callable, [exceptionType], [message])**
```cfml
// Assert any exception
assertThrows(function() {
    user.delete();  // Throws if user has dependencies
});

// Assert specific exception type
assertThrows(function() {
    divide(10, 0);
}, "java.lang.ArithmeticException");
```

### Collection Assertions

**assertCount(expected, collection, [message])**
```cfml
assertCount(5, users);  // Arrays
assertCount(3, query);  // Queries
```

**assertContains(needle, haystack, [message])**
```cfml
assertContains("admin", user.roles);
assertContains("id", structKeyArray(user));
```

**assertNotContains(needle, haystack, [message])**
```cfml
assertNotContains("guest", user.roles);
```

**assertEmpty(value, [message])**
```cfml
assertEmpty([]);
assertEmpty("");
assertEmpty({});
```

**assertNotEmpty(value, [message])**
```cfml
assertNotEmpty(user.name);
assertNotEmpty(users);
```

### Pattern Matching

**assertMatches(pattern, string, [message])**
```cfml
assertMatches("^\d{3}-\d{2}-\d{4}$", ssn);
assertMatches("^[A-Z]", user.name, "Name should start with capital");
```

### Type Assertions

**assertInstanceOf(expectedType, actual, [message])**
```cfml
assertInstanceOf("struct", user);
assertInstanceOf("array", results);
assertInstanceOf("query", queryResult);
```

### Numeric Comparisons

**assertGreaterThan(expected, actual, [message])**
```cfml
assertGreaterThan(0, user.id);
assertGreaterThan(18, user.age, "Must be adult");
```

**assertLessThan(expected, actual, [message])**
```cfml
assertLessThan(100, user.age);
```

## Database Transaction Rollback

Each test runs in isolated database transaction that **automatically rolls back** after test completes.

### How It Works

```cfml
public function testCreateUser() {
    // Begin transaction (automatic)

    query datasource="#getDatasource()#" {
        writeOutput("INSERT INTO users (name) VALUES ('Test User')");
    }

    // Verify insert worked
    query name="result" datasource="#getDatasource()#" {
        writeOutput("SELECT COUNT(*) as cnt FROM users WHERE name='Test User'");
    }
    assertEqual(1, result.cnt);

    // Rollback transaction (automatic)
    // Record does NOT persist after test
}

public function testUserIsIsolated() {
    // Previous test's insert was rolled back
    // Each test starts with clean database state
    query name="result" datasource="#getDatasource()#" {
        writeOutput("SELECT COUNT(*) as cnt FROM users WHERE name='Test User'");
    }
    assertEqual(0, result.cnt);  // Passes - previous insert rolled back
}
```

### Key Points

- **Automatic:** No manual transaction management needed
- **Isolated:** Each test gets clean database state
- **Always Rolls Back:** Even on failures or errors
- **Works with all databases:** Any JDBC-compliant database supporting transactions

### Datasource Configuration

Datasource resolution order:
1. TestRunner init parameter
2. `application.datasource`
3. Default `"fuse"` datasource

```cfml
// Custom datasource
runner = new fuse.testing.TestRunner(datasource = "test_db");
```

## Console Output

### Progress Indicators
- `.` = Pass (green)
- `F` = Failure (red)
- `E` = Error (yellow)

### Example Output

```
Running tests from: /tests/examples
..F.E.

Failures:
1) ExampleValidationTest::testInvalidEmailFails
   Expected email to contain @ symbol
   Expected: true, Actual: false
   at /tests/examples/ExampleValidationTest.cfc:16

Errors:
1) ExampleErrorTest::testDivisionError
   Division by zero
   at /tests/examples/ExampleErrorTest.cfc:18

6 tests, 4 passed, 1 failure, 1 error
Finished in 0.52 seconds
```

## Test Discovery

Framework automatically discovers tests using convention:

1. Scans `/tests/**/*Test.cfc` recursively
2. Filters to only CFCs extending `fuse.testing.TestCase`
3. Discovers public methods starting with `test` prefix
4. Builds test registry for runner

## Programmatic Usage

```cfml
// Initialize components
discovery = new fuse.testing.TestDiscovery(testPath = expandPath("/tests"));
runner = new fuse.testing.TestRunner(datasource = "test_db");
reporter = new fuse.testing.TestReporter();

// Execute pipeline
tests = discovery.discover();
results = runner.run(tests);
reporter.reportSummary(results);
```

## Complete Example

```cfml
component extends="fuse.testing.TestCase" {

    variables.user = "";

    public function setup() {
        // Runs before each test
        variables.user = {
            id: 1,
            name: "John Doe",
            email: "john@example.com",
            roles: ["user", "admin"],
            createdAt: now()
        };
    }

    public function teardown() {
        // Runs after each test
        variables.user = "";
    }

    public function testUserHasId() {
        assertGreaterThan(0, variables.user.id);
    }

    public function testUserHasValidEmail() {
        assertMatches("^[^@]+@[^@]+\.[^@]+$", variables.user.email);
    }

    public function testUserHasRoles() {
        assertCount(2, variables.user.roles);
        assertContains("admin", variables.user.roles);
        assertNotContains("guest", variables.user.roles);
    }

    public function testUserIsStruct() {
        assertInstanceOf("struct", variables.user);
    }

    public function testCreatedAtNotNull() {
        assertNotNull(variables.user.createdAt);
    }
}
```

## See Also

- **Example Tests:** `/tests/examples/`
- **Test Runner:** `/fuse/testing/run.cfm`
- **CLI Runner:** `/fuse/testing/cli-runner.cfm`
