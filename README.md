# nerv.lua
`nerv.lua` is inspired by nerve impulses for controlled randomness

#### Situations where `nerv` might be useful:
* make birds fly/frogs jump/fog lift randomly when player approaches
* make enemies attack player randomly when player approaches and drastically reduce the chance of enemies attempting to attack when obstructed by obstacle
* make customers leave the store with increasing chances as the waiting time increases
* make interesting interactive patterns

## Installation
`local nerv = require 'nerv'`

## Basic Idea
`nerv` mimics the behaviour of membrane potential of actual nerve cells. [This](http://www.dummies.com/how-to/content/understanding-the-transmission-of-nerve-impulses.html), [this](http://www.sumanasinc.com/webcontent/animations/content/action_potential.html), [this](http://highered.mcgraw-hill.com/sites/0072495855/student_view0/chapter14/animation__the_nerve_impulse.html) and [this](http://www.youtube.com/watch?v=hFzqlO7FbzM)
may be more than necessary to help you understand the biological basis of `nerv.lua`.

In each frame, stimuli sent will triger a change in the `potential` of `nerv`. If the `potential` reaches `threshold potential`, a massive change in `potential` will be triggered that last the duration of `refractory period`, during which `potential` will not be affected by any stimuli.

## Documentation



###nerv
=======
####Synopsis
```lua
  new_nerv = nerv(fn_onStart, fn_onFinished, maxPotential, refractoryPeriod, lagTime, isSynchronised)
```
or else
```lua
  new_nerv = nerv()
  new_nerv:setFunctions(function() a=a+1 end, function() b=b+1 end)
```
or else
```lua
  new_nerv = nerv():setPeriod(.6)`
```


####Arguments
`fn_onStart` (null function)  function that is called when `potential` reaches `threshold potential`

`fn_onFinished` (null function) function that is called at the end of `refractory period`

`maxPotential` (8) maximum potential that `potential` will reach after exceeding `threshold potential`

`refractoryPeriod` (1) period of time when stimuli have no effect on `potential` when `potential` is undergoing massive change

`lagTime` (refractoryPeriod/2 or .5) delay before nerve impulse is fired to any connected nerv cell (if there is any)

`isSynchronised` (false) determine whether nervs created at the same frame should have similar `potential` variations
