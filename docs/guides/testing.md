# Testing

Fuse provides an xUnit-style testing framework with automatic database transaction rollback, comprehensive assertions, and seamless integration with models and handlers for both unit and integration testing.

## Overview

Write tests extending `fuse.testing.TestCase` to validate application logic:

```cfml
// tests/models/UserTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        // Runs before each test
        variables.user = new app.models.User(getDatasource());
    }

    public function testUserEmailValidation() {
        variables.user.email = "invalid";
        assertFalse(variables.user.isValid());
        assertContains("is not a valid email", variables.user.getErrors("email"));
    }

    public function testUserCreation() {
        variables.user.name = "John Doe";
        variables.user.email = "john@example.com";
        assertTrue(variables.user.save());
        assertGreaterThan(0, variables.user.id);
    }
}
```

Fuse testing framework provides:
- **Automatic transaction rollback** - Each test gets clean database state
- **Comprehensive assertions** - 15+ assertion methods for all scenarios
- **Setup/teardown lifecycle** - Prepare and cleanup test state
- **Test discovery** - Automatic test file detection
- **CLI integration** - Run tests with `lucli test`

## Test File Conventions

Organize tests following these conventions:

### Directory Structure

```
/tests
  /models           # Model unit tests
    UserTest.cfc
    PostTest.cfc
  /handlers         # Handler integration tests
    UsersHandlerTest.cfc
    PostsHandlerTest.cfc
  /integration      # End-to-end integration tests
    BlogWorkflowTest.cfc
  /unit             # Other unit tests
    HelperTest.cfc
```

### Naming Conventions

- **Location:** `/tests/` directory with subdirectories
- **Filename:** Must end with `Test.cfc` (e.g., `UserTest.cfc`)
- **Base class:** Extend `fuse.testing.TestCase`
- **Test methods:** Public functions starting with `test` prefix
- **One test class per file:** Class name matches filename

Example:

```cfml
// tests/models/PostTest.cfc
component extends="fuse.testing.TestCase" {

    public function testPostValidation() {
        // Test code
    }

    public function testPostCreation() {
        // Test code
    }
}
```

## TestCase Setup

### Lifecycle Methods

Tests support setup and teardown hooks:

```cfml
component extends="fuse.testing.TestCase" {

    public function setup() {
        // Runs BEFORE each test method
        variables.datasource = getDatasource();
        variables.user = new app.models.User(variables.datasource);
        variables.post = new app.models.Post(variables.datasource);
    }

    public function teardown() {
        // Runs AFTER each test method
        structDelete(variables, "user");
        structDelete(variables, "post");
    }

    public function testUserPost() {
        // Test code here
        // setup() already ran, teardown() will run after
    }
}
```

**Lifecycle order:**
1. `setup()` - Prepare test data
2. `testMethod()` - Run test
3. `teardown()` - Cleanup
4. Repeat for each test method

### Datasource Access

Tests automatically access configured datasource:

```cfml
public function setup() {
    // Get datasource from framework config
    variables.datasource = getDatasource();

    // Use in model instantiation
    variables.user = new app.models.User(variables.datasource);
}
```

Datasource resolution order:
1. TestRunner init parameter
2. `application.datasource`
3. Default `"fuse"` datasource

## Assertions

Fuse provides comprehensive assertion methods for all testing scenarios.

### Equality Assertions

**assertEqual(expected, actual, [message])**

Verify values are equal:

```cfml
public function testUserName() {
    var user = User::create({name: "John Doe"});
    assertEqual("John Doe", user.name);
    assertEqual(1, user.id, "ID should be set after creation");
}
```

**assertNotEqual(expected, actual, [message])**

Verify values are different:

```cfml
public function testUserPassword() {
    var user = new User(getDatasource());
    user.password = "secret";
    user.hashPassword();
    assertNotEqual("secret", user.password, "Password should be hashed");
}
```

### Boolean Assertions

**assertTrue(value, [message])**

Verify value is true:

