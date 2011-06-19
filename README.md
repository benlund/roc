# ROC

Redis Object Collection: a collection of Ruby classes that wrap [Redis](http://redis.io) data structures.

ROC also includes a pure-Ruby in-memory implementation of the Redis commands and data structures to allow you to use the ROC clases without persistence.


## Summary

    require 'roc'
    
    Store = ROC::Store::RedisStore.new(:url => 'redis://127.0.0.1/1')
    
    
    ## ROC::Integer ##
    
    # objects are initialized inside a store with a key 
    counter = Store.init_integer('counter')

    # Alternative way to initialize objects:
    # counter = ROC::Integer.new('counter', Store)

    # Or set the default store for all:
    # ROC::Base.storage = Store
    # counter = ROC::Integer.new('counter')

    # calling INCR key
    10.times{counter.incr}
    counter.value #=> 10
    
    #Ruby integer methods work
    counter + 2 # => 12
    
    
    ## ROC::SortedSet ##
    
    rocky_planets = Store.init_sorted_set('rocky_planets')
    
    # calling ZADD key score value
    rocky_planets.add(1, 'Mercury')
    rocky_planets.add(2, 'Venus')
    rocky_planets.add(3, 'Earth')
    rocky_planets.add(4, 'Mars')
    
    # calling ZSCORE key value
    rocky_planets.score('Mars') #=> '4'
    # calling ZRANK key value
    rocky_planets.rank('Mars') #=> 3
    
    # array-like methods
    rocky_planets[0] #=> 'Mercury'
    rocky_planets.include?('Earth') #=> true
    rocky_planets.include?('Pluto') #=> false        
    rocky_planets.reverse #=> ['Mars', 'Earth', 'Venus', 'Mercury']
    
    
    ## ROC::Hash ##
      
    tally = Store.init_hash('tally)
    Store.multi
      tally.increment('oranges', 2)
      tally.increment('lemons', 5)
    end
    tally['lemons'] #=> '5'  # values are always strings
    tally.to_hash #=> {'oranges' => '2', 'lemons' => '5'}



See test/*.rb for many more examples


## Aims

 1. To provide classes that directly represent each of the Redis data structures, where instances of each class encapsulate their own key and respond to methods that directly represent the Redis commands available for their corresponding data structure.

 2. To add additional methods to those classes in order to allow instances to be used like their nearest Ruby Standard Library equivalents (e.g ROC::List => Array, ROC::Hash => Hash).

 3. To provide additional classes that can directly use and manipulate Redis strings for non-string data types (e.g. ROC::Integer, ROC::Time).


## Features

 * Global, class-specific or instance-specific storage for ROC objects. This means it's easy to use multiple redis backends. (See Creating Instances below)

 * A full Ruby in-memory implementaion of the raw redis data structures and commands. This allows you to use the ROC classes without an underlying redis connection.  For example, this is useful for re-using logic that operates on ROC objects with temporary data that doesn't need persistence. (See ROC::Store::TransientStore)

 * Automagical delegation of Ruby Standard Library methods called on ROC objects, including monkeypatched methods. (See Delegation, Shortcuts and Masking below)

 * Support for rolling your own Redis-backed objects. (see ROC::Time for an example)

 * Support for Lua scripting (See EVAL below)

## Classes

### ROC::String

Implements the Redis commands that treat the value as a [string](http://redis.io/commands#string)

### ROC::Integer

Implements the Redis commands that treat a string value as an integer

### ROC::Float

Represents Ruby Float objects as a Redis string

### ROC::Time

Represents Ruby Time objects as a Redis string

### ROC::List

Wraps the Redis [list](http://redis.io/commands#list) data structure

### ROC::Set

Wraps the Redis [set](http://redis.io/commands#set) data structure

### ROC::SortedSet

Wraps the Redis [sorted set](http://redis.io/commands#sorted_set) data structure

### ROC::Hash

Wraps the Redis [hash](http://redis.io/commands#hash) data structure


## Creating Instances

To explicitly initialize an object inside a particular store:

    store.init_xxx(key, initial_data) #initial_data is optional

or

    ROC::Xxx.new(key, store, initial_data) #initial_data is optional

To set the default store once for all objects:

    ROC::Base.storage = store

or for just a particular type:

    ROC::SortedSet.storage = store

Once a default store has been set, you can initialize objects and omit the storage parameter:

    ROC::Xxx.new(key)

If you try to initialze an object without storage and there's no default storage for its class (and no global default storage), an ArgumentError is raised.

You can start using the returned object whether or not the underlying key exists in the store you're connected to.

If the initial_data arg is given the appropriate Redis command for the type will be called immediately with that data (e.g. set for strings, multiple rpush calls for lists).

NOTE: If the key already exists and initial_data is passed, then existing data is first deleted.


## Command method names and arguments

Instances of each class respond to methods named the same as the equivalent Redis command. For example:

    Store.init_string('alphabet').append('abcd')

Sends the folowing to Redis:

    APPEND alphabet abcd

In addition, all instances will respond to methods named after the Redis commands that affect [all keys](http://redis.io/commands#generic). For example, to delete an object:

    str = Store.init_string('foo')
    str.set('bar')
    str.del # sends DEL foo
    str.value #=> nil

Refer to the [Redis docs](http://redis.io/commands) for a full list of methods available.

Argument order is the same as for the equivalent Redis command, except that:

 * the key is not needed as the first arg - this is added in by the object, since it knows its own key
 * optional arguments are represented as hashes (e.g.  zset.zrange(0, -1, :withscores => true) )

All arguments are serialized to strings (this is done by the underlying Redis connection object) before being sent to Redis.


## Method aliases and helpers

Command methods are also aliased to more convenient or short forms according to the following principles:

 * the initial character that denotes the redis data type is removed, e.g. zset.add is the same as zset.zadd, set.add is the same as set.sadd
  - except where such a method name would be ambiguous, e.g. hash.hdel is NOT aliased to del, since this would conflict with the del method that all objects respond to.
  - except where such a name would be the same as a Ruby method for an equivalent data type but the behavior is different, e.g. list.linsert in NOT aliased to l.insert, since Array#insert takes an index to insert at, whereas ROC::List#linsert takes a pivot value to insert before or after

Some methods are also aliased to more Ruby-ish names. E.g.:

 * str.value is an alias for str.get
 * str.value= is an alias for str.set
 * list << val is an alias for list.rpush
 * set << val is an alias for set.sadd
 * zset << [score, val] is an alias for zset.zadd(score, val)

Classes also implement expicit methods to create Ruby Standard Library equivalent objects.

ROC::String#to_s

ROC::Integer#to_i

ROC::Float#to_f

ROC::Time#to_time

ROC::List#to_a

ROC::Set#to_a, ROC::Set#to_hash

ROC::SortedSet#to_a, ROC::SortedSet#to_hash

ROC::Hash#to_hash

Methods that are delegated (see below) are delgated to the objects returned by these calls.

ROC::Set#to_set will also work, returning a [Ruby Standard Libarary Set](http://www.ruby-doc.org/stdlib/libdoc/set/rdoc/classes/Set.html). Why is this not the default Ruby type to delegate to? It's assumed that you're more likely to do set operations as Redis commands, and just want the resulting list of values returned. Note that the [Ruby Standard Libarary Sorted Set](http://www.ruby-doc.org/stdlib/libdoc/set/rdoc/classes/SortedSet.html) class is not suitable for delgating to since it sorts the values themselves, not based on separate scores.

## Delegation, Shortcuts and Masking

ROC classes mimic as closely as possible their nearest Ruby Standard Library equivalents according to the following principles:

### Non-destructive methods 

Classes will respond to all non-destructive methods that their Ruby equivalents respond to.

e.g. ROC::List#map, ROC::Hash#each_key work just fine

Most of these are simply delegated to the value returned by to_a, to_s , etc.

So, it is not necessary to call the getter methods most of the time. E.g. roc_time_obj.to_i works and is exactly equivalent to roc_time_obj.to_time.to_i

Some of these methods are explicitly implemented as shortcuts through the Redis commands when there is no need to fetch all the data from Redis, e.g. ROC::List#[] uses ROC::List#lrange or ROC::List#lindex as appropriate.  ROC::String#[] uses the Redis commands where appropriate, but falls back to delegating to the full string for regular expression arguments.

### Destructive methods

Destructive methods are implemented to show the same behavior as the Ruby equivalents where it is possible to implement this using Redis commands. Otherwise they are NOT delgated to the to_a, to_s, etc, but will raise a NotImplementedError instead.

E.g.  list.rem vs list.delete

    list = Store.init_list('foo')
    list << 'x'
    list << 'x'
    list << 'y'

    list.rem(1, 'x') # => 1 (number of items removed)
    list.delete('x') # => 'x' (item deleted)

    list.to_a # => ['y']

For a full list of additional methods implemented by the ROC classes, see the source.

## Stores

ROC ships with two storage classes:

    ROC::Store::RedisStore

which stores the data in a Redis backend, and

    ROC::Store::TransientStore

which stores the data in in-memory Ruby data structures and mimics the Redis API, but offers no persistence.  This store is useful for doing temporary operations but allowing you to use Redis-style data structures so as not to have to rewrite your logic.

To initialize an instance of RedisStore, pass in either an existing [Redis connection object](http://github.com/ezmobius/redis-rb) or the Redis connection options:

    ROC::Store::RedisStore.new(Redis.new)
    # or
    ROC::Store::RedisStore.new(:url => 'redis://127.0.0.1/1')

To initialze a TransientStore:

    ROC::Store::TransientStore.new
    # or
    ROC::Store::TransientStore.new('temp_storage')

TransientStores created without an argument are completely isolated from other TransientStore instances (unlike RedisStore instances). If you want to be able to access the same store in different parts of your code or from different threads, pass in a string name for the store. The data in the named TransientStore will be accessible under that name for the duration of the Ruby process. NOTE however that TransientStores are NOT (currently) thread safe.


## Transactions

All methods of ROC classes in a RedisStore are atomic, except for those that populate the initial data on Lists, Sets, SortedSets and Hashes. (Todo=fix)

NOTE: TransientStore operations are not (currently) thread safe and therefore not atomic.

To wrap multiple calls in a transaction use multi/exec/watch/discard:

    Store.multi do
      str.value = 'hi there ben'
      list << 'ben'
    end

See the [Redis docs](http://redis.io/commands#transactions) for more details on multi/exec/watch/discard.

## EVAL and Lua Scripting

ROC has support for the experimental [Lua scripting](http://antirez.com/post/an-update-on-redis-and-lua.html) ([also](http://antirez.com/post/scripting-branch-released.html) and [also](http://antirez.com/post/redis-and-scripting.html)) EVAL command in the [redis-scripting branch](https://github.com/antirez/redis/tree/scripting). You can even use Lua scripts on data stored in a ROC::TransientStore.

    # while EVAL is still an expermental Redis command, you'll need to explicitly enable in in ROC
    Store.enable_eval
    
    # you can run scripts directly from the store object
    Store.call :eval, "return redis.call('get', KEYS[1])", 1, 'some_key'
    
    # or via ROC objects
    hsh = Store.init_hash('some_hash', {'foo' => 'bar', 'bar' => 'baz'})
    hsh.eval("return redis.call('hmget', KEYS[1], ARGV[1], ARGV[2])", 'foo', 'bar') #=> ['bar', 'baz']

### eval keys and arguments ###

When running a Lua script via an eval call on a ROC object, the key of that object will be automaticaly added as KEYS[1] to the script args.  Any other ROC objects passed in as args will have their keys collected and sent as additional KEYS. There is therefore no need to pass an argument indicating how many keys are in the argument for ROC::Base#eval calls, or even a need to group all keys as the first args.

For example:
    
    lst = Store.init_list('some_list')
    hsh = Store.init_hash('some_hash')

    lst << 'bar'

    script = "return redis.call('hset', KEYS[2], ARGV[2], redis.call('lindex', KEYS[1], ARGV[1]))"

    lst.eval script, hsh, 0, 'foo'
    #is exactly equivalent to
    Store.call :eval, script, 2, lst.key, hsh.key, 0, 'blah'

    hsh.to_hash # => {"foo"=>"bar"}

NOTE: To use Lua with TransientStore, you'll need to install [rufus-lua](http://rufus.rubyforge.org/rufus-lua/).

## Implementing your own ROC classes

The ROC::Types::ScalarTypes module can be used to easily implement other data types that serialize to Redis Strings. You just need to do the following things:

 * implement serialize_value and deserialize_value
 * optionally tell it how to delegate methods

For example, here is the full implemtation of a hypothetical Foo::URI class:

    module Foo
      class URI < ROC::Base
        include  ROC::Types::ScalarType

        ## delgate any method that a URI responds_to? to the object returned by self.value (which you don't need to implement)
        delegate_methods :on => ::URI.new, :to => :value

        ## implementing scalar type required methods ##
        
        def serialize(uri)
          uri.to_s
        end
        
        def deserialize(val)
          ::URI.parse(val)
        end
      end
    end


## Comparison with other Redis libraries

https://github.com/nateware/redis-objects

Ruby-ish wrappers for Redis data structures, very similar to ROC.  Also includes support for adding proprties to models. No support for transient storage, and a less explicit separation between redis command methods and delgated or shortcut methods to mimic core Ruby objects.


https://github.com/grosser/redis-objective

Wraps Redis get / set /mget / mset to serialize / deserialze Ruby objects to Redis strings.


https://github.com/BrianTheCoder/redis-types

Includable module to use redis data types as model properties.  Similar to ROC in that it implements classes to wrap Redis data types, although those classes don't implement the methods of or delegate to core Redis data types.


https://github.com/soveran/ohm

"Object-hash mapping" for Redis. An ORM, except not, of course, because Redis isn't relational.


https://github.com/makevoid/redismapper

A basic ORM-equivalent for Redis.


https://github.com/malditogeek/redisrecord

An ORM-equivalent for Redis that supports realtionships between models.


http://rubygems.org/gems/easyredis

An ORM-equivalent for Redis that supports sorting and text completion on fields.


https://github.com/tlossen/remodel

An ORM-equivalent for Redis with ActiveRecord-like syntax for relations.


https://github.com/ashleyw/RedisModel

ORM-equivalent for Redis including support for some complex types as properties.


https://github.com/ldodds/redis-load

Load and dump Redis data from flat files.


https://github.com/flipsasser/ozy

A simple hash interface to storing Marshaled Ruby objects in Redis strings


https://github.com/peterc/simredis

A Redis simulator (similar to ROC::Store::TransientStore) - the Github page warns it is not complete or ready for serious use.


https://github.com/marcheiligers/frivol

Use Redis for temporary storage inside models.


https://github.com/defunkt/redis-namespace

Wraps a redis connection to namespace your keys.


https://github.com/soveran/nest

Use Redis keys to encode structure.


