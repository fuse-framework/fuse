/**
 * Users Handler
 *
 * RESTful CRUD actions for Users resource
 */
component {

	/**
	 * Constructor with optional dependency injection
	 */
	public function init() {
		// Initialize any required services here
		return this;
	}

	/**
	 * List all Users (GET /api_v1)
	 *
	 * @return Struct response
	 */
	public struct function index() {
		return {
			success: true,
			action: "index",
			data: []
		};
	}

	/**
	 * Show single Users (GET /api_v1/:id)
	 *
	 * @id Resource ID from route param
	 * @return Struct response
	 */
	public struct function show(required string id) {
		return {
			success: true,
			action: "show",
			id: arguments.id
		};
	}

	/**
	 * Show new Users form (GET /api_v1/new)
	 *
	 * @return String view name
	 */
	public string function new() {
		return "api_v1/new";
	}

	/**
	 * Create new Users (POST /api_v1)
	 *
	 * @return Struct response
	 */
	public struct function create() {
		return {
			success: true,
			action: "create"
		};
	}

	/**
	 * Show edit Users form (GET /api_v1/:id/edit)
	 *
	 * @id Resource ID from route param
	 * @return String view name
	 */
	public string function edit(required string id) {
		return "api_v1/edit";
	}

	/**
	 * Update Users (PUT/PATCH /api_v1/:id)
	 *
	 * @id Resource ID from route param
	 * @return Struct response
	 */
	public struct function update(required string id) {
		return {
			success: true,
			action: "update",
			id: arguments.id
		};
	}

	/**
	 * Delete Users (DELETE /api_v1/:id)
	 *
	 * @id Resource ID from route param
	 * @return Struct response
	 */
	public struct function destroy(required string id) {
		return {
			success: true,
			action: "destroy",
			id: arguments.id
		};
	}

}
