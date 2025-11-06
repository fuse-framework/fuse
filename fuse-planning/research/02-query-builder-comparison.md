# Query Builder Comparison: ActiveRecord vs Eloquent

Research comparing Rails ActiveRecord and Laravel Eloquent query builder patterns to inform Fuse ORM design.

## Executive Summary

- **ActiveRecord**: Relation-based chainable queries, hash syntax, smart eager loading, tight model integration
- **Eloquent**: Two-layer builder pattern, explicit execution, separate query/model builders, method-based syntax
- **Django ORM**: QuerySet immutability, manager pattern (included for context)

**Recommendation for Fuse**: Hybrid approach - Eloquent's architecture + ActiveRecord's syntax

---

## Rails ActiveRecord

### Architecture
**Relation-based delegation pattern**
- All queries return `ActiveRecord::Relation` objects
- Model class delegates ~80 query methods to `Relation` via `delegate`
- Lazy execution: queries build up but don't execute until iteration

### Query Method Delegation
```ruby
# From querying.rb
QUERYING_METHODS = [
  :find, :find_by, :find_by!, :take, :take!, :first, :first!, :last, :last!,
  :exists?, :any?, :many?, :none?, :one?,
  :second, :second!, :third, :third!, :fourth, :fourth!, :fifth, :fifth!,
  :forty_two, :forty_two!, :third_to_last, :third_to_last!,
  :second_to_last, :second_to_last!,
  :all, :where, :not, :select, :group, :order, :except, :extending,
  :having, :limit, :offset, :lock, :readonly, :or, :having, :create_with,
  :distinct, :references, :includes, :eager_load, :preload, :from,
  :left_outer_joins, :joins, :reselect, :reorder, :reverse_order, :arel,
  :only, :unscope, :optimizer_hints, :merge, :rewhere
].freeze

delegate(*QUERYING_METHODS, to: :all)
```

### Query Examples

#### Simple Queries
```ruby
# Find by ID - immediate execution
User.find(1)
User.find_by(id: 1)  # Returns first or nil

# Where conditions - returns Relation
User.where(name: 'John', active: true)
User.where(age: 18..65)              # Range
User.where.not(name: 'John')         # NOT
User.where('age > ?', 18)            # SQL string with bindings
```

#### Chaining
```ruby
User.where(active: true)
    .where('age > ?', 18)
    .order('created_at DESC')
    .limit(10)
# Returns Relation, executes on iteration
```

#### Joins
```ruby
# Association-aware joins
User.joins(:posts)                    # Inner join via association
User.left_outer_joins(:posts)        # Left join via association
User.joins(posts: :comments)         # Nested associations

# Manual joins
User.joins('LEFT JOIN posts ON...')
```

#### Eager Loading (Smart)
```ruby
# ActiveRecord chooses strategy automatically
User.includes(:posts)              # Preload (separate queries) or eager_load (JOIN)
User.includes(:posts, :comments)   # Multiple relations
User.includes(posts: :comments)    # Nested

# Force strategy
User.eager_load(:posts)            # Force LEFT JOIN
User.preload(:posts)               # Force separate queries
```

#### Subqueries
```ruby
User.where(id: Post.select(:user_id).where(published: true))
User.from(Post.select(:user_id).distinct, :users)
```

#### Scopes
```ruby
# In model
class User < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :recent, -> { where('created_at > ?', 1.week.ago) }
  scope :with_name, ->(name) { where(name: name) }
end

# Usage - chainable
User.active.recent
User.with_name('John').active
```

#### Raw SQL
```ruby
User.find_by_sql("SELECT * FROM users WHERE age > ?", [18])
User.where("age > ?", 18)
User.select(Arel.sql('COUNT(*) as cnt'))
```

### Key Characteristics
- **Hash-based where**: `where(name: 'x', age: 18)`
- **Smart eager loading**: Chooses JOIN vs separate queries based on context
- **Association names**: Can use relationship names in joins/includes
- **Implicit execution**: Queries execute on iteration (`each`, `to_a`, `first`)
- **Relation chaining**: Each method returns new Relation (via `spawn`)

### Files Examined
- `/Users/peter/Documents/Code/Active/frameworks/rails/activerecord/lib/active_record/querying.rb`
- `/Users/peter/Documents/Code/Active/frameworks/rails/activerecord/lib/active_record/relation/query_methods.rb`
- `/Users/peter/Documents/Code/Active/frameworks/rails/activerecord/lib/active_record/relation/finder_methods.rb`

---

## Laravel Eloquent

### Architecture
**Two-layer builder pattern**
- `Illuminate\Database\Eloquent\Builder` - ORM features
- `Illuminate\Database\Query\Builder` - Raw query building
- Eloquent Builder forwards unknown methods to Query Builder via `ForwardsCalls` trait

### Query Examples

