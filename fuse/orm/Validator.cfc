/**
 * Validator - ORM validation component
 *
 * Executes validation rules against ActiveRecord models and returns error messages.
 * Stateless design: receives model instance, executes validators, returns errors struct.
 *
 * USAGE:
 *
 * Model registration (in init):
 *     this.validates("email", {required: true, email: true});
 *
 * Validation execution:
 *     var validator = new fuse.orm.Validator();
 *     var errors = validator.validate(model);
 *     if (structCount(errors) > 0) {
 *         // Handle validation errors
 *     }
 *
 * Error structure:
 *     {
 *         fieldName: ["error message 1", "error message 2"],
 *         anotherField: ["error message"]
 *     }
 */
component {

	/**
	 * Validate model instance against registered validations
	 *
	 * @param model ActiveRecord model instance with validations defined
	 * @return Struct of validation errors {fieldName: [messages]}
	 */
	public struct function validate(required any model) {
		var errors = {};
		var modelVars = arguments.model.getVariablesScope();

		// Check if model has validations registered
		if (!structKeyExists(modelVars, "validations")) {
			return errors;
		}

		var validations = modelVars.validations;

		// Loop through each field's validations
		for (var fieldName in validations) {
			var fieldValidators = validations[fieldName];

			// Check if field exists in attributes
			var hasValue = structKeyExists(modelVars.attributes, fieldName);
			var fieldValue = hasValue ? modelVars.attributes[fieldName] : "";

			// Execute each validator for this field in registration order
			for (var validatorConfig in fieldValidators) {
				var type = validatorConfig.type;
				var options = validatorConfig.options;
				var errorMessage = "";

				// Execute appropriate validator - pass hasValue flag to handle null case
				if (type == "required") {
					errorMessage = validateRequired(fieldValue, hasValue, options);
				} else if (type == "email") {
					errorMessage = validateEmail(fieldValue, hasValue, options);
				} else if (type == "unique") {
					errorMessage = validateUnique(fieldName, fieldValue, hasValue, options, arguments.model);
				} else if (type == "length") {
					errorMessage = validateLength(fieldValue, hasValue, options);
				} else if (type == "format") {
					errorMessage = validateFormat(fieldValue, hasValue, options);
				} else if (type == "numeric") {
					errorMessage = validateNumeric(fieldValue, hasValue, options);
				} else if (type == "range") {
					errorMessage = validateRange(fieldValue, hasValue, options);
				} else if (type == "in") {
					errorMessage = validateIn(fieldValue, hasValue, options);
				} else if (type == "confirmation") {
					errorMessage = validateConfirmation(fieldName, fieldValue, hasValue, options, arguments.model);
				} else if (type == "custom") {
					errorMessage = validateCustom(fieldValue, hasValue, options, arguments.model);
				}

				// Collect error message if validation failed
				if (len(errorMessage)) {
					if (!structKeyExists(errors, fieldName)) {
						errors[fieldName] = [];
					}
					arrayAppend(errors[fieldName], errorMessage);
				}
			}
		}

		return errors;
	}

	// Built-in validators

	/**
	 * Validate required field has non-empty value
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct
	 * @return Error message or empty string if valid
	 */
	private string function validateRequired(any value, required boolean hasValue, required struct options) {
		// Missing field or empty string or whitespace-only strings are invalid
		if (!arguments.hasValue || !len(trim(arguments.value))) {
			return "is required";
		}
		return "";
	}

	/**
	 * Validate email format using regex
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct
	 * @return Error message or empty string if valid
	 */
	private string function validateEmail(any value, required boolean hasValue, required struct options) {
		// Skip validation if value doesn't exist or is empty (let required validator handle that)
		if (!arguments.hasValue || !len(trim(arguments.value))) {
			return "";
		}

		// Basic email regex pattern
		var emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$";
		if (!reFindNoCase(emailPattern, arguments.value)) {
			return "is not a valid email";
		}

		return "";
	}

	/**
	 * Validate unique field value in database
	 *
	 * @param fieldName Name of the field being validated
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct (may contain scope)
	 * @param model ActiveRecord model instance
	 * @return Error message or empty string if valid
	 */
	private string function validateUnique(required string fieldName, any value, required boolean hasValue, required struct options, required any model) {
		// Skip validation if value doesn't exist or empty
		if (!arguments.hasValue || !len(trim(arguments.value))) {
			return "";
		}

		var modelVars = arguments.model.getVariablesScope();
		var tableName = modelVars.tableName;
		var primaryKey = modelVars.primaryKey;
		var isPersisted = modelVars.isPersisted;
		var datasource = modelVars.datasource;

		// Build WHERE clause
		var sql = "SELECT COUNT(*) as count FROM #tableName# WHERE #arguments.fieldName# = ?";
		var params = [arguments.value];

		// Add scope condition if specified
		if (structKeyExists(arguments.options, "scope")) {
			var scopeField = arguments.options.scope;
			if (structKeyExists(modelVars.attributes, scopeField)) {
				var scopeValue = modelVars.attributes[scopeField];
				sql &= " AND #scopeField# = ?";
				arrayAppend(params, scopeValue);
			}
		}

		// Exclude current record if persisted (UPDATE case)
		if (isPersisted && structKeyExists(modelVars.attributes, primaryKey)) {
			sql &= " AND #primaryKey# != ?";
			arrayAppend(params, modelVars.attributes[primaryKey]);
		}

		// Execute query
		var result = queryExecute(sql, params, {datasource: datasource});
		var count = result.count;

		if (count > 0) {
			return "has already been taken";
		}

		return "";
	}

	/**
	 * Validate string length constraints
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct (min, max)
	 * @return Error message or empty string if valid
	 */
	private string function validateLength(any value, required boolean hasValue, required struct options) {
		// Skip validation if value doesn't exist (let required validator handle that)
		if (!arguments.hasValue) {
			return "";
		}

		var valueLength = len(arguments.value);

		if (structKeyExists(arguments.options, "min") && valueLength < arguments.options.min) {
			return "is too short (minimum #arguments.options.min# characters)";
		}

		if (structKeyExists(arguments.options, "max") && valueLength > arguments.options.max) {
			return "is too long (maximum #arguments.options.max# characters)";
		}

		return "";
	}

	/**
	 * Validate field matches regex pattern
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct (pattern)
	 * @return Error message or empty string if valid
	 */
	private string function validateFormat(any value, required boolean hasValue, required struct options) {
		// Skip validation if value doesn't exist or empty
		if (!arguments.hasValue || !len(trim(arguments.value))) {
			return "";
		}

		if (structKeyExists(arguments.options, "pattern")) {
			var pattern = arguments.options.pattern;
			if (!reFindNoCase(pattern, arguments.value)) {
				return "is invalid";
			}
		}

		return "";
	}

	/**
	 * Validate field is numeric type
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct
	 * @return Error message or empty string if valid
	 */
	private string function validateNumeric(any value, required boolean hasValue, required struct options) {
		// Skip validation if value doesn't exist (let required validator handle that)
		if (!arguments.hasValue) {
			return "";
		}

		if (!isNumeric(arguments.value)) {
			return "must be a number";
		}

		return "";
	}

	/**
	 * Validate numeric value falls within range
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct (min, max)
	 * @return Error message or empty string if valid
	 */
	private string function validateRange(any value, required boolean hasValue, required struct options) {
		// Skip validation if value doesn't exist
		if (!arguments.hasValue) {
			return "";
		}

		if (!isNumeric(arguments.value)) {
			return "must be a number";
		}

		var numValue = val(arguments.value);

		if (structKeyExists(arguments.options, "min") && numValue < arguments.options.min) {
			return "must be between #arguments.options.min# and #arguments.options.max#";
		}

		if (structKeyExists(arguments.options, "max") && numValue > arguments.options.max) {
			return "must be between #arguments.options.min# and #arguments.options.max#";
		}

		return "";
	}

	/**
	 * Validate field value is in whitelist array
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct (list)
	 * @return Error message or empty string if valid
	 */
	private string function validateIn(any value, required boolean hasValue, required struct options) {
		// Skip validation if value doesn't exist
		if (!arguments.hasValue) {
			return "";
		}

		if (structKeyExists(arguments.options, "list")) {
			var list = arguments.options.list;
			if (!arrayFind(list, arguments.value)) {
				return "is not included in the list";
			}
		}

		return "";
	}

	/**
	 * Validate field matches confirmation field
	 *
	 * @param fieldName Name of the field being validated
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct
	 * @param model ActiveRecord model instance
	 * @return Error message or empty string if valid
	 */
	private string function validateConfirmation(required string fieldName, any value, required boolean hasValue, required struct options, required any model) {
		// Skip validation if value doesn't exist
		if (!arguments.hasValue) {
			return "";
		}

		var confirmationFieldName = arguments.fieldName & "_confirmation";
		var modelVars = arguments.model.getVariablesScope();

		if (!structKeyExists(modelVars.attributes, confirmationFieldName)) {
			return "doesn't match confirmation";
		}

		var confirmationValue = modelVars.attributes[confirmationFieldName];
		if (arguments.value != confirmationValue) {
			return "doesn't match confirmation";
		}

		return "";
	}

	/**
	 * Execute custom validator method or closure
	 *
	 * @param value Field value
	 * @param hasValue Whether field exists in attributes
	 * @param options Validator options struct (validator)
	 * @param model ActiveRecord model instance
	 * @return Error message or empty string if valid
	 */
	private string function validateCustom(any value, required boolean hasValue, required struct options, required any model) {
		if (!structKeyExists(arguments.options, "validator")) {
			return "";
		}

		var validator = arguments.options.validator;
		var isValid = false;

		// Check if validator is a closure
		if (isClosure(validator) || isCustomFunction(validator)) {
			// Invoke closure directly - pass value
			isValid = validator(arguments.value, arguments.model);
		} else if (isSimpleValue(validator)) {
			// Method name string - invoke on model
			if (structKeyExists(arguments.model, validator)) {
				var method = arguments.model[validator];
				isValid = method(arguments.value, arguments.model);
			}
		}

		if (!isValid) {
			return "is invalid";
		}

		return "";
	}

}
