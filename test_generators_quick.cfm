<cfscript>
try {
	// Test ModelGenerator
	modelGen = new fuse.cli.generators.ModelGenerator();
	writeOutput("ModelGenerator instantiated successfully<br>");

	// Test MigrationGenerator
	migGen = new fuse.cli.generators.MigrationGenerator();
	writeOutput("MigrationGenerator instantiated successfully<br>");

	// Test HandlerGenerator
	handlerGen = new fuse.cli.generators.HandlerGenerator();
	writeOutput("HandlerGenerator instantiated successfully<br>");

	writeOutput("<br><strong>All generators compiled successfully!</strong>");

} catch (any e) {
	writeOutput("<strong>Error:</strong> " & e.message & "<br>");
	writeOutput("<strong>Detail:</strong> " & e.detail & "<br>");
	writeDump(e);
}
</cfscript>