#### Simple Queries
```php
// Find by ID - immediate execution
User::find(1)
User::where('id', 1)->first()
User::findOrFail(1)  // Throws if not found

// Where conditions - returns Builder
User::where('name', 'John')->where('active', true)
User::where('name', '=', 'John')    // Explicit operator
User::where('age', '>=', 18)
User::whereNotIn('id', [1, 2, 3])
User::whereRaw('age > ?', [18])
```

#### Chaining
```php
User::where('active', true)
    ->where('age', '>', 18)
    ->orderBy('created_at', 'desc')
    ->limit(10)
    ->get()  // Explicit execution required
```

#### Joins
```php
// Manual table/column specification required
User::join('posts', 'users.id', '=', 'posts.user_id')
User::leftJoin('posts', 'users.id', '=', 'posts.user_id')

// No automatic association joins
```

#### Eager Loading
```php
// Always uses separate queries
User::with('posts')->get()
User::with(['posts', 'comments'])->get()
User::with('posts.comments')->get()  // Nested

// No control over JOIN vs separate query strategy
```

#### Subqueries
```php
User::whereIn('id', function($query) {
    $query->select('user_id')
          ->from('posts')
          ->where('published', true);
})

User::fromSub($subquery, 'users')
```

#### Scopes
```php
// In model
class User extends Model {
    public function scopeActive($query) {
        return $query->where('active', true);
    }

    public function scopeRecent($query) {
        return $query->where('created_at', '>', now()->subWeek());
    }

    public function scopeWithName($query, $name) {
        return $query->where('name', $name);
    }
}

// Usage - note () required
User::active()->recent()->get()
User::withName('John')->active()->get()
```

#### Raw SQL
```php
User::fromQuery("SELECT * FROM users WHERE age > ?", [18])
User::whereRaw("age > ?", [18])
User::selectRaw('COUNT(*) as cnt')
DB::raw('COUNT(*) as cnt')  // For use in query methods
```

### Key Characteristics
- **Method-based where**: `where('name', 'John')`
- **Explicit execution**: Require `.get()`, `.first()` to execute
- **Two-layer separation**: Clear Eloquent vs Query builder
- **Manual joins**: Must specify table and column names
- **Separate query eager loading**: Always uses separate queries for relationships
- **Collections**: Returns `Collection` object (array-like with helpers)

### Files Examined
- `/Users/peter/Documents/Code/Active/frameworks/laravel-framework/src/Illuminate/Database/Eloquent/Builder.php`
- `/Users/peter/Documents/Code/Active/frameworks/laravel-framework/src/Illuminate/Database/Query/Builder.php`

---

## Django ORM (Context)

### Architecture
**QuerySet-based with immutability**
- Returns `QuerySet` objects
- Each query method returns new QuerySet (defensive copies)
- Manager pattern: Access via `Model.objects`

### Query Examples
```python
# Manager pattern
User.objects.filter(name='Oscar')      # Returns QuerySet
User.objects.get(id=1)                 # Executes, returns Model
User.objects.all()                     # Returns QuerySet

# Eager loading
User.objects.select_related('posts')   # JOIN (ForeignKey/OneToOne)
User.objects.prefetch_related('posts') # Separate query (ManyToMany)
```

---

## Side-by-Side Comparison

### Find by ID
```ruby
# ActiveRecord
User.find(1)                    # Immediate
User.find_by(id: 1)            # Returns first or nil
User.where(id: 1).first        # Chainable
```

```php
// Eloquent
User::find(1)                   // Immediate
User::where('id', 1)->first()  // Chainable
User::findOrFail(1)            // Throws if not found
```

### Where Conditions
```ruby
# ActiveRecord - Hash syntax preferred
User.where(name: 'John', active: true)
User.where(age: 18..65)
User.where.not(name: 'John')
User.where('age > ?', 18)
```

```php
// Eloquent - Method arguments
User::where('name', 'John')->where('active', true)
User::where('name', '=', 'John')
User::where('age', '>=', 18)
User::whereNotIn('id', [1, 2, 3])
User::whereRaw('age > ?', [18])
```

### Complex Chaining
```ruby
# ActiveRecord
users = User.where(active: true)
            .joins(:posts)
            .includes(:comments)
            .order('created_at DESC')
            .limit(10)
# Executes on iteration
```

```php
// Eloquent
$users = User::where('active', true)
             ->join('posts', 'users.id', '=', 'posts.user_id')
             ->with('comments')
             ->orderBy('created_at', 'desc')
             ->limit(10)
             ->get();  // Explicit execution
```

### Eager Loading
```ruby
# ActiveRecord - Smart strategy selection
User.includes(:posts)              # Chooses JOIN or separate
User.includes(:posts, :comments)
User.includes(posts: :comments)    # Nested
User.eager_load(:posts)            # Force JOIN
User.preload(:posts)               # Force separate
```

```php
// Eloquent - Always separate queries
User::with('posts')->get()
User::with(['posts', 'comments'])->get()
User::with('posts.comments')->get()
// No control over strategy
```

