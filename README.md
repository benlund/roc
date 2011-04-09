# ROC

Redis Object Collection: a collection of Ruby classes that wrap [Redis](http://redis.io) data structures


## Summary

    require 'roc'
    
    Store = ROC::Store::RedisStore.new(Redis.connect)

    # objects are initialized inside a store with a key
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
    rocky_planets.include?('Earth') #=> true
    rocky_planets.include?('Pluto') #=> false        
    rocky_planets.reverse #=> ['Mars', 'Earth', 'Venus', 'Mercury']


See test/*.rb for more examples

## Classes

## Delegation

## Stores

    ROC::Store::RedisStore

Stores in a Redis backend

    ROC::Store::TransientStore

Stores in-memory Ruby data structures, mimics the Redis API, but no persisence


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

