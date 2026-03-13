-- =========================================================
-- Logger.lua — FS25_CustomTriggerCreator
-- Prefixed log utility. All mod output tagged [CTC].
-- =========================================================

Logger = {}
Logger._mt = { __index = Logger }

-- Anchor to _G so the table survives any environment/scope quirks
-- that can occur when FS25 fires lifecycle hooks (onLoad, update, etc.)
-- after the initial source() pass has completed.
_G["Logger"] = Logger

local PREFIX = "[CTC]"
local debugEnabled = false

---Enable or disable debug-level output.
---@param enabled boolean
function Logger.setDebug(enabled)
    debugEnabled = enabled
end

---Log an info message.
---@param msg string
function Logger.info(msg)
    print(PREFIX .. " " .. tostring(msg))
end

---Log a warning message.
---@param msg string
function Logger.warn(msg)
    print(PREFIX .. " [WARN] " .. tostring(msg))
end

---Log an error message.
---@param msg string
function Logger.error(msg)
    print(PREFIX .. " [ERROR] " .. tostring(msg))
end

---Log a debug message (only printed when debug mode is on).
---@param msg string
function Logger.debug(msg)
    if debugEnabled then
        print(PREFIX .. " [DEBUG] " .. tostring(msg))
    end
end

---Format and log a message with a module tag.
---@param module string  Short module name, e.g. "MarkerDetector"
---@param msg    string
function Logger.module(module, msg)
    print(PREFIX .. " [" .. tostring(module) .. "] " .. tostring(msg))
end

-- ---------------------------------------------------------------------------
-- Nil-safety: if any code calls Logger before it is sourced (e.g. during a
-- hot-reload or mod conflict), provide a silent fallback so the game doesn't
-- crash with "attempt to index nil with 'info'".
-- ---------------------------------------------------------------------------
local _safeLogger = {
    info   = function(m) pcall(print, "[CTC][SAFE] " .. tostring(m)) end,
    warn   = function(m) pcall(print, "[CTC][SAFE][WARN] " .. tostring(m)) end,
    error  = function(m) pcall(print, "[CTC][SAFE][ERROR] " .. tostring(m)) end,
    debug  = function() end,
    module = function(mod, m) pcall(print, "[CTC][SAFE][" .. tostring(mod) .. "] " .. tostring(m)) end,
    setDebug = function() end,
}

---Return Logger if available, otherwise the silent fallback.
---Usage: local L = Logger.get(); L.info("msg")
function Logger.get()
    return _G["Logger"] or _safeLogger
end
