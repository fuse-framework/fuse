# Fuse: A Modern CFML Framework for Lucee 7

---

## The Problem

### CFML Framework Landscape (2025)

**Current Options:**

| Framework | Last Major Update | Target Platform | Modern Patterns |
|-----------|------------------|-----------------|-----------------|
| **ColdBox** | Active | ACF + Lucee | Comprehensive but complex |
| **FW/1** | Maintenance mode | ACF + Lucee 5.x | Simple but dated |
| **Wheels** | Active | ACF + Lucee | Rails-like but legacy compatible |

**The Gap:**

- No framework built exclusively for **modern Lucee 7**
- No framework leveraging **static methods** (Lucee 6+)
- No framework with **AI agent-first documentation**
- Legacy compatibility holds back innovation

---

## Why Now?

### Lucee 7 Changes Everything

**Static Methods in Components** (Lucee 6+, stable in 7)
```cfml
// Impossible before Lucee 6
user = User::find(1)
users = User::where({active: true}).get()
```

**Jakarta EE** (Modern Java ecosystem)
```cfml
// Access modern servlet APIs
servletContext = getPageContext().getServletContext()
```

**Application Singleton Mode** (Optional optimization)
```bash
# Server-level configuration
export lucee.application.singelton=true
```

**The Opportunity:** Build a framework that embraces Lucee 7 fully, no compromises.

---

## Introducing Fuse

### What is Fuse?

**A Rails-inspired, convention-over-configuration CFML framework built exclusively for Lucee 7.**

```cfml
// Modern, expressive syntax
users = User.includes("posts", "company")
    .where({active: true})
    .recent(30)
    .get()

for (user in users) {
    // No N+1 queries - relationships eager loaded
    writeOutput("#user.name# works at #user.company.name#")
}
```

**Core Philosophy:**
- **Lucee 7 exclusive** - No legacy baggage
- **Rails-strong conventions** - Productivity over configuration
- **Batteries included** - DI, ORM, testing, CLI built-in
- **AI agent-friendly** - Machine-readable docs, code generation
- **Developer experience first** - Fast, fun, modern

---

## The Fuse Advantage

### 1. ActiveRecord ORM

**Two-Layer Architecture** (Eloquent-inspired)

```
QueryBuilder (database layer)
    ↓
ModelBuilder (ORM features)
    ↓
ActiveRecord (base model)
```

**Hash-Based Where Syntax** (ActiveRecord-style)
```cfml
// Natural CFML structs
User.where({
    active: true,
    age: {gte: 18},
    email: {like: "%@example.com"}
}).get()
```

**Smart Eager Loading** (Prevents N+1)
```cfml
// Bad: 101 queries (N+1 problem)
users = User.get()
for (user in users) {
    posts = user.posts().get()  // Query per user
}

// Good: 2 queries total
users = User.includes("posts").get()
for (user in users) {
    posts = user.posts  // Already loaded!
}
```

**Static Method Syntax** (Requires Lucee 7)
```cfml
User::find(1)
User::where({active: true})
User::create({name: "John", email: "john@test.com"})
```

---

### 2. Convention Over Configuration

**File Structure** (Just works)
```
myapp/
├── models/User.cfc          → users table
├── handlers/UsersHandler.cfc → /users routes
├── views/users/index.cfm     → Auto-rendered
└── db/migrations/            → CFC-based
```

**Zero Config Setup**
```cfml
// models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    // Convention: User → users table
    // Convention: id = primary key
    // Just define relationships and validations

    function init() {
        super.init()
        validates("email", {required: true, email: true, unique: true})
        hasMany("posts")
    }
}
```

**RESTful Routes** (One line)
```cfml
// config/routes.cfm
router.resource("users")

// Generates 7 routes automatically:
// GET    /users           → index
// GET    /users/new       → new
// POST   /users           → create
// GET    /users/:id       → show
// GET    /users/:id/edit  → edit
// PUT    /users/:id       → update
// DELETE /users/:id       → delete
```

---

### 3. Modern Developer Experience

**CFC-Based Migrations** (Type-safe, IDE-friendly)
```cfml
// db/migrations/20250105_CreateUsers.cfc
component extends="fuse.orm.Migration" {
    function up() {
        schema.create("users", function(table) {
            table.id()
            table.string("name")
            table.string("email").unique()
            table.timestamps()
        })
    }

    function down() {
        schema.drop("users")
    }
}
```

**Built-in Testing** (Rails-like)
```cfml
// tests/models/UserTest.cfc
component extends="fuse.testing.TestCase" {
    function testEmailValidation() {
        user = User.create({email: "invalid"})
        assert(user.hasErrors())
    }
}
```

