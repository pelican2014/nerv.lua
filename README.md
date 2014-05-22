# nerv.lua
`nerv.lua` is inspired by nerve impulses for controlled randomness

#### Situations where `nerv` might be useful:
* make a group of birds fly away when player walks close enough in a random way
* make interesting patterns that interact with mouse/player randomly
* make the enemy or enemies shoot bullet(s) at player randomly when player walks close enough and prevent them from shooting when there is obstacle between them
* make customers leave the store with increasing chances as the waiting time increases

## Installation
====
`local nerv = require 'nerv'`

## Idea
====
Each nerv cell (instance of nerv) manages a variable, `potential`, that once exceeds a critical value, `threshold potential`, will further increase massively to a maximum value, `maximum potential`, before returning to normal levels. A function may be called when the critical value is exceeded, another function may also be supplied to be called as `potential` returns to normal levels.
