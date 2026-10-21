-- Chinese tablet controls, tap-to-toggle menu, and compact video scrubber. MIT.
local mp=require 'mp'
local utils=require 'mp.utils'
local overlay=mp.create_osd_overlay('ass-events')
local visible=false
local buttons={}
local settings_open=false
local canvas_w,canvas_h=1280,800
local expanded_until=0
local dragging=false
local preview_ratio=0
local drag_was_paused=false
local last_touch=-100
local render
local images={jpg=true,jpeg=true,png=true,webp=true,bmp=true,gif=true,tif=true,tiff=true,avif=true,jxl=true}
local function video_duration()
    local ext=(mp.get_property('filename',''):match('%.([^%.]+)$') or ''):lower()
    if images[ext] then return nil end
    local duration=mp.get_property_number('duration',0)
    if duration>0 and mp.get_property_bool('seekable',false) then return duration end
end
local function rect(x,y,w,h,color,alpha)
    return string.format('{\\an7\\pos(0,0)\\bord0\\shad0\\1c&H%s&\\1a&H%s&\\p1}m %d %d l %d %d %d %d %d %d{\\p0}',color,alpha,x,y,x+w,y,x+w,y+h,x,y+h)
end
local function text(x,y,label,size,align)
    return string.format('{\\an%d\\pos(%d,%d)\\fnMicrosoft YaHei UI\\fs%d\\b0\\bord0\\shad0\\1c&HFFFFFF&\\1a&H00&}%s',align or 5,x,y,size,label)
