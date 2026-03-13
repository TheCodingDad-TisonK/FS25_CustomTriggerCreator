-- =========================================================
-- Logger.lua — FS25_CustomTriggerCreator
-- Prefixed log utility. All mod output tagged [CTC].
-- =========================================================

Logger = {}
Logger._mt = { __index = Logger }

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
