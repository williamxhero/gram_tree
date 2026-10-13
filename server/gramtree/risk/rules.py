"""Atomic Redis observations, score updates and graduated action reservations."""

# All counters use the server's business clock; Redis TTL is only garbage collection.
# Each subject transition is one script, so parallel requests cannot lose intervals,
# inflate distinct counts, or create duplicate actions at the same tier.
OBSERVE = r"""
local base = KEYS[1]
local state = base .. ':state'
local now = tonumber(ARGV[1])
local mode = ARGV[2]
local cfg = cjson.decode(ARGV[3])
local input = cjson.decode(ARGV[4])
local ttl = cfg.retention_seconds
local function window(name, seconds, member)
  local key = base .. ':' .. name
  redis.call('ZREMRANGEBYSCORE', key, '-inf', now - seconds)
  redis.call('ZADD', key, now, member)
  redis.call('EXPIRE', key, math.max(ttl, seconds * 2))
  return redis.call('ZCARD', key)
end
local function finish(level, retry, action, rule, evidence, points, old)
  return cjson.encode({level=level, retry=retry, action_id=action, rule=rule,
    evidence=evidence, points=points, previous_action=old})
end
local active = redis.call('HGET', state, 'active') or ''
local ends = tonumber(redis.call('HGET', state, 'ends') or '0')
local old = ''
if active ~= '' and ends > 0 and ends <= now then
  old = redis.call('HGET', state, 'action_id') or ''
  redis.call('HDEL', state, 'active', 'ends', 'action_id')
  active = ''
end
if active == 'permanent_block' or active == 'temporary_block' or active == 'captcha' then
  return finish(active, math.max(0, ends-now), redis.call('HGET', state, 'action_id') or '',
    '', {}, 0, old)
end
local recovering = false
if redis.call('HGET', state, 'grace') == '1' and mode == 'request' then
  redis.call('HDEL', state, 'grace')
  recovering = true
end
local rule = ''
local evidence = {}
local points = 10
if mode == 'request' then
  local count = window('requests', cfg.short_window_seconds, input.member)
  if count >= cfg.short_request_limit then
    rule = 'short_burst'
    evidence = {count=count, window_seconds=cfg.short_window_seconds}
  end
  if input.detail ~= '' then
    local previous = tonumber(redis.call('HGET', state, 'detail_at') or '-1')
    local previous_gap = tonumber(redis.call('HGET', state, 'detail_gap') or '-1')
    local gap = now - previous
    local repeats = 0
    if previous >= 0 and gap >= 0 and gap <= cfg.detail_interval_seconds then
      local stable = math.abs(gap-previous_gap)*1000 <= cfg.detail_interval_tolerance_ms
      if previous_gap < 0 or stable then
        repeats = tonumber(redis.call('HGET', state, 'rapid') or '0') + 1
      else
        repeats = 1
      end
      redis.call('HSET', state, 'detail_gap', gap)
    else
      redis.call('HDEL', state, 'detail_gap')
    end
    redis.call('HSET', state, 'detail_at', now, 'rapid', repeats)
    if rule == '' and repeats >= cfg.detail_repeat_limit then
      rule = 'rapid_detail'
      evidence = {repeat_count=repeats, interval_seconds=gap,
        tolerance_ms=cfg.detail_interval_tolerance_ms}
    end
    local distinct = window('details', cfg.short_window_seconds, input.detail)
    if rule == '' and distinct >= cfg.sequential_limit then
      rule = 'sequential_detail'
      evidence = {distinct_count=distinct, window_seconds=cfg.short_window_seconds}
    end
  end
  local bucket_seconds = cfg.uniform_bucket_seconds
  local bucket = math.floor(now / bucket_seconds)
  local bucket_key = base .. ':uniform'
  redis.call('HINCRBY', bucket_key, tostring(bucket), 1)
  redis.call('EXPIRE', bucket_key, math.max(ttl, (cfg.uniform_days+1)*86400))
  local buckets = redis.call('HGETALL', bucket_key)
  local required = math.ceil(cfg.uniform_days*86400/bucket_seconds)
  local counts = {}
  local total = 0
  local minimum = math.huge
  local maximum = 0
  for i=1,#buckets,2 do
    local b = tonumber(buckets[i])
    if b < bucket-required then
      redis.call('HDEL', bucket_key, buckets[i])
    elseif b < bucket then
      local n = tonumber(buckets[i+1])
      counts[#counts+1] = n
      total = total + n
      minimum = math.min(minimum, n)
      maximum = math.max(maximum, n)
    end
  end
  if rule == '' and #counts == required and total >= cfg.uniform_daily_limit*cfg.uniform_days then
    local mean = total/required
    if maximum-minimum <= mean*cfg.uniform_tolerance_percent/100 then
      rule = 'uniform_daily_access'
      evidence = {count=total, days=cfg.uniform_days, bucket_seconds=bucket_seconds,
        minimum_bucket_count=minimum, maximum_bucket_count=maximum}
      points = 15
    end
  end
elseif mode == 'login' then
  local count = window('accounts', cfg.score_ttl_seconds, input.account)
  if input.new_account then
    count = window('new-accounts', cfg.short_window_seconds, input.account)
    if count >= cfg.subnet_new_account_limit then
      rule = 'subnet_new_accounts'
      evidence = {account_count=count, window_seconds=cfg.short_window_seconds}
    end
  elseif count >= cfg.multi_account_limit then
    rule = 'multi_account_device'
    evidence = {account_count=count, window_seconds=cfg.score_ttl_seconds}
  end
elseif mode == 'security' then
  local count = window('security', cfg.short_window_seconds, input.member)
  rule = input.rule
  evidence = {count=count, window_seconds=cfg.short_window_seconds, signal=input.rule}
  points = count >= cfg.security_failure_limit and 10 or 0
end
redis.call('EXPIRE', state, ttl)
if recovering and rule ~= '' then
  return finish('', 0, '', rule, evidence, 0, old)
end
if rule ~= '' and points == 0 then
  return finish(active, math.max(0,ends-now), redis.call('HGET', state, 'action_id') or '',
    rule, evidence, 0, old)
end
if rule ~= '' then
  local last_signal = tonumber(redis.call('HGET', state, 'signal_at') or '0')
  local score = tonumber(redis.call('HGET', state, 'score') or '0')
  if now-last_signal > cfg.score_ttl_seconds then score = 0 end
  score = score + points
  redis.call('HSET', state, 'score', score, 'signal_at', now)
  local previous = redis.call('HGET', state, 'last_level') or ''
  local level = ''
  if input.can_ban and score >= cfg.permanent_block_points then level = 'permanent_block'
  elseif score >= cfg.temporary_block_points then level = 'temporary_block'
  elseif score >= cfg.throttle_points then level = 'throttle'
  elseif score >= cfg.captcha_points then level = 'captcha' end
  local order = {captcha=1, throttle=2, temporary_block=3, permanent_block=4}
  -- Never skip the recoverable first tier, even when operators overlap thresholds.
  if previous == '' and level ~= '' then level = 'captcha' end
  if previous ~= '' and order[level] and order[level] > order[previous]+1 then
    if previous == 'captcha' then level = 'throttle'
    elseif previous == 'throttle' then level = 'temporary_block' end
  end
  local not_advanced = previous ~= '' and order[previous]
    and (not order[level] or order[level] <= order[previous])
  if not_advanced then
    if previous == 'captcha' then level = 'throttle'
    elseif previous == 'throttle' then level = 'temporary_block'
    elseif previous == 'temporary_block' and input.can_ban then level = 'permanent_block'
    else level = previous end
  end
  if level ~= '' then
    local end_at = 0
    if level == 'captcha' then end_at = now+cfg.captcha_seconds end
    if level == 'throttle' then end_at = now+cfg.throttle_seconds end
    if level == 'temporary_block' then end_at = now+cfg.temporary_block_seconds end
    old = redis.call('HGET', state, 'action_id') or old
    redis.call('HSET', state, 'active', level, 'last_level', level,
      'ends', end_at, 'action_id', input.action_id)
    redis.call('EXPIRE', state, ttl)
    return finish(level, math.max(0,end_at-now), input.action_id, rule, evidence, points, old)
  end
  return finish('', 0, '', rule, evidence, points, old)
end
if active == 'throttle' then
  local count = window('throttle', cfg.throttle_window_seconds, input.member)
  if count > cfg.throttle_request_limit then
    return finish('throttle', cfg.throttle_window_seconds,
      redis.call('HGET', state, 'action_id') or '', '', {}, 0, old)
  end
end
return finish('', 0, '', '', {}, 0, old)
"""

