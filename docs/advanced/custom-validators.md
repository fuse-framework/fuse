# Custom Validators

Extend Fuse's validation system with custom validation rules tailored to your application's specific business logic requirements beyond built-in validators.

## Overview

Custom validators enable application-specific validation logic:

```cfml
// app/models/CreditCard.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Use custom validator
        this.validates("card_number", {
            custom: "validateLuhn"
        });

        return this;
    }

    // Custom validator method
    private boolean function validateLuhn(value, model) {
        if (!len(trim(arguments.value))) {
            return true;  // Let required validator handle empty
        }

        // Luhn algorithm for credit card validation
        var digits = reReplace(arguments.value, "[^0-9]", "", "ALL");
        if (len(digits) < 13 || len(digits) > 19) {
            return false;
        }

        var sum = 0;
        var alternate = false;

        for (var i = len(digits); i >= 1; i--) {
            var digit = val(mid(digits, i, 1));

            if (alternate) {
                digit = digit * 2;
                if (digit > 9) {
                    digit = digit - 9;
                }
            }

            sum += digit;
            alternate = !alternate;
        }

        return (sum % 10 == 0);
    }
}
```

```cfml
// Validation in action
var card = new CreditCard(datasource);
card.card_number = "4532-1488-0343-6467";

if (card.isValid()) {
    card.save();  // Valid card number
} else {
    var errors = card.getErrors("card_number");
    // ["is invalid"]
}
```

Custom validators integrate seamlessly with built-in validators and provide application-specific validation logic.

## Creating Custom Validators

### Basic Validator Method

Define private validation method in model:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        this.validates("username", {
            custom: "validateUsername"
        });

        return this;
    }

    /**
     * Validate username format and restrictions
     *
     * @param value The field value to validate
     * @param model The model instance being validated
     * @return Boolean true if valid, false if invalid
     */
    private boolean function validateUsername(value, model) {
        // Empty values skip validation (use required separately)
        if (!len(trim(arguments.value))) {
            return true;
        }

        var username = arguments.value;

        // Check length
        if (len(username) < 3 || len(username) > 20) {
            return false;
        }

        // Check format: alphanumeric and underscore only
        if (!reFind("^[a-zA-Z0-9_]+$", username)) {
            return false;
        }

        // Check reserved usernames
        var reserved = ["admin", "root", "system", "anonymous"];
        if (arrayFindNoCase(reserved, username)) {
            return false;
        }

        return true;
    }
}
```

**Validator method signature:**
- **Parameters**: `value` (field value), `model` (ActiveRecord instance)
- **Returns**: Boolean - `true` if valid, `false` if invalid
- **Access**: Private method in model component

### Validator Return Values

Custom validators return boolean:

```cfml
private boolean function myValidator(value, model) {
    // Return true if valid
    if (meetsRequirements(arguments.value)) {
        return true;
    }

    // Return false if invalid
    return false;
}
```

**Validation result:**
- `true` = passes validation, no error added
- `false` = fails validation, generic error message added

## Validator Registration

### Registration Pattern

Register custom validators in model `init()`:

```cfml
// app/models/Product.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        // Combine with built-in validators
        this.validates("sku", {
            required: true,
            custom: "validateSKU"
        });

        this.validates("price", {
            required: true,
            numeric: true,
            custom: "validatePrice"
        });

        return this;
    }

    private boolean function validateSKU(value, model) {
        // SKU format: 3 letters, dash, 4 numbers
        return reFind("^[A-Z]{3}-\d{4}$", arguments.value);
    }

    private boolean function validatePrice(value, model) {
        // Price must be positive
        return val(arguments.value) > 0;
    }
}
```

### Multiple Custom Validators

Apply multiple custom validators to same field:

```cfml
// Note: Current implementation supports single custom validator
// For multiple validations, combine logic in one validator method

