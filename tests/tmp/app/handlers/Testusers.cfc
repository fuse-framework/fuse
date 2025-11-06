/**
 * Testusers Handler
 *
 * RESTful CRUD actions for Testusers resource
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
	 * List all Testusers (GET /)
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
	 * Show single Testusers (GET //:id)
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
	 * Show new Testusers form (GET //new)
	 *
	 * @return String view name
	 */
	public string function new() {
		return "/new";
	}

	/**
	 * Create new Testusers (POST /)
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
	 * Show edit Testusers form (GET //:id/edit)
	 *
	 * @id Resource ID from route param
	 * @return String view name
	 */
	public string function edit(required string id) {
		return "/edit";
	}

	/**
	 * Update Testusers (PUT/PATCH //:id)
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
	 * Delete Testusers (DELETE //:id)
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
