gol = require('../lib/gol')
CellLibrary = gol.CellLibrary
dead = gol.dead
alive = gol.alive

should = require('should')
expect = require('chai').expect

describe 'cell library unit', ->
  describe 'id', ->
    lib = new CellLibrary
    it 'should increment id for each new cell', ->
      a = lib.get(dead, dead, dead, dead)
      b = lib.get(dead, dead, dead, alive)
      c = lib.get(dead, dead, alive, alive)

      b.id.should.be.equal(a.id + 1)
      c.id.should.be.equal(b.id + 1)


  describe 'lookup', ->
    lib = new CellLibrary
    it 'should return cached cell if it exists', ->
      a = lib.get(dead, dead, dead, dead)
      b = lib.get(dead, dead, dead, dead)

      b.should.be.equal(a)