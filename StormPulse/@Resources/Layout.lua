-- Layout.lua: posiciona dinamicamente los modulos visibles y el pronostico del clima

local MODS = {
  CPU = {
    card = "MeterCPUCard",
    meters = {
      { name = "MeterCPUTitle", dy = 18 },
      { name = "MeterCPUSub",   dy = 18 },
      { name = "MeterCPUValue", dy = 53 },
      { name = "MeterCPUUnit",  dy = 48 },
      { name = "MeterCPUArea",  dy = 28 },
      { name = "MeterCPUGraph", dy = 28 },
    }
  },
  GPU = {
    card = "MeterGPUCard",
    meters = {
      { name = "MeterGPUTitle",     dy = 18 },
      { name = "MeterGPUSub",       dy = 18 },
      { name = "MeterGPUSubNoTemp", dy = 18 },
      { name = "MeterGPUValue",     dy = 53 },
      { name = "MeterGPUUnit",      dy = 48 },
      { name = "MeterGPUArea",      dy = 28 },
      { name = "MeterGPUGraph",     dy = 28 },
    }
  },
  RAM = {
    card = "MeterRAMCard",
    meters = {
      { name = "MeterRAMTitle", dy = 18 },
      { name = "MeterRAMSub",   dy = 18 },
      { name = "MeterRAMValue", dy = 53 },
      { name = "MeterRAMUnit",  dy = 48 },
      { name = "MeterRAMArea",  dy = 28 },
      { name = "MeterRAMGraph", dy = 28 },
    }
  },
  NET = {
    card = "MeterNETCard",
    meters = {
      { name = "MeterNETTitle",  dy = 18 },
      { name = "MeterNETSub",    dy = 18 },
      { name = "MeterNETAIcon",  dy = 34 },
      { name = "MeterNETAValue", dy = 34 },
      { name = "MeterNETAUnit",  dy = 34 },
      { name = "MeterNETBIcon",  dy = 49 },
      { name = "MeterNETBValue", dy = 49 },
      { name = "MeterNETBUnit",  dy = 49 },
      { name = "MeterNETGraph",  dy = 28 },
    }
  },
  DISK = {
    card = "MeterDISKCard",
    meters = {
      { name = "MeterDISKTitle",  dy = 18 },
      { name = "MeterDISKSub",    dy = 18 },
      { name = "MeterDISKAIcon",  dy = 34 },
      { name = "MeterDISKAValue", dy = 34 },
      { name = "MeterDISKAUnit",  dy = 34 },
      { name = "MeterDISKBIcon",  dy = 49 },
      { name = "MeterDISKBValue", dy = 49 },
      { name = "MeterDISKBUnit",  dy = 49 },
      { name = "MeterDISKGraph",  dy = 28 },
    }
  },
  WEATHER = {
    card = "MeterWEATHERCard",
    meters = {
      { name = "MeterWEATHERTitle",   dy = 18 },
      { name = "MeterWEATHERSub",     dy = 18 },
      { name = "MeterWEATHERValue",   dy = 53 },
      { name = "MeterWEATHERUnit",    dy = 48 },
      { name = "MeterWEATHERCond",    dy = 35 },
      { name = "MeterWEATHERDetails", dy = 49 },
    }
  }
}

function Initialize()
  ApplyLayout()
end

function Update()
  return 0
end

