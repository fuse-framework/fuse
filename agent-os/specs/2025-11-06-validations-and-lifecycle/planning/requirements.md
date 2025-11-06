# Spec Requirements: Validations & Lifecycle

## Initial Description
Implement validation DSL and lifecycle callbacks for ActiveRecord models. Validations prevent invalid data from being saved to database. Callbacks execute custom logic at specific points in model lifecycle (before/after save/create/delete).

## Requirements Discussion

### Approved Design Decisions

**Q1: Validation DSL Syntax**
**Answer:** Field-based `this.validates("email", {required: true, email: true})` - flexible, multiple validators per field

**Q2: Validation Timing**
**Answer:** save() returns boolean (false on failure). No exceptions by default. Add save!(throw: true) option later if needed.

**Q3: Error Collection Structure**
**Answer:** `variables.errors = {email: ["is required", "is not a valid email"]}` with methods:
- `hasErrors()` - boolean
- `getErrors()` - all errors
- `getErrors("email")` - field-specific errors

**Q4: Built-in Validators**
**Answer:**
- required, email, unique, length (min/max), format (regex), numeric, range, in (whitelist), confirmation
- length uses `{min: X, max: Y}` structure
- confirmation for password matching

**Q5: Unique Validator Behavior**
**Answer:**
- Excludes current record on UPDATE (WHERE email = ? AND id != ?)
- Supports scoped uniqueness: `unique: {scope: "team_id"}`

**Q6: Custom Validator Registration**
**Answer:** Both method name strings (reusable) and closures (one-offs)
- String: `this.validates("field", {custom: "myValidatorMethod"})`
- Closure: `this.validates("field", {custom: function(value, model){ return true/false; }})`

**Q7: Lifecycle Callback Registration**
**Answer:** Method name strings only for v1
- `this.beforeSave("myMethod")`
- Closures for later if needed

**Q8: Callback Execution Order**
**Answer:**
- beforeCreate → beforeSave → INSERT/UPDATE → afterSave → afterCreate
- Multiple callbacks chainable (append to array)
- Return false halts execution

**Q9: Callback vs Validation Timing**
**Answer:**
1. Run validations
2. If valid, run beforeSave/beforeCreate
3. Persist to DB
4. Run afterSave/afterCreate
- Callbacks only run on valid data

**Q10: beforeDelete Safety**
**Answer:** Runs just before DELETE executes. Return false prevents deletion.

**Q11: Integration with save()**
**Answer:** Validation errors prevent save() from executing automatically. Add explicit `isValid()` method for manual checking.

**Q12: Validation Scope**
**Answer:** Save-time only for v1. `validateAttribute("email")` for later if needed.

### Existing Code to Reference

**Event System Pattern**: Examine EventService.cfc for interceptor registration patterns to mirror for callbacks.

**ActiveRecord Save/Update/Delete Methods**: Study existing persistence methods in ActiveRecord.cfc to understand integration points for validations and callbacks.

## Existing Codebase Analysis

### EventService.cfc Pattern (Callback Inspiration)

**Key Observations:**
- Uses array storage for listeners: `variables.interceptors[point] = []`
- `registerInterceptor()` appends listener (function/closure) to array
- `trigger()` executes listeners in registration order
- Short-circuits execution when `event.abort = true`
- Validates interceptor point names against whitelist

**Pattern to Mirror for Callbacks:**
- Store callbacks in arrays: `variables.callbacks = {beforeSave: [], afterSave: [], ...}`
- Registration method appends to array: `this.beforeSave("methodName")`
- Execution loops through callbacks in order
- Short-circuit when callback returns false (halt behavior)

### ActiveRecord.cfc Integration Points

**save() method (lines 487-503):**
- Detects INSERT vs UPDATE via `!variables.isPersisted`
- Calls `performInsert()` or `performUpdate()`
- Resets dirty tracking after save
- Returns model instance (needs to change to boolean)

**Validation Integration Points:**
1. **Before performInsert/performUpdate**: Run validations, return false if invalid
2. **Before performInsert/performUpdate**: Run beforeSave/beforeCreate callbacks
3. **After performInsert/performUpdate**: Run afterSave/afterCreate callbacks

**delete() method (lines 528-559):**
- Validates record is persisted
- Executes DELETE query
- Marks as detached
- Returns boolean

**Delete Integration Point:**
1. **Before DELETE query**: Run beforeDelete callbacks, abort if false returned

**update() method (lines 511-521):**
- Merges changes into attributes
- Calls save() to persist
- Returns model instance

**Update Integration Point:**
- Uses existing save() flow, so validations/callbacks run automatically

