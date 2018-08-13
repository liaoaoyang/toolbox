-- from https://gist.github.com/chrisboulton/6043871
-- modify by ay

-- riac == redis ip access controller
function riac_refresh_ip_list(ip_list, redis_key)
    local redis_host = ngx.var.riac_redis_host;
    local redis_port = ngx.var.riac_redis_port;
    local redis_password = ngx.var.riac_redis_password;

    -- connection timeout for redis in ms. don't set this too high!
    local redis_connect_timeout = ngx.var.riac_redis_connect_timeout;

    if redis_connect_timeout == nil then
        redis_connect_timeout = 100;
    end

    -- cache lookups for this many seconds
    local cache_ttl = ngx.var.riac_cache_ttl;

    if cache_ttl == nil then
        cache_ttl = 60;
    end

    local refresh_ip = ngx.var.riac_refresh_ip;

    if refresh_ip == nil then
        refresh_ip = "127.0.0.1";
    end

    local refresh_token = ngx.var.riac_refresh_token;

    if refresh_token == nil then
        refresh_token = "just_do_it";
    end

    local last_update_time = ip_list:get("last_update_time");
    local is_riac_refresh_request = ngx.var.arg_riac_refresh_token == refresh_token and refresh_ip == ngx.var.remote_addr;

    -- only update ip_blacklist from Redis once every cache_ttl seconds:
    if is_riac_refresh_request or last_update_time == nil or last_update_time < (ngx.now() - cache_ttl) then
        if is_riac_refresh_request then
            ngx.log(ngx.DEBUG, "Nginx tried to refresh");
        end

        local redis = require "resty.redis";
        local red = redis:new();

        red:set_timeout(redis_connect_timeout);

        local ok, err = red:connect(redis_host, redis_port);
        if not ok then
            ngx.log(ngx.DEBUG, "Redis connection error while retrieving : " .. redis_key .. " err: " .. err);
        else
            local passed_auth = true;

            if redis_password ~= nil then
                local count, err = red:get_reused_times();

                if 0 == count then
                    ok, err = red:auth(redis_password)
                    if not ok then
                        ngx.log(ngx.DEBUG, "Redis failed to authenticate: " .. err);
                        passed_auth = false;
                    end
                elseif err then
                    ngx.log(ngx.DEBUG, "Redis failed to get reused times: " .. err);
                    return
                end
            end

            if passed_auth then
                local new_ip_list, err = red:smembers(redis_key);
                if err then
                    ngx.log(ngx.DEBUG, "Redis read error while retrieving ip list: " .. redis_key .. " err: " .. err);
                else
                    -- replace the locally stored ip_blacklist with the updated values:
                    ip_list:flush_all();
                    for index, affected_ip in ipairs(new_ip_list) do
                        ip_list:set(affected_ip, true);
                    end

                    -- update time
                    ip_list:set("last_update_time", ngx.now());
                end
            end
        end
    end
end

function ngx_riac()
    local redis_host = ngx.var.riac_redis_host;
    local redis_port = ngx.var.riac_redis_port;

    if redis_host == nil or redis_port == nil then
        return;
    end

    local redis_blacklist_key = ngx.var.riac_redis_blacklist_key;

    if redis_blacklist_key == nil then
        redis_blacklist_key = "riac_ip_blacklist";
    end

    local redis_whitelist_key = ngx.var.riac_redis_whitelist_key;

    if redis_whitelist_key == nil then
        redis_whitelist_key = "riac_ip_whitelist";
    end

    local prefer_ip_key_name = ngx.var.riac_prefer_ip_key_name;

    if prefer_ip_key_name == nil then
        prefer_ip_key_name = "remote_addr";
    end

    local mode = ngx.var.riac_mode;

    if mode == nil then
        mode = "blacklist";
    end

    if not mode == "blacklist" or not mode == "whitelist" or not mode == "both" then
        return;
    end
    -- end configuration

    local ip = ngx.var[prefer_ip_key_name];

    if mode == "whitelist" or mode == "both" then
        local ip_whitelist = ngx.shared.riac_ip_whitelist;
        riac_refresh_ip_list(ip_whitelist, redis_whitelist_key);
        if ip_whitelist:get(ip) then
            return;
        else
            ngx.log(ngx.DEBUG, "IP not in whitelist and refused access: " .. ip);
            return ngx.exit(ngx.HTTP_FORBIDDEN);
        end
    end

    if mode == "blacklist" or mode == "both" then
        local ip_blacklist = ngx.shared.riac_ip_blacklist;
        riac_refresh_ip_list(ip_blacklist, redis_blacklist_key);
        if ip_blacklist:get(ip) then
            ngx.log(ngx.DEBUG, "Banned IP detected and refused access: " .. ip);
            return ngx.exit(ngx.HTTP_FORBIDDEN);
        end
    end

    if mode == "both" then
        ngx.log(ngx.DEBUG, "IP not in any list and refused access: " .. ip);
        return ngx.exit(ngx.HTTP_FORBIDDEN);
    end
end

ngx_riac()

