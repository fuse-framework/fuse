# Error Reference

Complete taxonomy of Fuse framework exceptions for AI agents.

---

## Exception Hierarchy

```
BaseException (fuse.exceptions.BaseException)
├── ModelNotFoundException
├── ValidationException
├── CircularDependency
├── MissingDependency
├── CacheMiss
├── RouteNotFoundException
└── MethodNotFoundException
```

---

## ModelNotFoundException

**Type:** `ModelNotFoundException`
**Extends:** `fuse.exceptions.BaseException`

**When Thrown:**
- `findOrFail(id)` called with non-existent ID
- `firstOrFail()` returns no results

**Data Included:**
```cfml
{
    model: "User",  // Model name
    id: 999         // Attempted ID
}
```

**How to Handle:**
```cfml
// Pattern 1: Try/catch
try {
    user = User.findOrFail(id);
} catch (ModelNotFoundException e) {
    return {status: 404, message: "User not found"};
}

// Pattern 2: Use find() and check
user = User.find(id);
if (isNull(user)) {
    return {status: 404, message: "User not found"};
}
```

**HTTP Status:** 404 Not Found

---

## ValidationException

**Type:** `ValidationException`
**Extends:** `fuse.exceptions.BaseException`

**When Thrown:**
- `save()` called with invalid attributes
- `create()` called with invalid data
- `update()` called with invalid data

**Data Included:**
```cfml
{
    errors: {
        email: ["Email is required", "Email must be valid"],
        name: ["Name is too short"]
    },
    model: User  // Model instance
}
```

**How to Handle:**
```cfml
// Pattern 1: Check hasErrors() (recommended)
user = User.create(params.user);
if (user.hasErrors()) {
    return {
        status: 422,
        errors: user.getErrors()
    };
}

// Pattern 2: Try/catch
try {
    user = User.create(params.user);
} catch (ValidationException e) {
    return {
        status: 422,
        errors: e.data.errors
    };
}
```

**HTTP Status:** 422 Unprocessable Entity

---

## CircularDependency

**Type:** `CircularDependency`
**Extends:** `fuse.exceptions.BaseException`

**When Thrown:**
- Module dependencies form a cycle
- DI container detects circular injection

**Data Included:**
```cfml
{
    modules: ["auth", "user", "auth"]  // Dependency chain
}
```

**How to Handle:**
```cfml
// This is a FATAL error - fix your module dependencies
// Cannot be caught - framework will not boot

// Fix: Break the circular dependency
// modules/auth/Module.cfc
function getDependencies() {
    return {
        required: [],  // Remove circular ref
        optional: ["user"]  // Make it optional
    };
}
```

**HTTP Status:** 500 Internal Server Error (framework fatal)

---

## MissingDependency

**Type:** `MissingDependency`
**Extends:** `fuse.exceptions.BaseException`

**When Thrown:**
- Module requires another module that isn't loaded
- DI container cannot resolve required dependency

**Data Included:**
```cfml
{
    module: "auth",
    dependency: "cache"
}
```

**How to Handle:**
```cfml
// This is a FATAL error - add missing module
// Cannot be caught - framework will not boot

// Fix: Ensure required module is present
// 1. Add module to modules/ directory
// 2. Or make dependency optional

function getDependencies() {
    return {
        required: [],
        optional: ["cache"]  // Change to optional
    };
}
```

**HTTP Status:** 500 Internal Server Error (framework fatal)

---

## CacheMiss

**Type:** `CacheMiss`
**Extends:** `fuse.exceptions.BaseException`

**When Thrown:**
- `cache.get(key)` called with non-existent key (RAMProvider)
- No default value provided

**Data Included:**
```cfml
{
    key: "user:123"
}
```

**How to Handle:**
```cfml
// Pattern 1: Provide default
value = cache.get("key", defaultValue);

// Pattern 2: Try/catch
try {
    value = cache.get("key");
} catch (CacheMiss e) {
    value = computeValue();
    cache.set("key", value);
}

// Pattern 3: Use remember()
value = cache.remember("key", 3600, function() {
    return computeValue();
});
```

**HTTP Status:** N/A (application logic)

---

## RouteNotFoundException

**Type:** `RouteNotFoundException`
**Extends:** `fuse.exceptions.BaseException`

**When Thrown:**
- Requested URL doesn't match any route
- HTTP method not allowed for route

**Data Included:**
```cfml
{
    path: "/nonexistent",
    method: "GET"
}
```

**How to Handle:**
```cfml
// Framework handles automatically
// Returns 404 page

// Custom 404 handler
// handlers/ErrorsHandler.cfc
function notFound() {
    return {
        status: 404,
        view: "errors/404"
    };
}

// config/routes.cfm
router.error(404, "Errors.notFound");
```

