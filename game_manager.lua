-- Entropy 2048, an artificial player for 2048.
-- Copyright (C) 2014 Christophe Thiéry
-- This program is free software; you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation; either version 3 of the License, or
-- (at your option) any later version.
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software Foundation,
-- Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA


-- Manages a 2048 game.
-- Usage:
-- local game_manager = require("game_manager")
-- local game = game_manager:new()
-- game:move(action)  -- action may be 1 (right), 2 (top), 3 (left) or 4 (bottom).

local game_manager = {}
local num_rows = 4
local num_columns = 4
local num_cells = num_rows * num_columns

-- Return a flat index from a row and a column.
local function get_index(row, column)
  return (row - 1) * num_columns + column
end

-- Creates a new game.
function game_manager:new()

  local game = {}
  local board = {}    -- Table of 16 numbers or nils.
  local alive = true
  local score = 0
  local best_tile = 0

  -- Returns the value of a tile or nil.
  local function get_tile(index)

    assert(index > 0 and index <= num_cells)
    return board[index]
  end

  -- Sets the value of a tile (possibly nil).
  local function set_tile(index, value)

    assert(index > 0 and index <= num_cells)
    board[index] = value
  end

  -- Creates a 2 or 4 tile in a random free cell.
  local function spawn_tile()

    -- Pick a random cell amongst free ones.
    local free_indexes = {}
    for i = 1, num_cells do
      if board[i] == nil then
        free_indexes[#free_indexes + 1] = i
      end
    end

    assert(#free_indexes > 0)

    local index = free_indexes[math.random(#free_indexes)]
    local tile = math.random(10) == 1 and 4 or 2
    set_tile(index, tile)

    return true
  end

  -- Moves a tile from a cell to another one.
  -- The source cell must be non-empty and the destination cell must be empty.
  local function move_tile(from, to)
    local tile = get_tile(from)
    assert(tile ~= nil)
    assert(get_tile(to) == nil)
    set_tile(from, nil)
    set_tile(to, tile)
  end

  local function initialize()
    -- Spawn two tiles initially.
    spawn_tile()
    spawn_tile()
  end

  function game:get_num_cells()
    return num_cells
  end

  function game:get_num_rows()
    return num_rows
  end

  function game:get_num_columns()
    return num_columns
  end

  function game:get_board()
    return board
  end

  function game:get_score()
    return score
  end

  -- Returns the maximum value of a tile.
  function game:get_best_tile()
    return best_tile
  end

  function game:print(file)
    file = file or io.stdout
    file:write("-----------------------------\n")
    for i = 1, num_rows do
      file:write("|      |      |      |      |\n")
      file:write("|")
      for j = 1, num_columns do
        local index = get_index(i, j)
        local tile = get_tile(index)
        if tile == nil then
          file:write("      ")
        else
          file:write(string.format("%4d  ", tile))
        end
        file:write("|")
      end
      file:write("\n")
      file:write("|      |      |      |      |\n")
      file:write("-----------------------------\n")
    end
    file:write("Score: ")
    file:write(score)
    file:write("\n")
  end

  -- Checks if the game is finished.
  local function check_alive()

    for index = 1, num_cells do
      if get_tile(index) == nil  then
        alive = true
        return
      end
    end

    for i = 1, num_rows do
      for j = 1, num_columns - 1 do
        local index = get_index(i, j)
        local tile = get_tile(index)
        if tile ~= nil then
          local next_index = get_index(i, j + 1)
          if get_tile(next_index) == tile then
            alive = true
            return
          end
        end
      end
    end

    for j = 1, num_columns do
      for i = 1, num_rows - 1 do
        local index = get_index(i, j)
        local tile = get_tile(index)
        if tile ~= nil then
          local next_index = get_index(i + 1, j)
          if get_tile(next_index) == tile then
            alive = true
            return
          end
        end
      end
    end

    alive = false
  end

  -- Returns whether the game is finished.
  function game:is_alive()
    return alive
  end

  -- Moves upwards (-1) or downwards (1).
  local function move_vertical(direction)

    local moved = false

    local first_i, last_i, increment
    if direction == 1 then
      first_i, last_i, increment = num_rows, 1, -1
    else
      first_i, last_i, increment = 1, num_rows, 1
    end

    for j = 1, num_columns do
      local dst_candidate = first_i
      for i = first_i + increment, last_i, increment do
        local src_index = get_index(i, j)
        local src_tile = get_tile(src_index)
        if src_tile ~= nil then
          -- Make this tile fall at dst_candidate.
          local dst_index = get_index(dst_candidate, j)
          local dst_tile = get_tile(dst_index)

          if dst_tile == nil then
            -- The destination is an available cell.
            move_tile(src_index, dst_index)
            moved = true
          elseif dst_tile == src_tile then
            -- The destination is a tile that can be merged.
            local merged_tile = dst_tile * 2
            set_tile(src_index, nil)
            set_tile(dst_index, merged_tile)
            dst_candidate = dst_candidate + increment
            score = score + merged_tile
            if merged_tile > best_tile then
              best_tile = merged_tile
            end
            moved = true
          else
            -- The destination is a tile that cannot be merged. Find an empty cell.
            for i2 = first_i + increment, i - increment, increment do
              dst_index = get_index(i2, j)
              if get_tile(dst_index) == nil then
                move_tile(src_index, dst_index)
                moved = true
                break
              end
            end
            dst_candidate = i
          end
        end
      end
    end

    return moved
  end

  -- Moves to the left (-1) or to the right (1).
  local function move_horizontal(direction)

    local moved = false

    local first_j, last_j, increment
    if direction == 1 then
      first_j, last_j, increment = num_rows, 1, -1
    else
      first_j, last_j, increment = 1, num_rows, 1
    end

    for i = 1, num_rows do
      local dst_candidate = first_j
      for j = first_j + increment, last_j, increment do
        local src_index = get_index(i, j)
        local src_tile = get_tile(src_index)
        if src_tile ~= nil then
          -- Make this tile fall at dst_candidate.
          local dst_index = get_index(i, dst_candidate)
          local dst_tile = get_tile(dst_index)

          if dst_tile == nil then
            -- The destination is an available cell.
            move_tile(src_index, dst_index)
            moved = true
          elseif dst_tile == src_tile then
            -- The destination is a tile that can be merged.
            local merged_tile = dst_tile * 2
            set_tile(src_index, nil)
            set_tile(dst_index, merged_tile)
            dst_candidate = dst_candidate + increment
            score = score + merged_tile
            moved = true
          else
            -- The destination is a tile that cannot be merged. Find an empty cell.
            for j2 = first_j + increment, j - increment, increment do
              dst_index = get_index(i, j2)
              if get_tile(dst_index) == nil then
                move_tile(src_index, dst_index)
                moved = true
                break
              end
            end
            dst_candidate = j
          end
        end
      end
    end

    return moved
  end

  function game:move_right()
    return game:move(1)
  end

  function game:move_up()
    return game:move(2)
  end

  function game:move_left()
    return game:move(3)
  end

  function game:move_down()
    return game:move(4)
  end

  -- Makes an action (1 to 4). Returns true in case of success,
  -- false if this action is not possible in the current state.
  function game:move(action, spawn)

    -- Spawn a new tile by default.
    if spawn == nil then
      spawn = true
    end

    -- Save the previous state.
    local board_copy = {}
    for i = 1, num_cells do
      board_copy[i] = board[i]
    end
    local state = {
      alive = alive,
      score = score,
      best_tile = best_tile,
      board = board_copy,
    }

    -- Make the action.
    local success = false
    if action == 1 then
      success = move_horizontal(1)
    elseif action == 2 then
      success = move_vertical(-1)
    elseif action == 3 then
      success = move_horizontal(-1)
    elseif action == 4 then
      success = move_vertical(1)
    else
      error("Invalid action")
    end

    if success then
      previous_state = state
      if spawn then
        spawn_tile()
      end
      check_alive()
    end

    return success
  end

  -- Cancels the last move.
  function game:undo()

    if previous_state == nil then
      error("Cannot undo more")
    end

    alive = previous_state.alive
    score = previous_state.score
    best_tile = previous_state.best_tile
    for i = 1, num_cells do
      board[i] = previous_state.board[i]
    end
    previous_state = nil
  end

  initialize()
  return game
end

return game_manager