function ApplyLayout()
  local scale = tonumber(SKIN:GetVariable("Scale")) or 1
  local padX  = tonumber(SKIN:GetVariable("PadX")) or 0
  local padY  = tonumber(SKIN:GetVariable("PadY")) or 0
  local orderStr = SKIN:GetVariable("ModOrder") or "CPU,GPU,RAM,NET,DISK,WEATHER"

  local wMode  = tonumber(SKIN:GetVariable("WeatherMode")) or 0
  local wHours = tonumber(SKIN:GetVariable("WeatherHours")) or 6
  local wDays  = tonumber(SKIN:GetVariable("WeatherDays")) or 5
  local wRows  = 0
  if wMode == 1 then wRows = math.min(math.max(wHours, 1), 10)
  elseif wMode == 2 then wRows = math.min(math.max(wDays, 1), 10) end
  local wExtraH = (wRows > 0) and (wRows * 15 + 10) or 0

  local order = {}
  local seen = {}
  for token in string.gmatch(orderStr, "[^,]+") do
    local k = token:match("^%s*(.-)%s*$"):upper()
    if MODS[k] and not seen[k] then
      table.insert(order, k)
      seen[k] = true
    end
  end
  for _, k in ipairs({"CPU", "GPU", "RAM", "NET", "DISK", "WEATHER"}) do
    if not seen[k] then
      table.insert(order, k)
      seen[k] = true
    end
  end

  local visible = {}
  for _, mod in ipairs(order) do
    local show = tonumber(SKIN:GetVariable("Show" .. mod)) or 1
    if show == 1 then
      table.insert(visible, mod)
    else
      SKIN:Bang("!HideMeterGroup", "Mod" .. mod)
    end
  end

  -- Always hide forecast rows first; re-show only needed ones if WEATHER is visible
  for r = 0, 9 do
    SKIN:Bang("!HideMeter", "MeterWF" .. r .. "L")
    SKIN:Bang("!HideMeter", "MeterWF" .. r .. "M")
    SKIN:Bang("!HideMeter", "MeterWF" .. r .. "R")
  end

  local curY = 40
  for idx, mod in ipairs(visible) do
    local shapeName = "Shape" .. tostring(idx + 1)
    local dy = curY * scale
    local lineDef = string.format("Line %.1f,%.1f,%.1f,%.1f | StrokeWidth 1 | Stroke LinearGradient Div",
      14 * scale, dy, 226 * scale, dy)
    SKIN:Bang("!SetOption", "MeterCard", shapeName, lineDef)

    local info = MODS[mod]
    SKIN:Bang("!ShowMeterGroup", "Mod" .. mod)
    if mod == "GPU" then
      local st = tonumber(SKIN:GetVariable("ShowTemps")) or 1
      if st == 1 then
        SKIN:Bang("!ShowMeter", "MeterGPUSub")
        SKIN:Bang("!HideMeter", "MeterGPUSubNoTemp")
      else
        SKIN:Bang("!HideMeter", "MeterGPUSub")
        SKIN:Bang("!ShowMeter", "MeterGPUSubNoTemp")
      end
    end
    SKIN:Bang("!SetOption", info.card, "Y", tostring(padY + curY * scale))
    for _, m in ipairs(info.meters) do
      SKIN:Bang("!SetOption", m.name, "Y", tostring(padY + (curY + m.dy) * scale))
    end

    if mod == "WEATHER" then
      local barH = (34 + wExtraH) * scale
      local barShape = string.format(
        "Rectangle %.1f,%.1f,%.1f,%.1f,%.1f | Fill Color #CWEATHER# | StrokeWidth 0",
        14 * scale, 13 * scale, 3 * scale, barH, 1.5 * scale
      )
      SKIN:Bang("!SetOption", "MeterWEATHERCard", "Shape", barShape)

      if wRows > 0 then
        local prefix = (wMode == 1) and "WH" or "WD"
        for r = 0, wRows - 1 do
          local ry = padY + (curY + 64 + r * 15) * scale
          local vL = SKIN:GetVariable(prefix .. r .. "L") or ""
          local vM = SKIN:GetVariable(prefix .. r .. "M") or ""
          local vR = SKIN:GetVariable(prefix .. r .. "R") or ""
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "L", "Y", tostring(ry))
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "M", "Y", tostring(ry))
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "R", "Y", tostring(ry))
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "L", "Text", vL)
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "M", "Text", vM)
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "R", "Text", vR)
          SKIN:Bang("!ShowMeter", "MeterWF" .. r .. "L")
          SKIN:Bang("!ShowMeter", "MeterWF" .. r .. "M")
          SKIN:Bang("!ShowMeter", "MeterWF" .. r .. "R")
        end
      end
      curY = curY + 60 + wExtraH
    else
      curY = curY + 60
    end
  end

  -- Hide unused dividers
  for idx = #visible + 1, 6 do
    SKIN:Bang("!SetOption", "MeterCard", "Shape" .. tostring(idx + 1),
      "Rectangle 0,0,0,0 | Fill Color 0,0,0,0 | StrokeWidth 0")
  end

  SKIN:Bang("!UpdateMeter", "*")
  SKIN:Bang("!Redraw")
end