```cfml
public function testUserIsValid() {
    var user = new User(getDatasource());
    user.name = "John Doe";
    user.email = "john@example.com";
    assertTrue(user.isValid());
    assertTrue(user.save(), "Save should succeed with valid data");
}
```

**assertFalse(value, [message])**

Verify value is false:

```cfml
public function testInvalidEmail() {
    var user = new User(getDatasource());
    user.email = "invalid";
    assertFalse(user.isValid());
    assertFalse(user.save(), "Save should fail with invalid data");
}
```

### Null Assertions

**assertNull(value, [message])**

Verify value is null:

```cfml
public function testOptionalField() {
    var post = new Post(getDatasource());
    assertNull(post.published_at, "New post should not be published");
}
```

**assertNotNull(value, [message])**

Verify value is not null:

```cfml
public function testTimestamps() {
    var user = User::create({name: "John", email: "john@example.com"});
    assertNotNull(user.created_at);
    assertNotNull(user.updated_at);
}
```

### Collection Assertions

**assertCount(expected, collection, [message])**

Verify collection size:

```cfml
public function testUserPosts() {
    var user = User::find(1);
    var posts = user.posts().get();
    assertCount(3, posts, "User should have 3 posts");
}
```

**assertContains(needle, haystack, [message])**

Verify collection contains value:

```cfml
public function testUserRoles() {
    var user = User::find(1);
    var roles = ["admin", "member"];
    assertContains("admin", roles);
    assertContains("email", structKeyArray(user));
}
```

**assertNotContains(needle, haystack, [message])**

Verify collection doesn't contain value:

```cfml
public function testRestrictedRoles() {
    var user = User::find(1);
    user.roles = ["member"];
    assertNotContains("admin", user.roles);
}
```

**assertEmpty(value, [message])**

Verify collection is empty:

```cfml
public function testNoPosts() {
    var user = User::create({name: "New User", email: "new@example.com"});
    var posts = user.posts().get();
    assertEmpty(posts);
}
```

**assertNotEmpty(value, [message])**

Verify collection is not empty:

```cfml
public function testHasErrors() {
    var user = new User(getDatasource());
    user.isValid();
    var errors = user.getErrors();
    assertNotEmpty(errors);
}
```

### Exception Assertions

**assertThrows(callable, [exceptionType], [message])**

Verify code throws exception:

```cfml
public function testRecordNotFound() {
    // Assert any exception
    assertThrows(function() {
        User::find(99999);
    });

    // Assert specific exception type
    assertThrows(function() {
        User::find(99999);
    }, "RecordNotFoundException");
}

public function testValidationException() {
    assertThrows(function() {
        var user = User::create({email: "invalid"});
    }, "ValidationException");
}
```

### Pattern Matching

**assertMatches(pattern, string, [message])**

Verify string matches regex:

```cfml
public function testEmailFormat() {
    var user = new User(getDatasource());
    user.email = "john@example.com";
    assertMatches("^[^@]+@[^@]+\.[^@]+$", user.email);
}

public function testSlug() {
    var post = Post::create({title: "My Post"});
    assertMatches("^[a-z0-9-]+$", post.slug);
}
```

### Type Assertions

**assertInstanceOf(expectedType, actual, [message])**

Verify value type:

```cfml
public function testUserInstance() {
    var user = User::find(1);
    assertInstanceOf("struct", user);
    assertInstanceOf("array", user.posts().get());
}
```

### Numeric Comparisons

**assertGreaterThan(expected, actual, [message])**

Verify value is greater:

```cfml
public function testPositiveId() {
    var user = User::create({name: "John", email: "john@example.com"});
    assertGreaterThan(0, user.id);
}

public function testAdultAge() {
    var user = User::find(1);
    assertGreaterThan(18, user.age, "User must be adult");
}
```

**assertLessThan(expected, actual, [message])**

Verify value is less:

```cfml
public function testReasonableAge() {
    var user = new User(getDatasource());
    user.age = 25;
    assertLessThan(120, user.age);
}
```

