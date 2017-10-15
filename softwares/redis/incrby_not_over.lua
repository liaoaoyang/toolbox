--[[
Usage: 
redis-cli eval "$(cat incrby_not_over.lua)" 1 key_name max_value [step expire]

or

redis-cli evalsha xxx 1 key_name max_value [step expire]
--]]
local key     = KEYS[1]
local step    = 1
local max_val = tonumber(ARGV[1])

if #ARGV >= 2 then
	step = tonumber(ARGV[2])
end

local key_exists = redis.call("EXISTS", key)

if key_exists == 0 then
	local ret = redis.call("INCRBY", key, step)

	if #ARGV == 3 then
		local expire  = tonumber(ARGV[3])
		redis.call("EXPIRE", key, expire)
	end

	return ret
else
	local now_val = tonumber(redis.call("GET", key))

	if now_val >= max_val then
		return -max_val
	end

	local ret = redis.call("INCRBY", key, step)
	return ret
end
