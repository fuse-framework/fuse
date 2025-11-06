# Fuse Framework Planning Documentation

Comprehensive planning and architecture documentation for Fuse - a modern Lucee 7 framework.

**Repository:** https://github.com/fuse-framework/fuse
**Planning Docs:** https://github.com/fuse-framework/fuse-planning

---

## Project Vision

**Fuse** is a Rails-inspired, convention-over-configuration CFML framework built exclusively for Lucee 7. It combines the best patterns from Rails, Laravel, and Django with CFML's strengths to create a productive, modern development experience.

### Core Principles
- **Lucee 7 exclusive**: Static methods, Jakarta EE, modern runtime features
- **Rails-strong conventions**: Fast development, minimal configuration
- **Batteries included**: DI, ORM, testing, CLI built-in
- **Developer experience first**: Clear errors, great tooling, comprehensive docs
- **Modular architecture**: Everything is a module, easily extensible
- **Architecture-first performance**: Clean design beats runtime magic
- **AI agent-friendly**: Machine-readable API schema, explicit contracts, code generation templates

---

## For AI Agents

**START HERE:** **[AI Agent Guide](ai-agent-guide.md)** - Quick start, decision trees, common tasks

**Critical References:**
- **[API Reference (YAML)](api-reference.yaml)** - Machine-parseable API schema
- **[Error Reference](error-reference.md)** - All exceptions and handling patterns
- **[Code Templates](code-generation-templates/)** - Generation templates for models, handlers, etc.

---

## Documentation Index

### Research
Analysis of existing frameworks and technologies to inform Fuse design.

1. **[Bootstrap Comparison](research/01-bootstrap-comparison.md)**
   - How FW/1, ColdBox, and Wheels initialize
   - Comparison matrix of approaches
   - Key insights for Fuse

2. **[Query Builder Comparison](research/02-query-builder-comparison.md)**
   - Rails ActiveRecord vs Laravel Eloquent
   - Side-by-side syntax examples
   - Recommendations for Fuse

3. **[Lucee 7 Capabilities](research/03-lucee-7-capabilities.md)**
   - Static methods in components
   - Jakarta EE access via PageContext
   - Optional server-level singleton optimization
   - Modern features enabling better framework design

### Decisions
Architectural decisions with rationale.

1. **[Core Decisions](decisions/01-core-decisions.md)**
   - Target platform (Lucee 7 exclusive)
   - DI container (built-in)
   - Convention strength (Rails-strong)
   - Bootstrap pattern (application scope with locking)
   - Migrations (CFC-based)
   - Testing (built-in)
   - CLI (embedded)

2. **[ORM Decisions](decisions/02-orm-decisions.md)**
   - ActiveRecord pattern
   - Two-layer query builder
   - Hash-based where syntax
   - Explicit query execution
   - Smart eager loading
   - Method-based scopes

3. **[Module Decisions](decisions/03-module-decisions.md)**
   - Auto-discovery pattern
   - IModule interface
   - Pluggable cache layer
   - Everything-is-a-module approach

### Architecture
Detailed technical architecture specifications.

1. **[Bootstrap Architecture](architecture/01-bootstrap-architecture.md)**
   - Application.cfc pattern
   - Bootstrap.cfc orchestration
   - Module loading sequence
   - DI container integration
   - Complete initialization flow

2. **[ORM Architecture](architecture/02-orm-architecture.md)**
   - QueryBuilder implementation (database layer)
   - ModelBuilder layer (ORM features)
   - ActiveRecord base class (static methods, instance methods)
   - Eager loading algorithm
   - Transaction handling
   - Static method boilerplate reality

3. **[Module System](architecture/03-module-system.md)** *(To be created)*
   - Module discovery
   - Dependency resolution
   - Lifecycle (register/boot)
   - Route collection
   - Interceptor registration

4. **[Cache Architecture](architecture/04-cache-architecture.md)** *(To be created)*
   - CacheManager design
   - ICacheProvider interface
   - RAM provider implementation
   - Third-party provider pattern

5. **[CLI Architecture](architecture/05-cli-architecture.md)** *(To be created)*
   - lucli integration
   - Command structure
   - Generator templates
   - Database commands

