local Class = require "shared.middleclass"
local Unit = require "shared.unit"
local LogicCore = require "hymn.logiccore"
local DecayUnitBT = require "hymn.staticdata.decayunitbehaviortree"
local BehaviorTree = require "shared.behaviortree"

local DecayingUnit = Class("DecayingUnit", Unit)

-- TODO: Proper STATE HANDLING

function DecayingUnit:initialize(entityStatic, player)
	Unit.initialize(self, entityStatic, player)
    self.speed = self.speed + (math.random()-0.5) * 20

	self.behaviorTree = BehaviorTree.BehaviorTree:new(self, DecayUnitBT())
	self.decayInterval = 1 -- in seconds
	self.decayAmount = 1 -- in health
	self.timeSinceLastDecay = 0
	self.state = "default"
	self.timeInState = 0
end

local themes = {
    "frost",
    "lava",
}

function DecayingUnit:setPlayer(player)
    self.player = player
    self.theme = themes[player.playerId] or themes[1]
    self:setAnimation("images/minion/" .. self.theme .. "/walk.png", 0.175, 0.7)
end

function DecayingUnit:update(dt)
	if self.state == "default" then
		Unit.update(self, dt)
		self.timeInState = self.timeInState + dt
		local dtLastDecay = self.timeSinceLastDecay
		dtLastDecay = dtLastDecay + dt

		if dtLastDecay > self.decayInterval then
			self.health = self.health - self.decayAmount
			self.timeSinceLastDecay = dtLastDecay - self.decayInterval
		else
			self.timeSinceLastDecay = dtLastDecay
		end

		self.behaviorTree:tick(dt)

	    -- DEATH
	    if self.health <= 0 then
	    	self:setAnimation("images/minion/" .. self.theme .. "/die.png", 0.25, 0.7, "pauseAtEnd")
	        self.state = "dying"
	        self.timeInState = 0
	        -- LogicCore.entityManager:remove(self.id)
	    end
    elseif self.state == "dying" then
		self.timeInState = self.timeInState + dt
		dbgprint(self.animation.status)
		if self.animation.status == "paused" then
			LogicCore.entityManager:remove(self.id)
		end
	end
end

return DecayingUnit