## Database Transaction Rollback

Every test runs in isolated database transaction that **automatically rolls back** after completion.

### How It Works

```cfml
public function testCreateUser() {
    // Transaction begins automatically

    // Create user (INSERT executed)
    var user = User::create({
        name: "Test User",
        email: "test@example.com"
    });

    // Verify creation worked
    assertEqual("Test User", user.name);
    assertGreaterThan(0, user.id);

    // Transaction rolls back automatically
    // User record does NOT persist after test
}

public function testUserNotPersisted() {
    // Previous test's user was rolled back
    // Each test starts with clean database

    var users = User::where({email: "test@example.com"}).get();
    assertEmpty(users, "Previous test data rolled back");
}
```

### Key Points

- **Automatic:** No manual transaction management
- **Isolated:** Each test gets clean database state
- **Always rolls back:** Even on test failures or errors
- **Database agnostic:** Works with any JDBC-compliant database

### Benefits

```cfml
public function testUserDeletion() {
    // Create test data
    var user = User::create({name: "Delete Me", email: "delete@example.com"});
    var userId = user.id;

    // Delete user
    user.delete();

    // Verify deletion
    assertThrows(function() {
        User::find(userId);
    });

    // Rollback happens automatically
    // No cleanup code needed
    // Next test gets clean state
}
```

No need for manual cleanup in `teardown()` - database changes automatically roll back.

## Test Organization

Organize tests by type and scope for maintainability.

### Unit Tests - Models

Test model logic in isolation:

```cfml
// tests/models/UserTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.user = new app.models.User(getDatasource());
    }

    public function testEmailValidation() {
        variables.user.email = "invalid";
        assertFalse(variables.user.isValid());
        assertContains("is not a valid email", variables.user.getErrors("email"));
    }

    public function testRequiredName() {
        variables.user.email = "valid@example.com";
        variables.user.name = "";
        assertFalse(variables.user.isValid());
        assertContains("is required", variables.user.getErrors("name"));
    }

    public function testSuccessfulCreation() {
        variables.user.name = "John Doe";
        variables.user.email = "john@example.com";
        assertTrue(variables.user.save());
        assertGreaterThan(0, variables.user.id);
    }
}
```

### Unit Tests - Validation Logic

Test validation rules comprehensively:

```cfml
// tests/models/PostValidationTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.post = new app.models.Post(getDatasource());
    }

    public function testRequiredTitle() {
        variables.post.title = "";
        assertFalse(variables.post.isValid());
        var errors = variables.post.getErrors("title");
        assertContains("is required", errors);
    }

    public function testTitleLength() {
        variables.post.title = "ab";  // Too short
        assertFalse(variables.post.isValid());
        var errors = variables.post.getErrors("title");
        assertMatches("too short", errors[1]);
    }

    public function testValidPost() {
        variables.post.title = "Valid Title";
        variables.post.body = "Post content here";
        assertTrue(variables.post.isValid());
        assertFalse(variables.post.hasErrors());
    }
}
```

### Unit Tests - Relationships

Test relationship queries:

```cfml
// tests/models/UserRelationshipsTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        // Create test data
        variables.user = User::create({
            name: "Test User",
            email: "test@example.com"
        });

        variables.post = Post::create({
            user_id: variables.user.id,
            title: "Test Post",
            body: "Content"
        });
    }

    public function testUserHasPosts() {
        var posts = variables.user.posts().get();
        assertCount(1, posts);
        assertEqual("Test Post", posts[1].title);
    }

    public function testPostBelongsToUser() {
        var user = variables.post.user().first();
        assertNotNull(user);
        assertEqual("Test User", user.name);
    }

    public function testPostCountQuery() {
        var count = variables.user.posts().count();
        assertEqual(1, count);
    }
}
```

### Integration Tests - Handlers

Test handler actions with database:

