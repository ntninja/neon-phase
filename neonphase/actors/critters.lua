local Gamestate = require 'vendor.hump.gamestate'
local Vector = require 'vendor.hump.vector'

local actors_base = require 'klinklang.actors.base'
local actors_misc = require 'klinklang.actors.misc'
local util = require 'klinklang.util'
local whammo_shapes = require 'klinklang.whammo.shapes'
local DialogueScene = require 'klinklang.scenes.dialogue'


-- Doesn't do anything; just needs an actor to be animated
local Glowmeleon = actors_base.Actor:extend{
    name = 'glowmeleon',
    sprite_name = 'glowmeleon',
}
local TV = actors_base.Actor:extend{
    name = 'tv',
    sprite_name = 'tv',
}


local DustBunny = actors_base.MobileActor:extend{
    name = 'dustbunny',
    sprite_name = 'dustbunny',

    xaccel = 100,
    friction = 50,
    max_speed = 10,

    -- Conscious movement decisions
    decision_walk = 0,
    decision_jump_mode = 0,
}

function DustBunny:blocks()
    return false
end

function DustBunny:think()
    if self.busy then
        return
    end

    if love.math.random() < 0.5 then
        self.decision_walk = -1
    else
        self.decision_walk = 1
    end

    self.busy = true
    worldscene.tick:delay(function() self.decision_walk = 0 end, 1):after(function() self.busy = false end, 3)
end

-- FIXME merge this with Player
function DustBunny:update(dt)
    if self.is_dead then
        -- FIXME a corpse still has physics, just not input
        self.sprite:update(dt)
        return
    end

    -- Make some decisions
    self:think()

    local xmult
    if self.on_ground then
        -- TODO adjust this factor when on a slope, so ascending is harder than
        -- descending?  maybe even affect max_speed going uphill?
        xmult = self.ground_friction
    else
        xmult = self.aircontrol
    end
    --print()
    --print()
    --print("position", self.pos, "velocity", self.velocity)

    -- Explicit movement
    local pose = 'stand'
    if self.decision_walk > 0 then
        if self.velocity.x < self.max_speed then
            self.velocity.x = math.min(self.max_speed, self.velocity.x + self.xaccel * xmult * dt)
        end
        self.facing_left = false
        pose = 'walk'
    elseif self.decision_walk < 0 then
        if self.velocity.x > -self.max_speed then
            self.velocity.x = math.max(-self.max_speed, self.velocity.x - self.xaccel * xmult * dt)
        end
        self.facing_left = true
        pose = 'walk'
    end
    -- FIXME no aliases, and no walking pose yet...
    pose = 'default'

    -- Jumping
    -- [n/a]

    -- Run the base logic to perform movement, collision, sprite updating, etc.
    DustBunny.__super.update(self, dt)

    -- FIXME uhh this sucks, but otherwise the death animation is clobbered by
    -- the bit below!  should death skip the rest of the actor's update cycle
    -- entirely, including activating any other collision?  should death only
    -- happen at the start of a frame?  should it be an event or something?
    if self.is_dead then
        return
    end

    -- Update pose depending on actual movement
    if self.on_ground then
    elseif self.velocity.y < 0 then
        --pose = 'jump'
    elseif self.velocity.y > 0 then
        --pose = 'fall'
    end
    -- TODO how do these work for things that aren't players?
    self.sprite:set_facing_right(not self.facing_left)
    self.sprite:set_pose(pose)
end


local Colorbird1 = actors_base.MobileActor:extend{
    name = 'color bird 1',
    sprite_name = 'color bird 1',

    xaccel = 100,
    friction = 50,
    max_speed = 10,
    gravity_multiplier = 0.25,

    -- Conscious movement decisions
    decision_walk = 0,
    decision_jump_mode = 0,
}

function Colorbird1:init(...)
    Colorbird1.__super.init(self, ...)

    self.pos0 = self.pos
    self.flutter_amplitude = math.random(32, 96)
    self.flutter_frequency = math.random() + 0.5
end

function Colorbird1:blocks()
    return false
end

function Colorbird1:think()
    if self.busy then
        return
    end

    if love.math.random() < 0.5 then
        self.decision_walk = -1
    else
        self.decision_walk = 1
    end

    self.busy = true
    worldscene.tick:delay(function() self.decision_walk = 0 end, 1):after(function() self.busy = false end, 3)
end

