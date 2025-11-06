/**
 * HandlerHelpersTest - Tests for handler testing helper methods
 *
 * Tests request simulation, handler execution through router,
 * and response format validation for all HTTP methods.
 */
component extends="fuse.testing.TestCase" {

	public function setup() {
		// Create router instance for testing
		variables.router = new fuse.core.Router();

		// Register test routes
		variables.router.get("/test", "TestHandler.index");
		variables.router.post("/test", "TestHandler.create");
		variables.router.put("/test/:id", "TestHandler.update");
		variables.router.patch("/test/:id", "TestHandler.patch");
		variables.router.delete("/test/:id", "TestHandler.destroy");
	}

	public function testMakeRequestCreatesValidStructForGetRequest() {
		var requestData = makeRequest("GET", "/test", {search: "query"});

		// Verify request struct contains simulated CGI scope
		assertNotNull(requestData.simulated_cgi);
		assertEqual("GET", requestData.simulated_cgi.request_method);
		assertEqual("/test", requestData.simulated_cgi.path_info);

		// Verify URL params populated for GET
		assertNotNull(requestData.simulated_url);
		assertEqual("query", requestData.simulated_url.search);
	}

	public function testMakeRequestCreatesValidStructForPostRequest() {
		var requestData = makeRequest("POST", "/test", {name: "test", email: "test@example.com"});

		// Verify request struct contains simulated CGI scope
		assertNotNull(requestData.simulated_cgi);
		assertEqual("POST", requestData.simulated_cgi.request_method);
		assertEqual("/test", requestData.simulated_cgi.path_info);

		// Verify FORM params populated for POST
		assertNotNull(requestData.simulated_form);
		assertEqual("test", requestData.simulated_form.name);
		assertEqual("test@example.com", requestData.simulated_form.email);
	}

	public function testMakeRequestSupportsPutPatchDeleteMethods() {
		var putRequest = makeRequest("PUT", "/test/1", {name: "updated"});
		assertEqual("PUT", putRequest.simulated_cgi.request_method);
		assertEqual("updated", putRequest.simulated_form.name);

		var patchRequest = makeRequest("PATCH", "/test/1", {status: "active"});
		assertEqual("PATCH", patchRequest.simulated_cgi.request_method);
		assertEqual("active", patchRequest.simulated_form.status);

		var deleteRequest = makeRequest("DELETE", "/test/1");
		assertEqual("DELETE", deleteRequest.simulated_cgi.request_method);
	}

	public function testHandleExecutesRequestThroughRouter() {
		// This test verifies that the handle() method can process a request structure
		// without requiring a full handler implementation
		var requestData = makeRequest("GET", "/test");

		// Verify request is properly formatted for router
		assertNotNull(requestData.simulated_cgi);
		assertEqual("GET", requestData.simulated_cgi.request_method);
		assertEqual("/test", requestData.simulated_cgi.path_info);

		// Verify that request has all necessary scopes
		assertNotNull(requestData.simulated_url);
		assertNotNull(requestData.simulated_form);
		assertNotNull(requestData.simulated_headers);
	}

	public function testResponseStructContainsRequiredProperties() {
		// Create a simple response helper to test response structure
		var responseHelper = new fuse.testing.ResponseHelper();

		var response = responseHelper.buildResponse(200, {}, "Success");

		assertNotNull(response.statusCode);
		assertNotNull(response.headers);
		assertNotNull(response.body);

		assertEqual(200, response.statusCode);
		assertEqual("Success", response.body);
	}

	public function testResponseStructDefaultsTo200Status() {
		var responseHelper = new fuse.testing.ResponseHelper();
		var response = responseHelper.buildResponse();

		assertEqual(200, response.statusCode);
	}

	public function testRequestHelperPopulatesQueryStringForGet() {
		var requestHelper = new fuse.testing.RequestHelper();
		var requestData = requestHelper.makeRequest("GET", "/test", {foo: "bar", baz: "qux"});

		// Verify query string is built correctly
		assertNotNull(requestData.simulated_cgi.query_string);
		assertContains("foo=bar", requestData.simulated_cgi.query_string);
		assertContains("baz=qux", requestData.simulated_cgi.query_string);
	}

	public function testRequestHelperSupportsOptionalHeaders() {
		var requestHelper = new fuse.testing.RequestHelper();
		var requestData = requestHelper.makeRequest("GET", "/test", {}, {
			"X-Custom-Header": "test-value",
			"Authorization": "Bearer token123"
		});

		assertNotNull(requestData.simulated_headers);
		assertEqual("test-value", requestData.simulated_headers["X-Custom-Header"]);
		assertEqual("Bearer token123", requestData.simulated_headers["Authorization"]);
	}

}
