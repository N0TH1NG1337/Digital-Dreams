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

local windows = {}
windows.contain_windows = {}

local window = {}
window.__index = window

windows.create_new = function(name, position, size)
    local ptr = {}
    setmetatable(ptr, window)

    ptr._name       = name
    ptr._position   = position
    ptr._size       = size
    ptr._fade       = 0 -- Current Alpha
    ptr._is_focus   = false

    ptr._data = {}

    ptr._events = {
        ["render"] = {},
        ["on_focus"] = {}
    }

    windows.contain_windows[#windows.contain_windows + 1] = ptr

    return ptr
end

function window:set_position(new_position)    self._position = new_position   end
function window:set_size(new_size)            self._size = new_size           end

function window:set_focus(new_focus)
    self._is_focus = new_focus

    for index in ipairs(self._events["on_focus"]) do
        assert(self._events["on_focus"][index], "Failed to index on_focus event")

        self._events["on_focus"][index](new_focus)
    end
end

function window:get_position()  return self._position   end
function window:get_size()      return self._size       end
function window:get_fade()      return self._fade       end
function window:get_focus()     return self._is_focus   end

function window:attach_data()
    --
end

function window:attach_callback(event, callback_fn)
    if not self._events[event] then
        error("Invalid window event")
    end

    local h_event = self._events[event]
    h_event[#h_event + 1] = callback_fn

end

function window:get_draw()
    return function()
        for index = 1, #self._events["render"] do
            self._events["render"][index](self)
        end
    end
end