**lucli Integration** (Lucee 7 CLI)
```bash
lucli fuse:new myapp           # Create new app
lucli fuse:generate:model User # Generate model
lucli fuse:db:migrate          # Run migrations
lucli fuse:test                # Run tests
```

---

### 4. AI Agent-Friendly

**Machine-Readable API Schema**
```yaml
# api-reference.yaml
User:
  methods:
    find:
      type: static
      params: [{name: id, type: numeric|string, required: true}]
      returns: User|null
      throws: []
      executes: immediate
```

**Code Generation Templates**
```cfml
// AI can generate from templates
lucli fuse:generate:crud Post
  → Post.cfc (model)
  → PostsHandler.cfc (handler)
  → 20250105_CreatePosts.cfc (migration)
  → tests/models/PostTest.cfc (tests)
```

**Explicit Error Contracts**
```markdown
ModelNotFoundException
├─ When: findOrFail() with missing ID
├─ Returns: {model: "User", id: 999}
└─ Handle: 404 response
```

**Decision Trees**
```
Need record by ID? → User.find(id)
Need records by criteria? → User.where({...}).get()
Need to eager load? → User.includes("posts")
```

---

## Performance

### Architecture-First Performance

**Not Magic, Just Clean Design:**

| Metric | Target | How |
|--------|--------|-----|
| Framework overhead | <1ms/request | Application scope caching, no reload checks |
| Query builder | 2-10ms | Two-layer separation, prepared statements |
| Eager loading | 3 queries vs N+1 | Smart strategy (JOIN vs separate) |
| Memory footprint | ~10MB | Efficient component lifecycle |
| Startup time | <200ms | Module-based, dependency resolution |

**Optional Server Optimization:**
```bash
# Enable Lucee singleton mode (5-20ms/request savings)
export lucee.application.singelton=true
```

**Realistic Expectations:**
- Not revolutionary performance
- Solid, predictable, modern CFML speed
- Performance through **architecture** not runtime magic

---

## Module System

### Everything is a Module

**Core Modules** (Built-in)
```
fuse/modules/
├── routing/   - Router, route matching
├── events/    - Event system, interceptors
├── cache/     - Cache manager + RAM provider
├── orm/       - ActiveRecord, query builder
├── views/     - View rendering, layouts
└── testing/   - Test framework
```

**Third-Party Modules** (Community)
```
modules/
├── fuse-auth/     - Authentication
├── fuse-admin/    - Admin panel
├── fuse-api/      - API toolkit
├── fuse-redis/    - Redis cache provider
├── fuse-email/    - Email sending
└── fuse-queue/    - Background jobs
```

**Module Interface** (Consistent)
```cfml
component implements="fuse.interfaces.IModule" {
    function getName() { return "auth" }
    function getDependencies() { return {required: ["cache"]} }
    function register(injector) { /* DI bindings */ }
    function boot(framework) { /* Initialize */ }
    function getRoutes() { /* Module routes */ }
}
```

---

## Why Fuse vs Existing Frameworks?

### Comparison Matrix

|  | ColdBox | FW/1 | Wheels | **Fuse** |
|--|---------|------|--------|----------|
| **Target** | ACF + Lucee | ACF + Lucee 5.x | ACF + Lucee | **Lucee 7 only** |
| **Static Methods** | No | No | No | **Yes** |
| **ORM** | ColdBox ORM | External | Wheels ORM | **ActiveRecord** |
| **Where Syntax** | Method-based | N/A | Method-based | **Hash-based** |
| **DI** | WireBox | Optional | WireBox | **Built-in** |
| **Migrations** | DBMigrate | External | DBMigrate | **CFC-based** |
| **Testing** | TestBox | External | TestBox | **Built-in** |
| **CLI** | CommandBox | N/A | CommandBox | **lucli** |
| **AI Docs** | No | No | No | **Yes (YAML)** |
| **Complexity** | High | Low | Medium | **Medium** |

### When to Use Each

**Use ColdBox if:**
- Need Adobe CF support
- Want enterprise features
- Team already knows ColdBox

**Use FW/1 if:**
- Want minimal framework
- Legacy Lucee 5.x

**Use Wheels if:**
- Need Adobe CF support
- Want Rails patterns
- Maintain Wheels apps

**Use Fuse if:**
- Lucee 7 exclusive ✅
- Want modern patterns (static methods, ActiveRecord) ✅
- AI agent coding ✅
- Rails-like DX without legacy baggage ✅
- Building new applications ✅

---

## The Case for Fuse

### 1. Embrace Modern Lucee