### Scopes
```ruby
# ActiveRecord - Lambda syntax
class User < ApplicationRecord
  scope :active, -> { where(active: true) }
  scope :with_name, ->(name) { where(name: name) }
end

User.active.with_name('John')
```

```php
// Eloquent - Method syntax
class User extends Model {
    public function scopeActive($query) {
        return $query->where('active', true);
    }

    public function scopeWithName($query, $name) {
        return $query->where('name', $name);
    }
}

User::active()->withName('John')->get()
```

---

## Comparison Matrix

| Aspect | ActiveRecord | Eloquent |
|--------|-------------|----------|
| **Where syntax** | Hash: `where(name: 'x')` | Method: `where('name', 'x')` |
| **Execution** | Implicit (on iteration) | Explicit (`.get()`, `.first()`) |
| **Eager loading** | Smart (JOIN or separate) | Always separate queries |
| **Joins** | Association names | Manual table/column |
| **Scope definition** | Lambda: `scope :x, ->` | Method: `scopeX($query)` |
| **Result type** | Array-like | `Collection` object |
| **Raw SQL** | `find_by_sql`, `Arel.sql` | `fromQuery`, `DB::raw()` |
| **Builder layers** | Single (Relation) | Two (Eloquent + Query) |
| **Association aware** | Yes (joins, includes) | No (manual specs) |

---

## CFML Considerations

### ActiveRecord Pattern
**Pros:**
- Hash-based where natural for CFML structs
- Smart eager loading reduces queries
- Association-aware joins (use relationship names)
- Cleaner, more concise syntax

**Cons:**
- More "magic" (implicit behavior)
- Harder to implement (tight model integration)
- Requires sophisticated Relation class

### Eloquent Pattern
**Pros:**
- Two-layer design easier to understand/implement
- Clear separation: Model vs Query builder
- Explicit execution (clear when queries run)
- Method-based scopes easier in CFML

**Cons:**
- More verbose (`.get()` required everywhere)
- Manual join specifications
- Less intelligent eager loading
- Can't leverage relationship metadata

---

## Recommendation for Fuse

### Hybrid Approach

**Combine best of both worlds:**

1. **Two-layer builder** (Eloquent architecture)
   - `QueryBuilder.cfc` - Database-agnostic query building
   - `ModelBuilder.cfc` - ORM features (relationships, scopes)
   - Clear separation, easier to implement

2. **Hash-based where** (ActiveRecord syntax)
   ```cfml
   User.where({name: "John", active: true})
   User.where({age: {gte: 18}})  // Operator structs
   ```

3. **Explicit execution** (Eloquent pattern)
   ```cfml
   User.where({active: true}).get()    // Execute, return array
   User.where({active: true}).first()  // Execute, return one
   User.find(1)                         // Immediate (no .get())
   ```

4. **Smart eager loading** (ActiveRecord feature)
   ```cfml
   User.includes("posts")        // Use relationship name
   User.joins("posts")           // Auto-generate SQL from relationship
   ```

5. **Method-based scopes** (CFML-friendly)
   ```cfml
   // In User.cfc
   function scopeActive(query) {
       return query.where({active: true});
   }

   // Usage
   User.active().recent().get()
   ```

### Example API
```cfml
// Simple queries
users = User.where({active: true}).get();
user = User.find(1);

// Complex chaining
users = User.where({active: true})
    .whereRaw("age > ?", [18])
    .orderBy("created_at DESC")
    .limit(10)
    .get();

// Relationship queries
posts = User.find(1).posts().where({published: true}).get();

// Eager loading (smart)
users = User.includes("posts").where({active: true}).get();
// users[1].posts is preloaded

// Scopes
activeUsers = User.active().verified().get();

// Raw SQL mixing
users = User.where({active: true})
    .whereRaw("created_at > ?", [dateAdd("d", -7, now())])
    .get();
```

### Benefits of Hybrid
- **Natural CFML syntax**: Structs for conditions
- **Clear execution**: Know when queries run
- **Smart performance**: Automatic eager loading optimization
- **Easier implementation**: Two-layer separation
- **Association-aware**: Use relationship names
- **Flexible**: Mix raw SQL when needed

---

## Open Questions

1. **Execution model**: Lazy (execute on iteration) or explicit `.get()`?
   - **Recommendation**: Explicit `.get()` for clarity

2. **Collection class**: CFML array or custom collection object?
   - **Recommendation**: Start with arrays, add collection later

3. **Builder immutability**: Clone on each chain or mutate?
   - **Recommendation**: Mutate (like AR/Eloquent) for performance

4. **Operator syntax**: How to express `>`, `<`, `LIKE`?
   ```cfml
   // Option 1: Operator structs
   User.where({age: {gte: 18}})

   // Option 2: Special keys
   User.where({"age >": 18})

   // Option 3: whereGte() methods
   User.whereGte("age", 18)
   ```
   - **Recommendation**: Operator structs + helper methods

5. **Relationship definition**: Where to define hasMany/belongsTo?
   - **Decision made**: Method calls in `init()` (Rails pattern)