```cfml
// tests/handlers/UsersHandlerTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        // Create test user
        variables.user = User::create({
            name: "Test User",
            email: "test@example.com"
        });

        // Instantiate handler
        variables.handler = new app.handlers.Users();
    }

    public function testIndexAction() {
        var result = variables.handler.index();

        assertTrue(result.success);
        assertInstanceOf("array", result.users);
        assertGreaterThan(0, arrayLen(result.users));
    }

    public function testShowAction() {
        var result = variables.handler.show(id = variables.user.id);

        assertTrue(result.success);
        assertEqual("Test User", result.user.name);
    }

    public function testCreateAction() {
        form.name = "New User";
        form.email = "new@example.com";

        var result = variables.handler.create();

        assertTrue(result.success);
        assertTrue(result.created);
        assertGreaterThan(0, result.user.id);
    }

    public function testShowNotFound() {
        var result = variables.handler.show(id = 99999);

        assertFalse(result.success);
        assertEqual(404, result.status);
    }
}
```

### Integration Tests - Full Workflows

Test complete user workflows:

```cfml
// tests/integration/BlogWorkflowTest.cfc
component extends="fuse.testing.TestCase" {

    public function testCreatePostWithComments() {
        // Create user
        var user = User::create({
            name: "Author",
            email: "author@example.com"
        });

        // Create post
        var post = Post::create({
            user_id: user.id,
            title: "My Post",
            body: "Post content"
        });

        // Add comments
        var comment1 = Comment::create({
            post_id: post.id,
            user_id: user.id,
            content: "First comment"
        });

        var comment2 = Comment::create({
            post_id: post.id,
            user_id: user.id,
            content: "Second comment"
        });

        // Verify workflow
        var loadedPost = Post::find(post.id);
        var comments = loadedPost.comments().get();

        assertCount(2, comments);
        assertEqual("First comment", comments[1].content);
        assertEqual("Second comment", comments[2].content);

        // Verify relationships
        var author = loadedPost.user().first();
        assertEqual("Author", author.name);
    }
}
```

## Testing Models

Comprehensive model testing patterns.

### Testing CRUD Operations

```cfml
// tests/models/UserCRUDTest.cfc
component extends="fuse.testing.TestCase" {

    public function testCreate() {
        var user = User::create({
            name: "John Doe",
            email: "john@example.com"
        });

        assertGreaterThan(0, user.id);
        assertEqual("John Doe", user.name);
        assertNotNull(user.created_at);
    }

    public function testRead() {
        var created = User::create({name: "Jane", email: "jane@example.com"});
        var found = User::find(created.id);

        assertEqual(created.id, found.id);
        assertEqual("Jane", found.name);
    }

    public function testUpdate() {
        var user = User::create({name: "Old Name", email: "test@example.com"});
        user.name = "New Name";
        user.save();

        var reloaded = User::find(user.id);
        assertEqual("New Name", reloaded.name);
    }

    public function testDelete() {
        var user = User::create({name: "Delete Me", email: "delete@example.com"});
        var id = user.id;
        user.delete();

        assertThrows(function() {
            User::find(id);
        });
    }
}
```

### Testing Validations

```cfml
// tests/models/UserValidationTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.user = new app.models.User(getDatasource());
    }

    public function testEmailRequired() {
        variables.user.name = "John";
        variables.user.email = "";

        assertFalse(variables.user.isValid());
        assertTrue(variables.user.hasErrors());
        assertContains("is required", variables.user.getErrors("email"));
    }

    public function testEmailFormat() {
        variables.user.email = "not-an-email";

        assertFalse(variables.user.isValid());
        assertContains("is not a valid email", variables.user.getErrors("email"));
    }

    public function testEmailUnique() {
        // Create first user
        User::create({name: "First", email: "duplicate@example.com"});

        // Try to create second user with same email
        var user2 = new app.models.User(getDatasource());
        user2.name = "Second";
        user2.email = "duplicate@example.com";

        assertFalse(user2.isValid());
        assertContains("has already been taken", user2.getErrors("email"));
    }

    public function testMultipleValidationErrors() {
        variables.user.name = "";
        variables.user.email = "invalid";

        assertFalse(variables.user.isValid());

        var errors = variables.user.getErrors();
        assertContains("name", structKeyArray(errors));
        assertContains("email", structKeyArray(errors));
    }

    public function testValidData() {
        variables.user.name = "John Doe";
        variables.user.email = "john@example.com";

        assertTrue(variables.user.isValid());
        assertFalse(variables.user.hasErrors());
        assertTrue(variables.user.save());
    }
}
```

