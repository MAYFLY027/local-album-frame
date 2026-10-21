-- Local Album Frame clock. MIT; uses mpv's public Lua overlay API.
local mp = require 'mp'
local utils = require 'mp.utils'
local overlay = mp.create_osd_overlay('ass-events')
local weekdays = {'星期日', '星期一', '星期二', '星期三', '星期四', '星期五', '星期六'}
local enabled = true
local random_corner = true
local media_info = true
do
    local config = mp.command_native({'expand-path','~~/'})
    local file = io.open(utils.join_path(config,'../settings.json'),'rb')
    if file then
        local content=file:read('*a'); file:close()
        content=content:gsub('^\239\187\191','')
        local settings=utils.parse_json(content)
        if settings then
            if settings.ShowClock ~= nil then enabled=settings.ShowClock end
            if settings.RandomClockCorner ~= nil then random_corner=settings.RandomClockCorner end
            if settings.ShowMediaInfo ~= nil then media_info=settings.ShowMediaInfo end
        end
    end
end
local corner = 2
local anchors = {7, 9, 1, 3}
math.randomseed(os.time())

local function render()
    if not enabled then overlay:remove(); return end
    local w, h = mp.get_osd_size()
    if not w or not h or w <= 0 or h <= 0 then return end
    -- Use a stable virtual canvas so text is readable on handheld screens.
    overlay.res_y = 800
    overlay.res_x = math.floor(800 * w / h)
    local right = corner == 2 or corner == 4
    local bottom = corner >= 3
    local x = right and overlay.res_x - 32 or 32
    -- Leave room for mpv's transport bar and the handheld's top status overlay.
    local y = bottom and 590 or 62
    if media_info and corner == 1 then y=126 end
    local now = os.date('*t')
    local time = string.format('%02d:%02d:%02d', now.hour, now.min, now.sec)
    local date = string.format('%d年%d月%d日  %s', now.year, now.month, now.day, weekdays[now.wday])
    local style = string.format('{\\an%d\\pos(%d,%d)\\fnMicrosoft YaHei UI\\fs42\\b1\\bord2\\shad1\\1c&HFFFFFF&\\3c&H202020&}', anchors[corner], x, y)
    overlay.data = style .. time .. '{\\fs22\\b0}\\N' .. date
    overlay:update()
end

mp.register_event('file-loaded', function()
    -- Every new picture/video selects another corner, without immediate repeats.
    corner = random_corner and ((corner - 1 + math.random(1, 3)) % 4) + 1 or 2
    render()
end)
mp.observe_property('osd-dimensions', 'native', render)
mp.add_periodic_timer(1, render)
mp.add_key_binding(nil, 'toggle-clock', function()
    enabled = not enabled
    render()
end)
render()
