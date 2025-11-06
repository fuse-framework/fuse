/**
 * Users Handler
 *
 * Example handler demonstrating RESTful CRUD actions.
 * Handlers are transient (per-request) and support constructor DI.
 */
component {

	/**
	 * Constructor with optional dependency injection
	 *
	 * @logger Optional logger service
	 */
	public function init(any logger) {
		// Set defaults first
		variables.hasLogger = false;
		variables.logger = "";
		variables.instanceId = createUUID();

		// Override with injected dependencies if provided
		if (structKeyExists(arguments, "logger") && !isNull(arguments.logger)) {
			variables.logger = arguments.logger;
			variables.hasLogger = true;
		}

		return this;
	}

	/**
	 * List all users (GET /users)
	 *
	 * @return Struct response
	 */
	public struct function index() {
		return {
			success: true,
			action: "index",
			users: [],
			hasLogger: variables.hasLogger,
			instanceId: variables.instanceId
		};
	}

	/**
	 * Show single user (GET /users/:id)
	 *
	 * @id User ID from route param
	 * @return Struct response
	 */
	public struct function show(required string id) {
		return {
			success: true,
			action: "show",
			id: arguments.id,
			hasLogger: variables.hasLogger,
			instanceId: variables.instanceId
		};
	}

	/**
	 * Create new user (POST /users)
	 *
	 * @return Struct response
	 */
	public struct function create() {
		// In real app, would process form.data or request body
		return {
			created: true,
			action: "create",
			hasLogger: variables.hasLogger,
			instanceId: variables.instanceId
		};
	}

	/**
	 * Show new user form (GET /users/new)
	 *
	 * @return String view name
	 */
	public string function new() {
		return "users/new";
	}

	/**
	 * Show edit user form (GET /users/:id/edit)
	 *
	 * @id User ID from route param
	 * @return String view name
	 */
	public string function edit(required string id) {
		return "users/edit";
	}

	/**
	 * Update user (PUT/PATCH /users/:id)
	 *
	 * @id User ID from route param
	 * @return Struct response
	 */
	public struct function update(required string id) {
		return {
			updated: true,
			action: "update",
			id: arguments.id,
			hasLogger: variables.hasLogger
		};
	}

	/**
	 * Delete user (DELETE /users/:id)
	 *
	 * @id User ID from route param
	 * @return Struct response
	 */
	public struct function destroy(required string id) {
		return {
			deleted: true,
			action: "destroy",
			id: arguments.id,
			hasLogger: variables.hasLogger
		};
	}

}
