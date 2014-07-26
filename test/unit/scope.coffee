# scope tests

require '../helper'

Scope = require '../../src/scope'

describe 'Scope', ->
  scope = beforeEach -> scope = new Scope()

  describe 'local', ->
    it 'stores vars locally', ->
      scope.add 'foo'
      scope.add 'bar'
      scope.add 'baz'

      foo = scope.indexOf 'foo'
      foo.should.have.length 2
      foo[0].should.equal 0
      foo[1].should.equal 0
      bar = scope.indexOf 'bar'
      bar.should.have.length 2
      bar[0].should.equal 0
      bar[1].should.equal 1
      baz = scope.indexOf 'baz'
      baz.should.have.length 2
      baz[0].should.equal 0
      baz[1].should.equal 2

  describe 'parent', ->
    it 'gets parent vars', ->
      scope.add 'foo'
      child = scope.child()

      foo = child.indexOf 'foo'
      foo.should.have.length 2
      foo[0].should.equal 1
      foo[1].should.equal 0

    it 'shadows parent vars', ->
      scope.add 'foo'
      child = scope.child()
      child.add 'foo'

      foo = child.indexOf 'foo'
      foo.should.have.length 2
      foo[0].should.equal 0
      foo[1].should.equal 0
