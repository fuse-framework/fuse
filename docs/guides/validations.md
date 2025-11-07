# Validations

Fuse provides comprehensive model validation with built-in validators, custom error messages, and conditional logic to ensure data integrity before persisting to the database.

## Overview

Validations run automatically when saving records, preventing invalid data from reaching the database:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Define validation rules
        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });

        this.validates("name", {
            required: true,
            length: {min: 2, max: 100}
        });

        return this;
    }
}
```

```cfml
// Validation runs automatically on save
var user = new User(datasource);
user.email = "invalid-email";
user.name = "J";

if (user.save()) {
    // Success
} else {
    // Validation failed
    var errors = user.getErrors();
    // {email: ["is not a valid email"], name: ["is too short (minimum 2 characters)"]}
}
```

Validations protect data integrity, provide user-friendly error messages, and enforce business rules consistently.

## Basic Validation

### Checking Validity

Validate models explicitly before saving:

```cfml
var user = new User(datasource);
user.email = "john@example.com";
user.name = "John Doe";

// Check if valid without saving
if (user.isValid()) {
    // Model passes all validations
    user.save();
} else {
    // Handle validation errors
    var errors = user.getErrors();
}
```

### Retrieving Errors

Access validation errors after calling `isValid()` or failed `save()`:

```cfml
var user = new User(datasource);
user.email = "";  // Invalid
user.isValid();

// Get all errors
var allErrors = user.getErrors();
// {email: ["is required"], name: ["is required"]}

// Get errors for specific field
var emailErrors = user.getErrors("email");
// ["is required"]

// Check if errors exist
if (user.hasErrors()) {
    // Handle validation failure
}
```

Error structure:
- **Keys**: Field names with validation errors
- **Values**: Array of error messages for that field
- Multiple validations on same field produce multiple messages

### Validation Timing

Validations run at specific points in model lifecycle:

```cfml
// 1. Explicit validation check
user.isValid();  // Returns boolean, populates errors

// 2. Automatic validation on save
user.save();  // Returns false if validation fails

// 3. Automatic validation on create
User::create({email: "invalid"});  // Returns false if validation fails

// 4. Automatic validation on update
user.update({email: "invalid"});  // Returns false if validation fails
```

Validations always run before database operations to prevent invalid data persistence.

## Built-in Validators

Fuse includes validators for common validation scenarios.

### required

Ensures field has non-empty value:

```cfml
this.validates("email", {required: true});
this.validates("name", {required: true});
this.validates("bio", {required: true});
```

```cfml
user.email = "";  // Fails
user.email = "   ";  // Fails (whitespace-only)
user.email = "john@example.com";  // Passes
```

Error message: `"is required"`

### email

Validates email format using regex:

```cfml
this.validates("email", {email: true});
this.validates("contact_email", {email: true});
```

```cfml
user.email = "invalid";  // Fails
user.email = "test@";  // Fails
user.email = "john@example.com";  // Passes
```

Pattern: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`

Error message: `"is not a valid email"`

Note: Empty values pass (combine with `required` to enforce presence).

### length

Validates string length constraints:

```cfml
// Minimum length
this.validates("name", {length: {min: 2}});

// Maximum length
this.validates("title", {length: {max: 100}});

// Both minimum and maximum
this.validates("username", {length: {min: 3, max: 20}});
```

```cfml
user.username = "ab";  // Fails (too short)
user.username = "abc";  // Passes
user.username = "a".repeat(21);  // Fails (too long)
```

Error messages:
- `"is too short (minimum X characters)"`
- `"is too long (maximum X characters)"`

### numeric

Validates value is numeric type:

```cfml
this.validates("age", {numeric: true});
this.validates("price", {numeric: true});
this.validates("quantity", {numeric: true});
```

```cfml
user.age = "twenty";  // Fails
user.age = "25";  // Passes
user.age = 25;  // Passes
```

Error message: `"must be a number"`

### range

Validates numeric value falls within range:

```cfml
// Minimum value
this.validates("age", {range: {min: 18}});

// Maximum value
this.validates("discount", {range: {max: 100}});

// Both minimum and maximum
this.validates("rating", {range: {min: 1, max: 5}});
```

```cfml
product.rating = 0;  // Fails
product.rating = 3;  // Passes
product.rating = 6;  // Fails
```

Error message: `"must be between X and Y"`

Note: Automatically checks if value is numeric first.

### unique

Validates field value is unique in database:

```cfml
this.validates("email", {unique: true});
this.validates("username", {unique: true});
```

```cfml
// First user
var user1 = User::create({email: "john@example.com"});  // Passes

// Second user with same email
var user2 = User::create({email: "john@example.com"});  // Fails
```

