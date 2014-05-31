local nerv = {
__version = '0.1.0',
__license = [[
The MIT License (MIT)

Copyright (c) 2014 pelican2014

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]
}
nerv.__index = nerv

--can't take credit for the internal functions below
local function _in_quad(a,b,x) return a+(b-a)*x^2 end
local function _out_quad(a,b,x) return a+(b-a)*(1-(1-x)^2) end
local function _max(a,b) return a>b and a or b end

local function _findIndex(t,value)
  for i,v in pairs(t) do
    if v == value then return i end
  end
end

local function _checkFn(fn)
  if type(fn) == 'function' then
    return true
  else
    local mt = getmetatable(fn)
	if mt then return mt.__call end
  end
  return false
end

local function _clamp(x,min,max) return x<min and min or (x>max and max or x) end

local _nerv_num = 0
local _active_nerv_num = {}
local _nervTable = {}

function nerv.new( fn_onStart, fn_onFinished, maxPotential, refractoryPeriod )
  _nerv_num = _nerv_num + 1
  if fn_onStart~= nil then
    assert( _checkFn(fn_onStart), 'fn_onStart (1st parameter) should be a function (or nil) but it is ' .. type(fn_onStart) )
  end
  if fn_onFinished~= nil then
    assert( _checkFn(fn_onFinished), 'fn_onFinished (2nd parameter) should be a function (or nil) but it is ' .. type(fn_onFinished) )
  end
  if maxPotential~= nil then
    assert( type(maxPotential) =='number' and maxPotential >= 1, ' maxPotential (3rd parameter) should be a number such that maxPotentials >= threshold potential(1) (or nil), but it is ' .. type(maxPotential) )
  end
  if refractoryPeriod~= nil then
    assert( type(refractoryPeriod) == 'number' and refractoryPeriod >= 0, 'refractoryPeriod (4th parameter) should be a non-negative number (or nil)' )
  end
  local t = setmetatable( {
    
	fn_onStart = fn_onStart or function() end,
	fn_onFinished = fn_onFinished or function() end,
	rP = 0,		--resting potential
	tP = 1,		--threshold potential
	potential = 0,
	recordedPotential = 0,
	mP = maxPotential or 8,
	rPe = refractoryPeriod or 1,
	stRPe = nil,
	isLocked = false,
	timers = {love.math.random(1,10000)/100},
	timerNum = 0,
	nervNum = _nerv_num,
	connectedNervs = {},
	lagTime = {},
	isFiredNervs = {},		--a table of booleans that indicate whether impulses have been transmitted to the nervs connected downstream
	type = 'nerv'
	
  }, {__index = nerv} )
    _nervTable[_nerv_num] = t
	return t
end

function nerv:update(dt)

  if not self.isLocked and self.potential >= self.tP and self.rPe ~= 0 then
    self.fn_onStart()
    self.isLocked = true
  end

  for i = 1,#self.timers do
    self.timers[i] = self.timers[i] + dt
  end
  self.recordedPotential = self.potential <= self.tP and self.potential or ( self.stRPe and not self.isSkipped and self.potential or ( self.rPe ~= 0 and self.tP or self.potential) )	--make sure the potential returned does not exceed threshold potential( because the potential can be so awefully large )
  
  if not self.isLocked then
    self.timerNum = 0
    self.potential = self.rP
  else
    --tweening
    self.stRPe = self.stRPe or love.timer.getTime()	--stRPe: starting time of refractory period
	local tDif = love.timer.getTime()-self.stRPe
	
	if not self.isSkipped then
	  local tP,rP,mP,rPe = self.tP, self.rP, self.mP, self.rPe
	  if not self.isReverseMP then
	    local frac_tDif = (tDif%(self.rPe/2))/(self.rPe/2)
	    self.potential = tDif<rPe/2 and _out_quad(tP, mP, frac_tDif) or ( tDif<rPe and _in_quad(mP, rP, frac_tDif) or rP )
	  else
	    local frac_tDif = (tDif%(self.rPe/4))/(self.rPe/4)
	    self.potential = tDif<rPe/4 and _out_quad(tP, mP, frac_tDif) or ( tDif<rPe/2 and _in_quad(mP, rP, frac_tDif) or ( tDif<rPe*3/4 and _out_quad(rP, rP-(mP-rP), frac_tDif ) or ( tDif<rPe and _in_quad(rP-(mP-rP), rP, frac_tDif ) or rP ) ) )
	  end
	end
	
	--fire impulse to the connected nerv
	for i, _nerv in pairs( self.connectedNervs ) do
	  if not self.isFiredNervs[i] then
		if tDif > self.lagTime[i] then self.isFiredNervs[i] = true; _nerv:fire() end
	  end
	end
	
	--tidy up after potential changes back
	if tDif > self.rPe then
	  self.fn_onFinished()
	  self.potential = self.rP		--in case tweening is skipped
      self.timerNum = 0
	  self.isLocked = false
	  self.stRPe = nil
	  for i = 1, #self.isFiredNervs do self.isFiredNervs[i] = false end
	  local i = _findIndex( _active_nerv_num, self.nervNum-1 )
	  if i then _active_nerv_num[i] = nil end
	end
  end
	  
end

function nerv:send( strength )
  assert( type(strength) == 'number', 'strength of stimulus sent needs to be a number, but it is ' .. type(strength) )
  if not self.isLocked then
    local strength = _max(strength,0)
    self.timerNum = self.timerNum + 1
    if self.timerNum > #self.timers then
      self.timers[ #self.timers+1 ] = 0
    end
    --order is important
  
    self.potential = _clamp( self.potential + love.math.noise( self.timers[self.timerNum] )*strength, self.rP-(self.mP-self.rP), self.mP )
  end
end

function nerv:inhibit( strength )
  assert( type(strength) == 'number', 'strength of inhibition needs to be a number, but it is ' .. type(strength) )
  if not self.isLocked then
    local strength = _max(strength,0)
    self.timerNum = self.timerNum + 1
    if self.timerNum > #self.timers then
      self.timers[ #self.timers+1 ] = 0
    end
  
    self.potential = _clamp( self.potential - (.5+love.math.noise( self.timers[self.timerNum] )/2)*strength, self.rP-(self.mP-self.rP), self.mP )
  end
end

function nerv:getPotential()
  return self.recordedPotential
end

function nerv:setPotentials( maxPotential, restingPotential, thresholdPotential, isReverseMP )
  if restingPotential ~= nil then
    assert( type(restingPotential) =='number', ' restingPotential (2nd parameter of :setPotentials()) should be a number (or nil), but it is ' .. type(restingPotential) )
	self.rP = restingPotential
	self.potential = self.rP
  end
  if thresholdPotential ~= nil then
    assert( type(thresholdPotential) =='number', ' thresholdPotential (3rd parameter of :setPotentials()) should be a number (or nil), but it is ' .. type(thresholdPotential) )
	self.tP = thresholdPotential
  end
  if maxPotential ~= nil then
    assert( type(maxPotential) =='number' and maxPotential >= self.tP, ' maxPotential (1st parameter of :setPotentials()) should be a number such that maxPotentials >= threshold potential(1) (or nil), but it is ' .. type(maxPotential) )
    self.mP = maxPotential
  end
  if isReverseMP ~= nil then
    assert( type(isReverseMP) == 'boolean', 'isReverseMP (4th parameter of :setPotentials()), should be a boolean (or nil), but it is ' .. type(isReverseMP) )
    self.isReverseMP = isReverseMP  --whether to let potential go down to -1*maxPotential after it drops from maxPotential to restingPotential
  end
  return self
end

function nerv:setFunctions( fn_onStart, fn_onFinished )
  if fn_onStart ~= nil then
    assert( _checkFn(fn_onStart), 'fn_onStart, 1st parameter of setFunctions() should be a function (or nil) but it is ' .. type(fn_onStart) )
    self.fn_onStart = fn_onStart
  end
  if fn_onFinished ~= nil then
    assert( _checkFn(fn_onFinished), 'fn_onFinished, 2nd parameter of setFunctions() should be a function (or nil) but it is ' .. type(fn_onFinished) )
    self.fn_onFinished = fn_onFinished
  end
  return self
end

function nerv:setPeriod( refractoryPeriod )	--refractory period (during which massive change in potential happens)
  assert( type(refractoryPeriod) == 'number' and refractoryPeriod >= 0, 'refractoryPeriod should be a non-negative number (or nil)' )
  self.rPe = refractoryPeriod
  return self
end

function nerv:sync()	--used when creating many instances together
  self.timers = {0}
  return self
end

function nerv:setSkipped()	--whether or not tweening should be skipped (faster by about one third)
  self.isSkipped = true
  return self
end

function nerv:connect(n,lagTime)
  --lagTime(.1): time lag for firing of nerv impulse to the next nerv
  assert( type(n) == 'table' and n.type == 'nerv', 'Only instances of nerv can be connected.' )
  self.connectedNervs[#self.connectedNervs+1] = n
  self.isFiredNervs[#self.isFiredNervs+1] = false
  if lagTime ~= nil then
    assert( type(lagTime) == 'number' and lagTime >= 0, 'lagTime, 2nd parameter of :connect(), should be a non-negative number (or nil)' )
    self.lagTime[#self.lagTime+1] = lagTime
  else
    self.lagTime[#self.lagTime+1] = .1
  end
  return self
end

function nerv:fire()	--for connected nervs upstream to fire off impulse on itself
  if not self.isLocked then
    self.fn_onStart()
	self.isLocked = self.rPe ~= 0
  end
end

setmetatable( nerv, {__call = function(_,...) return nerv.new(...) end } )

return nerv
