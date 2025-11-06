component extends="testbox.system.BaseSpec" {

	function run() {
		describe("EventService interceptor registration and execution", function() {

			beforeEach(function() {
				eventService = new fuse.core.EventService();
			});

			it("should register interceptor for valid point", function() {
				var listener = function(required struct event) {
					event.executed = true;
				};

				eventService.registerInterceptor("onBeforeRequest", listener);

				// Verify registration by triggering
				var event = {abort: false};
				eventService.trigger("onBeforeRequest", event);
				expect(event.executed).toBeTrue();
			});

			it("should trigger all registered listeners in order", function() {
				var executionOrder = [];

				var listener1 = function(required struct event) {
					arrayAppend(executionOrder, "first");
				};

				var listener2 = function(required struct event) {
					arrayAppend(executionOrder, "second");
				};

				var listener3 = function(required struct event) {
					arrayAppend(executionOrder, "third");
				};

				eventService.registerInterceptor("onAfterRouting", listener1);
				eventService.registerInterceptor("onAfterRouting", listener2);
				eventService.registerInterceptor("onAfterRouting", listener3);

				var event = {abort: false};
				eventService.trigger("onAfterRouting", event);

				expect(executionOrder).toHaveLength(3);
				expect(executionOrder[1]).toBe("first");
				expect(executionOrder[2]).toBe("second");
				expect(executionOrder[3]).toBe("third");
			});

			it("should short-circuit execution when event.abort is true", function() {
				var executionOrder = [];

				var listener1 = function(required struct event) {
					arrayAppend(executionOrder, "first");
					event.abort = true;
				};

				var listener2 = function(required struct event) {
					arrayAppend(executionOrder, "second");
				};

				var listener3 = function(required struct event) {
					arrayAppend(executionOrder, "third");
				};

				eventService.registerInterceptor("onBeforeHandler", listener1);
				eventService.registerInterceptor("onBeforeHandler", listener2);
				eventService.registerInterceptor("onBeforeHandler", listener3);

				var event = {abort: false};
				eventService.trigger("onBeforeHandler", event);

				// Only first listener should execute
				expect(executionOrder).toHaveLength(1);
				expect(executionOrder[1]).toBe("first");
				expect(event.abort).toBeTrue();
			});

			it("should support all 6 interceptor points", function() {
				var points = [
					"onBeforeRequest",
					"onAfterRouting",
					"onBeforeHandler",
					"onAfterHandler",
					"onBeforeRender",
					"onAfterRender"
				];

				for (var point in points) {
					var executed = false;
					var listener = function(required struct event) {
						executed = true;
					};

					eventService.registerInterceptor(point, listener);
					var event = {abort: false};
					eventService.trigger(point, event);

					expect(executed).toBeTrue("Point #point# should execute");
				}
			});

			it("should throw error for invalid interceptor point", function() {
				var listener = function(required struct event) {};

				expect(function() {
					eventService.registerInterceptor("invalidPoint", listener);
				}).toThrow(type = "InvalidInterceptorPointException");
			});

			it("should return modified event struct from trigger", function() {
				var listener = function(required struct event) {
					event.modified = true;
					event.data = "test value";
				};

				eventService.registerInterceptor("onAfterHandler", listener);

				var event = {abort: false};
				var result = eventService.trigger("onAfterHandler", event);

				expect(result).toBeStruct();
				expect(result.modified).toBeTrue();
				expect(result.data).toBe("test value");
			});

			it("should handle trigger when no listeners registered", function() {
				var event = {abort: false, data: "original"};
				var result = eventService.trigger("onBeforeRequest", event);

				expect(result).toBeStruct();
				expect(result.data).toBe("original");
			});

			it("should allow multiple listeners per point to modify event", function() {
				var listener1 = function(required struct event) {
					event.value = (structKeyExists(event, "value") ? event.value : 0) + 1;
				};

				var listener2 = function(required struct event) {
					event.value = (structKeyExists(event, "value") ? event.value : 0) + 10;
				};

				var listener3 = function(required struct event) {
					event.value = (structKeyExists(event, "value") ? event.value : 0) + 100;
				};

				eventService.registerInterceptor("onBeforeRender", listener1);
				eventService.registerInterceptor("onBeforeRender", listener2);
				eventService.registerInterceptor("onBeforeRender", listener3);

				var event = {abort: false};
				eventService.trigger("onBeforeRender", event);

				expect(event.value).toBe(111);
			});

		});
	}

}
