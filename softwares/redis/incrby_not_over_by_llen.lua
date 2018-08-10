--[[
Usage: 
redis-cli eval "$(cat incrby_not_over_by_llen.lua)" 2 queue_name max_value msg [LPUSH]

or

redis-cli evalsha xxx 2 queue_name max_value msg [LPUSH]
--]]
local PUSH = "LPUSH"

if #ARGV >= 3 then
	PUSH = "RPUSH"
end

if redis.call("LLEN", KEYS[1]) >= tonumber(ARGV[1]) then
	return -tonumber(ARGV[1])
end

return redis.call("LPUSH", KEYS[1], ARGV[2])

