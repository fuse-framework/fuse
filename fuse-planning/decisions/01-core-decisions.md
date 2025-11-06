# Core Framework Decisions

Fundamental architectural decisions for Fuse framework.

## Decision Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| **Target Platform** | Lucee 7 exclusive | Static methods, Jakarta EE, modern features, lucli integration |
| **DI Container** | Built-in | Cohesive experience, auto-wiring, consistent patterns |
| **Convention Strength** | Rails-strong | Fast development, opinionated structure, best for teams |
| **Bootstrap Pattern** | Application scope with locking | Thread-safe, standard pattern, optional server-level singleton |
| **Migrations** | CFC-based | Type safety, IDE support, reusable, testable |
| **Testing** | Built-in Rails-like | Cohesive experience, framework conventions |
| **CLI** | Embedded in framework | Single install, version-locked to framework |

---

## Target Platform: Lucee 7 Exclusive

### Decision
Target Lucee 7 exclusively. No backwards compatibility with Lucee 6.x or Adobe ColdFusion.

### Rationale
1. **Static methods required**: Essential for clean ActiveRecord pattern (`User::find()`)
2. **lucli integration**: Framework relies on lucli CLI (Lucee 7 only)
3. **Jakarta EE access**: Modern Java ecosystem via PageContext wrapper
4. **Simpler codebase**: No compatibility layers, version checks, or polyfills
5. **Modern patterns**: Latest CFML features without constraints
6. **Future-aligned**: Active Lucee development, community support
7. **Stable platform**: Lucee 7 mature, well-tested
8. **Optional performance**: Server-level singleton mode available

### Why Exclusive Works
- **Clean requirements**: Static methods + lucli = Lucee 7 only
- **Modern stack**: Target forward-thinking developers
- **No compromises**: Use best patterns without legacy constraints
- **Realistic expectations**: Standard Lucee 7 performance (1-5ms overhead)

### Trade-offs
- **Narrower audience**: Lucee 7+ only (acceptable for new framework)
- **No Adobe CF**: Can't target Adobe (acceptable)
- **Cutting edge**: Requires modern Lucee installation

### Verdict
**Lucee 7 exclusive** - framework fundamentally relies on static methods and lucli. Embrace modern platform fully.

---

## DI Container: Built-in

### Decision
Framework includes full DI container with auto-wiring, constructor/property injection.

### Rationale
1. **Cohesive experience**: Everything works together out of the box
2. **Auto-wiring**: Convention-based dependency injection
3. **Consistent patterns**: Single way to do DI across framework
4. **Framework integration**: Core modules use same DI as user code
5. **Learning curve**: One system to learn (vs optional external DI)

### Alternatives Considered
- **Optional DI** (FW/1 pattern): Lower entry barrier but inconsistent experience
- **Adapter pattern**: Maximum flexibility but fragmented ecosystem

### Implementation Notes
- Lightweight implementation (not full WireBox clone)
- Constructor injection primary, property injection secondary
- Singleton/transient scopes
- Interface binding for pluggable components

---

## Convention Strength: Rails-strong

### Decision
Heavy conventions with sensible defaults, minimal configuration required.

### Rationale
1. **Fast development**: Less boilerplate, more productivity
2. **Opinionated structure**: Clear project organization
3. **Team-friendly**: Easy onboarding, consistent codebases
4. **Rails lineage**: Proven pattern, familiar to many developers
5. **Wheels experience**: Peter maintains Wheels (Rails-like CFML framework)

### Conventions
- File/directory structure (handlers/, models/, views/)
- Naming patterns (UsersHandler.cfc, User.cfc)
- Database table names (users for User model)
- Route patterns (RESTful by default)
- Auto-discovery (modules, models, handlers)

### Escape Hatches
- Configuration can override any convention
- Explicit registration when needed
- Custom naming strategies available

---

## Bootstrap Pattern: Application Scope with Locking

### Decision
Application scope caching with proper locking, request-scoped accessor for per-request data.

### Rationale
1. **Thread-safe**: Exclusive lock during init, reads thread-safe
2. **Standard pattern**: Works on vanilla Lucee 7
3. **Request isolation**: Request-scoped accessor for per-request data
4. **Development-friendly**: Optional reload via query param
5. **Production-ready**: No special server config required

