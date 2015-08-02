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

dead = 0
alive = 1

_to_int = (b) -> if b then alive else dead

_step_single = (cell, neighbours) ->
  nLiving = neighbours.filter((x) -> (x isnt dead)).length
  if nLiving < 2 or nLiving > 3
    return dead
  else if nLiving is 2
    return cell
  else # nLiving is 3
    return alive

_join_rows = (a, b) ->
  result = []
  result.push(a[i].concat(b[i])) for i in [0...a.length]
  return result

_split_rows = (c) ->
  a = []
  b = []
  (a.push(c[i][0...c.length]); b.push(c[i][c.length...2 * c.length])) \
    for i in [0...c.length]
  return [a, b]


###
  A macro-cell is an analogue of a quad-tree node in the Hashlife algorithm.
  A macro-cell size is a power of two. Given a macro-cell of size 2^n, we say
  it's level is n.

  Aside from the four (n-1) child-macro-cells (as in a quad-tree), we also make
  use of a fifth (n-1) child located at the center of the macro-cell. This
  child contains the state of the simulation after 2^(n-2) steps. We refer
  to this fifth child as the 'result' of its parent macro-cell.
###
class MacroCell
  @from_array: (a) ->
    row_size = Math.sqrt(a.length)
    row_array = []
    row_array.push(a[i...i + row_size]) for i in [0...a.length] by row_size
    return MacroCell._from_row_array(row_array)

  @_from_row_array: (a) ->
    if a.length is 2
      return new MacroCell(a[0][0], a[0][1], a[1][0], a[1][1])
    else
      j = a.length / 2
      [nw_rows, ne_rows] = _split_rows(a[0...j])
      [sw_rows, se_rows] = _split_rows(a[j...a.length])
      return new MacroCell(
        MacroCell._from_row_array(nw_rows),
        MacroCell._from_row_array(ne_rows),
        MacroCell._from_row_array(sw_rows),
        MacroCell._from_row_array(se_rows)
      )

  @get_hash: (nw, ne, sw, se) ->
    if nw instanceof MacroCell
      return [nw, ne, sw, se].map((x) -> x.id).join('-')
    else
      return ((nw << 3) |
              (ne << 2) |
              (sw << 1) |
               se).toString()

  constructor: (
    @nw = dead, @ne = dead,
    @sw = dead, @se = dead, @id = 0) ->
      if @nw instanceof MacroCell
        @level = @nw.level + 1
      else
        @level = 1;
        if typeof @nw isnt 'number'
          @nw = _to_int(@nw)
          @ne = _to_int(@ne)
          @sw = _to_int(@sw)
          @se = _to_int(@se)

      @hash = MacroCell.get_hash(@nw, @ne, @sw, @se)
      @_result = null

  _to_row_array: ->
    if @level is 1
      return [[@nw, @ne], [@sw, @se]]
    else
      top_rows = _join_rows(@nw._to_row_array(), @ne._to_row_array())
      bottom_rows = _join_rows(@sw._to_row_array(), @se._to_row_array())
      return top_rows.concat(bottom_rows)

  to_array: ->
    return @_to_row_array().reduce((p, c) -> p.concat(c))

  n: -> new MacroCell(@nw.ne, @ne.nw, @nw.se, @ne.sw)
  s: -> new MacroCell(@sw.ne, @se.nw, @sw.se, @se.sw)
  w: -> new MacroCell(@nw.sw, @nw.se, @sw.nw, @sw.ne)
  e: -> new MacroCell(@ne.sw, @ne.se, @se.nw, @se.ne)
  c: -> new MacroCell(@nw.se, @ne.sw, @sw.ne, @se.nw)

  _base_case: ->
    return new MacroCell(
      _step_single(@nw.se,
        [@nw.nw, @nw.ne, @nw.sw, @ne.nw, @ne.sw, @sw.nw, @sw.ne, @se.nw]),
      _step_single(@ne.sw,
        [@nw.ne, @nw.se, @ne.nw, @ne.ne, @ne.se, @sw.ne, @se.nw, @se.ne]),
      _step_single(@sw.ne,
        [@nw.sw, @nw.se, @ne.sw, @sw.nw, @sw.sw, @sw.se, @se.nw, @se.sw]),
      _step_single(@se.nw,
        [@nw.se, @ne.sw, @ne.se, @sw.ne, @sw.se, @se.ne, @se.sw, @se.se]),
    )

  _recursive_case: ->
    lvl1_nw = @nw.compute_result()
    lvl1_ne = @ne.compute_result()
    lvl1_sw = @sw.compute_result()
    lvl1_se = @se.compute_result()
    lvl1_n = @n().compute_result()
    lvl1_s = @s().compute_result()
    lvl1_w = @w().compute_result()
    lvl1_e = @e().compute_result()
    lvl1_c = @c().compute_result()

    lvl2_nw = new MacroCell(lvl1_nw, lvl1_n, lvl1_w, lvl1_c).compute_result()
    lvl2_ne = new MacroCell(lvl1_n, lvl1_ne, lvl1_c, lvl1_e).compute_result()
    lvl2_sw = new MacroCell(lvl1_w, lvl1_c, lvl1_sw, lvl1_s).compute_result()
    lvl2_se = new MacroCell(lvl1_c, lvl1_e, lvl1_s, lvl1_se).compute_result()

    return new MacroCell(lvl2_nw, lvl2_ne, lvl2_sw, lvl2_se)

  compute_result: ->
    if @_result?
      return @_result
    else if (@level is 2)
      return @_result = @_base_case()
    else if @level > 2
      return @_result = @_recursive_case()


###
  The hashlife algorithm takes advantage of pattern-redundancy in the
  simulation. It does so by macro-cell reuse. Every time a new macro-cell is
  needed, the library will first check if it has not already been computed, and
  if it has, then it yields a reference to the existing instance.

  In order to quickly match a given macro-cell with the library's existing
  collection, we use a hash-table. When creating a new cell, it is given a
  unique hash string - it is a combination of its children's hashes.
###
class CellLibrary
  constructor: ->
    @_id = 0  # we start at 2 since IDs 0 and 1 are reserved for the 1x1
              # atomic 'dead' and 'alive' cells.
    @_hashmap = new Object()

  get: (nw, ne, sw, se) ->
    hash = MacroCell.get_hash(nw, ne, sw, se)
    if !@_hashmap[hash]?
      @_hashmap[hash] = new MacroCell(nw, ne, sw, se, @_id)
      ++ @_id
    return @_hashmap[hash]



###
  Simulates an infinite cell grid running Conway's Game of Life (GOL).
  In GOL, a cell can be either dead or alive. The simulation proceeds in
  discrete time steps and cells evolve according to the following rules:
    1. A living cell with fewer than 2 living neighbours dies from isolation.
    2. A living cell with more than 3 living neighbours dies from overcrowding.
    3. A dead cell with with exactly 3 living neighbours becomes alive due to
       reproduction.
###
class GameOfLife
  constructor: ->


root = this
if module?.exports?
  module.exports.MacroCell = MacroCell
  module.exports.CellLibrary = CellLibrary
  module.exports.dead = dead
  module.exports.alive = alive
root.MacroCell = MacroCell
root.CellLibrary = CellLibrary
root.dead = dead
root.alive = alive