end
local function circle(x,y,r)
    local points={}
    for i=0,24 do
        local angle=2*math.pi*i/24
        points[#points+1]=string.format('%s %d %d',i==0 and 'm' or 'l',x+math.cos(angle)*r,y+math.sin(angle)*r)
    end
    return '{\\an7\\pos(0,0)\\bord0\\shad0\\1c&HFFFFFF&\\1a&H00&\\p1}'..table.concat(points,' ')..'{\\p0}'
end
local function stamp(seconds)
    seconds=math.max(0,math.floor(seconds or 0))
    if seconds>=3600 then return string.format('%d:%02d:%02d',math.floor(seconds/3600),math.floor(seconds/60)%60,seconds%60) end
    return string.format('%02d:%02d',math.floor(seconds/60),seconds%60)
end
local function show_settings()
    if settings_open then return end
    settings_open=true
    local was_paused=mp.get_property_bool('pause',false)
    mp.set_property_bool('pause',true);render()
    local root=utils.join_path(mp.command_native({'expand-path','~~/'}),'..')
    mp.command_native_async({name='subprocess',args={utils.join_path(root,'ui/AlbumSettings.exe')},playback_only=false,capture_stdout=true,capture_stderr=true},function(success,result,error)
        settings_open=false
        if success and result and result.status==10 then mp.commandv('quit')
        else
            mp.set_property_bool('pause',was_paused)
            if not success or not result or result.status~=0 then
                mp.msg.error('Settings window failed: '..tostring(error)..' '..tostring(result and result.stderr))
                mp.osd_message('设置窗口未能打开，请使用桌面上的新版相册入口。',5)
            end
            render()
        end
    end)
end
local function toggle()visible=not visible;expanded_until=0;render()end
render=function()
    local w,h=mp.get_osd_size()
    if not w or not h or w<=0 or h<=0 then return end
    canvas_w=math.floor(800*w/h);canvas_h=800
    overlay.res_x=canvas_w;overlay.res_y=canvas_h
    buttons={}
    local data={}
    local duration=video_duration()
    local expanded=duration and (dragging or mp.get_time()<expanded_until)
    local function button(x,y,bw,bh,label,action,color)
        buttons[#buttons+1]={x=x,y=y,w=bw,h=bh,action=action}
        data[#data+1]=rect(x,y,bw,bh,color or '553526','18')
        data[#data+1]=text(x+bw/2,y+bh/2,label,25)
    end
    if visible and not expanded then
        local margin,gap=16,10
        local columns=canvas_w<850 and 3 or 6
        local bw=math.floor((canvas_w-2*margin-(columns-1)*gap)/columns)
        local rows=math.ceil(6/columns)
        local top=canvas_h-rows*74-14
        data[#data+1]=rect(0,top-12,canvas_w,canvas_h-top+12,'1C120C','25')
        local entries={
            {'上一项',function()mp.commandv('playlist-prev')end},
            {mp.get_property_bool('pause',false) and '继续播放' or '暂停播放',function()mp.commandv('cycle','pause')end},
            {'下一项',function()mp.commandv('playlist-next')end},
            {settings_open and '设置已打开' or '设置',show_settings},
            {mp.get_property_bool('mute',true) and '打开声音' or '关闭声音',function()mp.commandv('cycle','mute')end},
            {'退出相册',function()mp.commandv('quit')end,'3B365C'}
        }
        for i,entry in ipairs(entries)do
            local col=(i-1)%columns;local row=math.floor((i-1)/columns)
            button(margin+col*(bw+gap),top+row*74,bw,64,entry[1],entry[2],entry[3])
        end
    end
    if duration then
        local ratio=dragging and preview_ratio or math.max(0,math.min(1,mp.get_property_number('time-pos',0)/duration))
        if expanded then
            data[#data+1]=rect(0,696,canvas_w,104,'1C120C','15')
            data[#data+1]=text(34,724,stamp(ratio*duration)..' / '..stamp(duration),20,4)
            data[#data+1]=text(canvas_w-34,724,'拖动圆点调整进度',18,6)
            local left,length=36,canvas_w-72
            data[#data+1]=rect(left,760,length,7,'78695C','00')
            data[#data+1]=rect(left,760,math.floor(length*ratio),7,'FFD047','00')
            data[#data+1]=circle(left+length*ratio,763,13)
        else
            -- Four physical pixels, independent of the virtual overlay scale.
            local thickness=math.max(2,math.floor(4*800/h+0.5))
            data[#data+1]=rect(0,800-thickness,canvas_w,thickness,'665549','35')
            data[#data+1]=rect(0,800-thickness,math.floor(canvas_w*ratio),thickness,'FFD047','00')
        end
    end
    overlay.data=table.concat(data,'\n');overlay:update()
end
local function virtual(x,y)
    local w,h=mp.get_osd_size()
    if not w or not h or w<=0 or h<=0 then return end
    return x*canvas_w/w,y*canvas_h/h
end
local function set_preview(x)
    preview_ratio=math.max(0,math.min(1,(x-36)/(canvas_w-72)))
end
local function pointer_down(rawx,rawy)
    local x,y=virtual(rawx,rawy)
    if not x then return end
    local duration=video_duration()
    local expanded=duration and mp.get_time()<expanded_until
    if duration and y>=(expanded and 696 or 764)then
        if expanded then
            dragging=true;drag_was_paused=mp.get_property_bool('pause',false)
            mp.set_property_bool('pause',true);set_preview(x)
        end
        expanded_until=mp.get_time()+10;render();return
    end
    for _,b in ipairs(buttons)do
        if x>=b.x and x<=b.x+b.w and y>=b.y and y<=b.y+b.h then b.action();render();return end
    end
    toggle()
end
local function pointer_move(rawx,rawy)
    if not dragging then return end
    local x=virtual(rawx,rawy)
    if x then set_preview(x);expanded_until=mp.get_time()+4;render()end
end
local function pointer_up()
    if not dragging then return end
    dragging=false;expanded_until=mp.get_time()+3
    -- Seek once on release, avoiding repeated cloud reads while scrubbing.
    mp.commandv('seek',preview_ratio*100,'absolute-percent+exact')
    mp.set_property_bool('pause',drag_was_paused);render()
end
mp.add_forced_key_binding('MBTN_LEFT','touch-click',function(event)
    if mp.get_time()-last_touch<0.7 then return end
    local pos=mp.get_property_native('mouse-pos')
    if event.event=='down' then
        if pos then pointer_down(pos.x,pos.y)end
    elseif event.event=='up' then
        -- Mouse-move observations may be coalesced during a quick drag.
        -- Read the release position directly so the final location is never lost.
        if pos and dragging then pointer_move(pos.x,pos.y)end
        pointer_up()
    elseif event.event=='press' then
        if pos then pointer_down(pos.x,pos.y);pointer_up()end
    end
end,{complex=true})
mp.observe_property('mouse-pos','native',function(_,pos)
    if dragging and pos and mp.get_time()-last_touch>=0.7 then pointer_move(pos.x,pos.y)end
end)
mp.add_forced_key_binding('mouse_move','seek-pointer-move',function()
    if dragging and mp.get_time()-last_touch>=0.7 then
        local pos=mp.get_property_native('mouse-pos')
        if pos then pointer_move(pos.x,pos.y)end
    end
end)
local active_touch=nil
mp.observe_property('touch-pos','native',function(_,points)
    local point=points and points[1]
    if point then
        last_touch=mp.get_time()
        if active_touch~=point.id then active_touch=point.id;pointer_down(point.x,point.y)
        else pointer_move(point.x,point.y)end
    elseif active_touch then
        last_touch=mp.get_time();active_touch=nil;pointer_up()
    end
end)
mp.add_forced_key_binding('MBTN_LEFT_DBL','touch-double-click',function()end)
mp.add_key_binding(nil,'toggle-toolbar',toggle)
mp.add_key_binding(nil,'settings',show_settings)
mp.observe_property('pause','bool',render)
mp.observe_property('mute','bool',render)
mp.observe_property('playlist-pos','number',render)
mp.observe_property('osd-dimensions','native',render)
mp.observe_property('duration','number',render)
mp.register_event('file-loaded',function()dragging=false;expanded_until=0;render()end)
mp.add_periodic_timer(0.12,function()if video_duration()then render()end end)
render()