### Testing Relationships

```cfml
// tests/models/PostRelationshipsTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.user = User::create({
            name: "Author",
            email: "author@example.com"
        });

        variables.post = Post::create({
            user_id: variables.user.id,
            title: "Test Post",
            body: "Content"
        });

        Comment::create({
            post_id: variables.post.id,
            user_id: variables.user.id,
            content: "Comment 1"
        });

        Comment::create({
            post_id: variables.post.id,
            user_id: variables.user.id,
            content: "Comment 2"
        });
    }

    public function testPostBelongsToUser() {
        var author = variables.post.user().first();

        assertNotNull(author);
        assertEqual(variables.user.id, author.id);
        assertEqual("Author", author.name);
    }

    public function testPostHasComments() {
        var comments = variables.post.comments().get();

        assertCount(2, comments);
        assertInstanceOf("array", comments);
    }

    public function testUserHasPosts() {
        var posts = variables.user.posts().get();

        assertCount(1, posts);
        assertEqual("Test Post", posts[1].title);
    }

    public function testCommentBelongsToPost() {
        var comment = Comment::where({content: "Comment 1"}).first();
        var post = comment.post().first();

        assertEqual(variables.post.id, post.id);
    }
}
```

### Testing Query Building

```cfml
// tests/models/UserQueryTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        User::create({name: "Active User", email: "active@example.com", active: true});
        User::create({name: "Inactive User", email: "inactive@example.com", active: false});
    }

    public function testWhereClause() {
        var activeUsers = User::where({active: true}).get();
        assertCount(1, activeUsers);
        assertEqual("Active User", activeUsers[1].name);
    }

    public function testOrderBy() {
        var users = User::all().orderBy("name").get();
        assertEqual("Active User", users[1].name);
    }

    public function testLimitOffset() {
        var users = User::all().limit(1).get();
        assertCount(1, users);
    }

    public function testCount() {
        var count = User::count();
        assertEqual(2, count);
    }

    public function testFirst() {
        var user = User::where({active: true}).first();
        assertNotNull(user);
        assertEqual("Active User", user.name);
    }
}
```

## Testing Handlers

Test handler actions and request handling.

### Testing RESTful Actions

```cfml
// tests/handlers/PostsHandlerTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.handler = new app.handlers.Posts();
        variables.user = User::create({name: "Author", email: "author@example.com"});
        variables.post = Post::create({
            user_id: variables.user.id,
            title: "Test Post",
            body: "Content"
        });
    }

    public function testIndexAction() {
        var result = variables.handler.index();

        assertTrue(result.success);
        assertInstanceOf("array", result.posts);
    }

    public function testShowAction() {
        var result = variables.handler.show(id = variables.post.id);

        assertTrue(result.success);
        assertEqual("Test Post", result.post.title);
    }

    public function testCreateAction() {
        form.user_id = variables.user.id;
        form.title = "New Post";
        form.body = "New content";

        var result = variables.handler.create();

        assertTrue(result.created);
        assertGreaterThan(0, result.post.id);
    }

    public function testUpdateAction() {
        form.title = "Updated Title";

        var result = variables.handler.update(id = variables.post.id);

        assertTrue(result.updated);
        assertEqual("Updated Title", result.post.title);
    }

    public function testDestroyAction() {
        var result = variables.handler.destroy(id = variables.post.id);

        assertTrue(result.deleted);

        // Verify deletion
        assertThrows(function() {
            Post::find(variables.post.id);
        });
    }
}
```

