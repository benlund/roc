# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../lib', __FILE__)
require 'roc/version'

Gem::Specification.new do |s|
  s.name = 'redis-roc'
  s.version = ROC::VERSION

  s.authors = ['Ben Lund']  
  s.description = 'Collection of Ruby classes wrapping the Redis data structures'
  s.summary = 'ROC::String, ROC::Integer, ROC::List, ROC::SortedSet, etc. Also a Ruby in-memory implementation of the Redis commmands to allow you to use the ROC classes without a connection to Redis.'
  s.email = 'ben@benlund.com'
  s.homepage = 'http://github.com/benlund/roc'

  s.add_dependency('redis')
  s.add_dependency('cim_attributes')
  s.files = ['lib/redis-roc.rb'] + Dir['lib/roc/*.rb'] + Dir['lib/roc/*/*.rb']
end
