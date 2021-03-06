local Class = require "spiceminion_engine.libs.middleclass"

local EntityManager = require "spiceminion_engine.game_core.entitymanager"
local InputHandler 	= require "hymn.inputhandler"
local HymnPlayer 	= require "hymn.hymnplayer"

local blocking = require "spiceminion_engine.logic.blocking"

-- LogicCore Class
local LogicCore = Class "LogicCore"

function LogicCore:initialize(eMng, iHndlr)
	local player1 = HymnPlayer:new()
	local player2 = HymnPlayer:new()
	self.players = {
		[player1.playerId] = player1,
		[player2.playerId] = player2,
	}
	self.entityManager = eMng or  EntityManager:new(self)
	self.inputHandler = iHndlr or InputHandler:new(self)
	self.state = "running"
	self.map = false
end

function LogicCore:startMap(map)
    self.map = map
end

function LogicCore:reset()

end

-- LogicCore Singleton
local logicCore = LogicCore:new()

return logicCore