### Testing Error Handling

```cfml
// tests/handlers/PostsHandlerErrorTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.handler = new app.handlers.Posts();
    }

    public function testShowNotFound() {
        var result = variables.handler.show(id = 99999);

        assertFalse(result.success);
        assertEqual(404, result.status);
        assertEqual("Post not found", result.error);
    }

    public function testCreateValidationError() {
        form.title = "";  // Invalid
        form.body = "";

        var result = variables.handler.create();

        assertFalse(result.success);
        assertEqual(422, result.status);
        assertInstanceOf("struct", result.errors);
    }

    public function testUpdateNotFound() {
        form.title = "New Title";

        var result = variables.handler.update(id = 99999);

        assertFalse(result.success);
        assertEqual(404, result.status);
    }
}
```

### Testing with Dependencies

```cfml
// tests/handlers/UsersHandlerWithDITest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        // Mock dependencies
        variables.mockLogger = {
            info: function(message) {},
            error: function(message) {}
        };

        variables.mockUserService = {
            createUser: function(data) {
                return User::create(data);
            }
        };

        // Inject mocks
        variables.handler = new app.handlers.Users(
            logger = variables.mockLogger,
            userService = variables.mockUserService
        );
    }

    public function testCreateWithService() {
        form.name = "New User";
        form.email = "new@example.com";

        var result = variables.handler.create();

        assertTrue(result.created);
        assertGreaterThan(0, result.user.id);
    }
}
```

## Mocking Dependencies

Create mock objects for testing isolation.

### Simple Mocks

```cfml
// Create mock struct
variables.mockLogger = {
    info: function(message) {
        // Track calls if needed
        variables.logCalls = variables.logCalls ?: [];
        arrayAppend(variables.logCalls, message);
    },
    error: function(message) {}
};

// Use mock
var handler = new app.handlers.Users(logger = variables.mockLogger);
```

### Service Mocks

```cfml
public function testHandlerWithMockedService() {
    // Mock user service
    variables.mockService = {
        getAll: function() {
            return [
                {id: 1, name: "Test User 1"},
                {id: 2, name: "Test User 2"}
            ];
        },
        createUser: function(data) {
            return {id: 1, name: data.name, email: data.email};
        }
    };

    var handler = new app.handlers.Users(userService = variables.mockService);
    var result = handler.index();

    assertCount(2, result.users);
}
```

### Verifying Mock Calls

```cfml
public function testLoggerCalled() {
    variables.logCalls = [];

    variables.mockLogger = {
        info: function(message) {
            arrayAppend(variables.logCalls, {method: "info", message: message});
        }
    };

    var handler = new app.handlers.Users(logger = variables.mockLogger);
    handler.index();

    assertGreaterThan(0, arrayLen(variables.logCalls));
    assertContains("Listing users", variables.logCalls[1].message);
}
```

## Running Tests

Execute tests via CLI or web interface.

### Command Line

Run all tests:

```bash
lucli test
```

Run specific directory:

```bash
lucli test tests/models
```

Run specific file:

```bash
lucli test tests/models/UserTest.cfc
```

### Web Interface

Visit test runner in browser:

```
http://localhost:8080/fuse/testing/run.cfm
```

Run specific path:

```
http://localhost:8080/fuse/testing/run.cfm?path=/tests/models
```

### Output Format

Console output shows progress:

```
Running tests from: /tests/models
...F..E.

Failures:
1) UserTest::testInvalidEmail
   Email validation should fail
   Expected: false, Actual: true

Errors:
1) UserTest::testDatabaseError
   Database connection failed

8 tests, 5 passed, 1 failure, 1 error
Finished in 0.84 seconds
```

Progress indicators:
- `.` = Pass (green)
- `F` = Failure (red)
- `E` = Error (yellow)

## Best Practices

### Test Organization

```cfml
// Good - Organized by feature
/tests
  /models
    UserTest.cfc
    UserValidationTest.cfc
    UserRelationshipsTest.cfc
  /handlers
    UsersHandlerTest.cfc
  /integration
    UserWorkflowTest.cfc
```

