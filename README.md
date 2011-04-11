# ROC

Redis Object Collection: a collection of Ruby classes that wrap [Redis](http://redis.io) data structures.

ROC also includes a pure-Ruby in-memory implemtation of the Redis commands and data strucures to allow you to use the ROC clases without persistence.


## Summary

    require 'roc'
    
    Store = ROC::Store::RedisStore.new(:url => 'redis://127.0.0.1/1')
    
    
    ## ROC::Integer ##
    
    # objects are initialized inside a store with a key 
    counter = Store.init_integer('counter') # or ROC::Integer.new('counter', Store)
    
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
    rocky_planets.rank('Mars') #=> '4'
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

 2. To add aditional methods to those classes in order to allow instances to be used like their nearest core Ruby equivalents (e.g ROC::List => Array, ROC::Hash => Hash).

 3. To provide additional classes that can directly use and manipulate Redis strings (e.g. ROC::Integer, ROC::Time).


## Classes

ROC::String

Implements the Redis commands that treat the value as a [string](http://redis.io/commands#string)

ROC::Integer

Implements the Redis commands that treat a string value as an integer

ROC::Float

Represents Ruby Float objects as a Redis string

ROC::Time

Represents Ruby Time objects as a Redis string

ROC::List

Wraps the Redis [list](http://redis.io/commands#list) data structure

ROC::Set

Wraps the Redis [set](http://redis.io/commands#set) data structure

ROC::SortedSet

Wraps the Redis [zset](http://redis.io/commands#zset) data structure

ROC::Hash

Wraps the Redis [hash](http://redis.io/commands#hash) data structure


## Creating instances

   store.init_xxx(key, _initial_data_)

or

   XXX.new(key, store, (initial_data)

You can start using the returned object wheter or not the underlying key exists in the Redis instance you're connected to.

If the initial_data arg is given the appripriate Redis command for the type will be called immediately with that data (e.g. set for strings, multiple rpush calls for lists)

NOTE: If the key already exists and initial data is passed, then existing data is first deleted.


## Command method names and arguments

Instances of each class respond to methods named the same as the equivalent Redis command. For example:

    Store.init_string('alphabet').append('abcd')

Sends the folowing to Redis:

    APPEND alphabet abcd

In addition, all instances will respond to methods named after Redis commands that affect [all keys](http://redis.io/commands#keys). For example, to delete an object:

    str = Store.init_string('foo')
    str.set('bar')
    str.del
    str.value #=> nil

Refer to the (Redis docs)[http://redis.io/commands] for a full list of methods available, with the following exceptions, which don't make sense in this context:

@@@

The argument order is the same as for the equivalent Redis command, except that:

  the key is not needed as the first arg - this is added in by the object, since it knows its own key
  optional arguments are repesented as hashes (e.g.  zset.zrange(0, -1, :withscores => true) )

All arguments are serialized to strings (this is done by the underlying Redis connection object) before being sent to Redis.


## Method aliases and helpers

Command method are also aliases to more conveneient or short forms acording to the following principles:

 * the initial character that denotes the redis data type is removed, e.g. zset.add is the same as zset.zadd, set.add is the same as s.sadd
   - expept where such a method name would be ambiguous, e.g. hash.hdel is NOT aliases to del, since this would conflict with the del method that all object implement
   - except where such a name would be the same as a ruby method for an equivalent data type but the behavior is different, e.h. list.linsert in NOT aliases to l.insert, since Array#insert takes an index to insert at, whereas ROC::List#linsert takes a pivot value to insert before or after

Methods are alias aliased to more Ruby-ish names -- e.g. str.value= is an alias for str.set, and list << val is an alias for list.rpush

scalar values: .value, .value=
other types: .values, and the Redis commands

Classes also implement expicit methods to create Ruby-core equivalent objects.

ROC::String - to_s
ROC::Integer - to_i
ROC::Float - to_f
ROC::Time - to_time

ROC::List - to_a
ROC::Set - to_a, to_hash
ROC::SortedSet - to_a, to_hash
ROC::Hash - to_hash


## Delegation, Shortcuts and Masking

ROC classes mimic as closely as possible their nearest Ruby equivalents.

### Non-destructive methods 

Classes will respond to all non-destructive methods that their Ruby equivalents respond to.

e.g. ROC::List#map, ROC::Hash#each_key work just fine

Most of these are simply delegated to the value retuned by to_a, to_s , etc

So, it is not necessary to call the getter methods most of the time. E.g. roc_time_obj.to_i works and is exactly  equivalent to roc_time_obj.to_time.to_i

Some of these methods are explicitly implemented as shortcuts though the Redis commands, when there is no need to fetch all the data from Redis, e.g. ROC::List#[] uses ROC::List#lrange or ROC::List#lrange if possible, and only fall back to fetching the entire array and delgating the call to it if @@@@

### Destructive methods

Destructive methods are implemented to show the same behavior as Ruby equivs where it is possible to implement this using Redis commands, otherwise they will NOT be delgated to the to_a, to_s, etc, but will raise a NotImeplemtedError instead.

e.g.  list.rem vs list.delete

For a full list of additional methods implemented by the ROC classes, see the rdoc. @@


## Stores

ROC ships with two storage classes:

    ROC::Store::RedisStore

which stores the data in a Redis backend, and

    ROC::Store::TransientStore

which stores the data in in-memory Ruby data structures and mimics the Redis API, but offers no persisetnce.

To initialize an instance of RedisStore, pass in either an existing [Redis(@@link) connection object](link) or the redis connection options:

    ROC::Store::RedisStore.new(Redis.new)
    # or
    ROC::Store::RedisStore.new(:url => 'redis://127.0.0.1/1')

To initialze a TransientStore, pass in a string name for the store.  TransientStores are NOT thread safe

    ROC::Store::TransientStore('temp_storage')


## Transactions

All methods of ROC classes in a RedisStore are atomic, except for those that populate the initial data on Lists, Sets, SortedSets and Hashes.

NOTE: TransientStore operations are not thread safe and therefore not atomic.

To wrap multiple calls in a transaction use multi/exec/watch/discard (see Redis docs)


## Implementing your own ROC classes

The ROC::Types::ScalarTypes module can be used to easily implement other datatype that serialize to Redis Strings

@@ need to implemt the following methods, e.g here is the full implemtation of a hypothetical ROC::@@ class


## Comparison with other Redis libraries

https://github.com/nateware/redis-objects

Ruby-ish wrappers for Redis data structures, very similar to ROC.  Also includes support for adding proprties to models. No support for transient Storage, and a less explicit separation between redis command methods and delgated or shortcut methods to mimic core Ruby objects.


https://github.com/grosser/redis-objective

Wraps Redis get / set /mget / mset to serialize / deserialze Ruby objects to Redis strings.


https://github.com/BrianTheCoder/redis-types

Includable module to use redis data types as model properties.  Similar to ROC in that it implements classes to wrap Redis data types, although those classes don't implement methods of or delegate to core Redis data types.


https://github.com/soveran/ohm

"Object-hash mapping" for Redis


https://github.com/makevoid/redismapper

A basic ORM for Redis.


https://github.com/malditogeek/redisrecord

An ORM for Redis that supports realtionships between models.


http://rubygems.org/gems/easyredis

An ORM for Redis that supports sorting and text completion on fields.


https://github.com/tlossen/remodel

An ORM for Redis with ActiveRecord-like syntax for relations.


https://github.com/ashleyw/RedisModel

ORM for Redis including support for some complex types as properties.


https://github.com/ldodds/redis-load

Load and dump Redis data from flat files.


https://github.com/flipsasser/ozy

A simple hash interface to storing Marshaled Ruby objects in Redis strings


https://github.com/peterc/simredis

A Redis sumulator (similar to ROC::Store::TransientStore) - the Github page warns it is not complete or ready for serious use.


https://github.com/marcheiligers/frivol

Use Redis for temporary storage inside models.


https://github.com/defunkt/redis-namespace

Wraps a redis connection to namespace your keys.


https://github.com/soveran/nest

Use Redis keys to encode structure.


