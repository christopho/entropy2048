-- Runs the cross-entropy method to optimize appropriate weights for
-- the features_player.lua artificial player.
-- Usage : luajit cross_entropy.lua
-- Press Ctrl-C to stop.

-- The cross-entropy method is described in
-- http://hal.inria.fr/docs/00/41/89/30/PDF/article.pdf

local game_manager = require("game_manager")
local player = require("features_player")

local noise = 10.0

-- Plays a new game and returns the score and the best tile.
local function play_game()
  local game = game_manager:new()
  while game:is_alive() do
    game:move(player:get_action(game))
  end
  return game:get_score(), game:get_best_tile()
end

-- Plays several games and returns the mean score.
local function play_games(num_games)

  local average = 0
  for i = 1, num_games do
    average = average + play_game()
  end
  return average / num_games
end

-- Returns a random number generated from a gaussian distribution.
local function rand_gaussian(mean, deviation)

  -- This is a very simple approximation of a gaussian.
  -- TODO improve it
  local rand = 0.0
  for i = 1, 12 do
    rand = rand + math.random()
  end
  rand = rand - 6.0

  return rand * deviation + mean
end

-- Prints a vector of weights.
local function print_weights(weights)

  for _, weight in ipairs(weights) do
    io.write(string.format("  %.2f,\n", weight))
  end
end

local seed = os.time()
io.write("Random seed: ", seed, "\n")
math.randomseed(seed)

local num_dimensions = #player:get_weights()
local generator = {}
for dim = 1, num_dimensions do
  generator[dim] = {  -- Mean and variance of the gaussian for this dimension.
    mean = 0.0,
    variance = 100.0
  }
end

local num_samples = 100  -- Number of weight vectors generated at each generation.
local samples = {}
local num_generations = 0
local best_score = 0
local best_weights

while true do

  -- Generate weight vector samples.
  num_generations = num_generations + 1
  io.write("\nGeneration ", num_generations, ": generating ", num_samples,
      " samples\n")
  for i = 1, num_samples do
    local sample = {}
    samples[i] = sample
    for dim = 1, num_dimensions do
      local distribution = generator[dim]
      sample[dim] = rand_gaussian(distribution.mean, math.sqrt(distribution.variance))
    end
  end

  -- Play games with each sample.
  io.write("Playing a game with each sample...\n")
  local scores = {}
  local average = 0
  for i = 1, num_samples do
    player:set_weights(samples[i])
    local score = play_games(1)
    scores[#scores + 1] = { sample = samples[i], score = score }
    average = average + score

    if score > best_score then
      best_score = score
      best_weights = samples[i]
    end
  end
  average = average / num_samples
  io.write("Average score of generation: ", average, "\n")

  -- Select the best ones.
  table.sort(scores, function(first, second)
    return first.score > second.score
  end)
  local kept_samples = {}
  for i = 1, num_samples / 10 do
    kept_samples[#kept_samples + 1] = scores[i].sample
  end

  io.write("Best score so far: ", best_score, "\n")
  io.write("  with weights:\n")
  print_weights(best_weights)

  -- Generate a new gaussian distribution from the best samples.
  for dim = 1, num_dimensions do
    local mu = 0.0
    local sigma2 = 0.0
    for _, sample in ipairs(kept_samples) do
      local weight = sample[dim]
      mu = mu + weight
      sigma2 = sigma2 + weight * weight
    end
    mu = mu / #kept_samples
    sigma2 = sigma2 / #kept_samples
    sigma2 = sigma2 - mu * mu  -- E[(X - E[X])^2 = E[X^2]-E[X]^2
    sigma2 = math.max(sigma2, 0.0)
    sigma2 = sigma2 + noise  -- Noise.
    generator[dim].mean = mu
    generator[dim].variance = sigma2
  end
end

