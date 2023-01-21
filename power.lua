-- This script is custom-made to monitor the power storage in a GregTech Lapotronic Supercapacitor on GregTech: New Horizons v2.2.8
-- Author: Bright (aka ItzMeBright)

local component = require("component")
local gpu = component.gpu
local lsc = component.gt_machine

function resize(scale)
  local maxW, maxH = gpu.maxResolution()
  gpu.setResolution(maxW * scale, maxH * scale)
end

function clearScreen()
  local w, h = gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
end

function centeredText(y, heading)
  local w, _ = gpu.getResolution()
  local length = string.len(heading)
  local x = (w - length) / 2
  gpu.set(x + 1, y, heading)
end

function showStats(y)
  local w, _ = gpu.getResolution()
  local filled = getFillPercentage()

  gpu.fill(2, y, w - 4, 1, "-")
  gpu.fill(2, y + 4, w - 4, 1, "-")
  gpu.fill(3, y + 1, w - 6, 3, " ")

  for i = 1, 3 do
    gpu.set(2, y + i, "|")
    gpu.setBackground(0x0000FF)
    gpu.fill(3, y + i, (w - 6) * filled, 1, " ")
    gpu.setBackground(0x000000)
    gpu.set(w - 3, y + i, "|")
  end
  
  centeredText(y + 2, string.format("%.1f", filled * 100) .. "% Filled")

  local input = lsc.getAverageElectricInput()
  local output = lsc.getAverageElectricOutput()
  local info = lsc.getSensorInformation()

  local storedString = string.sub(info[2], 16)
  local storedStripEU = string.gsub(storedString, "EU", "")
  local storedStripComma = string.gsub(storedStripEU, ",", "")
  local stored = tonumber(storedStripComma)

  local maxString = string.sub(info[3], 17)
  local maxStripEU = string.gsub(maxString, "EU", "")
  local maxStripComma = string.gsub(maxStripEU, ",", "")
  local max = tonumber(maxStripComma)


  local remain = max - stored
  if(lsc.getStoredEU() > 0) then
    output = output + getPassiveLoss()
  end
  local net = input - output

  gpu.fill(17, y + 5, w, 1, " ")
  gpu.set(2, y + 5, "Capacity (EU): " .. formatNumber(stored) .. "/" .. formatNumber(max))

  gpu.fill(18, y + 6, w, 1, " ")
  gpu.set(2, y + 6, "Input (EU/t): " .. formatNumber(input))

  gpu.fill(19, y + 7, w, 1, " ")
  gpu.set(2, y + 7, "Output (EU/t): " .. formatNumber(output))

  gpu.fill(15, y + 8, w, 1, " ")
  gpu.set(2, y + 8, "Net (EU/t): ")
  
  local color = 0xFF0000
  local sign = ""
  if(net > 0) then
    color = 0x00FF00
    sign = "+"
  end

  gpu.setForeground(color)
  gpu.set(15, y + 8, sign .. formatNumber(net))
  gpu.setForeground(0xFFFFFF)

  gpu.fill(7, y + 9, w, 1, " ")
  gpu.set(2, y + 9, "ETA: ")
  
  local etaString = "NO INPUT"
  color = 0xFF0000

  if (net > 0) then
    color = 0x00FF00
    etaString = formatTick(remain // net)
  elseif (net < 0) then
    etaString = formatTick(-stored // net)
  end

  gpu.setBackground(color)
  gpu.set(7, y + 9, etaString)
  gpu.setBackground(0x000000)

  gpu.fill(24, y + 10, w, 1, " ")
  gpu.set(2, y + 10, "Total Wireless EU: ")

  local wirelessString = string.sub(info[12], 23)
  local removeComma = string.gsub(wirelessString, ",", "")
  gpu.set(23, y + 10, formatNumber(tonumber(removeComma)))
end

function getFillPercentage()
  return lsc.getStoredEU() / lsc.getEUMaxStored()
end

function getPassiveLoss()
  local passiveLossString = lsc.getSensorInformation()[4]
  local trim1, _ = string.gsub(passiveLossString, "Passive Loss: ", "")
  local trim2, _ = string.gsub(trim1, "EU/t", "")
  return tonumber(trim2)
end 

function formatNumber(num)
  if number == 0 then
    return "0"
  end

  local sign = ""

  if num < 0 then
    sign = "-"
  end

  local number = math.abs(num)

  local suffix = {
    {1, ""},
    {1e3, "k"},
    {1e6, "m"},
    {1e9, "g"},
    {1e12, "t"},
    {1e15, "p"},
    {1e18, "e"},
    {1e21, "z"}
  }

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

resize(1/4)
clearScreen()
centeredText(1, "Lapotronic Supercapacitor")

while true do
  showStats(2)
  os.sleep(0.25)
end
