--[[

    Digital Dreams      .Lua [Window Class]
    
    author          :   n0th1ng.
    last update     :   21/06/2024
    version         :   5.0

--]]

-- >>   Constacts    << --

local NONE      = nil
local INVALID   = -1
local FONT_NAME = "Arial"
local WHITE     = color(255)

-- >    Window Class    < --

local windows       = {}
local window_mt    = {}


windows.active_windows  = new.queue()

windows.NO_ATTACH       = 1
windows.CENTER_ATTACH   = 2

windows.mouse_position          = ui.get_mouse_position()
windows.active_mouse_position   = ui.get_mouse_position()

windows.is_left_pressed         = false
windows.is_right_pressed        = false

windows.is_holding              = NONE

windows.find = function(name)
    local pos = windows.active_windows.first
    while pos ~= NONE do
        current_window = pos:get_value()

        if current_window._name == name then
            return current_window
        end

        pos = pos:get_next()
    end

    return NONE
end

windows.process = function()
    -- General things
    windows.active_mouse_position = ui.get_mouse_position()
    windows.is_left_pressed = common.is_button_down(1)
    windows.is_right_pressed = common.is_button_down(2)

    if not windows.is_left_pressed then
        windows.mouse_position  = ui.get_mouse_position()
    end

    -- Is anything moving
    local pos = windows.active_windows.first

    while pos ~= NONE do
        current_window = pos:get_value()

        if current_window and current_window._is_moving then
            --return current_window
            windows.is_holding = current_window
            return
        end

        pos = pos:get_next()
    end

    windows.is_holding = NONE
end

windows.is_anything_moving = function()
    return windows.is_holding ~= NONE
end

window_mt.__index = window_mt

new.window = function(name, position, size, should_attach)
    local new_window = {}
    setmetatable(new_window, window_mt)

    new_window._name        = name
    new_window._position    = position
    new_window._size        = size

    new_window._fade        = 0

    new_window._is_moving   = false
    new_window._move_delta  = vector(0, 0)
    new_window._attach      = should_attach or windows.NO_ATTACH
    new_window._is_attach   = false

    new_window._render_calls  = {}

    windows.active_windows:insert(new_window)

    return new_window
end

function window_mt:set_position(new_position)
    self._position = new_position
end

function window_mt:set_size(new_size)
    self._size = new_size
end

function window_mt:set_fade(new_fade)
    self._fade = new_fade
end

function window_mt:get_position()   return self._position end
function window_mt:get_size()       return self._size end
function window_mt:get_fade()       return self._fade end
function window_mt:get_name()       return self._name end
function window_mt:is_used()        return self._is_using end
function window_mt:is_moving()      return self._is_moving end

function window_mt:register(index, value)
    self[index] = value
end

function window_mt.__call(current, index)
    return current[index]
end

function window_mt.__eq(current, new)
    if type(new) == "string" then
        return current._name == new
    end

    return current._name == new._name
end

function window_mt:delete()
    local temp = new.queue()

    while not windows.active_windows:is_empty() do
        local wnd = windows.active_windows:remove()

        if wnd:get_name() ~= self:get_name() then
            temp:insert(wnd)
        end
    end

    while not temp:is_empty() do
        windows.active_windows:insert(temp:remove())
    end

    for index in pairs(self._render_calls) do
        events["render"]:unset(self._render_calls[index])
    end
end
    
function window_mt:unregisrer_render(index)
    -- MAYBE ! ADD CHECK IF INDEX VALUD
    events["render"]:unset(self._render_calls[index])
end

function window_mt:fade(new_value)
    self._fade = render.do_animation(self._fade, new_value)
end

function window_mt:register_render(callback, index)
    local protected_method = hooks.protected_call(function() callback(self) end, index)

    events["render"]:set(protected_method)
    self._render_calls[index] = protected_method
end

function window_mt:override_position(size)

    if self._fade ~= 1 then
        return
    end

    if windows.mouse_position:is_in_bounds(self._position, size) and windows.is_left_pressed and not windows.is_anything_moving() and not gui.use_element then
        self._is_moving = true
        self._move_delta.x = self._position.x - windows.active_mouse_position.x
        self._move_delta.y = self._position.y - windows.active_mouse_position.y
    end

    if not windows.is_left_pressed and self._is_moving then
        --ctx._is_focus = false
        self._is_moving = false
    end

    if self._is_moving then
        self._position.x = math.floor(self._move_delta.x + windows.active_mouse_position.x)

        if not utils.is_virtual_key_pressed(0x10) then
            self._position.y = math.floor(self._move_delta.y + windows.active_mouse_position.y)
        end
    end

    if self._attach == windows.CENTER_ATTACH then
        local delta = math.abs(theme.screen_size.x / 2 - (self._position.x + size.x / 2))
        if delta < 50 then
            self._position.x = theme.screen_size.x / 2 - size.x / 2
            self._is_attach = true
        else
            self._is_attach = false
        end
    end
end