**Stop Holding Back:**
- Other frameworks support ACF → can't use Lucee 7 features
- Legacy compatibility prevents innovation
- Fuse says: **Lucee 7 only, use everything**

**Static Methods:**
```cfml
// Clean, expressive, Rails-like
User::find(1)
User::where({active: true}).recent().get()

// vs traditional
userService.find(1)
userGateway.getActive().getRecent()
```

**Modern Stack:**
- Jakarta EE (modern Java ecosystem)
- lucli (proper CLI)
- Current Lucee development

---

### 2. Developer Productivity

**Batteries Included:**
- ORM, migrations, validations
- DI container, module system
- Testing framework
- CLI tools
- View rendering

**Convention Over Configuration:**
```cfml
// This just works:
component extends="fuse.orm.ActiveRecord" {
    function init() {
        validates("email", {email: true})
        hasMany("posts")
    }
}

// vs configuring:
// - table name
// - primary key
// - datasource
// - column mappings
// - relationship setup
```

**Fast Scaffolding:**
```bash
lucli fuse:generate:crud BlogPost
# → Model, Handler, Migration, Tests, Views
# Ready to customize, not start from scratch
```

---

### 3. AI-First Framework

**The Future is AI-Assisted Coding:**

**Fuse Provides:**
- Machine-readable API schema (YAML)
- Explicit types, returns, throws
- Code generation templates
- Decision trees for common tasks
- Complete error taxonomy

**Result:**
- AI agents can generate correct Fuse code
- Less "hallucination", more accuracy
- Faster development with AI pair programming

**Example AI Prompt:**
```
"Create a User model with email validation,
 has many Posts relationship, and tests"
```

**AI Response:**
```cfml
// Reads api-reference.yaml
// Uses model.cfc.template
// Generates correct code instantly
component extends="fuse.orm.ActiveRecord" {
    function init() {
        validates("email", {required: true, email: true})
        hasMany("posts")
    }
}
```

---

### 4. Forward-Thinking

**Not Just For Today:**

**Lucee 7+ Alignment:**
- Active development (vs maintenance mode)
- Modern runtime (Jakarta EE, async/await coming)
- Performance improvements
- Community support

**Extensible Architecture:**
- Module system (everything is a module)
- Pluggable components (cache, DI, routing)
- Clean interfaces
- Easy to extend, customize

**AI Integration:**
- Ready for AI code generation
- Ready for AI code review
- Ready for AI documentation

**Future Enhancements:**
- Background jobs module
- WebSocket support
- GraphQL support
- Real-time features
- Enhanced tooling

---

## Roadmap

### 16-Week Implementation Plan

**Phase 1: Bootstrap (Weeks 1-2)**
- Application.cfc pattern
- Module loading
- DI container

**Phase 2: Core Modules (Weeks 3-4)**
- Routing system
- Event system
- Cache layer
- View rendering

**Phase 3: ORM Foundation (Weeks 5-7)**
- QueryBuilder
- ActiveRecord base
- Migrations

**Phase 4: ORM Relationships (Weeks 8-9)**
- hasMany, belongsTo, hasOne
- Eager loading (smart)

**Phase 5: Validations (Week 10)**
- Built-in validators
- Custom validators
- Callbacks

**Phase 6: Testing (Weeks 11-12)**
- Test framework
- Model factories
- Integration tests

**Phase 7: CLI (Weeks 13-14)**
- lucli integration
- Code generators
- Database commands

**Phase 8: Documentation & Polish (Weeks 15-16)**
- Complete docs
- Tutorial app
- 1.0.0 release

**Target: 1.0.0 in 16 weeks**

---

## For Different Audiences

### For Developers

**You'll Love Fuse If You:**
- Want Rails DX in CFML
- Tired of XML configuration
- Love convention over configuration
- Want modern patterns (ActiveRecord, static methods)
- Use AI coding assistants (Cursor, Claude, etc)

**You'll Build Faster:**
- Less boilerplate
- Clear conventions
- Excellent defaults
- Comprehensive CLI

---

### For Teams

**Team Benefits:**
- **Consistent codebases** - Strong conventions
- **Easy onboarding** - Rails familiarity, clear docs
- **Faster development** - Batteries included
- **Modern stack** - Attracts talent
- **AI-ready** - Future-proof

**Lower TCO:**
- Less configuration to maintain
- Fewer dependencies to manage
- Built-in testing (quality)
- Clear upgrade path

---

### For Businesses

**Business Case:**

**Faster Time-to-Market:**
- Rapid prototyping (scaffolding)
- Quick iterations (convention)
- Less debugging (clear errors)

**Lower Development Costs:**
- Higher productivity per developer
- Easier to hire (Rails familiarity)
- Less maintenance (built-in tools)

