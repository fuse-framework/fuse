# Specification: Validations & Lifecycle

## Goal
Add validation DSL and lifecycle callbacks to ActiveRecord models to prevent invalid data persistence and enable custom logic execution at specific points in the model lifecycle.

## User Stories
- As a developer, I want to declare validation rules declaratively using a DSL so that invalid data is automatically prevented from being saved to the database
- As a developer, I want to execute custom logic before/after database operations (save, create, delete) so that I can implement cross-cutting concerns like logging, cache invalidation, and derived attribute calculation

## Specific Requirements

**Validation DSL Registration**
- Models use `this.validates("fieldName", {validator: options})` in init() to register validation rules
- Multiple validators per field supported: `this.validates("email", {required: true, email: true})`
- Validators stored in `variables.validations = {fieldName: [validatorConfigs]}` array structure
- Validation config includes validator type and options: `{type: "required", options: {}}`
- Validators executed in registration order during save()
- Registration happens in init() method after super.init() call

**Built-in Validators**
- `required`: Field must have non-empty value (`required: true`)
- `email`: Field must match email format regex (`email: true`)
- `unique`: Field value must be unique in table (`unique: true` or `unique: {scope: "field"}`)
- `length`: String length constraints (`length: {min: 5, max: 100}`)
- `format`: Field must match regex pattern (`format: /^[A-Z]{3}$/`)
- `numeric`: Field must be numeric type (`numeric: true`)
- `range`: Numeric value must fall within range (`range: {min: 1, max: 100}`)
- `in`: Field value must be in whitelist array (`in: ["option1", "option2"]`)
- `confirmation`: Field must match confirmation field (`confirmation: true` for "password" checks "password_confirmation")

**Unique Validator Scope Behavior**
- Basic unique: queries WHERE field = ? (excludes current record if persisted)
- Scoped unique: queries WHERE field = ? AND scope_field = ? (excludes current record)
- UPDATE queries include AND id != ? to exclude current record from uniqueness check
- INSERT queries omit id exclusion clause
- Example: `unique: {scope: "team_id"}` checks uniqueness within team

**Custom Validators**
- Method name string: `this.validates("field", {custom: "myValidatorMethod"})`
- Custom method signature: `private boolean function myValidatorMethod(value, model)`
- Return true for valid, false for invalid
- Closure support: `this.validates("field", {custom: function(value, model){ return true; }})`
- Custom validators executed after built-in validators for same field

**Error Collection Structure**
- Errors stored in `variables.errors = {fieldName: ["error message 1", "error message 2"]}`
- Multiple error messages per field supported (array)
- Error messages use default templates (e.g., "is required", "is not a valid email")
- Errors cleared at start of each validation run
- Only fields with errors present in errors struct (no empty arrays)

**Error Accessor Methods**
- `hasErrors()`: returns boolean indicating if any validation errors exist
- `getErrors()`: returns complete errors struct `{field: [messages]}`
- `getErrors("fieldName")`: returns array of error messages for specific field or empty array
- `isValid()`: manually triggers validation without persisting, returns boolean
- These methods callable on model instance at any time

**Lifecycle Callback Registration**
- Callbacks registered via method name strings: `this.beforeSave("methodName")`
- Available registration methods: `beforeSave()`, `afterSave()`, `beforeCreate()`, `afterCreate()`, `beforeDelete()`, `afterDelete()`
- Callbacks stored in `variables.callbacks = {beforeSave: [], afterSave: [], ...}` structure
- Multiple callbacks per point append to array (executed in registration order)
- Callback methods must exist on model: `private void function methodName()`
- Registration happens in init() after super.init() and validation registration

**Callback Execution Order**
- INSERT: beforeCreate → beforeSave → INSERT → afterSave → afterCreate
- UPDATE: beforeSave → UPDATE → afterSave
- DELETE: beforeDelete → DELETE → afterDelete
- Callbacks only execute if validations pass (except delete path)
- Return false from before* callbacks halts execution and prevents persistence
- After* callbacks execute after successful persistence (cannot halt)

