<cfscript>
try {
	writeOutput("<h2>Testing ModelGenerator</h2>");

	modelGen = new fuse.cli.generators.ModelGenerator();
	result = modelGen.generate(
		name = "TestUser",
		attributes = ["name:string", "email:string:unique"],
		options = {
			basePath: expandPath("/tests/tmp/"),
			noMigration: true
		}
	);

	writeOutput("Success: " & result.success & "<br>");
	writeOutput("Model Path: " & result.modelPath & "<br>");
	writeOutput("File exists: " & fileExists(result.modelPath) & "<br><br>");

	writeOutput("<h2>Testing MigrationGenerator</h2>");

	migGen = new fuse.cli.generators.MigrationGenerator();
	result2 = migGen.generate(
		name = "CreateTestPosts",
		attributes = ["title:string", "body:text"],
		options = {
			basePath: expandPath("/tests/tmp/")
		}
	);

	writeOutput("Success: " & result2.success & "<br>");
	writeOutput("Migration Path: " & result2.migrationPath & "<br>");
	writeOutput("File exists: " & fileExists(result2.migrationPath) & "<br><br>");

	writeOutput("<h2>Testing HandlerGenerator</h2>");

	handlerGen = new fuse.cli.generators.HandlerGenerator();
	result3 = handlerGen.generate(
		name = "TestUsers",
		options = {
			basePath: expandPath("/tests/tmp/")
		}
	);

	writeOutput("Success: " & result3.success & "<br>");
	writeOutput("Handler Path: " & result3.handlerPath & "<br>");
	writeOutput("File exists: " & fileExists(result3.handlerPath) & "<br><br>");

	writeOutput("<h1 style='color:green'>All generators functional!</h1>");

} catch (any e) {
	writeOutput("<h1 style='color:red'>Error:</h1>");
	writeOutput("<strong>Message:</strong> " & e.message & "<br>");
	writeOutput("<strong>Detail:</strong> " & e.detail & "<br>");
	writeDump(e);
}
</cfscript>