Error message: `"has already been taken"`

**Scope to specific conditions:**

```cfml
// Unique within scope
this.validates("name", {unique: {scope: "category_id"}});
// Only checks uniqueness within same category_id
```

**Update handling:**
- Automatically excludes current record when updating
- Prevents false positives on self-updates

### in

Validates value is in whitelist array:

```cfml
this.validates("role", {in: {list: ["admin", "member", "guest"]}});
this.validates("status", {in: {list: ["active", "pending", "suspended"]}});
```

```cfml
user.role = "superadmin";  // Fails
user.role = "admin";  // Passes
```

Error message: `"is not included in the list"`

### format

Validates value matches regex pattern:

```cfml
// Phone number
this.validates("phone", {format: {pattern: "^\d{3}-\d{3}-\d{4}$"}});

// ZIP code
this.validates("zip", {format: {pattern: "^\d{5}$"}});

// Custom pattern
this.validates("code", {format: {pattern: "^[A-Z]{2}\d{4}$"}});
```

```cfml
user.phone = "123-456-7890";  // Passes
user.phone = "1234567890";  // Fails (no dashes)
```

Error message: `"is invalid"`

### confirmation

Validates field matches confirmation field:

```cfml
this.validates("password", {confirmation: true});
// Expects password_confirmation field to match
```

```cfml
user.password = "secret123";
user.password_confirmation = "secret123";  // Passes

user.password = "secret123";
user.password_confirmation = "different";  // Fails
```

Error message: `"doesn't match confirmation"`

Convention: Confirmation field name is `{field}_confirmation`.

## Defining Validation Rules

### Single Field, Multiple Validators

Chain multiple validators for same field:

```cfml
this.validates("email", {
    required: true,
    email: true,
    unique: true
});
```

All validators run in registration order. Each failure produces separate error message.

### Multiple Fields

Define validations separately for each field:

```cfml
public function init(datasource) {
    super.init(datasource);

    this.validates("email", {
        required: true,
        email: true,
        unique: true
    });

    this.validates("name", {
        required: true,
        length: {min: 2, max: 100}
    });

    this.validates("age", {
        numeric: true,
        range: {min: 18, max: 120}
    });

    return this;
}
```

### Validation Registration Location

Register validations in model `init()` method:

```cfml
// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Register validations here
        this.validates("title", {required: true, length: {max: 200}});
        this.validates("body", {required: true});

        return this;
    }
}
```

Benefits:
- Centralized validation logic
- Consistent validation across application
- Automatic execution on save/create/update

## Error Handling

### Error Structure

Errors stored as struct with field names as keys:

```cfml
{
    "email": ["is required", "is not a valid email"],
    "name": ["is too short (minimum 2 characters)"],
    "age": ["must be a number"]
}
```

Each field contains array of error messages (multiple validations can fail).

### Accessing Errors

```cfml
// Get all errors
var errors = user.getErrors();

// Check if errors exist
if (user.hasErrors()) {
    // Handle errors
}

// Get errors for specific field
var emailErrors = user.getErrors("email");
if (arrayLen(emailErrors) > 0) {
    // Handle email-specific errors
}
```

### Clearing Errors

Errors automatically clear on next `isValid()` call:

```cfml
user.email = "";
user.isValid();  // Fails
expect(user.hasErrors()).toBeTrue();

// Fix issue and re-validate
user.email = "john@example.com";
user.isValid();  // Passes
expect(user.hasErrors()).toBeFalse();  // Errors cleared
```

### Displaying Errors to Users

```cfml
var user = new User(datasource);
user.assign(form);

if (!user.save()) {
    var errors = user.getErrors();

    // Display all errors
    for (var field in errors) {
        for (var message in errors[field]) {
            writeOutput("#field# #message#<br>");
        }
    }

    // Or format as JSON for API
    var response = {
        success: false,
        errors: errors
    };
    return response;
}
```

## Custom Error Messages

Default error messages can be customized (note: custom messages currently require custom validators - see [Custom Validators](../advanced/custom-validators.md) guide).

### Default Messages

Each validator has default message:

| Validator | Default Message |
|-----------|----------------|
| required | "is required" |
| email | "is not a valid email" |
| unique | "has already been taken" |
| length (min) | "is too short (minimum X characters)" |
| length (max) | "is too long (maximum X characters)" |
| numeric | "must be a number" |
| range | "must be between X and Y" |
| in | "is not included in the list" |
| format | "is invalid" |
| confirmation | "doesn't match confirmation" |

### Message Formatting

Error messages automatically include field context when displayed:

```cfml
// Field name prefixes message
"email is required"
"name is too short (minimum 2 characters)"
"age must be a number"
```

Format for display:
```cfml
var errors = user.getErrors();
for (var field in errors) {
    for (var msg in errors[field]) {
        writeOutput("#field# #msg#");
        // Output: "email is required"
    }
}
```

## Conditional Validations

For advanced conditional validation logic (validating only when certain conditions are met), use custom validators with conditional logic:

```cfml
// app/models/Order.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Use custom validator for conditional logic
        this.validates("shipping_address", {
            custom: "validateShippingAddress"
        });

        return this;
    }

    private boolean function validateShippingAddress(value, model) {
        // Only require shipping address if shipping_method is not "pickup"
        if (arguments.model.shipping_method == "pickup") {
            return true;  // Skip validation
        }

        // Require address for delivery
        return len(trim(arguments.value)) > 0;
    }
}
```

Common conditional patterns:
- **When conditions**: Validate only when specific field has value
- **Unless conditions**: Validate unless condition is met
- **Complex logic**: Multiple conditions combined

See [Custom Validators](../advanced/custom-validators.md) for advanced conditional validation patterns.

## Example: Complete Model with Validations

```cfml
/**
 * User Model with comprehensive validations
 */
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Email validations
        this.validates("email", {
            required: true,
            email: true,
            unique: true
        });

        // Name validations
        this.validates("name", {
            required: true,
            length: {min: 2, max: 100}
        });

        // Username validations
        this.validates("username", {
            required: true,
            length: {min: 3, max: 20},
            unique: true,
            format: {pattern: "^[a-zA-Z0-9_]+$"}
        });

        // Age validations
        this.validates("age", {
            numeric: true,
            range: {min: 18, max: 120}
        });

        // Role validations
        this.validates("role", {
            required: true,
            in: {list: ["admin", "member", "guest"]}
        });

        // Password confirmation
        this.validates("password", {
            required: true,
            length: {min: 8},
            confirmation: true
        });

        return this;
    }
}
```

Usage with error handling:

```cfml
// Create user with form data
var user = new User(datasource);
user.assign({
    email: form.email,
    name: form.name,
    username: form.username,
    age: form.age,
    role: form.role,
    password: form.password,
    password_confirmation: form.password_confirmation
});

// Validate and save
if (user.isValid()) {
    user.save();
    // Success - redirect or show confirmation
} else {
    // Validation failed - show errors
    var errors = user.getErrors();

    // Display errors in view
    for (var field in errors) {
        for (var message in errors[field]) {
            writeOutput("<div class='error'>#field# #message#</div>");
        }
    }
}
```

## Anti-Patterns

### Client-Side Only Validation

**Bad:**
```cfml
<!-- Only validate in JavaScript -->
<script>
    function validateForm() {
        if (!email.match(/@/)) {
            alert("Invalid email");
            return false;
        }
    }
</script>
```

**Good:**
```cfml
// Always validate server-side
// app/models/User.cfc
this.validates("email", {required: true, email: true});

// Client-side validation is optional enhancement
```

Client-side validation can be bypassed. Always validate server-side for security.

### Validation Logic in Controllers

**Bad:**
```cfml
// app/handlers/Users.cfc
public function create() {
    if (!isValid("email", form.email)) {
        return "Invalid email";
    }
    if (len(form.name) < 2) {
        return "Name too short";
    }
    // ... more validation
}
```

**Good:**
```cfml
// app/models/User.cfc
this.validates("email", {required: true, email: true});
this.validates("name", {length: {min: 2}});

// app/handlers/Users.cfc
public function create() {
    var user = User::create(form);
    if (user.hasErrors()) {
        return user.getErrors();
    }
}
```

Centralize validation logic in models for reusability and consistency.

### Ignoring Validation Errors

**Bad:**
```cfml
var user = new User(datasource);
user.email = "invalid";
user.save();  // Fails silently
```

**Good:**
```cfml
var user = new User(datasource);
user.email = "invalid";

if (user.save()) {
    // Handle success
} else {
    // Handle validation errors
    var errors = user.getErrors();
    log.error("Validation failed", errors);
}
```

Always check return value of `save()` and handle errors appropriately.

### Validating in Database

**Bad:**
```cfml
// Rely only on database constraints
ALTER TABLE users ADD CONSTRAINT email_unique UNIQUE (email);
```

**Good:**
```cfml
// Use both model validations AND database constraints
// app/models/User.cfc
this.validates("email", {unique: true});

// Migration
table.string("email").unique();
```

Database constraints are last line of defense. Model validations provide better user experience with clear error messages.