### Roadmap
Implementation plan and timeline.

1. **[Implementation Phases](roadmap/implementation-phases.md)**
   - 16-week implementation plan
   - Week-by-week deliverables
   - Milestones and success criteria
   - Risk mitigation

2. **[Open Questions](roadmap/open-questions.md)**
   - Unresolved architectural questions
   - Deferred decisions
   - Priority rankings
   - Decision process

---

## Quick Reference

### Key Decisions

| Aspect | Decision |
|--------|----------|
| **Platform** | Lucee 7 only |
| **Bootstrap** | Application singleton + request accessor |
| **DI** | Built-in container with auto-wiring |
| **ORM** | ActiveRecord with Eloquent architecture |
| **Query Syntax** | Hash-based where, explicit `.get()` |
| **Caching** | Pluggable, RAM default |
| **Modules** | Auto-discovery, IModule interface |
| **Testing** | Built-in Rails-like framework |
| **CLI** | Embedded, lucli-based |
| **Migrations** | CFC with schema builder |

### Timeline

- **Weeks 1-2**: Bootstrap core, DI container
- **Weeks 3-4**: Routing, events, cache, views
- **Weeks 5-7**: ORM foundation (query builder, ActiveRecord, migrations)
- **Weeks 8-9**: ORM relationships and eager loading
- **Week 10**: Validations and callbacks
- **Weeks 11-12**: Testing framework
- **Weeks 13-14**: CLI tools and generators
- **Weeks 15-16**: Documentation, polish, 1.0 release

### Example Usage

```cfml
// Model
component extends="fuse.orm.ActiveRecord" {
    function init() {
        super.init();
        validates("email", {required: true, email: true});
        hasMany("posts");
    }
}

// Query
users = User.where({active: true})
    .includes("posts")
    .orderBy("created_at DESC")
    .limit(10)
    .get();

// Handler
component {
    function index() {
        users = User.active().recent().get();
        return {view: "users/index", data: {users: users}};
    }
}

// Migration
component extends="fuse.orm.Migration" {
    function up() {
        create.table("users", function(t) {
            t.id();
            t.string("email").unique();
            t.timestamps();
        });
    }
}

// CLI
lucli fuse:new myapp
lucli fuse:generate:model User
lucli fuse:db:migrate
lucli fuse:test
```

---

## Research Sources

### CFML Frameworks
- **Wheels**: `/wheels/` - Rails-inspired CFML framework
- **FW/1**: `/fw1/` - Lightweight convention-based framework
- **ColdBox**: `/coldbox-platform/` - Enterprise modular framework

### Non-CFML Frameworks
- **Rails**: `/rails/` - Ruby web framework
- **Django**: `/django/` - Python web framework
- **Laravel**: `/laravel-framework/` - PHP web framework

### Platform
- **Lucee**: `/lucee/` - Lucee server source
- **lucli**: `/lucli/` - Lucee CLI tool

---

## Next Steps

### For Implementation
1. Review all decision documents
2. Start with Phase 1: Bootstrap Core (weeks 1-2)
3. Follow implementation roadmap
4. Update architecture docs as implementation progresses
5. Resolve open questions as they become critical

### For Planning
1. Create remaining architecture documents (ORM, Module System, Cache, CLI)
2. Expand open questions as new ones arise
3. Document decisions as they're made
4. Update roadmap based on actual progress

---

## Contributing to Planning

When adding to this planning documentation:

1. **Research**: Document findings in `research/`
2. **Decisions**: Record decisions with rationale in `decisions/`
3. **Architecture**: Detail technical specs in `architecture/`
4. **Roadmap**: Update timeline and open questions in `roadmap/`
5. **Update this README**: Keep index current

---

## Notes

This is living documentation. Update as:
- Decisions are made
- Architecture evolves
- Implementation reveals new insights
- Community provides feedback

Goal: Comprehensive reference for building Fuse from design through 1.0 release.

---

**Last Updated**: 2025-01-05
**Status**: Planning phase
**Target 1.0 Release**: 16 weeks from implementation start
