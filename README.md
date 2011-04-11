# ROC

Redis Object Collection: a collection of Ruby classes that wrap [Redis](http://redis.io) data structures.

Also includes a pure-Ruby in-memory implemtation of the Redis commands and datastricures for useing the clsses here without presistnce.


## Summary

    require 'roc'
    
    Store = ROC::Store::RedisStore.new(Redis.connect)
    
    
    ## ROC::Integer ##
    
    # objects are initialized inside a store with a key 
    counter = Store.init_integer('counter')
    
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
      

See test/*.rb for more examples


## Aims

 1. To provide classe that directly represent each of the Redis data types, encapsualting their own key

 2. To add aditional methods to those classes to allow instances to be used like their nearest core Ruby equivalents (e.g ROC::List => Array, ROC::Hash => Hash)

 3. To provide additional types that can directly use and maniputate the Redis String data type (e.g. ROC::Integer, ROC::Time)


## Classes

ROC::String

Implements the Redis commands that treat the value is a string

ROC::Integer

Implements the Redis commands that treat the value as an integer

ROC::Float

Represents Ruby Float objects as a Redis string

ROC::Time

Represents Ruby Time objects as a Redis string

ROC::List

Wraps the Redis List data structure

ROC::Set

Wraps the Redis Set data structure

ROC::SortedSet

Wraps the Redis Zset data structure

ROC::Hash

Wraps the Redis Hash data structure


## Method names and arguments

methods are named the same as the equivalent Redis command

all objects will repond to methods named after the all keys commads (see doc), except these, which don;t make sense in this context

@@@

args are as Redis (see docs), except:

  the key is not needed as the first arg - this is added in by the object, since it knows its own key
  optional arguments are repesented as hashes (e.g.  zset.zrange(0, -1, :withscores => true) )

method are also aliases to more conveneient or short forms acording to the following principles

 * the initial character that denotes the redis data type is removed, e.g. zset.add is the same as zset.zadd, set.add is the same as s.sadd
   - expept where such a method name would be ambiguous, e.g. hash.hdel is NOT aliases to del, since this would conflict with the del method that all object implementd
   - except where such a name would be the same as a ruby method for an equivalent data type but the behavior is different, e.h. list.linsert in NOT aliases to l.insert, since Array#insert takes an index to insert at, whereas ROC::List#linsert takes a pivot value to insert before or after

## Getting and Setting

scalar values: .value, .value=
other types: .values, and the Redis commands

Classes also implemente expicit methods to access  Ruby-core equivs objects

ROC::String - to_s
ROC::Integer - to_i
ROC::Float - to_f
ROC::Time - to_f

ROC::List - to_a
ROC::Set - to_a, to_hash
ROC::SortedSet - to_a, to_hash
ROC::Hash - to_hash


## Delegation, Shortcuts and Masking

### non-destructive methods 

Classes will reposd to all non-destrcutive methods that there Ruby equivs implement

e.g. ROC::List#map, ROC::Hash#each_key work just fine

Most of these are simply delegated to the value retuned by to_a, to_s 

Some are explicitly implemented as shortcuts to this, where there is no need to fetch all the data from Redis, e.g. ROC::List#[]

### destruciteve methods

destructive methods are implemented to show same behavior as RUby equivs where possible, otherwise they will NOT be delgated to the to_a, to_s, etc, but will raise a NotImeplemtedError

e.g.  list.rem vs list.delete

## Stores

    ROC::Store::RedisStore

Stores in a Redis backend

    ROC::Store::TransientStore

Stores in-memory Ruby data structures, mimics the Redis API, but no persisence


## Implemting your own ROC classes

The ROC::Types::ScalarTypes module can be used to easily implement other datatype sthat serialize to Redis Strings

@@ need to implemt the following methods, e.g here is the full iplemtation of a hypothetical ROC::@@@@ class


TBC...



----

Compare to:

http://rubygems.org/gems/redis-objective

http://rubygems.org/gems/redismapper

http://rubygems.org/gems/redisrecord

http://rubygems.org/gems/easyredis

http://rubygems.org/gems/redis-aid

http://rubygems.org/gems/redis-load

http://rubygems.org/gems/ozy

http://rubygems.org/gems/simredis

http://rubygems.org/gems/remodel

http://rubygems.org/gems/redis-types

http://rubygems.org/gems/frivol

http://rubygems.org/gems/redismodel

http://rubygems.org/gems/remodel-h

http://rubygems.org/gems/superfeedr-em-redis

http://rubygems.org/gems/em-redis

https://github.com/nateware/redis-objects

https://github.com/defunkt/redis-namespace

https://github.com/soveran/nest

Ohm