### Not Validating Before Updates

**Bad:**
```cfml
var user = User::find(1);
user.email = "invalid";
user.save();  // No validation check
```

**Good:**
```cfml
var user = User::find(1);
user.email = "invalid";

if (!user.isValid()) {
    // Handle validation errors before attempting save
    return user.getErrors();
}
user.save();
```

Validate explicitly before save operations, especially in update scenarios.

## Testing Validations

Test validation rules comprehensively in unit tests:

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

    public function testNameMinLength() {
        variables.user.name = "J";  // Too short

        assertFalse(variables.user.isValid());
        var errors = variables.user.getErrors("name");
        assertMatches("too short", errors[1]);
    }

    public function testMultipleErrors() {
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

    public function testSaveReturnsFalseOnInvalidData() {
        variables.user.email = "invalid";

        var result = variables.user.save();

        assertFalse(result);
        assertTrue(variables.user.hasErrors());
    }
}
```

See [Testing](testing.md) guide for more testing patterns.

## Common Errors

### ValidationException on save()

**Error:** `save()` throws ValidationException when data is invalid.

**Cause:** Attempting to persist invalid model without checking validation.

```cfml
var user = User::create({
    email: "invalid-email"
});
// Throws ValidationException
```

**Solution:** Check validity before saving or handle errors:

```cfml
// Option 1: Check before saving
var user = new User(datasource);
user.email = "invalid-email";

if (user.isValid()) {
    user.save();
} else {
    var errors = user.getErrors();
    // Handle validation errors
}

// Option 2: Check save() return value
if (user.save()) {
    // Success
} else {
    // Validation failed
    var errors = user.getErrors();
}
```

See [Error Reference](../../fuse-planning/error-reference.md#validationexception) for details.

### Unique Validation Failing for Existing Record

**Error:** Unique validation fails when updating existing record.

**Cause:** Unique validator checks all records including the current one.

```cfml
var user = User::find(1);
user.email = user.email;  // Same email
user.save();  // Fails unique validation!
```

**Solution:** Unique validator should exclude current record ID (framework handles this automatically for updates):

```cfml
// Framework automatically excludes current record on update
var user = User::find(1);
user.name = "Updated Name";
user.save();  // Works correctly
```

If issue persists, ensure model has correct primary key set.

### Custom Validator Not Executing

**Error:** Custom validator method doesn't run.

**Cause:** Method name misspelled or not properly registered.

```cfml
// app/models/User.cfc
this.validates("email", {
    custom: "validateEmail"  // Method name
});

// But method is named differently
private function checkEmail(value, model) {
    // Never executes!
}
```

**Solution:** Ensure method name matches exactly:

```cfml
this.validates("email", {
    custom: "validateEmail"
});

private boolean function validateEmail(value, model) {
    // Correct method name
    return len(arguments.value) > 0;
}
```

### Format Validation Pattern Issues

**Error:** Format validation not working as expected.

**Cause:** Regex pattern syntax errors or incorrect escaping.

```cfml
this.validates("phone", {
    format: {pattern: "^\d{3}-\d{3}-\d{4}$"}  // Wrong escaping
});
```

**Solution:** Use proper CFML regex syntax:

```cfml
this.validates("phone", {
    format: {pattern: "^\d{3}-\d{3}-\d{4}$"}
});

// Or use character classes
this.validates("username", {
    format: {pattern: "^[a-zA-Z0-9_]+$"}
});
```

### Validation Errors Not Displaying

**Error:** `getErrors()` returns empty even when validation fails.

**Cause:** Not calling `isValid()` or `save()` before checking errors.

```cfml
var user = new User(datasource);
user.email = "invalid";
var errors = user.getErrors();  // Empty! No validation run yet
```

**Solution:** Call `isValid()` or attempt `save()` first:

```cfml
var user = new User(datasource);
user.email = "invalid";

// Trigger validation
user.isValid();

// Now errors are available
var errors = user.getErrors();
// {email: ["is not a valid email"]}
```

## API Reference

For detailed validation method signatures:

- [Validation Rules](../reference/api-reference.md#validation) - required, email, unique, minLength, maxLength, format
- [Model Validation Methods](../reference/api-reference.md#models-activerecord) - isValid(), hasErrors(), getErrors()
- [ValidationException](../reference/api-reference.md#exceptions) - Exception thrown on save() failure

## Related Topics

- [Models & ORM](models-orm.md) - Model basics and CRUD operations
- [Custom Validators](../advanced/custom-validators.md) - Create custom validation rules
- [Testing](testing.md) - Test validation logic
- [Migrations](migrations.md) - Database constraints and validations
