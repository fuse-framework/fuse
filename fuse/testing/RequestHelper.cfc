/**
 * RequestHelper - Simulates HTTP requests for handler testing
 *
 * Creates request structures with CGI scope simulation, parameter population,
 * and optional headers for testing handlers without running a web server.
 *
 * USAGE EXAMPLES:
 *
 * GET request with query params:
 *     helper = new fuse.testing.RequestHelper();
 *     request = helper.makeRequest("GET", "/users", {page: 1});
 *
 * POST request with form data:
 *     request = helper.makeRequest("POST", "/users", {name: "John", email: "john@test.com"});
 *
 * With custom headers:
 *     request = helper.makeRequest("GET", "/api/users", {}, {
 *         "Authorization": "Bearer token123",
 *         "Accept": "application/json"
 *     });
 *
 * Request structure (uses simulated_ prefix to avoid CFML scope conflicts):
 *     {
 *         simulated_cgi: {
 *             request_method: "GET",
 *             path_info: "/users",
 *             query_string: "page=1",
 *             http_host: "localhost"
 *         },
 *         simulated_url: {page: 1},
 *         simulated_form: {},
 *         simulated_headers: {}
 *     }
 */
component {

	/**
	 * Initialize RequestHelper
	 *
	 * @return RequestHelper instance for chaining
	 */
	public function init() {
		return this;
	}

	/**
	 * Create request struct simulating HTTP request
	 *
	 * Populates URL scope for GET requests, FORM scope for POST/PUT/PATCH/DELETE.
	 * Simulates CGI scope with request_method, path_info, query_string, etc.
	 * Uses simulated_ prefix to avoid CFML reserved scope names.
	 *
	 * @method HTTP method (GET, POST, PUT, PATCH, DELETE)
	 * @path URL path (e.g., "/users", "/posts/123")
	 * @params Parameters struct (query params for GET, body params for others)
	 * @headers Optional headers struct
	 * @return Request struct matching Router expectations
	 */
	public struct function makeRequest(
		required string method,
		required string path,
		struct params = {},
		struct headers = {}
	) {
		var requestData = {
			simulated_cgi: buildCgiScope(arguments.method, arguments.path, arguments.params),
			simulated_url: {},
			simulated_form: {},
			simulated_headers: arguments.headers
		};

		// Populate appropriate scope based on method
		if (uCase(arguments.method) == "GET") {
			requestData.simulated_url = arguments.params;
		} else {
			// POST, PUT, PATCH, DELETE use form scope
			requestData.simulated_form = arguments.params;
		}

		return requestData;
	}

	// PRIVATE METHODS

	/**
	 * Build CGI scope struct for request simulation
	 *
	 * @method HTTP method
	 * @path URL path
	 * @params Parameters struct
	 * @return CGI scope struct
	 */
	private struct function buildCgiScope(
		required string method,
		required string path,
		required struct params
	) {
		var cgiData = {
			request_method: uCase(arguments.method),
			path_info: arguments.path,
			query_string: "",
			http_host: "localhost",
			server_name: "localhost",
			server_port: "80",
			server_protocol: "HTTP/1.1",
			script_name: "/index.cfm",
			remote_addr: "127.0.0.1"
		};

		// Build query string for GET requests
		if (uCase(arguments.method) == "GET" && !structIsEmpty(arguments.params)) {
			cgiData.query_string = buildQueryString(arguments.params);
		}

		return cgiData;
	}

	/**
	 * Build query string from parameters struct
	 *
	 * @params Parameters struct
	 * @return Query string (e.g., "foo=bar&baz=qux")
	 */
	private string function buildQueryString(required struct params) {
		var parts = [];

		for (var key in arguments.params) {
			var value = arguments.params[key];
			arrayAppend(parts, urlEncodedFormat(key) & "=" & urlEncodedFormat(value));
		}

		return arrayToList(parts, "&");
	}

}
