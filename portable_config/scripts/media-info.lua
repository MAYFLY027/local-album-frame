-- Compact local media information, modelled after the supplied JPEGView reference.
local mp=require 'mp'
local utils=require 'mp.utils'
local overlay=mp.create_osd_overlay('ass-events')
local enabled=true
local modified='—'
local weekdays={'周日','周一','周二','周三','周四','周五','周六'}
do
    local config=mp.command_native({'expand-path','~~/'})
    local file=io.open(utils.join_path(config,'../settings.json'),'rb')
    if file then
        local content=file:read('*a');file:close()
        local settings=utils.parse_json(content:gsub('^\239\187\191',''))
        if settings and settings.ShowMediaInfo~=nil then enabled=settings.ShowMediaInfo end
    end
end
local function shorten(value,budget)
    local out,used={},0
    for char in value:gmatch('[%z\1-\127\194-\244][\128-\191]*') do
        local width=#char>1 and 16 or 8
        if used+width>budget-24 then return table.concat(out)..'…' end
        out[#out+1]=char;used=used+width
    end
    return table.concat(out)
end
local function line(x,y,value,size)
    value=mp.command_native({'escape-ass',value})
    return string.format('{\\an7\\pos(%d,%d)\\fnMicrosoft YaHei UI\\fs%d\\b0\\bord0\\shad0\\1c&HFFFFFF&\\1a&H00&}%s',x,y,size,value)
end
local function render()
    if not enabled then overlay:remove();return end
    local w,h=mp.get_osd_size()
    if not w or not h or w<=0 or h<=0 then return end
    local cw=math.floor(800*w/h)
    local width=math.floor(math.min(580,cw*0.55))
    width=math.max(240,width)
    overlay.res_x=cw;overlay.res_y=800
    local index=mp.get_property_number('playlist-pos',-1)+1
    local count=mp.get_property_number('playlist-count',0)
    local name=mp.get_property('filename','')
    local params=mp.get_property_native('video-dec-params') or mp.get_property_native('video-params') or {}
    local image_width=params.w or mp.get_property_number('width',0)
    local image_height=params.h or mp.get_property_number('height',0)
    local first=shorten(string.format('[%d/%d] %s',index,count,name),width-24)
    overlay.data=table.concat({line(12,10,first,16),line(12,41,'图片宽度：    '..(image_width>0 and tostring(image_width) or '—'),15),line(12,59,'图片高度：    '..(image_height>0 and tostring(image_height) or '—'),15),line(12,77,'修改日期：    '..modified,15)},'\n')
    overlay:update()
end
mp.register_event('file-loaded',function()
    modified='—'
    local path=mp.get_property('path')
    if path then
        -- One file-stat request for the current item, never a media-library scan.
        local info=utils.file_info(path)
        if info and info.mtime then
            local date=os.date('*t',info.mtime)
            modified=weekdays[date.wday]..' '..os.date('%Y/%m/%d %H:%M',info.mtime)
        end
    end
    render()
end)
mp.observe_property('video-params','native',render)
mp.observe_property('width','number',render)
mp.observe_property('height','number',render)
mp.register_event('video-reconfig',render)
mp.observe_property('playlist-pos','number',render)
mp.observe_property('osd-dimensions','native',render)
-- Dimensions can arrive after file-loaded; local property polling does not read the media again.
mp.add_periodic_timer(0.5,render)
render()
