local component = require("component")
local gpu = component.gpu
local lsc = component.gt_machine

 local suffix = {
  {1, ""},
  {1e3, "k"},
  {1e6, "m"},
  {1e9, "B"},
  {1e12, "T"},
  {1e15, "qd"},
  {1e18, "Qn"},
  {1e21, "sx"},
  {1e24, "Sp"},
  {1e27, "O"},
  {1e30, "N"}
 }

local tiers = {"ULV", "LV", "MV", "HV", "EV", "IV", "LuV", "ZPM", "UV", "UHV", "UEV", "UIV", "UMV", "UXV", "MAX"}

function resize(scale)
  local maxW, maxH = gpu.maxResolution()
  gpu.setResolution(maxW * scale, maxH * scale)
end

function clearScreen()
  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
end

function formatNumber(num)
  if num == 0 then
    return "0"
  end

  local sign = ""

  if num < 0 then
    sign = "-"
  end

  local number = math.abs(num)

  for _, b in ipairs(suffix) do
    if b[1] <= math.abs(number + 1) then
      suffix.use = _
    end
  end
  
  local result = string.format("%.1f", number / suffix[suffix.use][1])
  if tonumber(result) >= 1e3 and suffix.use < table.getn(suffix) then
    suffix.use = suffix.use + 1
    result = string.format("%.1f", tonumber(result) / 1e3)
  end

  result = string.sub(result, 0, string.sub(result, -1) == "0" and -3 or -1)
  return sign .. result .. suffix[suffix.use][2]
end

function formatTick(tick)
  local copy = tick
  local hour = copy // 72000
  copy = copy - (hour * 72000)
  local minute = copy // 1200
  copy = copy - (minute * 1200)
  local second = copy // 20

  result = ""
  
  if hour > 0 then
    result = result .. tostring(hour) .. "hour(s)"
  end
  
  if minute > 0 then
    result = result .. tostring(minute) .. "minute(s)"
  end

  if second > 0 then
    result = result .. tostring(second) .."second(s)"
  end
  
  return result
end

function centeredText(y, heading)
  local w, _ = gpu.getResolution()
  local length = string.len(heading)
  local x = (w - length) / 2
  gpu.set(x + 1, y, heading)
end

function getWirelessNetwork()
  local info = lsc.getSensorInformation()
  local wirelessString = string.sub(info[15], 23)
  local removeComma = string.gsub(wirelessString, ",", "")
  return tonumber(removeComma)
end

function formatEUt(eut)
  if eut < 0 then
    return "NaN"
  end

  tier = "NULL"
  amp = -1

  if eut <= 8 then
    tier = "ULV"
    amp = eut / 8
  elseif eut >= 2 ^ 31 then
    tier = "MAX"
    amp = eut / (2 ^ 31)
  else
    for i = 2, #tiers do
      if eut < 2 ^ (2 * i + 1) then
        tier = tiers[i-1]
        amp = eut * 2 / (2 ^ (2 * i))
        break
      end
    end
  end

  return tostring(amp) .. " amp(s) of " .. tostring(tier)
end

local old = getWirelessNetwork()
local update = 1



local w, h = gpu.getResolution()

while true do
  local current = getWirelessNetwork()
  gpu.setForeground(0xFFFFFF)

  clearScreen()
  centeredText(h/2-1, "Wireless Energy Network")
  gpu.set(2, h/2, "Stored amount: " .. tostring(current) .. " EU")
  
  gpu.set(2, h/2+1, "Last update:")

  local net = "+"
  local color = 0x00FF00
  if current < old then
    net = "-"
    color = 0xFF0000
  end

  gpu.setForeground(color)

  local diffPerTick = math.abs(old - current) / (update * 20)
  gpu.set(15, h/2+1, net .. formatEUt(diffPerTick))

  os.sleep(update)
  old = current
end
