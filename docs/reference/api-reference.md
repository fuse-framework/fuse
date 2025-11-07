# API Reference

Complete API documentation for Fuse framework. This document provides human-readable reference for all framework methods and features.

**Note:** The canonical machine-readable API reference is in `/fuse-planning/api-reference.yaml`. AI agents should read the YAML directly for structured data. This markdown document is generated from the YAML for human readability.

## Table of Contents

- [Models (ActiveRecord)](#models-activerecord)
  - [Static Query Methods](#static-query-methods)
  - [Instance Methods](#instance-methods)
  - [Relationship Methods](#relationship-methods)
- [QueryBuilder](#querybuilder)
  - [Query Conditions](#query-conditions)
  - [Ordering & Limiting](#ordering--limiting)
  - [Joins](#joins)
  - [Execution Methods](#execution-methods)
- [ModelBuilder (ORM)](#modelbuilder-orm)
  - [Eager Loading](#eager-loading)
  - [ORM Execution Methods](#orm-execution-methods)
- [Validation](#validation)
  - [Validation Rules](#validation-rules)
- [Router](#router)
  - [Route Registration](#route-registration)
- [Transaction](#transaction)
  - [Transaction Methods](#transaction-methods)
- [WHERE Operators](#where-operators)
- [Exceptions](#exceptions)
- [Conventions](#conventions)

---

## Models (ActiveRecord)

ActiveRecord models extend `fuse.orm.ActiveRecord` and provide ORM functionality for database persistence.

**Base class:** `fuse.orm.ActiveRecord`

**Example:**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    // Conventions: table=users, primaryKey=id
}
```

### Static Query Methods

Static methods called on the model class for querying and creating records.

#### find()

Find a record by primary key.

**Signature:** `Model.find(id)`

**Parameters:**

| Parameter | Type             | Required | Description              |
|-----------|------------------|----------|--------------------------|
| `id`      | numeric\|string  | Yes      | Primary key value        |

**Returns:** `Model|null` - Model instance or null if not found

**Throws:** None

**Execution:** Immediate (executes query)

**Example:**
```cfml
// app/handlers/UsersHandler.cfc
var user = User.find(1);
if (!isNull(user)) {
    writeOutput(user.name);
}
```

**Related Methods:** [findOrFail()](#findorfail), [where()](#where)

---

#### findOrFail()

Find a record by primary key or throw exception.

**Signature:** `Model.findOrFail(id)`

**Parameters:**

| Parameter | Type             | Required | Description              |
|-----------|------------------|----------|--------------------------|
| `id`      | numeric\|string  | Yes      | Primary key value        |

**Returns:** `Model` - Model instance (never null)

**Throws:** `ModelNotFoundException` - If record not found

**Execution:** Immediate (executes query)

**Example:**
```cfml
// app/handlers/UsersHandler.cfc
try {
    var user = User.findOrFail(params.id);
    return {user: user};
} catch (ModelNotFoundException e) {
    response.status(404);
    return {error: "User not found"};
}
```

**Related Methods:** [find()](#find)

---

#### where()

Build WHERE conditions for querying records. Chainable query builder method.

**Signatures:**

**1. Hash syntax:**
```cfml
Model.where(criteria)
```

**2. Column/value syntax:**
```cfml
Model.where(column, value)
```

**3. Column/operator/value syntax:**
```cfml
Model.where(column, operator, value)
```

**Parameters:**

| Parameter  | Type   | Required | Description                              |
|------------|--------|----------|------------------------------------------|
| `criteria` | struct | Varies   | Hash of column:value conditions          |
| `column`   | string | Varies   | Column name                              |
| `operator` | string | No       | Comparison operator (=, >=, <, etc.)     |
| `value`    | any    | Varies   | Value to compare                         |

**Returns:** `ModelBuilder` - Chainable query builder

**Throws:** None

**Execution:** Lazy (doesn't execute until `.get()`, `.first()`, etc.)

**Examples:**
```cfml
// Hash syntax
var activeUsers = User.where({active: true}).get();

// Column/value syntax
var john = User.where('email', 'john@test.com').first();

// Column/operator/value syntax
var adults = User.where('age', '>=', 18).get();

// Chaining conditions
var results = User.where({active: true})
                  .where('age', '>=', 18)
                  .orderBy('name')
                  .limit(10)
                  .get();
```

**Related Methods:** [find()](#find), [all()](#all), [QueryBuilder.where()](#where-1)

---

#### all()

Get query builder for all records.

**Signature:** `Model.all()`

**Parameters:** None

**Returns:** `ModelBuilder` - Query builder for all records

**Throws:** None

**Execution:** Lazy (doesn't execute until terminal method)

**Example:**
```cfml
// Get all users
var users = User.all().get();

// Chain with other methods
var activeUsers = User.all()
                      .where({active: true})
                      .orderBy('created_at', 'DESC')
                      .get();
```

**Related Methods:** [where()](#where), [query()](#query)

---

#### create()

Create and save a new record in one operation.

**Signature:** `Model.create(attributes)`

**Parameters:**

| Parameter    | Type   | Required | Description                    |
|--------------|--------|----------|--------------------------------|
| `attributes` | struct | Yes      | Hash of attribute values       |

**Returns:** `Model` - The created model instance

**Throws:** `ValidationException` - If validation fails

**Execution:** Immediate (INSERTs to database)

**Example:**
```cfml
// app/handlers/UsersHandler.cfc
try {
    var user = User.create({
        name: "John Doe",
        email: "john@example.com",
        age: 30
    });
    return {user: user};
} catch (ValidationException e) {
    return {errors: e.errors};
}
```

**Related Methods:** [save()](#save), [update()](#update)

---

#### query()

Get a new query builder instance for advanced queries.

**Signature:** `Model.query()`

**Parameters:** None

**Returns:** `ModelBuilder` - Fresh query builder

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
// Complex query
var users = User.query()
                .where('age', '>=', 18)
                .whereIn('status', ['active', 'pending'])
                .orderBy('created_at', 'DESC')
                .limit(50)
                .get();
```

**Related Methods:** [where()](#where), [all()](#all)

---

### Instance Methods

Methods called on model instances for persistence and attribute access.

#### save()

Save the model to the database (INSERT or UPDATE).

**Signature:** `modelInstance.save()`

**Parameters:** None

**Returns:** `boolean` - True if saved successfully

**Throws:** `ValidationException` - If validation fails

**Execution:** Immediate (writes to database)

**Example:**
```cfml
// Create new record
var user = new User(datasource);
user.name = "Jane Doe";
user.email = "jane@example.com";
var saved = user.save();

// Update existing record
var user = User.find(1);
user.name = "Jane Updated";
user.save();
```

**Related Methods:** [create()](#create), [update()](#update-1)

---

#### update()

Update model attributes and save in one operation.

**Signature:** `modelInstance.update(attributes)`

**Parameters:**

| Parameter    | Type   | Required | Description                    |
|--------------|--------|----------|--------------------------------|
| `attributes` | struct | Yes      | Hash of attributes to update   |

**Returns:** `boolean` - True if updated successfully

**Throws:** `ValidationException` - If validation fails

**Execution:** Immediate (UPDATEs database)

**Example:**
```cfml
var user = User.find(1);
user.update({
    name: "Updated Name",
    email: "newemail@example.com"
});
```

**Related Methods:** [save()](#save), [create()](#create)

---

#### delete()

Delete the record from the database.

**Signature:** `modelInstance.delete()`

**Parameters:** None

**Returns:** `boolean` - True if deleted successfully

**Throws:** None

**Execution:** Immediate (DELETEs from database)

**Example:**
```cfml
var user = User.find(1);
user.delete();

// Or inline
User.find(1).delete();
```

**Related Methods:** [save()](#save)

---

#### get()

Get an attribute value from the model.

**Signature:** `modelInstance.get(key)`

**Parameters:**

| Parameter | Type   | Required | Description          |
|-----------|--------|----------|----------------------|
| `key`     | string | Yes      | Attribute name       |

**Returns:** `any|null` - Attribute value or null

**Throws:** None

**Execution:** Immediate

**Example:**
```cfml
var user = User.find(1);
var email = user.get('email');
var name = user.get('name');
```

**Related Methods:** [set()](#set)

---

#### set()

Set an attribute value on the model.

**Signature:** `modelInstance.set(key, value)`

**Parameters:**

| Parameter | Type   | Required | Description          |
|-----------|--------|----------|----------------------|
| `key`     | string | Yes      | Attribute name       |
| `value`   | any    | Yes      | Value to set         |

**Returns:** `Model` - Returns this for chaining

**Throws:** None

**Execution:** Immediate (in-memory only, doesn't save)

**Example:**
```cfml
var user = new User(datasource);
user.set('name', 'John Doe')
    .set('email', 'john@example.com')
    .save();
```

**Related Methods:** [get()](#get), [save()](#save)

---

#### hasErrors()

Check if the model has validation errors.

**Signature:** `modelInstance.hasErrors()`

**Parameters:** None

**Returns:** `boolean` - True if errors exist

**Throws:** None

**Execution:** Immediate

**Example:**
```cfml
var user = new User(datasource);
user.email = "invalid";
user.save();

if (user.hasErrors()) {
    return {errors: user.getErrors()};
}
```

**Related Methods:** [getErrors()](#geterrors), [isValid()](#isvalid)

---

#### getErrors()

Get validation errors for the model or a specific field.

**Signature:** `modelInstance.getErrors([field])`

**Parameters:**

| Parameter | Type   | Required | Description                           |
|-----------|--------|----------|---------------------------------------|
| `field`   | string | No       | Specific field to get errors for      |

**Returns:** `array|struct` - Array of errors for field, or struct of all errors

**Throws:** None

**Execution:** Immediate

**Example:**
```cfml
var user = new User(datasource);
user.save(); // Fails validation

// Get all errors
var allErrors = user.getErrors();
// {email: ["Email is required"], name: ["Name is required"]}

// Get field-specific errors
var emailErrors = user.getErrors("email");
// ["Email is required"]
```

**Related Methods:** [hasErrors()](#haserrors)

---

### Relationship Methods

Methods for defining model relationships. Called in model initialization.

#### hasMany()

Define a one-to-many relationship.

**Signature:** `hasMany(name, [options])`

**Parameters:**

| Parameter | Type   | Required | Description                              |
|-----------|--------|----------|------------------------------------------|
| `name`    | string | Yes      | Relationship name (pluralized)           |
| `options` | struct | No       | Custom foreignKey, model name, etc.      |

**Returns:** `void`

**Throws:** None

**Execution:** Immediate (during model initialization)

**Example:**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(required datasource) {
        super.init(datasource);

        // User has many posts
        hasMany('posts');

        // With custom options
        hasMany('articles', {
            foreignKey: 'author_id',
            model: 'Post'
        });
    }
}

// Usage
var user = User.find(1);
var posts = user.posts; // Returns array of Post models
```

**Related Methods:** [belongsTo()](#belongsto), [hasOne()](#hasone)

---

#### belongsTo()

Define a many-to-one relationship.

**Signature:** `belongsTo(name, [options])`

**Parameters:**

| Parameter | Type   | Required | Description                              |
|-----------|--------|----------|------------------------------------------|
| `name`    | string | Yes      | Relationship name (singular)             |
| `options` | struct | No       | Custom foreignKey, model name, etc.      |

**Returns:** `void`

**Throws:** None

**Execution:** Immediate (during model initialization)

**Example:**
```cfml
// app/models/Post.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(required datasource) {
        super.init(datasource);

        // Post belongs to user
        belongsTo('user');

        // With custom options
        belongsTo('author', {
            foreignKey: 'author_id',
            model: 'User'
        });
    }
}

// Usage
var post = Post.find(1);
var user = post.user; // Returns User model
```

**Related Methods:** [hasMany()](#hasmany), [hasOne()](#hasone)

---

#### hasOne()

Define a one-to-one relationship.

**Signature:** `hasOne(name, [options])`

**Parameters:**

| Parameter | Type   | Required | Description                              |
|-----------|--------|----------|------------------------------------------|
| `name`    | string | Yes      | Relationship name (singular)             |
| `options` | struct | No       | Custom foreignKey, model name, etc.      |

**Returns:** `void`

**Throws:** None

**Execution:** Immediate (during model initialization)

**Example:**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function init(required datasource) {
        super.init(datasource);

        // User has one profile
        hasOne('profile');
    }
}

// Usage
var user = User.find(1);
var profile = user.profile; // Returns Profile model
```

**Related Methods:** [hasMany()](#hasmany), [belongsTo()](#belongsto)

---

## QueryBuilder

Database-agnostic query builder for constructing SQL queries. Used internally by ModelBuilder but can be used directly for raw queries.

**Base class:** `fuse.database.QueryBuilder`

### Query Conditions

Methods for adding WHERE conditions to queries.

#### where()

Add WHERE condition to query.

**Signature:** `builder.where(criteria, [operator], [value])`

**Parameters:**

| Parameter  | Type         | Required | Description                         |
|------------|--------------|----------|-------------------------------------|
| `criteria` | struct\|string | Yes    | Hash of conditions or column name   |
| `operator` | string       | No       | Comparison operator (default: "=")  |
| `value`    | any          | No       | Value to compare                    |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
// Hash syntax
builder.where({active: true, verified: true});

// Column/value
builder.where('status', 'active');

// Column/operator/value
builder.where('age', '>=', 18);
```

**Related Methods:** [whereIn()](#wherein), [whereNull()](#wherenull), [whereRaw()](#whereraw)

---

#### whereIn()

Add WHERE IN condition.

**Signature:** `builder.whereIn(column, values)`

**Parameters:**

| Parameter | Type   | Required | Description              |
|-----------|--------|----------|--------------------------|
| `column`  | string | Yes      | Column name              |
| `values`  | array  | Yes      | Array of values          |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.whereIn('status', ['active', 'pending', 'verified']);
builder.whereIn('id', [1, 2, 3, 4, 5]);
```

**Related Methods:** [where()](#where-1), [whereNotIn()](#wherenotin)

---

#### whereNull()

Add WHERE column IS NULL condition.

**Signature:** `builder.whereNull(column)`

**Parameters:**

| Parameter | Type   | Required | Description              |
|-----------|--------|----------|--------------------------|
| `column`  | string | Yes      | Column name              |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.whereNull('deleted_at'); // Soft delete check
builder.whereNull('verified_at'); // Unverified users
```

**Related Methods:** [whereNotNull()](#wherenotnull), [where()](#where-1)

---

#### whereNotNull()

Add WHERE column IS NOT NULL condition.

**Signature:** `builder.whereNotNull(column)`

**Parameters:**

| Parameter | Type   | Required | Description              |
|-----------|--------|----------|--------------------------|
| `column`  | string | Yes      | Column name              |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.whereNotNull('email'); // Has email
builder.whereNotNull('verified_at'); // Verified users
```

**Related Methods:** [whereNull()](#wherenull), [where()](#where-1)

---

#### whereRaw()

Add raw WHERE clause with optional parameter bindings.

**Signature:** `builder.whereRaw(sql, [bindings])`

**Parameters:**

| Parameter  | Type   | Required | Description                      |
|------------|--------|----------|----------------------------------|
| `sql`      | string | Yes      | Raw SQL WHERE clause             |
| `bindings` | array  | No       | Parameter values (default: [])   |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.whereRaw('age > ?', [18]);
builder.whereRaw('YEAR(created_at) = ?', [2024]);
builder.whereRaw('name LIKE ?', ['%john%']);
```

**Related Methods:** [where()](#where-1)

---

### Ordering & Limiting

Methods for ordering, limiting, and offsetting query results.

#### orderBy()

Add ORDER BY clause.

**Signature:** `builder.orderBy(column, [direction])`

**Parameters:**

| Parameter   | Type   | Required | Description                         |
|-------------|--------|----------|-------------------------------------|
| `column`    | string | Yes      | Column to order by                  |
| `direction` | string | No       | "ASC" or "DESC" (default: "ASC")    |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.orderBy('created_at', 'DESC');
builder.orderBy('name'); // ASC by default
builder.orderBy('age', 'DESC').orderBy('name'); // Multiple orders
```

**Related Methods:** [limit()](#limit), [offset()](#offset)

---

#### limit()

Add LIMIT clause.

**Signature:** `builder.limit(value)`

**Parameters:**

| Parameter | Type    | Required | Description                  |
|-----------|---------|----------|------------------------------|
| `value`   | numeric | Yes      | Maximum number of results    |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.limit(10); // First 10 results
builder.orderBy('created_at', 'DESC').limit(5); // 5 most recent
```

**Related Methods:** [offset()](#offset), [orderBy()](#orderby)

---

#### offset()

Add OFFSET clause (skip first N results).

**Signature:** `builder.offset(value)`

**Parameters:**

| Parameter | Type    | Required | Description                  |
|-----------|---------|----------|------------------------------|
| `value`   | numeric | Yes      | Number of results to skip    |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
// Pagination: page 2, 10 per page
builder.limit(10).offset(10);

// Page 3
builder.limit(10).offset(20);
```

**Related Methods:** [limit()](#limit), [orderBy()](#orderby)

---

### Joins

Methods for joining tables.

#### join()

Add INNER JOIN clause.

**Signature:** `builder.join(table, first, [operator], second)`

**Parameters:**

| Parameter  | Type   | Required | Description                          |
|------------|--------|----------|--------------------------------------|
| `table`    | string | Yes      | Table to join                        |
| `first`    | string | Yes      | First column (usually main table)    |
| `operator` | string | No       | Comparison operator (default: "=")   |
| `second`   | string | Yes      | Second column (joined table)         |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.join('posts', 'users.id', '=', 'posts.user_id');
builder.join('comments', 'posts.id', 'comments.post_id'); // = assumed
```

**Related Methods:** [leftJoin()](#leftjoin)

---

#### leftJoin()

Add LEFT JOIN clause.

**Signature:** `builder.leftJoin(table, first, [operator], second)`

**Parameters:**

| Parameter  | Type   | Required | Description                          |
|------------|--------|----------|--------------------------------------|
| `table`    | string | Yes      | Table to join                        |
| `first`    | string | Yes      | First column (usually main table)    |
| `operator` | string | No       | Comparison operator (default: "=")   |
| `second`   | string | Yes      | Second column (joined table)         |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
// Include users even without posts
builder.leftJoin('posts', 'users.id', '=', 'posts.user_id');
```

**Related Methods:** [join()](#join)

---

#### select()

Specify columns to SELECT.

**Signature:** `builder.select(columns)`

**Parameters:**

| Parameter | Type          | Required | Description                       |
|-----------|---------------|----------|-----------------------------------|
| `columns` | array\|string | Yes      | Column names to select            |

**Returns:** `QueryBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
builder.select(['id', 'name', 'email']);
builder.select('id, name, email'); // String also works
```

**Related Methods:** [where()](#where-1), [join()](#join)

---

### Execution Methods

Terminal methods that execute the query and return results.

#### get()

Execute query and return all results.

**Signature:** `builder.get()`

**Parameters:** None

**Returns:** `array` - Array of structs (raw results)

**Throws:** None

**Execution:** Immediate (executes SQL)

**Example:**
```cfml
var results = builder
    .where({active: true})
    .orderBy('created_at', 'DESC')
    .get();

for (var row in results) {
    writeOutput(row.name);
}
```

**Related Methods:** [first()](#first-1), [count()](#count)

---

#### first()

Execute query and return first result only.

**Signature:** `builder.first()`

**Parameters:** None

**Returns:** `struct|null` - First result or null if none

**Throws:** None

**Execution:** Immediate (executes SQL with LIMIT 1)

**Example:**
```cfml
var result = builder
    .where('email', 'john@example.com')
    .first();

if (!isNull(result)) {
    writeOutput(result.name);
}
```

**Related Methods:** [get()](#get-1), [findOrFail()](#findorfail-1)

---

#### count()

Execute COUNT(*) query and return number of matching records.

**Signature:** `builder.count()`

**Parameters:** None

**Returns:** `numeric` - Count of records

**Throws:** None

**Execution:** Immediate (executes SQL)

**Example:**
```cfml
var activeCount = builder.where({active: true}).count();
var totalUsers = User.query().count();
```

**Related Methods:** [exists()](#exists), [get()](#get-1)

---

#### exists()

Check if any records exist matching the query.

**Signature:** `builder.exists()`

**Parameters:** None

**Returns:** `boolean` - True if records exist

**Throws:** None

**Execution:** Immediate (executes SQL)

**Example:**
```cfml
var hasActiveUsers = User.query().where({active: true}).exists();

if (builder.where('email', params.email).exists()) {
    throw(type="ValidationError", message="Email already exists");
}
```

**Related Methods:** [count()](#count), [first()](#first-1)

---

#### pluck()

Get array of values for a single column.

**Signature:** `builder.pluck(column)`

**Parameters:**

| Parameter | Type   | Required | Description                  |
|-----------|--------|----------|------------------------------|
| `column`  | string | Yes      | Column to extract values from |

**Returns:** `array` - Array of column values

**Throws:** None

**Execution:** Immediate (executes SQL)

**Example:**
```cfml
var emails = User.query().where({active: true}).pluck('email');
// ["john@example.com", "jane@example.com", ...]

var ids = Post.query().where({published: true}).pluck('id');
// [1, 5, 12, 23, ...]
```

**Related Methods:** [get()](#get-1)

---

## ModelBuilder (ORM)

ORM-specific query builder that extends QueryBuilder with model instantiation and eager loading.

**Base class:** `fuse.orm.ModelBuilder`

**Extends:** `QueryBuilder`

### Eager Loading

Methods for loading related models to prevent N+1 query problems.

#### includes()

Eager load relationships to prevent N+1 queries.

**Signature:** `builder.includes(relationships)`

**Parameters:**

| Parameter       | Type                 | Required | Description                        |
|-----------------|----------------------|----------|------------------------------------|
| `relationships` | string\|array\|struct | Yes     | Relationship(s) to eager load      |

**Returns:** `ModelBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Examples:**
```cfml
// Single relationship
var users = User.query().includes('posts').get();

// Multiple relationships (array)
var users = User.query().includes(['posts', 'comments']).get();

// Multiple relationships (string)
var users = User.query().includes('posts, comments').get();

// Nested relationships (struct)
var users = User.query().includes({
    posts: ['comments', 'tags']
}).get();
```

**Related Methods:** [with()](#with), Model [hasMany()](#hasmany)

---

#### with()

Alias for `includes()`. Use for eager loading relationships.

**Signature:** `builder.with(relationships)`

**Parameters:**

| Parameter       | Type                 | Required | Description                        |
|-----------------|----------------------|----------|------------------------------------|
| `relationships` | string\|array\|struct | Yes     | Relationship(s) to eager load      |

**Returns:** `ModelBuilder` - For chaining

**Throws:** None

**Execution:** Lazy

**Example:**
```cfml
var users = User.query().with('posts', 'comments').get();
```

**Related Methods:** [includes()](#includes)

---

### ORM Execution Methods

ModelBuilder overrides QueryBuilder execution methods to return model instances instead of raw structs.

#### get()

Execute query and return array of model instances.

**Signature:** `builder.get()`

**Parameters:** None

**Returns:** `array<Model>` - Array of model instances

**Throws:** None

**Execution:** Immediate (executes SQL)

**Example:**
```cfml
var users = User.query()
    .where({active: true})
    .includes('posts')
    .get();

for (var user in users) {
    writeOutput(user.name); // Model method
    writeOutput(user.posts.len()); // Loaded relationship
}
```

**Related Methods:** [first()](#first-2), [count()](#count)

---

#### first()

Execute query and return first model instance.

**Signature:** `builder.first()`

**Parameters:** None

**Returns:** `Model|null` - First model or null

**Throws:** None

**Execution:** Immediate (executes SQL)

**Example:**
```cfml
var user = User.query()
    .where('email', 'john@example.com')
    .first();

if (!isNull(user)) {
    writeOutput(user.name);
}
```

**Related Methods:** [get()](#get-2), [findOrFail()](#findorfail-1)

---

#### findOrFail()

Find by ID or throw exception.

**Signature:** `builder.findOrFail(id)`

**Parameters:**

| Parameter | Type             | Required | Description              |
|-----------|------------------|----------|--------------------------|
| `id`      | numeric\|string  | Yes      | Primary key value        |

**Returns:** `Model` - Model instance (never null)

**Throws:** `ModelNotFoundException` - If not found

**Execution:** Immediate (executes SQL)

**Example:**
```cfml
var user = User.query().includes('posts').findOrFail(params.id);
```

**Related Methods:** [first()](#first-2), Model [findOrFail()](#findorfail)

---

#### create()

Create and save new model instance.

**Signature:** `builder.create(attributes)`

**Parameters:**

| Parameter    | Type   | Required | Description                    |
|--------------|--------|----------|--------------------------------|
| `attributes` | struct | Yes      | Hash of attribute values       |

**Returns:** `Model` - Created model instance

**Throws:** `ValidationException` - If validation fails

**Execution:** Immediate (INSERTs to database)

**Example:**
```cfml
var user = User.query().create({
    name: "John Doe",
    email: "john@example.com"
});
```

**Related Methods:** Model [create()](#create), Model [save()](#save)

---

## Validation

Validation rules for model attributes. Defined in model's `validations()` method.

**Example:**
```cfml
// app/models/User.cfc
component extends="fuse.orm.ActiveRecord" {

    public function validations() {
        validates('email', {required: true, email: true, unique: true});
        validates('password', {required: true, minLength: 8});
        validates('name', {required: true, maxLength: 100});
    }
}
```

### Validation Rules

#### required

Field must not be empty (null, empty string, or whitespace).

**Parameters:**

| Parameter | Type   | Required | Description                     |
|-----------|--------|----------|---------------------------------|
| `message` | string | No       | Custom error message            |

**Example:**
```cfml
validates('email', {required: true});
validates('email', {required: {message: "Email is mandatory"}});
```

---

#### email

Field must be a valid email address format.

**Parameters:**

| Parameter | Type   | Required | Description                     |
|-----------|--------|----------|---------------------------------|
| `message` | string | No       | Custom error message            |

**Example:**
```cfml
validates('email', {email: true});
validates('contact_email', {email: {message: "Invalid email format"}});
```

---

#### unique

Field value must be unique in the table.

**Parameters:**

| Parameter | Type   | Required | Description                     |
|-----------|--------|----------|---------------------------------|
| `message` | string | No       | Custom error message            |

**Example:**
```cfml
validates('email', {unique: true});
validates('username', {unique: {message: "Username taken"}});
```

---

#### minLength

Field must be at least N characters long.

**Parameters:**

| Parameter | Type    | Required | Description                     |
|-----------|---------|----------|---------------------------------|
| `value`   | numeric | Yes      | Minimum character count         |
| `message` | string  | No       | Custom error message            |

**Example:**
```cfml
validates('password', {minLength: 8});
validates('password', {minLength: {value: 8, message: "Too short"}});
```

---

#### maxLength

Field must be at most N characters long.

**Parameters:**

| Parameter | Type    | Required | Description                     |
|-----------|---------|----------|---------------------------------|
| `value`   | numeric | Yes      | Maximum character count         |
| `message` | string  | No       | Custom error message            |

**Example:**
```cfml
validates('name', {maxLength: 100});
validates('bio', {maxLength: {value: 500, message: "Bio too long"}});
```

---

#### format

Field must match a regular expression pattern.

**Parameters:**

| Parameter | Type   | Required | Description                     |
|-----------|--------|----------|---------------------------------|
| `regex`   | string | Yes      | Regular expression pattern      |
| `message` | string | No       | Custom error message            |

**Example:**
```cfml
validates('phone', {format: '^\d{10}$'});
validates('zip', {format: {regex: '^\d{5}$', message: "Invalid ZIP"}});
```

---

## Router

HTTP routing service for registering and resolving routes.

**Service:** `fuse.routing.Router`

### Route Registration

#### get()

Register a GET route.

**Signature:** `router.get(pattern, handler)`

**Parameters:**

| Parameter | Type   | Required | Description                          |
|-----------|--------|----------|--------------------------------------|
| `pattern` | string | Yes      | URL pattern (e.g., "/users/:id")     |
| `handler` | string | Yes      | Handler action ("Handler.method")    |

**Returns:** `void`

**Throws:** None

**Example:**
```cfml
// config/routes.cfm
router.get('/users', 'Users.index');
router.get('/users/:id', 'Users.show');
```

**Related Methods:** [post()](#post), [resource()](#resource)

---

#### post()

Register a POST route.

**Signature:** `router.post(pattern, handler)`

**Parameters:**

| Parameter | Type   | Required | Description                          |
|-----------|--------|----------|--------------------------------------|
| `pattern` | string | Yes      | URL pattern                          |
| `handler` | string | Yes      | Handler action ("Handler.method")    |

**Returns:** `void`

**Throws:** None

**Example:**
```cfml
router.post('/users', 'Users.create');
router.post('/login', 'Auth.login');
```

**Related Methods:** [get()](#get-3), [put()](#put), [delete()](#delete-1)

---

#### put()

Register a PUT route.

**Signature:** `router.put(pattern, handler)`

**Parameters:**

| Parameter | Type   | Required | Description                          |
|-----------|--------|----------|--------------------------------------|
| `pattern` | string | Yes      | URL pattern                          |
| `handler` | string | Yes      | Handler action ("Handler.method")    |

**Returns:** `void`

**Throws:** None

**Example:**
```cfml
router.put('/users/:id', 'Users.update');
```

**Related Methods:** [post()](#post), [delete()](#delete-1)

---

#### delete()

Register a DELETE route.

**Signature:** `router.delete(pattern, handler)`

**Parameters:**

| Parameter | Type   | Required | Description                          |
|-----------|--------|----------|--------------------------------------|
| `pattern` | string | Yes      | URL pattern                          |
| `handler` | string | Yes      | Handler action ("Handler.method")    |

**Returns:** `void`

**Throws:** None

**Example:**
```cfml
router.delete('/users/:id', 'Users.delete');
```

**Related Methods:** [get()](#get-3), [post()](#post), [put()](#put)

---

#### resource()

Register RESTful resource routes (all CRUD routes at once).

**Signature:** `router.resource(name, [callback])`

**Parameters:**

| Parameter  | Type     | Required | Description                          |
|------------|----------|----------|--------------------------------------|
| `name`     | string   | Yes      | Resource name (plural)               |
| `callback` | function | No       | Nested resource configuration        |

**Returns:** `void`

**Throws:** None

**Generated Routes:**

| Method | Path                 | Handler Action | Purpose        |
|--------|----------------------|----------------|----------------|
| GET    | /users               | Users.index    | List all       |
| GET    | /users/:id           | Users.show     | Show one       |
| POST   | /users               | Users.create   | Create new     |
| PUT    | /users/:id           | Users.update   | Update         |
| DELETE | /users/:id           | Users.delete   | Delete         |

**Example:**
```cfml
// Single resource
router.resource('users');

// Nested resources
router.resource('posts', function(router) {
    router.resource('comments');
});
```

**Related Methods:** [get()](#get-3), [post()](#post)

---

#### middleware()

Register named middleware.

**Signature:** `router.middleware(name, handler)`

**Parameters:**

| Parameter | Type   | Required | Description                          |
|-----------|--------|----------|--------------------------------------|
| `name`    | string | Yes      | Middleware name                      |
| `handler` | string | Yes      | Middleware handler component         |

**Returns:** `void`

**Throws:** None

**Example:**
```cfml
router.middleware('auth', 'AuthMiddleware');

// Apply to routes
router.get('/dashboard', 'Dashboard.index').middleware('auth');
```

---

## Transaction

Database transaction management for atomic operations.

**Service:** `fuse.database.Transaction`

### Transaction Methods

#### run()

Run a callback inside a transaction. Automatically commits on success or rolls back on error.

**Signature:** `Transaction.run(callback)`

**Parameters:**

| Parameter  | Type     | Required | Description                          |
|------------|----------|----------|--------------------------------------|
| `callback` | function | Yes      | Function to execute in transaction   |

**Returns:** `any` - Return value of callback

**Throws:** Any exception from callback (after rollback)

**Execution:** Immediate

**Example:**
```cfml
// Automatic commit/rollback
Transaction.run(function() {
    var user = User.create({name: "John", email: "john@test.com"});
    var profile = Profile.create({user_id: user.id, bio: "..."});
    return user;
});

// With error handling
try {
    var result = Transaction.run(function() {
        // Multiple operations
        User.find(1).update({balance: 100});
        User.find(2).update({balance: 200});
    });
} catch (any e) {
    // Transaction was rolled back
    writeOutput("Transaction failed: " & e.message);
}
```

**Related Methods:** [begin()](#begin), [commit()](#commit), [rollback()](#rollback)

---

#### begin()

Begin a transaction manually.

**Signature:** `Transaction.begin()`

**Parameters:** None

**Returns:** `void`

**Throws:** None

**Execution:** Immediate

**Example:**
```cfml
Transaction.begin();

try {
    User.create({name: "John"});
    Profile.create({user_id: 1});
    Transaction.commit();
} catch (any e) {
    Transaction.rollback();
    rethrow;
}
```

**Related Methods:** [commit()](#commit), [rollback()](#rollback), [run()](#run)

---

#### commit()

Commit the current transaction.

**Signature:** `Transaction.commit()`

**Parameters:** None

**Returns:** `void`

**Throws:** None

**Execution:** Immediate

**Example:**
```cfml
Transaction.begin();
// ... operations ...
Transaction.commit();
```

**Related Methods:** [begin()](#begin), [rollback()](#rollback)

---

#### rollback()

Rollback the current transaction.

**Signature:** `Transaction.rollback()`

**Parameters:** None

**Returns:** `void`

**Throws:** None

**Execution:** Immediate

**Example:**
```cfml
Transaction.begin();
try {
    // ... operations ...
    Transaction.commit();
} catch (any e) {
    Transaction.rollback();
    rethrow;
}
```

**Related Methods:** [begin()](#begin), [commit()](#commit)

---

## WHERE Operators

Advanced query operators for building complex WHERE conditions.

**Usage:** Pass operators in hash syntax to `where()`:

```cfml
User.where({age: {gte: 18, lte: 65}}).get();
User.where({name: {like: '%john%'}}).get();
User.where({status: {in: ['active', 'pending']}}).get();
```

### Available Operators

| Operator      | SQL         | Description              | Example                                    |
|---------------|-------------|--------------------------|--------------------------------------------|
| `eq`          | `=`         | Equal to                 | `{age: {eq: 18}}`                          |
| `neq`         | `!=`        | Not equal to             | `{status: {neq: 'inactive'}}`              |
| `gt`          | `>`         | Greater than             | `{age: {gt: 18}}`                          |
| `gte`         | `>=`        | Greater than or equal    | `{age: {gte: 18}}`                         |
| `lt`          | `<`         | Less than                | `{age: {lt: 65}}`                          |
| `lte`         | `<=`        | Less than or equal       | `{age: {lte: 65}}`                         |
| `like`        | `LIKE`      | Pattern match            | `{name: {like: '%john%'}}`                 |
| `in`          | `IN`        | Value in array           | `{status: {in: ['active', 'pending']}}`    |
| `notIn`       | `NOT IN`    | Value not in array       | `{status: {notIn: ['deleted']}}`           |
| `isNull`      | `IS NULL`   | Column is null           | `{deleted_at: {isNull: true}}`             |
| `isNotNull`   | `IS NOT NULL` | Column is not null     | `{email: {isNotNull: true}}`               |

**Examples:**
```cfml
// Age between 18 and 65
User.where({age: {gte: 18, lte: 65}}).get();

// Name contains "john"
User.where({name: {like: '%john%'}}).get();

// Status is active or pending
User.where({status: {in: ['active', 'pending']}}).get();

// Not deleted (soft delete)
Post.where({deleted_at: {isNull: true}}).get();

// Has email (not null)
User.where({email: {isNotNull: true}}).get();
```

---

## Exceptions

Framework exceptions thrown by various operations.

### ModelNotFoundException

Thrown when `findOrFail()` cannot find a record.

**Extends:** `fuse.exceptions.BaseException`

**Data:**
- `model` (string) - Model name
- `id` (any) - ID that wasn't found

**Example:**
```cfml
try {
    var user = User.findOrFail(999);
} catch (ModelNotFoundException e) {
    writeOutput("User #e.id# not found");
}
```

---

### ValidationException

Thrown when model validation fails on `save()` or `create()`.

**Extends:** `fuse.exceptions.BaseException`

**Data:**
- `errors` (struct) - Validation errors by field
- `model` (Model) - Model instance that failed validation

**Example:**
```cfml
try {
    var user = User.create({email: "invalid"});
} catch (ValidationException e) {
    writeOutput(serializeJSON(e.errors));
    // {"email": ["Email is not valid"]}
}
```

---

### CircularDependency

Thrown when modules have circular dependencies.

**Extends:** `fuse.exceptions.BaseException`

**Data:**
- `modules` (array) - Array of module names in circular chain

**Example:**
```cfml
// Module A depends on B which depends on A
// Throws: CircularDependency
```

---

### MissingDependency

Thrown when a required module dependency is not loaded.

**Extends:** `fuse.exceptions.BaseException`

**Data:**
- `module` (string) - Module that requires dependency
- `dependency` (string) - Missing dependency name

**Example:**
```cfml
// AuthModule requires CacheModule but it's not loaded
// Throws: MissingDependency
```

---

### CacheMiss

Thrown when cache key is not found (RAMProvider only).

**Extends:** `fuse.exceptions.BaseException`

**Data:**
- `key` (string) - Cache key that wasn't found

**Example:**
```cfml
try {
    var value = cache.get('nonexistent');
} catch (CacheMiss e) {
    writeOutput("Key #e.key# not in cache");
}
```

---

## Conventions

Framework naming and file structure conventions.

### Models

- **Naming:** Singular, PascalCase
- **Location:** `models/`
- **Example:** `models/User.cfc`
- **Table:** Plural, lowercase (e.g., `users`)

### Handlers

- **Naming:** PascalCase + "Handler" suffix
- **Location:** `handlers/`
- **Example:** `handlers/UsersHandler.cfc`

### Views

- **Naming:** Lowercase, matches action name
- **Location:** `views/{handler}/`
- **Example:** `views/users/index.cfm`

### Migrations

- **Naming:** `YYYYMMDDHHMMSS_Description.cfc`
- **Location:** `db/migrations/`
- **Example:** `db/migrations/20250105120000_CreateUsers.cfc`

### Tests

- **Naming:** Name + "Test.cfc" suffix
- **Location:** `tests/{type}/`
- **Example:** `tests/models/UserTest.cfc`

### Modules

- **Naming:** Directory name, `Module.cfc` inside
- **Location:** `modules/{name}/`
- **Example:** `modules/auth/Module.cfc`

---

## Related Topics

- [Models & ORM Guide](../guides/models-orm.md)
- [Query Building Guide](../guides/models-orm.md#query-building)
- [Relationships Guide](../guides/relationships.md)
- [Eager Loading Guide](../guides/eager-loading.md)
- [Validations Guide](../guides/validations.md)
- [Testing Guide](../guides/testing.md)
- [Routing Guide](../guides/routing.md)
- [Migrations Guide](../guides/migrations.md)
- [CLI Reference](cli-reference.md)
