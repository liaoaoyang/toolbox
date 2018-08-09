--[[
Usage: 
redis-cli eval "$(cat incrby_not_overby_zset.lua)" 1 zset_name max_value client_req_id client_req_timestamp [expire_second]

or

redis-cli evalsha xxx 1 zset_name max_value client_req_id [expire_second]
--]]
if #ARGV >=4 then
	redis.call("ZREMRANGEBYSCORE", KEYS[1], 0, tonumber(ARGV[3]) - tonumber(ARGV[4]))
end

if tonumber(redis.call("ZCARD", KEYS[1])) >= tonumber(ARGV[1]) then
	return -tonumber(ARGV[1])
end

redis.call("ZADD", KEYS[1], ARGV[3], ARGV[2])

return tonumber(redis.call("ZCARD", KEYS[1]))
