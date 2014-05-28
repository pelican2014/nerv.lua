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
```

## Basic Idea
`nerv.lua` mimics the behaviour of membrane potential of actual nerve cells. In each frame, stimuli sent to an instane of nerv will triger a change in its `potential`. If this value increases above the value of `threshold potential`, it will change drastically for the `refractory period`. During this period, the `potential` of that nerv instance will not be affected by any stimulus.

(If you are keen to understand the biological basis of `nerv.lua`, [this](http://www.dummies.com/how-to/content/understanding-the-transmission-of-nerve-impulses.html), [this](http://www.sumanasinc.com/webcontent/animations/content/action_potential.html), [this](http://highered.mcgraw-hill.com/sites/0072495855/student_view0/chapter14/animation__the_nerve_impulse.html) and [this](http://www.youtube.com/watch?v=hFzqlO7FbzM) may help.)

## Documentation
### Initiation of a new nerv instance
####Synopsis
```lua
  new_nerv = nerv(fn_onStart, fn_onFinished, maxPotential, refractoryPeriod, lagTime, isSynchronised)
```

####Examples
```lua
new_nerv = nerv(  _customer_leave , _, 3, .6, .1, true)

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

`refractoryPeriod` (1) period of time when stimuli have no effect on `potential` when `potential` is undergoing massive change

`lagTime` (refractoryPeriod/2 or .5) delay before nerve impulse is fired to any connected nerv cell (if there is any)

`isSynchronised` (false) determine whether nervs created at the same frame should have similar `potential` variations

==
