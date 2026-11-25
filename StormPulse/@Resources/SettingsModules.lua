-- SettingsModules.lua (cp1252): renderiza las 6 filas en la pestana Modulos

local LABELS = {
  CPU     = "CPU  ·  Procesador",
  GPU     = "GPU  ·  Gráfica",
  RAM     = "RAM  ·  Memoria",
  NET     = "NET  ·  Red",
  DISK    = "DISK ·  Disco",
  WEATHER = "CLIMA · Ciudad",
}

local ALL = {"CPU", "GPU", "RAM", "NET", "DISK", "WEATHER"}

function Initialize()
  SyncRows()
end

function Update()
  return 0
end

function SyncRows()
  local orderStr = SKIN:GetVariable("ModOrder") or "CPU,GPU,RAM,NET,DISK,WEATHER"
  local order = {}
  local seen = {}
  for token in string.gmatch(orderStr, "[^,]+") do
    local k = token:match("^%s*(.-)%s*$"):upper()
    if LABELS[k] and not seen[k] then
      table.insert(order, k)
      seen[k] = true
    end
  end
  for _, k in ipairs(ALL) do
    if not seen[k] then
      table.insert(order, k)
      seen[k] = true
    end
  end

  for i = 0, 5 do
    local mod = order[i + 1]
    local show = tonumber(SKIN:GetVariable("Show" .. mod)) or 1
    local col  = SKIN:GetVariable("C" .. mod) or "64,230,245"

    SKIN:Bang("!SetOption", "MeterRowLabel" .. i, "Text", LABELS[mod])
    if show == 1 then
      SKIN:Bang("!SetOption", "MeterRowLabel" .. i, "FontColor", "#UIFG#")
      SKIN:Bang("!SetOption", "MeterRowDot" .. i, "Shape", "Rectangle 0,0,4,18,2 | Fill Color " .. col .. " | StrokeWidth 0")
      SKIN:Bang("!SetOption", "MeterRowToggle" .. i, "Text", "ON")
      SKIN:Bang("!SetOption", "MeterRowToggle" .. i, "FontColor", "64,230,245")
    else
      SKIN:Bang("!SetOption", "MeterRowLabel" .. i, "FontColor", "160,185,200,90")
      SKIN:Bang("!SetOption", "MeterRowDot" .. i, "Shape", "Rectangle 0,0,4,18,2 | Fill Color 140,160,175,65 | StrokeWidth 0")
      SKIN:Bang("!SetOption", "MeterRowToggle" .. i, "Text", "OFF")
      SKIN:Bang("!SetOption", "MeterRowToggle" .. i, "FontColor", "160,185,200,95")
    end

    SKIN:Bang("!SetOption", "MeterRowUp" .. i, "FontColor", i == 0 and "160,185,200,40" or "#UIText2#")
    SKIN:Bang("!SetOption", "MeterRowDown" .. i, "FontColor", i == 5 and "160,185,200,40" or "#UIText2#")
  end

  SKIN:Bang("!UpdateMeterGroup", "Tab0")
  SKIN:Bang("!Redraw")
end