### Descriptive Test Names

```cfml
// Good - Clear test intent
public function testUserEmailMustBeUnique() {}
public function testPostRequiresTitle() {}
public function testCommentBelongsToPost() {}

// Bad - Vague names
public function test1() {}
public function testStuff() {}
```

### Arrange-Act-Assert Pattern

```cfml
public function testUserCreation() {
    // Arrange - Set up test data
    var userData = {
        name: "John Doe",
        email: "john@example.com"
    };

    // Act - Execute the operation
    var user = User::create(userData);

    // Assert - Verify results
    assertEqual("John Doe", user.name);
    assertGreaterThan(0, user.id);
}
```

### One Assertion per Test

```cfml
// Good - Focused tests
public function testUserHasName() {
    var user = User::create({name: "John", email: "john@example.com"});
    assertEqual("John", user.name);
}

public function testUserHasEmail() {
    var user = User::create({name: "John", email: "john@example.com"});
    assertEqual("john@example.com", user.email);
}

// Acceptable - Related assertions
public function testUserTimestamps() {
    var user = User::create({name: "John", email: "john@example.com"});
    assertNotNull(user.created_at);
    assertNotNull(user.updated_at);
}
```

### Use Setup for Common Data

```cfml
// Good - DRY principle
public function setup() {
    variables.validUserData = {
        name: "Test User",
        email: "test@example.com"
    };
}

public function testUserCreation() {
    var user = User::create(variables.validUserData);
    assertTrue(user.save());
}

public function testUserValidation() {
    var user = new app.models.User(getDatasource());
    user.assign(variables.validUserData);
    assertTrue(user.isValid());
}
```

### Test Both Success and Failure

```cfml
public function testValidEmail() {
    var user = new app.models.User(getDatasource());
    user.email = "valid@example.com";
    assertTrue(user.isValid());
}

public function testInvalidEmail() {
    var user = new app.models.User(getDatasource());
    user.email = "invalid";
    assertFalse(user.isValid());
}
```

### Clean Test Data

```cfml
// Good - Unique test data
public function testUserCreation() {
    var user = User::create({
        name: "Test User #createUUID()#",
        email: "test-#createUUID()#@example.com"
    });
    assertTrue(user.save());
}
```

## Anti-Patterns

### Testing Implementation Details

**Bad:**
```cfml
// Tests internal variable names
public function testInternalVariables() {
    var user = new app.models.User(getDatasource());
    assertTrue(structKeyExists(user, "validations"));
}
```

**Good:**
```cfml
// Tests behavior
public function testUserValidation() {
    var user = new app.models.User(getDatasource());
    user.email = "invalid";
    assertFalse(user.isValid());
}
```

### Dependent Tests

**Bad:**
```cfml
// Test order matters - WRONG
variables.userId = 0;

public function test1CreateUser() {
    var user = User::create({name: "Test", email: "test@example.com"});
    variables.userId = user.id;
}

public function test2UpdateUser() {
    var user = User::find(variables.userId);  // Depends on test1
    user.update({name: "Updated"});
}
```

**Good:**
```cfml
// Each test independent
public function testUpdateUser() {
    // Create own test data
    var user = User::create({name: "Test", email: "test@example.com"});
    user.update({name: "Updated"});
    assertEqual("Updated", user.name);
}
```

### Missing Assertions

**Bad:**
```cfml
public function testUserCreation() {
    var user = User::create({name: "Test", email: "test@example.com"});
    // No assertions - test always passes!
}
```

**Good:**
```cfml
public function testUserCreation() {
    var user = User::create({name: "Test", email: "test@example.com"});
    assertGreaterThan(0, user.id);
    assertEqual("Test", user.name);
}
```

### Testing Multiple Things