private boolean function validateEmailDomain(value, model) {
    if (!len(trim(arguments.value))) {
        return true;
    }

    // Multiple checks in one validator
    var email = arguments.value;

    // Check 1: No free email providers
    var freeProviders = ["gmail.com", "yahoo.com", "hotmail.com"];
    var domain = listLast(email, "@");
    if (arrayFindNoCase(freeProviders, domain)) {
        return false;
    }

    // Check 2: Must be corporate domain (.com, .net, .org)
    if (!reFind("\.(com|net|org)$", domain)) {
        return false;
    }

    return true;
}
```

## Validator Parameters

### Accessing Model State

Custom validators receive full model instance:

```cfml
// app/models/Order.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        this.validates("shipping_address", {
            custom: "validateShippingAddress"
        });

        return this;
    }

    private boolean function validateShippingAddress(value, model) {
        // Access other model attributes
        var shippingMethod = arguments.model.shipping_method;

        // Only require address if not pickup
        if (shippingMethod == "pickup") {
            return true;  // Skip validation
        }

        // Require address for delivery
        return len(trim(arguments.value)) > 0;
    }
}
```

**Available model properties:**
```cfml
private boolean function myValidator(value, model) {
    // Access attributes
    var otherField = arguments.model.other_field;

    // Check persistence state
    var isNew = !arguments.model.isPersisted();

    // Access model metadata
    var modelVars = arguments.model.getVariablesScope();
    var tableName = modelVars.tableName;

    return true;
}
```

### Conditional Validation Logic

Implement when/unless conditions in validator:

```cfml
// app/models/User.cfc
private boolean function validatePasswordStrength(value, model) {
    // Only validate if password is being changed
    if (!arguments.model.hasChanged("password")) {
        return true;
    }

    var password = arguments.value;

    // Require strong password for admin users
    if (arguments.model.role == "admin") {
        // Check for uppercase, lowercase, number, special char
        if (!reFind("[A-Z]", password)) return false;
        if (!reFind("[a-z]", password)) return false;
        if (!reFind("[0-9]", password)) return false;
        if (!reFind("[^a-zA-Z0-9]", password)) return false;
    }

    return true;
}
```

### Database Queries in Validators

Execute queries for complex validation:

```cfml
// app/models/BlogPost.cfc
private boolean function validateSlugUniqueness(value, model) {
    if (!len(trim(arguments.value))) {
        return true;
    }

    var modelVars = arguments.model.getVariablesScope();
    var datasource = modelVars.datasource;
    var tableName = modelVars.tableName;

    // Build query to check uniqueness within category
    var sql = "
        SELECT COUNT(*) as count
        FROM #tableName#
        WHERE slug = ?
        AND category_id = ?
    ";
    var params = [arguments.value, arguments.model.category_id];

    // Exclude current record if updating
    if (arguments.model.isPersisted()) {
        sql &= " AND id != ?";
        arrayAppend(params, arguments.model.id);
    }

    var result = queryExecute(sql, params, {datasource: datasource});

    return (result.count == 0);
}
```

## Error Message Customization

### Default Error Messages

Custom validators use generic error message:

```cfml
this.validates("field", {custom: "myValidator"});

// If validation fails, error message is:
// "is invalid"
```

### Custom Error Messages (Pattern)

Implement custom error messages by checking validation in validator and using model error collection:

```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        this.validates("password", {
            custom: "validatePasswordComplexity"
        });

        return this;
    }

    private boolean function validatePasswordComplexity(value, model) {
        if (!len(trim(arguments.value))) {
            return true;
        }

        var password = arguments.value;

        // Note: Custom validators return boolean only
        // For specific error messages, validation logic can be
        // implemented to fail generically, or you can combine
        // with other validators for more specific messages

        // Check minimum requirements
        if (len(password) < 8) {
            return false;  // Error: "is invalid"
        }

        if (!reFind("[A-Z]", password)) {
            return false;  // Error: "is invalid"
        }

        if (!reFind("[0-9]", password)) {
            return false;  // Error: "is invalid"
        }

        return true;
    }
}
```

**Note:** Current implementation uses generic "is invalid" message for custom validators. For field-specific error messages, combine custom validators with built-in validators that have specific messages.

## Example: Credit Card Validator

Complete credit card validation with Luhn algorithm:

```cfml
/**
 * Credit Card Model with Luhn validation
 */