**HTTP Status:** 404 Not Found

---

## MethodNotFoundException

**Type:** `MethodNotFoundException`
**Extends:** `fuse.exceptions.BaseException`

**When Thrown:**
- Handler action doesn't exist
- Model method called that doesn't exist (and not handled by onMissingMethod)

**Data Included:**
```cfml
{
    component: "UsersHandler",
    method: "invalidAction"
}
```

**How to Handle:**
```cfml
// This is usually a coding error
// Fix: Ensure handler action exists

// handlers/UsersHandler.cfc
function show() {  // Method must exist
    // ...
}

// Or implement onMissingMethod
function onMissingMethod(methodName, args) {
    throw(
        type="MethodNotAllowed",
        message="Action #methodName# not found"
    );
}
```

**HTTP Status:** 500 Internal Server Error (coding error)

---

## Error Handling Patterns

### Pattern 1: Explicit Null Checks

```cfml
user = User.find(id);
if (isNull(user)) {
    // Handle not found
}
```

**Use When:** Performance critical, avoid exceptions

### Pattern 2: Try/Catch

```cfml
try {
    user = User.findOrFail(id);
} catch (ModelNotFoundException e) {
    // Handle not found
}
```

**Use When:** Exceptional cases, cleaner code flow

### Pattern 3: Validation Check

```cfml
user = User.create(data);
if (user.hasErrors()) {
    return {errors: user.getErrors()};
}
```

**Use When:** User input validation (always)

### Pattern 4: Transaction Rollback

```cfml
try {
    Transaction.run(function() {
        user = User.create({...});
        user.posts().create({...});
    });
} catch (any e) {
    // Transaction rolled back automatically
    log.error(e.message);
}
```

**Use When:** Multi-step operations

---

## HTTP Status Code Mapping

| Exception | HTTP Status | Description |
|-----------|-------------|-------------|
| ModelNotFoundException | 404 | Record not found |
| ValidationException | 422 | Invalid input |
| CircularDependency | 500 | Framework config error |
| MissingDependency | 500 | Framework config error |
| RouteNotFoundException | 404 | Invalid URL |
| MethodNotFoundException | 500 | Coding error |
| CacheMiss | N/A | Application logic |

---

## Custom Exceptions

### Creating Custom Exceptions

```cfml
// exceptions/InsufficientFundsException.cfc
component extends="fuse.exceptions.BaseException" {
    function init(required numeric balance, required numeric amount) {
        super.init(
            type: "InsufficientFunds",
            message: "Insufficient funds: balance=#balance#, required=#amount#",
            data: {
                balance: arguments.balance,
                amount: arguments.amount
            }
        );
        return this;
    }
}
```

### Throwing Custom Exceptions

```cfml
// models/Account.cfc
function withdraw(required numeric amount) {
    if (variables.balance < arguments.amount) {
        throw new exceptions.InsufficientFundsException(
            balance: variables.balance,
            amount: arguments.amount
        );
    }

    variables.balance -= arguments.amount;
    save();
}
```

### Catching Custom Exceptions

```cfml
try {
    account.withdraw(100);
} catch (InsufficientFunds e) {
    return {
        status: 400,
        message: e.message,
        data: e.data
    };
}
```

---

## Error Logging

### Framework Error Logging

```cfml
// Errors automatically logged to:
// - Application log
// - Framework error log
// - Custom error handler (if configured)

// config/fuse.cfc
settings.logging = {
    errors: true,
    errorHandler: "ErrorService.logError",
    errorLog: "/logs/errors.log"
};
```

### Custom Error Logging

```cfml
// services/ErrorService.cfc
function logError(required any exception) {
    writeLog(
        file: "application",
        type: "error",
        text: "#exception.type#: #exception.message#"
    );

    // Send to monitoring service
    if (config.get("monitoring.enabled")) {
        monitoringService.captureException(exception);
    }
}
```

---

## Debugging Exceptions

### Development Mode

```cfml
// .env
FUSE_ENV=development

// Shows full stack trace
// Includes query details
// Displays debug info
```

### Production Mode

```cfml
// .env
FUSE_ENV=production

// Generic error page
// Errors logged only
// No sensitive data exposed
```

### Exception Data

```cfml
// All exceptions include:
{
    type: "ValidationException",
    message: "Validation failed",
    detail: "Email is required",
    data: {...},           // Custom exception data
    tagContext: [...],     // Stack trace
    stackTrace: "..."      // Full trace
}
```