RECOVER = r"""
local challenge = KEYS[1]
if redis.call('HGET', challenge, 'binding') ~= ARGV[1] then return '' end
if tonumber(redis.call('HGET', challenge, 'expires_at') or '0') <= tonumber(ARGV[2]) then
  return ''
end
local base = redis.call('HGET', challenge, 'base')
local action = redis.call('HGET', challenge, 'action_id')
local primary = base .. ':state'
if redis.call('HGET', primary, 'action_id') ~= action or
   redis.call('HGET', primary, 'active') ~= 'captcha' then return '' end
redis.call('DEL', challenge)
for i=2,#KEYS do
  local state = KEYS[i]
  if state == primary or not redis.call('HGET', state, 'active') then
    local subject_base = string.sub(state, 1, string.len(state)-6)
    redis.call('DEL', subject_base .. ':requests', subject_base .. ':details',
      subject_base .. ':uniform', subject_base .. ':accounts', subject_base .. ':new-accounts',
      subject_base .. ':security', subject_base .. ':throttle')
    redis.call('HDEL', state, 'active', 'ends', 'action_id', 'detail_at', 'detail_gap',
      'rapid', 'challenge')
    local levels = {captcha=1, throttle=2, temporary_block=3, permanent_block=4}
    local prior = redis.call('HGET', state, 'last_level') or 'captcha'
    if not levels[prior] or levels[prior] < levels.captcha then prior = 'captcha' end
    redis.call('HSET', state, 'score', 0, 'last_level', prior, 'grace', 1)
    redis.call('EXPIRE', state, ARGV[3])
  end
end
return action
"""