// app/models/Payment.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        this.validates("card_number", {
            required: true,
            custom: "validateCreditCard"
        });

        this.validates("cvv", {
            required: true,
            custom: "validateCVV"
        });

        this.validates("expiry_date", {
            required: true,
            custom: "validateExpiry"
        });

        return this;
    }

    /**
     * Validate credit card number using Luhn algorithm
     */
    private boolean function validateCreditCard(value, model) {
        if (!len(trim(arguments.value))) {
            return true;  // required handles empty
        }

        // Remove spaces and dashes
        var cardNumber = reReplace(arguments.value, "[^0-9]", "", "ALL");

        // Check length (13-19 digits for major cards)
        if (len(cardNumber) < 13 || len(cardNumber) > 19) {
            return false;
        }

        // Luhn algorithm
        var sum = 0;
        var alternate = false;

        for (var i = len(cardNumber); i >= 1; i--) {
            var digit = val(mid(cardNumber, i, 1));

            if (alternate) {
                digit = digit * 2;
                if (digit > 9) {
                    digit = digit - 9;
                }
            }

            sum += digit;
            alternate = !alternate;
        }

        return (sum % 10 == 0);
    }

    /**
     * Validate CVV format (3-4 digits)
     */
    private boolean function validateCVV(value, model) {
        if (!len(trim(arguments.value))) {
            return true;
        }

        var cvv = arguments.value;

        // Must be 3 or 4 digits
        if (!reFind("^\d{3,4}$", cvv)) {
            return false;
        }

        return true;
    }

    /**
     * Validate expiry date is in future
     */
    private boolean function validateExpiry(value, model) {
        if (!len(trim(arguments.value))) {
            return true;
        }

        // Expected format: MM/YY
        if (!reFind("^\d{2}/\d{2}$", arguments.value)) {
            return false;
        }

        var parts = listToArray(arguments.value, "/");
        var month = val(parts[1]);
        var year = val(parts[2]) + 2000;  // Convert YY to YYYY

        // Check valid month
        if (month < 1 || month > 12) {
            return false;
        }

        // Check not expired
        var expiryDate = createDate(year, month, 1);
        var now = now();

        return (expiryDate >= now);
    }
}
```

Usage:

```cfml
var payment = new Payment(datasource);
payment.card_number = "4532-1488-0343-6467";
payment.cvv = "123";
payment.expiry_date = "12/25";

if (payment.isValid()) {
    payment.save();
} else {
    var errors = payment.getErrors();
    // {card_number: ["is invalid"], cvv: ["is invalid"], expiry_date: ["is invalid"]}
}
```

## Example: Phone Number Validator

Validate North American phone numbers:

```cfml
// app/models/Contact.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        this.validates("phone", {
            custom: "validatePhoneNumber"
        });

        return this;
    }

    /**
     * Validate North American phone number format
     * Accepts: (555) 123-4567, 555-123-4567, 5551234567
     */
    private boolean function validatePhoneNumber(value, model) {
        if (!len(trim(arguments.value))) {
            return true;  // Optional field
        }

        var phone = arguments.value;

        // Remove all non-digits
        var digits = reReplace(phone, "[^0-9]", "", "ALL");

        // Must be exactly 10 digits
        if (len(digits) != 10) {
            return false;
        }

        // Area code (first 3 digits) must not start with 0 or 1
        var areaCode = left(digits, 3);
        if (left(areaCode, 1) == "0" || left(areaCode, 1) == "1") {
            return false;
        }

        // Exchange (next 3 digits) must not start with 0 or 1
        var exchange = mid(digits, 4, 3);
        if (left(exchange, 1) == "0" || left(exchange, 1) == "1") {
            return false;
        }

        return true;
    }
}
```

## Example: Business Logic Validator

Domain-specific validation logic:

```cfml
// app/models/Appointment.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        this.validates("scheduled_at", {
            required: true,
            custom: "validateBusinessHours"
        });

        return this;
    }

    /**
     * Validate appointment is during business hours
     * Monday-Friday, 9am-5pm
     */
    private boolean function validateBusinessHours(value, model) {
        if (!len(trim(arguments.value))) {
            return true;
        }

        var appointmentTime = parseDateTime(arguments.value);

        // Check day of week (Monday = 2, Friday = 6)
        var dayOfWeek = dayOfWeek(appointmentTime);
        if (dayOfWeek < 2 || dayOfWeek > 6) {
            return false;  // Weekend
        }

        // Check time (9:00 - 17:00)
        var hour = hour(appointmentTime);
        if (hour < 9 || hour >= 17) {
            return false;  // Outside business hours
        }

        // Check appointment duration doesn't extend past business hours
        var duration = arguments.model.duration_minutes;
        var endTime = dateAdd("n", duration, appointmentTime);
        var endHour = hour(endTime);

        if (endHour > 17 || (endHour == 17 && minute(endTime) > 0)) {
            return false;  // Extends past 5pm
        }

        return true;
    }
}
```

## Example: Cross-Field Validator

Validate relationships between multiple fields:

```cfml
// app/models/Event.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(datasource) {
        super.init(datasource);

        this.validates("end_date", {
            custom: "validateDateRange"
        });

        return this;
    }

    /**
     * Validate end_date is after start_date
     */
    private boolean function validateDateRange(value, model) {
        if (!len(trim(arguments.value))) {
            return true;
        }

        // Access related field
        var startDate = arguments.model.start_date;
        var endDate = parseDateTime(arguments.value);

        if (!len(trim(startDate))) {
            return true;  // Can't validate without start_date
        }

        var parsedStartDate = parseDateTime(startDate);

        // End must be after start
        return (endDate > parsedStartDate);
    }
}
```

## Testing Custom Validators

Test custom validators thoroughly:

```cfml
// tests/models/PaymentTest.cfc
component extends="fuse.testing.TestCase" {

    public function setup() {
        variables.payment = new app.models.Payment(getDatasource());
    }

    public function testValidCreditCard() {
        variables.payment.card_number = "4532-1488-0343-6467";  // Valid

        assertTrue(variables.payment.isValid());
    }

    public function testInvalidCreditCardLuhn() {
        variables.payment.card_number = "4532-1488-0343-6468";  // Invalid Luhn

        assertFalse(variables.payment.isValid());
        var errors = variables.payment.getErrors("card_number");
        assertContains("is invalid", errors[1]);
    }

    public function testInvalidCreditCardLength() {
        variables.payment.card_number = "4532";  // Too short

        assertFalse(variables.payment.isValid());
    }

    public function testValidCVV() {
        variables.payment.cvv = "123";  // Valid 3 digits

        // Only validate CVV field (incomplete model)
        variables.payment.card_number = "4532148803436467";
        variables.payment.expiry_date = "12/25";

        assertTrue(variables.payment.isValid());
    }

    public function testInvalidCVVFormat() {
        variables.payment.cvv = "12A";  // Non-numeric

        variables.payment.card_number = "4532148803436467";
        variables.payment.expiry_date = "12/25";

        assertFalse(variables.payment.isValid());
    }

    public function testExpiredCard() {
        variables.payment.expiry_date = "01/20";  // Expired

        variables.payment.card_number = "4532148803436467";
        variables.payment.cvv = "123";

        assertFalse(variables.payment.isValid());
    }

    public function testFutureExpiryDate() {
        var nextYear = year(now()) + 1;
        var yearShort = right(nextYear, 2);
        variables.payment.expiry_date = "12/" & yearShort;  // Future

        variables.payment.card_number = "4532148803436467";
        variables.payment.cvv = "123";

        assertTrue(variables.payment.isValid());
    }
}
```

## Anti-Patterns

### Returning Strings Instead of Booleans

**Bad:**
```cfml
private function validateField(value, model) {
    if (!isValid(arguments.value)) {
        return "custom error message";  // Wrong type
    }
    return true;
}
```

**Good:**
```cfml
private boolean function validateField(value, model) {
    if (!isValid(arguments.value)) {
        return false;  // Boolean
    }
    return true;
}
```

Custom validators must return boolean values.

### Not Handling Empty Values

**Bad:**
```cfml
private boolean function validateEmail(value, model) {
    // Fails on empty string
    return reFind("@", arguments.value);
}
```

**Good:**
```cfml
private boolean function validateEmail(value, model) {
    // Let required validator handle empty values
    if (!len(trim(arguments.value))) {
        return true;
    }

    return reFind("@", arguments.value);
}
```

Skip validation for empty values unless checking for presence.

### Performing Validation in Controllers

**Bad:**
```cfml
// app/handlers/Payments.cfc
public function create() {
    if (!isValidLuhn(form.card_number)) {
        return {error: "Invalid card"};
    }
    Payment::create(form);
}
```

**Good:**
```cfml
// app/models/Payment.cfc
this.validates("card_number", {custom: "validateLuhn"});