**Future-Proof:**
- Modern Lucee 7 platform
- Active development
- AI integration ready
- Extensible architecture

**Risk Mitigation:**
- Open source
- Clear documentation
- Active community (planned)
- Professional support (planned)

---

## Getting Started

### Installation

```bash
# Install Lucee 7
# Install lucli

# Create new Fuse app
lucli fuse:new myapp

# Run migrations
cd myapp
lucli fuse:db:migrate

# Start dev server
lucli fuse:serve

# Visit http://localhost:8080
```

### First Model

```cfml
// lucli fuse:generate:model User

// models/User.cfc
component extends="fuse.orm.ActiveRecord" {
    property name="id" type="numeric"
    property name="name" type="string"
    property name="email" type="string"

    function init() {
        super.init()
        validates("email", {required: true, email: true, unique: true})
        hasMany("posts")
    }
}
```

### First Handler

```cfml
// lucli fuse:generate:handler Users

// handlers/UsersHandler.cfc
component {
    function index() {
        return {
            view: "users/index",
            data: {users: User.all().get()}
        }
    }
}
```

### First Route

```cfml
// config/routes.cfm
router.resource("users")
```

**That's it. You have a working CRUD app.**

---

## Community & Support

### Open Source

**License:** MIT
**Repository:** https://github.com/fuse-framework/fuse
**Issues:** https://github.com/fuse-framework/fuse/issues

### Documentation

**Planning Docs:** Complete ✅
**AI Agent Guide:** Complete ✅
**Getting Started:** Phase 8
**API Reference:** Phase 8
**Tutorial:** Phase 8

### Roadmap

**1.0.0:** 16 weeks (Q2 2025)
**1.1.0:** Background jobs, WebSockets (Q3 2025)
**1.2.0:** GraphQL, Admin panel (Q4 2025)

---

## Call to Action

### The Time is Now

**Lucee 7 is here.**
**Static methods are stable.**
**AI coding is mainstream.**
**CFML needs a modern framework.**

### Join the Movement

**For Early Adopters:**
- Shape the framework
- Influence design decisions
- Build the community
- Get in early

**For Contributors:**
- Code contributions welcome
- Documentation help needed
- Module development
- Community building

**For Feedback:**
- Review planning docs
- Try prototypes
- Share use cases
- Report issues

---

## The Bottom Line

### Why Fuse?

**Because CFML developers deserve:**
- Modern patterns (ActiveRecord, static methods)
- Excellent developer experience (Rails-like)
- AI-ready tooling (code generation)
- No legacy compromises (Lucee 7 exclusive)
- Fast, productive development (batteries included)

### The Vision

**Make CFML development:**
- **Fast** - Convention over configuration
- **Fun** - Modern, expressive syntax
- **Future-proof** - AI-ready, Lucee 7 aligned
- **Productive** - Batteries included, great defaults

### The Future is Fuse

**A modern CFML framework for modern developers building modern applications on Lucee 7.**

---

## Questions?

**Repository:** https://github.com/fuse-framework/fuse
**Planning Docs:** https://github.com/fuse-framework/fuse-planning
**Issues:** https://github.com/fuse-framework/fuse/issues
**Discussions:** https://github.com/fuse-framework/fuse/discussions

**Thank you.**

---

## Appendix: Code Examples

### Complete CRUD Example

```cfml
// 1. Model
component extends="fuse.orm.ActiveRecord" {
    function init() {
        validates("title", {required: true, minLength: 3})
        validates("body", {required: true})
        belongsTo("user")
        hasMany("comments")
    }
}

// 2. Migration
component extends="fuse.orm.Migration" {
    function up() {
        schema.create("posts", function(table) {
            table.id()
            table.string("title")
            table.text("body")
            table.foreignId("user_id").references("id").on("users")
            table.timestamps()
        })
    }
}

// 3. Handler
component {
    function index() {
        return {
            view: "posts/index",
            data: {posts: Post.includes("user").orderBy("created_at DESC").get()}
        }
    }

    function create() {
        post = Post.create(params.post)
        if (post.hasErrors()) {
            return {view: "posts/new", data: {post: post, errors: post.getErrors()}}
        }
        relocate("posts.show", {id: post.id})
    }
}

// 4. Routes
router.resource("posts")

// 5. Test
component extends="fuse.testing.TestCase" {
    function testCreatePost() {
        post = Post.create({title: "Test", body: "Body", user_id: 1})
        assert(post.exists)
        assertEquals("Test", post.title)
    }
}
```

**Lines of code:** ~50
**Lines of configuration:** 0
**Time to build:** <10 minutes

**This is Fuse.**
