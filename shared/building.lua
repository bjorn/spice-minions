local Entity = require "spiceminion_engine.game_core.entity"


local Building = Entity:subclass("Building")

function Building:initialize(entityStatic, player)
    Entity.initialize(self, entityStatic, player)
    -- self.targetHealth = self.health
    self.health = 1
    self.constructing = true
end

function Building:instantBuild()
	self:finishConstruction()
end

function Building:update(dt)
    Entity.update(self, dt)
    if self.constructing and (self.health >= self.maxHealth) then
    	self:finishConstruction()
    elseif (self.health <= 0) then
        self.markedForRemoval = true
    	return
	end
end

function Building:finishConstruction()
	self.health = self.maxHealth
	self.constructing = nil
	self:setAnimation("images/buildings/" .. self.theme .. "/portal.png", 0.1)	
end

return Building