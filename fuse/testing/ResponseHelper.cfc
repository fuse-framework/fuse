/**
 * ResponseHelper - Normalizes handler responses for testing
 *
 * Extracts status code, headers, and body from handler execution results
 * to provide consistent response structure for test assertions.
 *
 * USAGE EXAMPLES:
 *
 * Build response with explicit status:
 *     helper = new fuse.testing.ResponseHelper();
 *     response = helper.buildResponse(201, {"Location": "/users/123"}, "Created");
 *
 * Build response with defaults:
 *     response = helper.buildResponse(body: "Success");
 *     // {statusCode: 200, headers: {}, body: "Success"}
 *
 * Extract from handler return value:
 *     handlerResult = {status: 404, body: "Not found"};
 *     response = helper.buildResponse(
 *         handlerResult.status ?: 200,
 *         {},
 *         handlerResult.body
 *     );
 *
 * Response structure:
 *     {
 *         statusCode: 200,
 *         headers: {},
 *         body: "Response content"
 *     }
 */
component {

	/**
	 * Initialize ResponseHelper
	 *
	 * @return ResponseHelper instance for chaining
	 */
	public function init() {
		return this;
	}

	/**
	 * Build normalized response struct
	 *
	 * Creates consistent response format with statusCode, headers, and body.
	 * Defaults to 200 status, empty headers, and empty body if not provided.
	 *
	 * @statusCode HTTP status code (defaults to 200)
	 * @headers Response headers struct (defaults to {})
	 * @body Response body content (defaults to "")
	 * @return Normalized response struct
	 */
	public struct function buildResponse(
		numeric statusCode = 200,
		struct headers = {},
		any body = ""
	) {
		return {
			statusCode: arguments.statusCode,
			headers: arguments.headers,
			body: arguments.body
		};
	}

	/**
	 * Extract response from handler return value
	 *
	 * Handles various handler return formats:
	 * - String: becomes body with 200 status
	 * - Struct with status/body: extracts both
	 * - Struct with statusCode/headers/body: returns as-is
	 * - Empty: returns 200 with empty body
	 *
	 * @handlerResult Handler method return value
	 * @return Normalized response struct
	 */
	public struct function extractResponse(any handlerResult) {
		// Handle null/undefined return
		if (isNull(arguments.handlerResult)) {
			return buildResponse();
		}

		// Handle string return (body only)
		if (isSimpleValue(arguments.handlerResult)) {
			return buildResponse(body: arguments.handlerResult);
		}

		// Handle struct return
		if (isStruct(arguments.handlerResult)) {
			var statusCode = 200;
			var headers = {};
			var body = "";

			// Extract statusCode (check both "statusCode" and "status" keys)
			if (structKeyExists(arguments.handlerResult, "statusCode")) {
				statusCode = arguments.handlerResult.statusCode;
			} else if (structKeyExists(arguments.handlerResult, "status")) {
				statusCode = arguments.handlerResult.status;
			}

			// Extract headers
			if (structKeyExists(arguments.handlerResult, "headers")) {
				headers = arguments.handlerResult.headers;
			}

			// Extract body
			if (structKeyExists(arguments.handlerResult, "body")) {
				body = arguments.handlerResult.body;
			} else if (structKeyExists(arguments.handlerResult, "content")) {
				body = arguments.handlerResult.content;
			}

			return buildResponse(statusCode, headers, body);
		}

		// Fallback: return default response
		return buildResponse();
	}

}
