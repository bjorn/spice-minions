local Unit = require "shared.unit"

local Enemy = Unit:subclass("Enemy")

local content = require "minionmaster.content"
local state = require "minionmaster.state"

local BehaviorTrees = require "minionmaster.behaviors.behaviortrees"
local BehaviorTree = require "shared.behaviortree"

-- speed: pixels/second
function Enemy:initialize(entityStatics)
    Unit.initialize(self, entityStatics, state.player)
    self.type = "enemy"
    self.maxHealth = self.health

    self.behavior = BehaviorTree.BehaviorTree:new(self, BehaviorTrees:createEnemyTree())

    self:setAnimation("images/minion/lava/walk.png", 0.175)
    self.attack = false
    self:setRandomStartAnimationTime()
end

function Enemy:died()
    state.entityManager:remove(self.entity.id)
end

function Enemy:update(dt)
    if self.dead then
        Unit.update(self, dt)
        return
    end

    if self.health <= 0 then
        self.dead = true
        state.dna = state.dna + self.dna
        self:setAnimation("images/minion/lava/die.png", 0.175)
        self.animation.onLoop = self.died
        self.animation.entity = self
        return
    end

    local wasAttacking = self.attack

    Unit.update(self, dt)
    self.behavior:tick(dt)

    if self.attack then
        if not wasAttacking then
            self:setAnimation("images/minion/lava/attack.png", 0.175)
            self:setRandomStartAnimationTime()
        end
    elseif wasAttacking then
        self:setAnimation("images/minion/lava/walk.png", 0.175)
        self:setRandomStartAnimationTime()
    end
end

function Enemy:draw(dt)
    -- love.graphics.circle("line", self.position.x, self.position.y, self.attackRange, 100);
    Unit.draw(self, dt)
end

return Enemy
