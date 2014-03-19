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


-- Simplistic artificial player that repeatedly plays right, up, left, down.
local player = {}

local actions = {1, 2, 3, 4}
local index = 0
function player:get_action(game)
  index = index % 4 + 1
  return actions[index]
end

return player

