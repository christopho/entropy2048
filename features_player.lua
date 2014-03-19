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


-- Artificial player that maximizes a weighted sum of features
-- with a depth of 1.
-- Some of the features are inspired from
-- http://stackoverflow.com/questions/22342854/what-is-the-optimal-algorithm-for-the-game-2048

local player = {}
local verbose = false

-- Weights below were obtained using the cross-entropy method
-- (see cross_entropy.lua).
local weights = {
  -10.72,
  -23.29,
  71.35,
  -4.22,
}

local function monotonicity(game)

  local result = 0
  local board = game:get_board()
  local num_cells = game:get_num_cells()
  local num_columns = game:get_num_columns()

  local left_increase = 0
  local right_increase = 0
  local top_increase = 0
  local bottom_increase = 0

  for i = 1, num_cells do
    local tile = board[i] or 0

    local right_tile
    if i % num_columns ~= 0 then
      right_tile = board[i + 1] or 0
      if right_tile > tile then
        right_increase = right_increase + (tile - right_tile)
      elseif tile > right_tile then
        left_increase = left_increase + (right_tile - tile)
      end
    end

    local bottom_tile
    if i + num_columns <= num_cells then
      bottom_tile = board[i + num_columns] or 0
      if bottom_tile > tile then
        bottom_increase = bottom_increase + (tile - bottom_tile)
      elseif tile > bottom_tile then
        top_increase = top_increase + (bottom_tile - tile)
      end
    end
  end

  return math.max(left_increase, right_increase) + math.max(top_increase, bottom_increase)
end

-- Sum of differences between adjacent tiles.
local function smoothness(game)

  local result = 0
  local board = game:get_board()
  local num_cells = game:get_num_cells()
  local num_columns = game:get_num_columns()

  for i = 1, num_cells do
    local tile = board[i] or 0
    local right_tile, bottom_tile
    if i % num_columns ~= 0 then
      right_tile = board[i + 1] or 0
      if right_tile ~= nil then
        result = result + math.abs(tile - right_tile)
      end
    end

    if i + num_columns <= num_cells then
      bottom_tile = board[i + num_columns] or 0
      if bottom_tile ~= nil then
        result = result + math.abs(tile - bottom_tile)
      end
    end
  end

  return result
end

-- Number of free cells before spawning the new tile.
local function num_free_cells(game)

  local board = game:get_board()
  local num_free_cells = 0
  for i = 1, game:get_num_cells() do
    if board[i] == nil then
      num_free_cells = num_free_cells + 1
    end
  end

  return num_free_cells * num_free_cells
end

-- Maximum tile of the board.
local function max_tile(game)
  return game:get_best_tile()
end

local features = {
  monotonicity,
  smoothness,
  num_free_cells,
  max_tile,
}

-- Returns the evaluation of a game state.
local function evaluate(game)

  local value = 0
  for i = 1, #features do
    value = value + features[i](game) * weights[i]
  end

  if verbose then
    game:print()
    print("Monotonicity: " .. monotonicity(game))
    print("Difference between adjacent cells: " .. smoothness(game))
    print("Number of free cells: " .. num_free_cells(game))
    print("Evaluation: " .. value)
    print()
  end

  return value
end

function player:get_action(game)
  
  -- Take the action that maximizes the value.
  local best_value = -math.huge, best_action
  for i = 1, 4 do
    if game:move(i, false) then
      local value = evaluate(game)
      game:undo()
      if value > best_value then
        best_value = value
        best_action = i
      end
    end
  end

  return best_action
end

function player:get_weights()
  return weights
end

function player:set_weights(w)
  weights = w
end

return player

