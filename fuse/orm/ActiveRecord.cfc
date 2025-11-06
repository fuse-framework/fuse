/**
 * ActiveRecord - Base class for ORM models
 *
 * Provides ORM patterns with static query methods and instance CRUD operations.
 * Models extend this class to gain database persistence capabilities with
 * automatic table name conventions, dirty tracking, and timestamp management.
 *
 * USAGE EXAMPLES:
 *
 * Define a model:
 *     component extends="fuse.orm.ActiveRecord" {
 *         // Optional overrides
 *         this.tableName = "people";  // defaults to "users"
 *         this.primaryKey = "user_id"; // defaults to "id"
 *     }
 *
 * Static finders (Lucee 7 double-colon syntax):
 *     var user = User::find(1);
 *     var activeUsers = User::where({active: true}).orderBy("name").get();
 *     var allUsers = User::all().orderBy("created_at DESC").get();
 *
 * Instance methods:
 *     var user = new User(datasource);
 *     user.name = "John Doe";
 *     user.email = "john@example.com";
 *     user.save();
 *
 *     user.update({name: "Jane Doe"});
 *     user.delete();
 *     user.reload();
 *
 * Conventions:
 * - Table name: pluralize component name with 's' (User -> users, Post -> posts)
 * - Primary key: defaults to 'id'
 * - Timestamps: auto-populate created_at on INSERT, updated_at on UPDATE
 * - Dirty tracking: UPDATE queries only include changed attributes
 */
