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
local player = {}

local function f1(game)
  -- TODO
  return 0
end

local function f2(game)
  -- TODO
  return 0
end

local function get_num_free_cells(game)

  local board = game:get_board()
  local num_free_cells = 0
  for i = 1, game:get_num_cells() do
    if board[i] == nil then
      num_free_cells = num_free_cells + 1
    end
  end
  return num_free_cells
end

local features = {
  f1,
  f2,
  get_num_free_cells,
}

local weights = {
  0, 0, 1
}

-- Returns the evaluation of a game state.
local function evaluate(game)

  local value = 0
  for i = 1, #features do
    value = value + features[i](game) * weights[i]
  end

  --[[
  game:print()
  print("Number of free cells: " .. get_num_free_cells(game))
  print("Evualation: " .. value)
  --]]

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

return player

