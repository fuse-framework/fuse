<cfscript>
// Manual test for handler return processing

// Setup container with required services
container = new fuse.core.Container();

// Register config
container.singleton("config", function(c) {
	return {
		views: {
			path: "/tests/fixtures/views",
			layoutPath: "/tests/fixtures/views/layouts",
			defaultLayout: "application"
		}
	};
});

// Register router singleton
container.singleton("router", function(c) {
	return new fuse.core.Router();
});

// Register eventService singleton
container.singleton("eventService", function(c) {
	return new fuse.core.EventService();
});

// Register ViewRenderer
container.singleton("ViewRenderer", function(c) {
	var config = c.resolve("config");
	return new fuse.views.ViewRenderer(config);
});

// Setup ViewModule to register interceptors
viewModule = new fuse.modules.ViewModule();
viewModule.register(container);
viewModule.boot(container);

// Setup test routes
router = container.resolve("router");
router.get("/users/:id", "Users.show", {name: "users_show"});

// Register dispatcher
container.bind("dispatcher", function(c) {
	return new fuse.core.Dispatcher(
		c.resolve("router"),
		c,
		c.resolve("eventService")
	);
});

// Test 1: String return
writeOutput("<h2>Test 1: String Return</h2>");
container.bind("Users", function(c) {
	return {
		show: function(id) {
			return "users/show";
		}
	};
});

dispatcher = container.resolve("dispatcher");
result = dispatcher.dispatch("/users/123", "GET");

if (structKeyExists(result, "body") && result.body contains "User ##123") {
	writeOutput("<p style='color:green'>PASS: String return processed correctly</p>");
} else {
	writeOutput("<p style='color:red'>FAIL: Expected view to render</p>");
	writeDump(result);
}

// Test 2: Struct return with locals
writeOutput("<hr><h2>Test 2: Struct Return with Locals</h2>");
router.get("/posts/:id", "Posts.show", {name: "posts_show"});
container.bind("Posts", function(c) {
	return {
		show: function(id) {
			return {
				view: "posts/show",
				locals: {id: arguments.id}
			};
		}
	};
});

dispatcher = container.resolve("dispatcher");
result = dispatcher.dispatch("/posts/456", "GET");

if (structKeyExists(result, "body") && result.body contains "Post ##456") {
	writeOutput("<p style='color:green'>PASS: Struct return with locals processed correctly</p>");
} else {
	writeOutput("<p style='color:red'>FAIL: Expected view with locals to render</p>");
	writeDump(result);
}

// Test 3: Null return (derive view from route)
writeOutput("<hr><h2>Test 3: Null Return (Convention)</h2>");
router.get("/articles/:id", "Articles.show");
container.bind("Articles", function(c) {
	return {
		show: function(id) {
			// No explicit return - should derive "articles/show"
		}
	};
});

dispatcher = container.resolve("dispatcher");
result = dispatcher.dispatch("/articles/789", "GET");

writeOutput("<p>Result for null return:</p>");
writeDump(var=result, label="Null Return Result");

writeOutput("<hr><h2>All Tests Complete</h2>");
</cfscript>