### Pattern
```cfml
// Application.cfc
component {
    function onApplicationStart() {
        lock name="fuseBootstrap_#this.name#" type="exclusive" timeout="30" {
            application.fuse = new fuse.system.Bootstrap().init();
        }
        return true;
    }

    function onRequestStart(targetPath) {
        // Optional: Development reload support
        if (structKeyExists(url, "fuseReload") && isDevelopment()) {
            lock name="fuseReload_#this.name#" type="exclusive" timeout="30" {
                applicationStop();
            }
        }

        // Request-scoped accessor (no lock needed - reads thread-safe)
        request._fuse = application.fuse.framework;
        return request._fuse.handleRequest(targetPath);
    }
}
```

### Benefits
- **No special config**: Works out of box
- **Thread-safe**: Proper locking prevents race conditions
- **No read locks needed**: Application scope reads thread-safe in Lucee
- **Simple reload**: Query param for development
- **Optional optimization**: Can enable server singleton for 5-20ms/request boost

### Performance
- Standard: <1ms per request (application scope read)
- Optimized: Can enable server-level singleton for extra performance

---

## Migrations: CFC-based

### Decision
Database migrations are CFC components extending base Migration class.

### Rationale
1. **Type safety**: Method signatures, return types
2. **IDE support**: Auto-complete, refactoring, navigation
3. **Reusable**: Extend base class with helper methods
4. **Testable**: Can unit test migration logic
5. **Object-oriented**: Access to DI container, services
6. **Consistent**: Matches rest of framework (everything is CFCs)
7. **Rails/Laravel pattern**: Both use class-based migrations

### Pattern
```cfml
// db/migrations/20250105120000_CreateUsersTable.cfc
component extends="fuse.orm.Migration" {
    function up() {
        create.table("users", function(t) {
            t.id();
            t.string("email").unique().notNull();
            t.string("name");
            t.timestamps();
        });
    }

    function down() {
        drop.table("users");
    }
}
```

### Alternatives Considered
- **CFM script**: Simpler but no IDE support, no inheritance
- **Raw SQL**: Direct but no abstraction, no cross-DB support

### Verdict
CFC migrations provide superior developer experience and maintainability.

---

## Testing: Built-in Rails-like

### Decision
Framework includes built-in test framework with Rails-like conventions.

### Rationale
1. **Cohesive experience**: Testing integrated with framework
2. **Convention-based**: Test files match source files
3. **Framework-aware**: Helpers for models, handlers, integration tests
4. **Single install**: No separate testing framework
5. **Consistent patterns**: Same conventions as rest of framework

### Pattern
```cfml
// tests/models/UserTest.cfc
component extends="fuse.testing.TestCase" {
    function testUserCreation() {
        user = User.create({email: "test@example.com", name: "Test"});

        assert(user.persisted());
        assertEqual("test@example.com", user.email);
    }
}
```

### Features
- TestCase base class
- Assertions library
- Database fixtures/factories
- Integration test helpers
- Handler/request testing

### Alternatives Considered
- **TestBox integration**: Mature tool but external dependency
- **Test-agnostic**: Maximum flexibility but no conventions

### Verdict
Built-in testing aligns with Rails-strong convention philosophy.

---

## CLI: Embedded

### Decision
CLI code embedded in framework (fuse/cli/), loaded by lucli as extension.

### Rationale
1. **Single install**: Framework includes CLI tools
2. **Version-locked**: CLI version matches framework version
3. **Cohesive**: Generators know framework structure
4. **Simpler distribution**: One package, not two
5. **lucli leverage**: Build on lucli infrastructure

### Structure
```
fuse/
  cli/
    FuseCLI.cfc          - Entry point for lucli
    commands/
      NewCommand.cfc     - lucli fuse:new
      GenerateCommand.cfc
      MigrateCommand.cfc
      TestCommand.cfc
```

### Commands
```bash
lucli fuse:new myapp
lucli fuse:generate:handler Users
lucli fuse:generate:model Post
lucli fuse:db:migrate
lucli fuse:test
lucli fuse:serve
```

### Alternatives Considered
- **Separate package**: Independent versioning but distribution complexity
- **lucli extension only**: Minimal framework code but harder to maintain

### Verdict
Embedded CLI provides best developer experience with single install.

---

## Summary

All core decisions align toward a **modern, opinionated, Rails-inspired CFML framework** that:
- Leverages Lucee 7 exclusively for modern features
- Provides cohesive, batteries-included experience
- Emphasizes convention over configuration
- Optimizes for developer productivity
- Maintains clean, testable architecture

These decisions form the foundation for all subsequent architectural choices.