component extends="ModelBuilder" {

	/**
	 * Initialize ActiveRecord model
	 *
	 * @datasource Datasource name for database queries
	 * @return ActiveRecord instance for chaining
	 */
	public function init(required string datasource) {
		// Extract component name from metadata
		var metadata = getMetadata(this);
		var componentName = listLast(metadata.name, ".");

		// Determine table name (override or convention)
		var tableName = "";
		if (structKeyExists(this, "tableName") && len(trim(this.tableName))) {
			tableName = this.tableName;
		} else {
			// Default: append 's' to component name and lowercase
			tableName = lcase(componentName & "s");
		}

		// Call parent ModelBuilder init with datasource and resolved tableName
		super.init(arguments.datasource, tableName);

		// Determine primary key (override or default)
		if (structKeyExists(this, "primaryKey") && len(trim(this.primaryKey))) {
			variables.primaryKey = this.primaryKey;
		} else {
			variables.primaryKey = "id";
		}

		// Detect timestamp columns at initialization
		detectTimestampColumns();

		// Initialize attribute storage for dirty tracking
		variables.attributes = {};
		variables.original = {};
		variables.isPersisted = false;

		return this;
	}

	/**
	 * Query records with WHERE conditions
	 * Can be called statically via User::where() or on instance
	 *
	 * @param conditions Struct of column/value pairs for WHERE clause
	 * @return ModelBuilder instance for chaining
	 *
	 * @example User::where({active: true}).orderBy("name").get()
	 */
	public function where(struct conditions) {
		// If called statically (no init), create temp instance
		if (!structKeyExists(variables, "datasource")) {
			var instance = createTempInstance();
			return instance.where(argumentCollection=arguments);
		}

		// Call parent where()
		super.where(argumentCollection=arguments);

		return this;
	}

	/**
	 * Find record(s) by primary key
	 * Can be called statically via User::find() or on instance
	 *
	 * @param id Single ID value or array of ID values
	 * @return Model instance (single ID), array of instances (ID array), or null/empty array if not found
	 *
	 * @example User::find(1) - returns User instance or null
	 * @example User::find([1,2,3]) - returns array of User instances
	 */
	public function find(required id) {
		// If called statically (no init), create temp instance
		if (!structKeyExists(variables, "datasource")) {
			var instance = createTempInstance();
			return instance.find(argumentCollection=arguments);
		}

		// Check if id is array
		if (isArray(arguments.id)) {
			// Array of IDs - return array of instances
			var conditions = {};
			conditions[variables.primaryKey] = {in: arguments.id};
			this.where(conditions);
			return this.get();
		} else {
			// Single ID - return instance or null
			var conditions = {};
			conditions[variables.primaryKey] = arguments.id;
			this.where(conditions);
			return this.first();
		}
	}

	/**
	 * Get all records
	 * Can be called statically via User::all() or on instance
	 *
	 * @return ModelBuilder instance for chaining
	 *
	 * @example User::all().orderBy("created_at DESC").get()
	 */
	public function all() {
		// If called statically (no init), create temp instance
		if (!structKeyExists(variables, "datasource")) {
			return createTempInstance();
		}

		// Return this for chaining
		return this;
	}

	/**
	 * Override ModelBuilder get() to return array of model instances
	 *
	 * @return Array of model instances
	 */
	public array function get() {
		// Call parent get() to get array of structs
		var rows = super.get();

		// Convert structs to model instances
		var instances = [];
		for (var row in rows) {
			var instance = createModelInstance();
			instance.populate(row);
			arrayAppend(instances, instance);
		}

		return instances;
	}

	/**
	 * Override ModelBuilder first() to return single model instance
	 *
	 * @return Model instance or null if no results
	 */
	public function first() {
		// Call parent first() to get struct or null
		var row = super.first();

		if (isNull(row)) {
			return null;
		}

		// Convert struct to model instance
		var instance = createModelInstance();
		instance.populate(row);

		return instance;
	}

	/**
	 * Populate model instance from database row struct
	 *
	 * @param data Struct of database column values
	 * @return Model instance for chaining
	 */
	public function populate(required struct data) {
		// Set attributes from data
		variables.attributes = duplicate(arguments.data);

		// Set original for dirty tracking baseline
		variables.original = duplicate(arguments.data);

		// Mark as persisted (exists in database)
		variables.isPersisted = true;

		return this;
	}

	/**
	 * Handle attribute getter/setter via missing method
	 *
	 * @param missingMethodName Name of the missing method
	 * @param missingMethodArguments Arguments passed to the missing method
	 * @return Attribute value for getter, this for setter
	 */
	public function onMissingMethod(required string missingMethodName, required struct missingMethodArguments) {
		var methodName = arguments.missingMethodName;
		var args = arguments.missingMethodArguments;

		// Detect getter pattern: method starts with "get" or has zero arguments
		var isGetter = false;
		var attributeName = "";

		if (left(methodName, 3) == "get" && len(methodName) > 3) {
			// Explicit getter: getName() -> name
			isGetter = true;
			attributeName = lcase(mid(methodName, 4, 1)) & mid(methodName, 5, len(methodName) - 4);
		} else if (structCount(args) == 0) {
			// Property access: user.name
			isGetter = true;
			attributeName = methodName;
		}

		if (isGetter) {
			// Return attribute value or null if not exists
			if (structKeyExists(variables.attributes, attributeName)) {
				return variables.attributes[attributeName];
			}
			return null;
		}

		// Detect setter pattern: method starts with "set" or has one argument
		var isSetter = false;
		var value = null;

		if (left(methodName, 3) == "set" && len(methodName) > 3) {
			// Explicit setter: setName("John") -> name = "John"
			isSetter = true;
			attributeName = lcase(mid(methodName, 4, 1)) & mid(methodName, 5, len(methodName) - 4);
			if (structCount(args) > 0) {
				// Get first positional argument or named argument
				var argKeys = structKeyArray(args);
				value = args[argKeys[1]];
			}
		} else if (structCount(args) == 1) {
			// Property assignment: user.name = "John"
			isSetter = true;
			attributeName = methodName;
			var argKeys = structKeyArray(args);
			value = args[argKeys[1]];
		}

		if (isSetter) {
			// Set attribute value
			variables.attributes[attributeName] = value;
			// Return this for chaining
			return this;
		}

		// If we get here, method pattern not recognized
		throw(
			type = "ActiveRecord.MethodNotFound",
			message = "Method '#methodName#' not found and doesn't match getter/setter pattern",
			detail = "Use property access (user.name) or explicit getters/setters (getName/setName)"
		);
	}

	/**
	 * Get dirty (changed) attributes
	 *
	 * @return Struct of changed attributes with their current values
	 */
	public struct function getDirty() {
		var dirty = {};

		// Compare current attributes to original
		for (var key in variables.attributes) {
			var currentValue = variables.attributes[key];
			var hasOriginal = structKeyExists(variables.original, key);

			if (!hasOriginal) {
				// New attribute added after populate
				dirty[key] = currentValue;
			} else {
				var originalValue = variables.original[key];
				// Compare values (handle null case)
				if (isNull(currentValue) && !isNull(originalValue)) {
					dirty[key] = currentValue;
				} else if (!isNull(currentValue) && isNull(originalValue)) {
					dirty[key] = currentValue;
				} else if (!isNull(currentValue) && !isNull(originalValue) && currentValue != originalValue) {
					dirty[key] = currentValue;
				}
			}
		}

		return dirty;
	}

	/**
	 * Save model instance to database
	 * Detects INSERT vs UPDATE based on isPersisted flag and primary key value
	 *
	 * @return Model instance for chaining
	 */
	public function save() {
		// Detect INSERT vs UPDATE
		var isInsert = !variables.isPersisted || !structKeyExists(variables.attributes, variables.primaryKey);

		if (isInsert) {
			// INSERT path
			performInsert();
		} else {
			// UPDATE path
			performUpdate();
		}

		// Reset dirty tracking
		variables.original = duplicate(variables.attributes);

		return this;
	}

	/**
	 * Update model instance with changes and save
	 *
	 * @param changes Struct of attribute changes
	 * @return Model instance for chaining
	 */
	public function update(required struct changes) {
		// Merge changes into attributes
		for (var key in arguments.changes) {
			variables.attributes[key] = arguments.changes[key];
		}

		// Save to persist changes
		this.save();

		return this;
	}

	/**
	 * Delete model instance from database
	 *
	 * @return Boolean true if deleted, false if no rows affected
	 */
	public boolean function delete() {
		// Check if record is persisted and has primary key
		if (!variables.isPersisted || !structKeyExists(variables.attributes, variables.primaryKey)) {
			throw(
				type = "ActiveRecord.DeleteFailed",
				message = "Cannot delete record that doesn't exist in database",
				detail = "Record has not been saved or has no primary key value"
			);
		}

		try {
			// Execute DELETE query
			var sql = "DELETE FROM #variables.tableName# WHERE #variables.primaryKey# = ?";
			var result = queryExecute(
				sql,
				[variables.attributes[variables.primaryKey]],
				{datasource: variables.datasource}
			);

			// Mark as detached
			variables.isPersisted = false;

			// Return true if rows affected
			return (structKeyExists(result, "recordCount") && result.recordCount > 0);
		} catch (any e) {
			throw(
				type = "ActiveRecord.DeleteFailed",
				message = "Failed to delete record from database",
				detail = "Error: " & e.message
			);
		}
	}

	/**
	 * Reload model instance from database
	 * Refreshes attributes with current database values
	 *
	 * @return Model instance for chaining
	 */
	public function reload() {
		// Check if record has primary key
		if (!structKeyExists(variables.attributes, variables.primaryKey)) {
			throw(
				type = "ActiveRecord.RecordNotFound",
				message = "Cannot reload record without primary key",
				detail = "Record must have a primary key value to reload"
			);
		}

		// Query database for fresh data
		var conditions = {};
		conditions[variables.primaryKey] = variables.attributes[variables.primaryKey];

		// Create temp builder for query
		var builder = createModelInstance();
		builder.where(conditions);
		var result = builder.first();

		if (isNull(result)) {
			throw(
				type = "ActiveRecord.RecordNotFound",
				message = "Record no longer exists in database",
				detail = "Primary key #variables.primaryKey# = #variables.attributes[variables.primaryKey]#"
			);
		}

		// Refresh attributes from database
		variables.attributes = duplicate(result.getVariablesScope().attributes);
		variables.original = duplicate(variables.attributes);
		variables.isPersisted = true;

		return this;
	}

	// Private helper methods

	/**
	 * Perform INSERT operation
	 */
	private function performInsert() {
		try {
			// Add created_at if column exists
			if (variables.hasCreatedAt) {
				variables.attributes["created_at"] = now();
			}

			// Build INSERT query
			var columns = [];
			var placeholders = [];
			var bindings = [];

			for (var key in variables.attributes) {
				arrayAppend(columns, key);
				arrayAppend(placeholders, "?");
				arrayAppend(bindings, variables.attributes[key]);
			}

			var sql = "INSERT INTO #variables.tableName# (#arrayToList(columns, ', ')#) VALUES (#arrayToList(placeholders, ', ')#)";

			var result = queryExecute(
				sql,
				bindings,
				{datasource: variables.datasource, result: "insertResult"}
			);

			// Get last inserted ID
			if (structKeyExists(insertResult, "generatedKey")) {
				variables.attributes[variables.primaryKey] = insertResult.generatedKey;
			}

			// Mark as persisted
			variables.isPersisted = true;
		} catch (any e) {
			throw(
				type = "ActiveRecord.SaveFailed",
				message = "Failed to insert record into database",
				detail = "Error: " & e.message
			);
		}
	}

	/**
	 * Perform UPDATE operation
	 */
	private function performUpdate() {
		try {
			// Get dirty attributes
			var dirty = getDirty();

			// Skip if nothing to update
			if (structCount(dirty) == 0) {
				return;
			}

			// Add updated_at if column exists
			if (variables.hasUpdatedAt) {
				variables.attributes["updated_at"] = now();
				dirty["updated_at"] = variables.attributes["updated_at"];
			}

			// Build UPDATE query
			var setClauses = [];
			var bindings = [];

			for (var key in dirty) {
				arrayAppend(setClauses, "#key# = ?");
				arrayAppend(bindings, dirty[key]);
			}

			// Add primary key to WHERE clause
			arrayAppend(bindings, variables.attributes[variables.primaryKey]);

			var sql = "UPDATE #variables.tableName# SET #arrayToList(setClauses, ', ')# WHERE #variables.primaryKey# = ?";

			queryExecute(
				sql,
				bindings,
				{datasource: variables.datasource}
			);
		} catch (any e) {
			throw(
				type = "ActiveRecord.SaveFailed",
				message = "Failed to update record in database",
				detail = "Error: " & e.message
			);
		}
	}

	/**
	 * Detect presence of timestamp columns in database schema
	 *
	 * Queries database schema to check for created_at and updated_at columns.
	 * Stores detection flags to avoid per-query schema checks.
	 */
	private function detectTimestampColumns() {
		// Query database schema for timestamp columns
		try {
			var result = queryExecute(
				"SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = ? AND COLUMN_NAME IN (?, ?)",
				[variables.tableName, "created_at", "updated_at"],
				{datasource: variables.datasource}
			);

			variables.hasCreatedAt = false;
			variables.hasUpdatedAt = false;

			for (var row in result) {
				if (row.COLUMN_NAME == "created_at") {
					variables.hasCreatedAt = true;
				}
				if (row.COLUMN_NAME == "updated_at") {
					variables.hasUpdatedAt = true;
				}
			}
		} catch (any e) {
			// If schema query fails, assume no timestamp columns
			variables.hasCreatedAt = false;
			variables.hasUpdatedAt = false;
		}
	}

	/**
	 * Create new instance of this model class
	 *
	 * @return New model instance
	 */
	private function createModelInstance() {
		var metadata = getMetadata(this);
		return createObject("component", metadata.name).init(variables.datasource);
	}

	/**
	 * Create temporary instance for static-like method calls
	 * This allows methods like where(), find(), all() to work when called statically
	 *
	 * @return New initialized model instance
	 */
	private function createTempInstance() {
		var metadata = getMetadata(this);
		var datasource = getStaticDatasource();
		return createObject("component", metadata.name).init(datasource);
	}

	/**
	 * Get datasource for static method calls
	 *
	 * Static methods need datasource but don't have instance variables.
	 * This will be enhanced in future to use DI container resolution.
	 *
	 * @return Datasource name
	 */
	private function getStaticDatasource() {
		// TODO: In future, resolve from DI container
		// For now, use application scope or default
		if (structKeyExists(application, "datasource")) {
			return application.datasource;
		}

		// Fallback to "fuse" as default datasource name
		return "fuse";
	}

	/**
	 * Helper method for tests to access variables scope
	 * TestBox needs this to verify internal state
	 *
	 * @return Struct of variables scope
	 */
	public struct function getVariablesScope() {
		return variables;
	}

}