**Integration with save() Method**
- save() returns boolean instead of model instance (breaking change)
- Execution order: 1) run validations, 2) return false if invalid, 3) run before callbacks, 4) return false if callback halts, 5) persist to DB, 6) run after callbacks, 7) return true
- save() populates variables.errors on validation failure
- Caller checks return value: `if (user.save()) { /* success */ } else { /* validation failed */ }`
- Dirty tracking reset only occurs on successful save

**Integration with update() Method**
- update() merges changes into attributes, then calls save()
- Inherits validation and callback behavior from save()
- Returns boolean like save() (breaking change for consistency)
- Validations run against final merged attributes

**Integration with delete() Method**
- delete() executes beforeDelete callbacks before DELETE query
- Return false from beforeDelete halts deletion and returns false
- afterDelete callbacks execute after successful DELETE
- Maintains existing exception behavior for non-persisted records
- Returns boolean (already implemented this way)

**Validator Component Architecture**
- Create `fuse/orm/Validator.cfc` component to encapsulate validation logic
- Validator.validate(model) method executes all validators and populates errors
- Built-in validators implemented as private methods in Validator.cfc
- Validator.cfc injected or instantiated in ActiveRecord during validation run
- Stateless design: validator receives model and returns errors struct

**CallbackManager Component Architecture**
- Create `fuse/orm/CallbackManager.cfc` to manage callback execution
- Follows EventService.cfc pattern for registration and triggering
- executeCallbacks(model, callbackPoint) executes callbacks in order with short-circuit
- Validates callback method existence before execution
- Returns boolean indicating whether to continue (false = halted by callback)

## Visual Design
No visual assets provided for this feature.

## Existing Code to Leverage

**EventService.cfc callback pattern (lines 8-88)**
- Array storage for listeners: `variables.interceptors[point] = []`
- Registration appends to array: `arrayAppend(variables.interceptors[point], listener)`
- Trigger executes in order with short-circuit when abort flag set
- Whitelist validation for point names prevents invalid registrations
- Replicate this pattern for callback registration and execution in CallbackManager.cfc

**ActiveRecord.cfc save() method (lines 487-503)**
- Current: detects INSERT/UPDATE, calls performInsert/performUpdate, resets dirty tracking, returns model instance
- Modify: add validation check before persistence, change return type to boolean
- Insert callback execution before performInsert/performUpdate (before*)
- Insert callback execution after performInsert/performUpdate (after*)
- Return false if validations fail or before* callback returns false

**ActiveRecord.cfc delete() method (lines 528-559)**
- Current: validates persistence, executes DELETE, marks detached, returns boolean
- Modify: add beforeDelete callback execution after persistence check
- Add afterDelete callback execution after successful DELETE
- Return false if beforeDelete callback returns false (halt execution)

**ActiveRecord.cfc init() method (lines 59-100)**
- Initialize validation and callback storage: `variables.validations = {}`, `variables.callbacks = {}`
- Initialize errors storage: `variables.errors = {}`
- Follows existing pattern of variables scope initialization
- Callback and validation methods called in child class init() after super.init()

**ActiveRecord.cfc variables scope patterns**
- attributes, original, isPersisted for state management
- relationships for metadata storage
- Follow same pattern for validations, callbacks, errors storage
- Private helper methods for complex operations (performInsert, performUpdate)

## Out of Scope
- Per-attribute validation (validateAttribute("email")) for validating single field - future enhancement
- save!(throw: true) option that throws exceptions on validation failure - future enhancement
- Closure-based callback registration - v1 supports method name strings only
- Conditional validations (if/unless options) - future enhancement
- Custom error messages via validator options - v1 uses default messages only
- I18n/localization of error messages - future enhancement
- Validation contexts (on: [:create, :update]) to conditionally apply validators - future enhancement
- Validation groups or sets for validating subsets of fields
- async/deferred validation execution
- Transaction rollback on after* callback failure (after* callbacks cannot halt)
