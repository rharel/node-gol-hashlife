###
 @author Raoul Harel
 @license The MIT license (LICENSE.txt)
 @copyright 2015 Raoul Harel
 @url rharel/node-gol-hashlife on GitHub
###

###
  Naming Convention Used
  ======================
  Any object, method, or argument whose name begins with an _underscore
  is to be considered a private implementation detail.
###

###
  A macro-cell is an analogue of a quad-tree node in the HashLife algorithm.
  A macro-cell size is a power of two. Given a macro-cell of size 2^n, we say
  it's level is n.

  Aside from the four (n-1) child-macro-cells (as in a quad-tree), we also make
  use of a fifth (n-1) child located at the center of the macro-cell. This
  child contains the state of the simulation after 2^(n-2) steps.
###
class _MacroCell
  constructor: (@_level, @_nw, @_ne, @_sw, @_se) ->

  _step: ->

###
  Simulates an infinite cell grid running Conway's Game of Life (GOL).
  In GOL, a cell can be either dead or alive. The simulation proceeds in
  discrete time steps and cells evolve according to the following rules:
    1. A living cell with fewer than 2 living neighbours dies from isolation.
    2. A living cell with more than 3 living neighbours dies from overcrowding.
    3. A dead cell with with exactly 3 living neighbours comes alive due to
       reproduction.
###
class GameOfLife
  constructor: ->