**Bad:**
```cfml
public function testEverything() {
    // Too many responsibilities
    var user = User::create({name: "Test", email: "test@example.com"});
    assertEqual("Test", user.name);

    var post = Post::create({user_id: user.id, title: "Post"});
    assertEqual("Post", post.title);

    var comment = Comment::create({post_id: post.id, content: "Comment"});
    assertEqual("Comment", comment.content);
}
```

**Good:**
```cfml
public function testUserCreation() {
    var user = User::create({name: "Test", email: "test@example.com"});
    assertEqual("Test", user.name);
}

public function testPostCreation() {
    var user = User::create({name: "Test", email: "test@example.com"});
    var post = Post::create({user_id: user.id, title: "Post"});
    assertEqual("Post", post.title);
}
```

## Common Errors

### Tests Not Running

**Error:** `lucli test` finds no tests or skips test files.

**Cause:** Test files not in correct location or naming pattern wrong.

```
tests/
  MyTest.cfc  // Wrong! Doesn't end in Test.cfc
```

**Solution:** Follow naming conventions:

```
tests/
  models/
    UserTest.cfc        // Correct
    PostTest.cfc        // Correct
  handlers/
    UsersHandlerTest.cfc  // Correct
```

Test files must:
- Be in /tests/ directory
- End with `Test.cfc`
- Extend `fuse.testing.TestCase`

### Transaction Not Rolling Back

**Error:** Test data persists between tests.

**Cause:** Test not using transaction or transaction disabled.

```cfml
// Persists to database - NO rollback
component extends="fuse.testing.TestCase" {
    public function testCreate() {
        User::create({name: "Test"});  // Stays in DB!
    }
}
```

**Solution:** Ensure TestCase handles transactions (default behavior):

```cfml
// TestCase automatically wraps each test in transaction
component extends="fuse.testing.TestCase" {
    public function testCreate() {
        User::create({name: "Test"});
        // Rolled back after test completes
    }
}
```

If issues persist, check datasource configuration.

### Assertion Failures

**Error:** Test fails with assertion error.

**Cause:** Expected value doesn't match actual value.

```cfml
assertEqual("John", user.name);
// FAIL: Expected 'John' but got 'Jane'
```

**Solution:** Debug by examining actual values:

```cfml
// Add debugging
writeDump(user);
assertEqual("John", user.name);

// Or use better assertion
assertNotNull(user);
assertTrue(len(user.name) > 0);
```

### Setup/Teardown Issues

**Error:** Tests fail because setup() not running or data not cleaned up.

**Cause:** Method name misspelled or not marked public.

```cfml
// Wrong: Private method
private function setup() {  // Never runs!
    // ...
}
```

**Solution:** Make setup/teardown public:

```cfml
// Correct
public function setup() {
    variables.user = User::create({name: "Test"});
}

public function teardown() {
    // Cleanup if needed (transaction usually handles it)
}
```

### Foreign Key Constraint Errors in Tests

**Error:** Cannot create test data due to missing foreign key references.

**Cause:** Creating child records before parent records.

```cfml
// Fails: No user with id=999
Post::create({
    user_id: 999,
    title: "Test"
});
```

**Solution:** Create parent records first:

```cfml
// Create parent first
var user = User::create({name: "Test", email: "test@example.com"});

// Then child with valid foreign key
var post = Post::create({
    user_id: user.id,  // Valid FK
    title: "Test Post"
});
```

## API Reference

For detailed test framework methods:

- [TestCase Assertions](../reference/api-reference.md#validation) - assertEqual(), assertTrue(), assertContains(), etc.
- [Test Lifecycle](../reference/api-reference.md#transaction) - setup(), teardown(), transaction rollback
- [Model Methods](../reference/api-reference.md#models-activerecord) - Testing CRUD operations

## Related Topics

- [Models & ORM](models-orm.md) - Test model queries and persistence
- [Validations](validations.md) - Test validation rules
- [Relationships](relationships.md) - Test model relationships
- [Handlers](../handlers.md) - Test handler actions
- [CLI Reference](../reference/cli-reference.md) - `lucli test` command
