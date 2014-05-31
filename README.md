# nerv.lua
`nerv.lua` is inspired by nerve impulses for controlled randomness

#### Situations where `nerv` might be useful:
* make birds fly/frogs jump/fog lift randomly when player approaches
* make enemies attack player randomly when player approaches and drastically reduce the chance of enemies attempting to attack when obstructed by obstacle
* make customers leave the store with increasing chances as the waiting time increases
* make interesting interactive patterns

## Installation
```lua
local nerv = require 'nerv'

--initiation
local new_nerv = nerv()

--update each instance
function love.update(dt)
  ...
  new_nerv:update(dt)
  ...
end
```

## Basic Idea
`nerv.lua` mimics the behaviour of membrane potential of actual nerve cells. In each frame, stimuli sent to an instane of nerv will triger a change in its `potential`. If this value increases above the value of `threshold potential`, it will change drastically for the `refractory period`. During this period, the `potential` of that nerv instance will not be affected by any stimulus.

(If you are keen to understand the biological basis of `nerv.lua`, [this](http://www.dummies.com/how-to/content/understanding-the-transmission-of-nerve-impulses.html), [this](http://www.sumanasinc.com/webcontent/animations/content/action_potential.html), [this](http://highered.mcgraw-hill.com/sites/0072495855/student_view0/chapter14/animation__the_nerve_impulse.html) and [this](http://www.youtube.com/watch?v=hFzqlO7FbzM) may help.)

##Documentation

###Overview of methods
```lua
new_nerv = nerv(fn_onStart, fn_onFinished, maxPotential, refractoryPeriod, lagTime, isSynchronised)

```

###Initiation of a new nerv instance
####Synopsis
```lua
new_nerv = nerv(fn_onStart, fn_onFinished, maxPotential, refractoryPeriod, lagTime, isSynchronised)
```

####Examples
```lua
new_nerv = nerv(  _add_bird, _, 3, .6, .1, true)

--initiate and change its properties later
new_nerv = nerv()
new_nerv:setFunctions(function() a=a+1 end, function() b=b+1 end)

--initiate with chained functions
new_nerv = nerv():setPeriod(.6):setFunctions( function() Enemies:shoot() end )
```

####Arguments
`fn_onStart` (null function)  function that is called when `potential` reaches `threshold potential`

`fn_onFinished` (null function) function that is called at the end of `refractory period`

`maxPotential` (8) maximum potential that `potential` will reach after exceeding `threshold potential`

`refractoryPeriod` (1) period of time when stimuli have no effect on `potential` when `potential` is undergoing massive change (if refractory period is 0, then the potential value of the nerv instance will not undergo a massive change when it exceeds threshold potential)

`lagTime` (refractoryPeriod/2 or .5) delay before nerve impulse is fired to any connected nerv cell (if there is any)

`isSynchronised` (false) determine whether nervs created at the same frame should have similar `potential` variations

##Sending stimulus
####Synopsis
```lua
function love.update(dt)
  ...
  new_nerv:send(strength)
  ...
  new_nerv:update(dt)
end
```

####Example
```lua
local _distance = math.sqrt( (player.x-mx)^2 + (player.y-my)^2 )
local _inv = 1/distance
local strength = _inv * 100
new_nerv:send(strength)
```

####Argument
`strength` (0) is the strength of the stimulus that is sent to that nerv instance. (the larger the strength, the more likely threshold potential will be reached)

##Applying inhibition
####Synopsis
```lua
new_nerv:inhibit(strength)
```

####Example
```lua
if Obstacle.isInPath() then
  new_nerv:inhibit(10000)
end
```

####Argument
`strength` (0) is the strength of inhibition applied to that nerv instance. Basically it is the negative of stimulus.

##Get that potential
####Synopsis
```lua
new_nerv:getPotential()
```

####Example
```lua
--love.update
local p = new_nerv:getPotential()
particle.actual_y = particle.y + p
...
--love.draw
love.graphics.circle('fill',particle.x,particle.actual_y)
```

##Connect nerv instances together
####Synopsis
```lua
new_nerv:connect(n)
```

####Example
```lua
local nerv = require 'nerv'
...
local nervs = {}
for n = 1,10 do
  table.insert( nervs, nerv() )
end
for n = 2,9 do
  nervs[n]:connect( nervs[n+1] )
  nervs[n]:connect( nervs[n-1] )
end
```

####Argument
`n` is the nerv instance to be connected downstream, meaning that if this nerv instance reaches threshold potential, then the nerv(s) connected to it will also undergo massive potential changes after `lagTime`.

##Set various properties
####Synopsis
```lua
new_nerv:setFunctions(fn_onStart, fn_onFinished)
```

####Synopsis
```lua
new_nerv:setSkipped(boolean)
```

####Argument
`boolean` indicates whether tweening should be skipped. It is advised to skip tweening when you do not need the value of potential but only need to invoke `fn_onStart` and/or `fn_onFinished` (faster by about 1/3 of the time).

####Synopsis
```lua
new_nerv:setPeriod(refractoryPeriod)
```

####Synopsis
```lua
new_nerv:setProperties( lagTime, isSynchronised, isReverseMP )
```

####Argument
`isReverseMP` indicates whether the value of potential should drop to the negative of `maxPotential` after `maxPotential` has been reached( all during the refractory period )

####Synopsis
```lua
new_nerv:setPotentials( maxPotential, restingPotential, thresholdPotential )
```

####Arguments
`restingPotential` is the value of the potential when no stimulus is applied
`thresholdPotential` is the value above which a massive change in potential will be triggered( to reach maxPotential )

####Examples
```lua
local new_nerv = nerv():setFunctions( function() Sounds.bird:play() end, _ ):setPeriod(0):setSkipped():setPotentials(3)
new_nerv:setProperties(.1,_,true)
```