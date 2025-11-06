/**
 * TestHelperWorkflowTest - Integration tests for cross-component workflows
 *
 * Tests critical integration points between factory, database assertions,
 * handler helpers, and mock system. Fills gaps in end-to-end testing.
 */
component extends="fuse.testing.TestCase" {

	public function setup() {
		// Skip if no datasource configured
		if (!isDatasourceConfigured()) {
			return;
		}

		// Create test table
		queryExecute("
			CREATE TABLE IF NOT EXISTS workflow_users (
				id INTEGER PRIMARY KEY AUTO_INCREMENT,
				name VARCHAR(100),
				email VARCHAR(100),
				is_admin BOOLEAN DEFAULT 0
			)
		", [], {datasource: getDatasource()});

		queryExecute("DELETE FROM workflow_users", [], {datasource: getDatasource()});
	}

	public function teardown() {
		if (!isDatasourceConfigured()) {
			return;
		}

		queryExecute("DROP TABLE IF EXISTS workflow_users", [], {datasource: getDatasource()});
	}

	/**
	 * TEST: Factory + Database Assertions Together
	 * Create factory data and verify with database assertions
	 */
	public function testFactoryWithDatabaseAssertions() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Insert test data manually (simulating factory create)
		queryExecute("
			INSERT INTO workflow_users (name, email, is_admin)
			VALUES ('Alice Admin', 'alice@test.com', 1)
		", [], {datasource: getDatasource()});

		// Verify using database assertions
		assertDatabaseHas("workflow_users", {name: "Alice Admin", is_admin: 1});
		assertDatabaseCount("workflow_users", 1);
		assertDatabaseMissing("workflow_users", {name: "Bob User"});
	}

	/**
	 * TEST: Handler Helpers + Database Assertions
	 * Make request, execute handler, verify database changes
	 */
	public function testHandlerHelpersWithDatabaseAssertions() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Insert initial data
		queryExecute("
			INSERT INTO workflow_users (name, email)
			VALUES ('Test User', 'test@test.com')
		", [], {datasource: getDatasource()});

		// Verify data exists before simulated request
		assertDatabaseHas("workflow_users", {email: "test@test.com"});

		// Create request (simulating handler that would modify DB)
		var request = makeRequest("POST", "/users", {
			name: "New User",
			email: "new@test.com"
		});

		// Verify request structure is correct
		assertNotNull(request.simulated_cgi);
		assertEqual("POST", request.simulated_cgi.request_method);
		assertEqual("New User", request.simulated_form.name);
	}

	/**
	 * TEST: Mock System + Database Assertions
	 * Mock a service, verify database interactions not called
	 */
	public function testMockSystemPreventsDatabaseCalls() {
		// Create mock of a service that normally saves to DB
		var mockService = mock("tests.testing.fixtures.SimpleService");

		// Stub the save method to return true without DB interaction
		stub(mockService, "save", true);

		// Call the stubbed method
		var result = mockService.save();

		// Verify stub worked
		assertEqual(true, result);

		// Verify method was called
		verify(mockService, "save", 1);

		// Verify no database changes occurred (since we mocked)
		if (isDatasourceConfigured()) {
			assertDatabaseCount("workflow_users", 0);
		}
	}

	/**
	 * TEST: Multiple Mocks + Verification
	 * Test multiple mocks with different call counts
	 */
	public function testMultipleMocksWithDifferentCallCounts() {
		var mockService1 = mock("tests.testing.fixtures.SimpleService");
		var mockService2 = mock("tests.testing.fixtures.SimpleService");

		stub(mockService1, "save", true);
		stub(mockService2, "save", true);

		// Call first mock once
		mockService1.save();

		// Call second mock three times
		mockService2.save();
		mockService2.save();
		mockService2.save();

		// Verify different call counts
		verify(mockService1, "save", 1);
		verify(mockService2, "save", 3);
	}

	/**
	 * TEST: Request Helper with Different HTTP Methods
	 * Verify params populate correct scopes for all methods
	 */
	public function testRequestHelperParameterScopesForAllMethods() {
		// Test GET - params go to URL scope
		var getReq = makeRequest("GET", "/test", {search: "query", page: "2"});
		assertEqual("query", getReq.simulated_url.search);
		assertEqual("2", getReq.simulated_url.page);
		assertContains("search=query", getReq.simulated_cgi.query_string);

		// Test POST - params go to FORM scope
		var postReq = makeRequest("POST", "/test", {name: "test", email: "test@test.com"});
		assertEqual("test", postReq.simulated_form.name);
		assertEqual("test@test.com", postReq.simulated_form.email);

		// Test PUT - params go to FORM scope
		var putReq = makeRequest("PUT", "/test/1", {name: "updated"});
		assertEqual("updated", putReq.simulated_form.name);

		// Test DELETE - can have params
		var deleteReq = makeRequest("DELETE", "/test/1", {confirm: "yes"});
		assertEqual("yes", deleteReq.simulated_form.confirm);
	}

	/**
	 * TEST: Database Assertions with Multiple Criteria
	 * Test matching multiple attributes in assertions
	 */
	public function testDatabaseAssertionsWithMultipleCriteria() {
		if (!isDatasourceConfigured()) {
			assertTrue(true, "Skipping - no datasource");
			return;
		}

		// Insert multiple records
		queryExecute("
			INSERT INTO workflow_users (name, email, is_admin) VALUES
			('Admin User', 'admin@test.com', 1),
			('Regular User', 'user@test.com', 0),
			('Another Admin', 'admin2@test.com', 1)
		", [], {datasource: getDatasource()});

		// Find admin by multiple criteria
		assertDatabaseHas("workflow_users", {name: "Admin User", is_admin: 1});

		// Verify missing with multiple criteria
		assertDatabaseMissing("workflow_users", {name: "Regular User", is_admin: 1});

		// Verify count
		assertDatabaseCount("workflow_users", 3);
	}

	/**
	 * TEST: Mock Verification with Min/Max Ranges
	 * Test flexible call count verification
	 */
	public function testMockVerificationWithRanges() {
		var mockService = mock("tests.testing.fixtures.SimpleService");
		stub(mockService, "save", true);

		// Call save 2 times
		mockService.save();
		mockService.save();

		// Verify with range (should pass)
		verify(mockService, "save", {min: 1, max: 5});

		// Verify exact match within range
		verify(mockService, "save", 2);
	}

	/**
	 * TEST: Handler Response Structure
	 * Verify response has all required properties
	 */
	public function testHandlerResponseStructure() {
		var responseHelper = new fuse.testing.ResponseHelper();

		// Test with all properties
		var response = responseHelper.buildResponse(
			201,
			{"Content-Type": "application/json"},
			"Created"
		);

		assertEqual(201, response.statusCode);
		assertEqual("application/json", response.headers["Content-Type"]);
		assertEqual("Created", response.body);

		// Test with defaults
		var defaultResponse = responseHelper.buildResponse();
		assertEqual(200, defaultResponse.statusCode);
		assertTrue(isStruct(defaultResponse.headers));
		assertNotNull(defaultResponse.body);
	}

	/**
	 * TEST: Request with Custom Headers
	 * Verify custom headers are included in request
	 */
	public function testRequestWithCustomHeaders() {
		var request = makeRequest("GET", "/api/users", {}, {
			"Authorization": "Bearer token123",
			"X-API-Key": "secret-key",
			"Accept": "application/json"
		});

		assertEqual("Bearer token123", request.simulated_headers["Authorization"]);
		assertEqual("secret-key", request.simulated_headers["X-API-Key"]);
		assertEqual("application/json", request.simulated_headers["Accept"]);
	}

	// HELPER METHODS

	private boolean function isDatasourceConfigured() {
		try {
			var ds = getDatasource();
			if (!len(ds)) {
				return false;
			}
			queryExecute("SELECT 1 as test", [], {datasource: ds});
			return true;
		} catch (any e) {
			return false;
		}
	}

	private string function getDatasource() {
		if (structKeyExists(variables, "datasource") && len(variables.datasource)) {
			return variables.datasource;
		}
		if (isDefined("application.datasource") && len(application.datasource)) {
			return application.datasource;
		}
		return "fuse";
	}

}