// app/handlers/Payments.cfc
public function create() {
    var payment = Payment::create(form);
    if (payment.hasErrors()) {
        return payment.getErrors();
    }
}
```

Validation logic belongs in models for reusability.

### Complex Logic Without Comments

**Bad:**
```cfml
private boolean function validateX(value, model) {
    var x = arguments.value;
    if (len(x) < 5 || !reFind("^[A-Z]", x) || val(right(x, 2)) < 10) {
        return false;
    }
    return true;
}
```

**Good:**
```cfml
/**
 * Validate product code format:
 * - Minimum 5 characters
 * - Starts with uppercase letter
 * - Last 2 characters are numeric >= 10
 */
private boolean function validateProductCode(value, model) {
    var code = arguments.value;

    // Check minimum length
    if (len(code) < 5) {
        return false;
    }

    // Check starts with uppercase letter
    if (!reFind("^[A-Z]", code)) {
        return false;
    }

    // Check last 2 digits are >= 10
    var suffix = val(right(code, 2));
    if (suffix < 10) {
        return false;
    }

    return true;
}
```

Document validation logic with comments and descriptive names.

## Related Topics

- [Validations](../guides/validations.md) - Built-in validation rules
- [Models & ORM](../guides/models-orm.md) - ActiveRecord basics
- [Testing](../guides/testing.md) - Test validation logic