**Existing Patterns:**
- Uses variables scope for state (`variables.attributes`, `variables.relationships`)
- Private helper methods for complex operations (`performInsert`, `performUpdate`)
- Throws exceptions with structured error types (`ActiveRecord.SaveFailed`)
- Returns model instance for chaining (except delete() returns boolean)

### ModelBuilder.cfc Context

**Eager Loading State (line 67):**
- `variables.eagerLoad = []` - array storage for includes()
- Similar pattern could store validation/callback metadata at class level

**Terminal Methods:**
- `get()` and `first()` overridden in ActiveRecord
- Return model instances, not structs
- Trigger eager loading if configured

## Requirements Summary

### Functional Requirements

**Validation System:**
- Field-based DSL: `this.validates("fieldName", {validator: options})`
- Built-in validators: required, email, unique, length, format, numeric, range, in, confirmation
- Custom validators: method name strings and closures
- Error collection structure: `{fieldName: ["error message", ...]}`
- Error accessor methods: `hasErrors()`, `getErrors()`, `getErrors("field")`
- Unique validator scoping: `unique: {scope: "otherField"}`
- Unique validator excludes current record on UPDATE
- Manual validation check: `isValid()` returns boolean
- Save integration: validations run before persistence, save() returns false if invalid

**Lifecycle Callback System:**
- Callback registration: `this.beforeSave("methodName")`, `this.afterSave("methodName")`
- Available callbacks: beforeSave, afterSave, beforeCreate, afterCreate, beforeDelete, afterDelete
- Multiple callbacks per point (append to array)
- Execution order: beforeCreate → beforeSave → DB operation → afterSave → afterCreate
- Return false halts execution (prevents save/delete)
- Method name strings only (v1), closures for future

**Integration with ActiveRecord:**
- Validations prevent save() execution if errors exist
- save() returns boolean instead of model instance
- Callbacks run only on valid data
- beforeDelete can prevent deletion by returning false
- update() inherits validation/callback behavior from save()

### Reusability Opportunities

**EventService.cfc Pattern:**
- Array-based listener storage
- Registration methods that append to arrays
- Execution with short-circuit support
- Whitelist validation for callback point names

**ActiveRecord.cfc Patterns:**
- Variables scope state management
- Private helper methods for complex logic
- Structured exception throwing
- Method chaining return patterns

**ModelBuilder.cfc Patterns:**
- Metadata storage at class level (similar to eagerLoad array)
- Initialization in init() method

### Scope Boundaries

**In Scope:**
- Validation DSL with built-in validators
- Custom validator support (strings and closures)
- Error collection and accessor methods
- Lifecycle callbacks (6 types: before/after for save/create/delete)
- Integration with save()/update()/delete() methods
- save() returns boolean (breaking change from current instance return)
- isValid() method for manual validation checks
- Unique validator with scope support
- beforeDelete halt behavior

**Out of Scope:**
- Per-attribute validation (validateAttribute("email")) - future enhancement
- save!(throw: true) throwing exceptions on validation failure - future enhancement
- Closure-based callbacks - future enhancement
- Conditional validations (if/unless) - future enhancement
- Custom error messages - v1 uses defaults
- I18n error messages - future enhancement
- Validation contexts (on: [:create, :update]) - future enhancement

### Technical Considerations

**Integration Points:**
- Modify save() to run validations before persistence
- Change save() return type from model instance to boolean
- Insert callback execution before/after performInsert/performUpdate
- Insert beforeDelete callback before DELETE query
- Add callback/validation metadata storage to variables scope
- Follow EventService pattern for callback registration and execution

**Existing System Constraints:**
- Must maintain backward compatibility with relationship system
- Must preserve dirty tracking behavior
- Must work with existing timestamp auto-population
- Must not break existing test suite (will require updates for save() return type change)

**Technology Preferences:**
- Component-based architecture (Validator.cfc, CallbackManager.cfc)
- CFML closures for custom validators
- Array storage for callbacks (matching EventService pattern)
- Struct storage for validations and errors

**Similar Code Patterns to Follow:**
- EventService.cfc: listener registration and execution
- ActiveRecord.cfc: private helper methods, exception handling
- ModelBuilder.cfc: metadata initialization in init()

### Breaking Changes

**save() Return Type:**
- Current: Returns model instance for chaining
- New: Returns boolean (true if saved, false if validation failed)
- Impact: Code like `user.save().reload()` will break
- Migration: Check return value or use update() which can maintain chaining

**update() Behavior:**
- Can maintain instance return for chaining since it calls save() internally
- Or change to boolean for consistency
- Decision: TBD during implementation