-- FIXME merge this with...  literally anything else
function Colorbird1:update(dt)
    if self.is_dead then
        -- FIXME a corpse still has physics, just not input
        self.sprite:update(dt)
        return
    end

    -- Make some decisions
    self:think()

    local xmult
    if self.on_ground then
        -- TODO adjust this factor when on a slope, so ascending is harder than
        -- descending?  maybe even affect max_speed going uphill?
        xmult = self.ground_friction
    else
        xmult = self.aircontrol
    end
    --print()
    --print()
    --print("position", self.pos, "velocity", self.velocity)

    -- Explicit movement
    local pose = 'stand'
    -- FIXME this doesn't at all smartly transition between fluttering and
    -- walking, which is particularly bad when a bird can fall off the perch it
    -- starts on
    if not self.on_ground then
        self.velocity.x = - self.flutter_amplitude * self.flutter_frequency * math.sin(self.flutter_frequency * self.timer)
        if self.pos.y > self.pos0.y then
            self.velocity.y = -32
        end
        self.facing_left = self.velocity.x < 0
        pose = 'jump'
    elseif self.decision_walk > 0 then
        if self.velocity.x < self.max_speed then
            self.velocity.x = math.min(self.max_speed, self.velocity.x + self.xaccel * xmult * dt)
        end
        self.facing_left = false
        pose = 'walk'
    elseif self.decision_walk < 0 then
        if self.velocity.x > -self.max_speed then
            self.velocity.x = math.max(-self.max_speed, self.velocity.x - self.xaccel * xmult * dt)
        end
        self.facing_left = true
        pose = 'walk'
    end

    -- Jumping
    -- [n/a]

    -- Run the base logic to perform movement, collision, sprite updating, etc.
    Colorbird1.__super.update(self, dt)

    -- FIXME uhh this sucks, but otherwise the death animation is clobbered by
    -- the bit below!  should death skip the rest of the actor's update cycle
    -- entirely, including activating any other collision?  should death only
    -- happen at the start of a frame?  should it be an event or something?
    if self.is_dead then
        return
    end

    -- Update pose depending on actual movement
    if self.on_ground then
    elseif self.velocity.y < 0 then
        --pose = 'jump'
    elseif self.velocity.y > 0 then
        --pose = 'fall'
    end
    -- TODO how do these work for things that aren't players?
    self.sprite:set_facing_right(not self.facing_left)
    self.sprite:set_pose(pose)
end

local Colorbird2 = Colorbird1:extend{
    name = 'color bird 2',
    sprite_name = 'color bird 2',
}
local Colorbird3 = Colorbird1:extend{
    name = 'color bird 3',
    sprite_name = 'color bird 3',
}
local Colorbird4 = Colorbird1:extend{
    name = 'color bird 4',
    sprite_name = 'color bird 4',
}
local Colorbird5 = Colorbird1:extend{
    name = 'color bird 5',
    sprite_name = 'color bird 5',
}


local Glomeleon = actors_base.MobileActor:extend{
    name = 'glomeleon',
    sprite_name = 'glomeleon',

    walking_left = true,
}

-- FIXME merge this with Player
function Glomeleon:update(dt)
    if self.is_dead then
        -- FIXME a corpse still has physics, just not input
        self.sprite:update(dt)
        return
    end

    local xmult
    if self.on_ground then
        -- TODO adjust this factor when on a slope, so ascending is harder than
        -- descending?  maybe even affect max_speed going uphill?
        xmult = self.ground_friction
    else
        xmult = self.aircontrol
    end
    --print()
    --print()
    --print("position", self.pos, "velocity", self.velocity)

    -- Explicit movement
    if self.velocity.x == 0 then
        self.walking_left = not self.walking_left
    end
    local pose = 'stand'
    if self.walking_left then
        if self.velocity.x < self.max_speed then
            self.velocity.x = self.velocity.x + self.xaccel * xmult * dt
        end
        self.facing_left = false
        pose = 'walk'
    elseif not self.walking_left then
        if self.velocity.x > -self.max_speed then
            self.velocity.x = self.velocity.x - self.xaccel * xmult * dt
        end
        self.facing_left = true
        pose = 'walk'
    end
    -- FIXME no aliases, and no walking pose for glomeleon yet...
    pose = 'stand'

    -- Jumping
    -- [n/a]

    -- Run the base logic to perform movement, collision, sprite updating, etc.
    Glomeleon.__super.update(self, dt)

    -- FIXME uhh this sucks, but otherwise the death animation is clobbered by
    -- the bit below!  should death skip the rest of the actor's update cycle
    -- entirely, including activating any other collision?  should death only
    -- happen at the start of a frame?  should it be an event or something?
    if self.is_dead then
        return
    end

    -- Update pose depending on actual movement
    if self.on_ground then
    elseif self.velocity.y < 0 then
        --pose = 'jump'
    elseif self.velocity.y > 0 then
        --pose = 'fall'
    end
    -- TODO how do these work for things that aren't players?
    self.sprite:set_facing_right(not self.facing_left)
    self.sprite:set_pose(pose)

    local hits = self._stupid_hits_hack
    debug_hits = hits
end

function Glomeleon:on_collide(other, d)
    other:damage(self, 1)
end

function Glomeleon:damage(source, amount)
    --self:die()
    worldscene:remove_actor(self)
end


return {
    DustBunny = DustBunny,
    Glomeleon = Glomeleon,
}
