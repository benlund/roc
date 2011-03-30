# -*- encoding: utf-8 -*-

$:.unshift File.expand_path('../lib', __FILE__)
require 'roc/version'

Gem::Specification.new do |s|
  s.name = 'roc'
  s.version = ROC::VERSION

  s.authors = ['Ben Lund']  
  s.description = 'Collection of Ruby classes wrapping the Redis data structures'
  s.summary = 'Collection of Ruby classes wrapping the Redis data structures'
  s.email = 'ben@benlund.com'
  s.homepage = 'http://github.com/benlund/roc'

  s.add_dependency('redis')
  s.files = ['lib/roc.rb'] + Dir['lib/roc/*.rb'] + Dir['lib/roc/*/*.rb']
end
