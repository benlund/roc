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
    rocky_planets.add(3, 'Mars')
    
    # calling ZRANK key value
    rocky_planets.rank('Mars') #=> '3'

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

