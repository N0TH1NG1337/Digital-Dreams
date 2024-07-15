
ffi.cdef[[
    typedef void*       HANDLE;
    typedef uint32_t    WPARAM;
    typedef uint32_t    DWORD;
    typedef int64_t     LPARAM;
    typedef int64_t     LRESULT;
    typedef HANDLE      HINSTANCE;
    typedef HANDLE      HHOOK;
    typedef int         BOOL;


    // use for access data inside the hook.
    typedef struct {
        DWORD vkCode;
        DWORD scanCode;
        DWORD flags;
        DWORD time;
        DWORD dwExtraInfo;
    } keybaord_low_level_hook_t; //KBDLLHOOKSTRUCT;


    // https://learn.microsoft.com/en-us/previous-versions/windows/desktop/legacy/ms644985(v=vs.85)
    // https://learn.microsoft.com/he-il/windows/win32/api/winuser/nf-winuser-setwindowshookexa?redirectedfrom=MSDN

    typedef LRESULT (__stdcall *HOOKPROC)(int code, WPARAM wParam, LPARAM lParam);
    HINSTANCE       GetModuleHandleA(const char* lpModuleName);
    HHOOK           SetWindowsHookExA(int idHook, void* lpfn, HINSTANCE hmod, DWORD dwThreadId);
    LRESULT         CallNextHookEx(HHOOK hhk, int nCode, WPARAM wParam, LPARAM lParam);
    BOOL            UnhookWindowsHookEx(HHOOK hhk);
    DWORD           GetLastError();
]]

local hooks do
    hooks = {}

    hooks.low_level_keyboard_event  = {}    -- used : save low level keyboad event functions
    hooks.keyboard_handle           = NONE  -- used : keyboard hook handle

    local low_level_keyboard_hook = function(n_code, w_param, l_param)

        if n_code >= 0 then
            
            for index = 1, #hooks.low_level_keyboard_event do
                fn = hooks.low_level_keyboard_event[index]

                if fn then
                    local ret = fn(n_code, w_param, l_param)
                    if ret == true then
                        return 1
                    end
                end
                
            end
        end

        return ffi.C.CallNextHookEx(NONE, n_code, w_param, l_param)
    end

    hooks.attach = function(event, callback, index)
        if event == "low_level_keyboard" then
            hooks.low_level_keyboard_event[#hooks.low_level_keyboard_event + 1] = protected_call(callback, index)
            return
        end

        events[event]:set(protected_call(callback, index))
    end

    hooks.destroy = function()
        if hooks.keyboard_handle then
            ffi.C.UnhookWindowsHookEx(hooks.keyboard_handle)
        end
    end

    hooks.initialize = function()

        local module_handle = ffi.C.GetModuleHandleA(NONE)

        if not ffi.istype("void*", module_handle) then 
            hooks.keyboard_handle = NONE

            return false
        end

        -- Low level keyboard hook : index 13, main thread
        hooks.keyboard_handle = ffi.C.SetWindowsHookExA(13, ffi.cast("HOOKPROC", low_level_keyboard_hook), module_handle, 0)

        hooks.attach("shutdown", hooks.destroy, "lua::hooks::destroy")

        return true
    end
end
