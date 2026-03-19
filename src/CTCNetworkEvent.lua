-- =========================================================
-- CTCNetworkEvent.lua -- FS25_CustomTriggerCreator
-- Routes economy addMoney calls from client to server.
-- Only used when the local machine is a client (not the server).
-- =========================================================

CTCNetworkEvent = {}
CTCNetworkEvent_mt = Class(CTCNetworkEvent, Event)
InitEventClass(CTCNetworkEvent, "CTCNetworkEvent")

function CTCNetworkEvent.emptyNew()
    local self = Event.new(CTCNetworkEvent_mt)
    return self
end

---@param farmId  number  Farm to receive/pay the money
---@param amount  number  Positive = farm receives, negative = farm pays
function CTCNetworkEvent.new(farmId, amount)
    local self = CTCNetworkEvent.emptyNew()
    self.farmId = farmId
    self.amount = amount
    return self
end

function CTCNetworkEvent:writeStream(streamId, connection)
    streamWriteInt32(streamId, self.farmId or 0)
    streamWriteInt32(streamId, self.amount  or 0)
end

function CTCNetworkEvent:readStream(streamId, connection)
    self.farmId = streamReadInt32(streamId)
    self.amount  = streamReadInt32(streamId)
    self:run(connection)
end

-- Server-side: apply the money operation
function CTCNetworkEvent:run(connection)
    if not g_currentMission:getIsServer() then return end
    if not self.farmId or self.farmId <= 0 then return end
    g_currentMission:addMoney(self.amount, self.farmId, MoneyType.OTHER, true)
end
