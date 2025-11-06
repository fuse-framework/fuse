# Raw Idea: Smart Eager Loading

## Feature Name
Smart Eager Loading

## Feature Description
Smart Eager Loading — includes() implementation with automatic N+1 prevention, smart strategy selection (JOIN vs separate queries), nested eager loading support, manual strategy override (joins, preload), result hydration for eager loaded relationships

## Context
This is for the Fuse framework, a CFML/Lucee 7 framework. This is item #8 on the roadmap. Items 1-7 have been completed:

1. Bootstrap Core & DI Container
2. Routing & Event System
3. Cache & View Rendering
4. Query Builder Foundation
5. ActiveRecord Base & CRUD
6. Schema Builder & Migrations
7. ORM Relationships (hasMany, belongsTo, hasOne with relationship metadata and query methods)

## Existing Framework Components

The framework already has:
- ActiveRecord base class with relationships (hasMany, belongsTo, hasOne)
- QueryBuilder for raw SQL
- ModelBuilder for ORM features
- Relationship definitions and basic relationship query methods

## Roadmap Position
Item #8 on the product roadmap
