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
    if mod == "CPU" then
      local st = tonumber(SKIN:GetVariable("ShowTemps")) or 1
      if st == 1 then SKIN:Bang("!ShowMeter", "MeterCPUSub")
      else SKIN:Bang("!HideMeter", "MeterCPUSub") end
    end
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
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "L", "Y", tostring(ry))
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "M", "Y", tostring(ry))
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "R", "Y", tostring(ry))
          -- Pass Rainmeter variable references (#WD0M#) so Rainmeter expands UTF-16 icons directly!
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "L", "Text", "#" .. prefix .. r .. "L#")
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "M", "Text", "#" .. prefix .. r .. "M#")
          SKIN:Bang("!SetOption", "MeterWF" .. r .. "R", "Text", "#" .. prefix .. r .. "R#")
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

  local cardH = curY + 6
  local wPx = 240 * scale
  local hPx = cardH * scale
  local rad = tonumber(SKIN:GetVariable("Radius")) or 8

  -- Size MeterBg & MeterCard cleanly once (no DynamicVariables needed!)
  SKIN:Bang("!SetOption", "MeterBg", "Shape",
    string.format("Rectangle 0,0,%.1f,%.1f,%d | Fill LinearGradient CardGrad | StrokeWidth 0", wPx, hPx, rad))
  SKIN:Bang("!SetOption", "MeterBg", "Shape2",
    string.format("Rectangle 0,0,%.1f,%.1f,%d | Fill RadialGradient Glow1 | StrokeWidth 0", wPx, hPx, rad))
  SKIN:Bang("!SetOption", "MeterBg", "Glow1",
    string.format("%.1f,%.1f | 0,0 | %.1f,%.1f | #CCPU#,#GlowA# ; 0.0 | #CCPU#,(#GlowA#*0.32) ; 0.42 | #CCPU#,0 ; 0.88 | #CCPU#,0 ; 1.0",
      wPx * 0.36, hPx * -0.42, 210 * scale, 210 * scale))
  SKIN:Bang("!SetOption", "MeterBg", "Shape3",
    string.format("Rectangle 0,0,%.1f,%.1f,%d | Fill RadialGradient Glow2 | StrokeWidth 0", wPx, hPx, rad))
  SKIN:Bang("!SetOption", "MeterBg", "Glow2",
    string.format("%.1f,%.1f | 0,0 | %.1f,%.1f | #CGPU#,#GlowA# ; 0.0 | #CGPU#,(#GlowA#*0.32) ; 0.42 | #CGPU#,0 ; 0.88 | #CGPU#,0 ; 1.0",
      wPx * -0.40, hPx * 0.44, 230 * scale, 230 * scale))
  SKIN:Bang("!SetOption", "MeterBg", "Shape4",
    string.format("Rectangle 1,1,%.1f,%.1f,%d | Fill LinearGradient Sheen | StrokeWidth 0", wPx - 2, hPx - 2, rad))
  SKIN:Bang("!SetOption", "MeterCard", "Shape",
    string.format("Rectangle 0.5,0.5,%.1f,%.1f,%d | Fill Color 0,0,0,0 | StrokeWidth 1 | Stroke LinearGradient BorderGrad", wPx - 1, hPx - 1, rad))
  SKIN:Bang("!SetOption", "MeterBottomSpacer", "Y", tostring(math.floor(padY * 2 + hPx - 1)))

  SKIN:Bang("!UpdateMeter", "*")
  SKIN:Bang("!Redraw")
end

-- ApplyLive(): aplica cambios visuales (temas, colores, opacidad, brillo, borde, grilla, relleno, fuentes)
-- SIN hacer !Refresh, conservando 100% del historial de los graficos!
function ApplyLive()
  local bgTop   = SKIN:GetVariable("BgTopRGB") or "13,22,30"
  local bgBot   = SKIN:GetVariable("BgBotRGB") or "7,13,19"
  local bgAlpha = SKIN:GetVariable("BgAlpha") or "185"
  local glowA   = tonumber(SKIN:GetVariable("GlowA")) or 42
  local cCPU    = SKIN:GetVariable("CCPU") or "64,230,245"
  local cGPU    = SKIN:GetVariable("CGPU") or "242,92,212"
  local cRAM    = SKIN:GetVariable("CRAM") or "238,190,98"
  local cNET    = SKIN:GetVariable("CNET") or "120,202,226"
  local cDISK   = SKIN:GetVariable("CDISK") or "118,204,136"
  local cWEATH  = SKIN:GetVariable("CWEATHER") or "189,156,236"
  local areaA   = SKIN:GetVariable("AreaAlpha") or "54"
  local bTop    = SKIN:GetVariable("BorderTop") or (cCPU .. ",62")
  local bMid    = SKIN:GetVariable("BorderMid") or "180,215,235,22"
  local bBot    = SKIN:GetVariable("BorderBot") or (cGPU .. ",52")
  local gMaj    = SKIN:GetVariable("GridMajor") or "170,215,235,24"
  local gMin    = SKIN:GetVariable("GridMinor") or "170,215,235,12"
  local gBase   = SKIN:GetVariable("GridBase") or "170,215,235,46"
  local fg      = SKIN:GetVariable("FG") or "236,244,248"
  local dim     = SKIN:GetVariable("Dim") or "190,215,230,165"
  local faint   = SKIN:GetVariable("Faint") or "170,202,220,105"
  local second  = SKIN:GetVariable("Second") or "175,205,225,155"
  local scale   = tonumber(SKIN:GetVariable("Scale")) or 1
  local rad     = tonumber(SKIN:GetVariable("Radius")) or 8

  -- Resolve nested #CCPU# / #CGPU# inside BorderTop/BorderBot
  bTop = bTop:gsub("#CCPU#", cCPU):gsub("#CGPU#", cGPU)
  bBot = bBot:gsub("#CCPU#", cCPU):gsub("#CGPU#", cGPU)

  -- Background gradients & glow
  SKIN:Bang("!SetOption", "MeterBg", "CardGrad", string.format("90 | %s,%s ; 0.0 | %s,%s ; 1.0", bgTop, bgAlpha, bgBot, bgAlpha))
  SKIN:Bang("!SetOption", "MeterCard", "BorderGrad", string.format("135 | %s ; 0.0 | %s ; 0.5 | %s ; 1.0", bTop, bMid, bBot))

  -- Module graph colors & fill (preserves graph history!)
  SKIN:Bang("!SetOption", "MeterCPUArea",  "PrimaryColor", cCPU .. "," .. areaA)
  SKIN:Bang("!SetOption", "MeterCPUGraph", "LineColor",    cCPU)
  SKIN:Bang("!SetOption", "MeterGPUArea",  "PrimaryColor", cGPU .. "," .. areaA)
  SKIN:Bang("!SetOption", "MeterGPUGraph", "LineColor",    cGPU)
  SKIN:Bang("!SetOption", "MeterRAMArea",  "PrimaryColor", cRAM .. "," .. areaA)
  SKIN:Bang("!SetOption", "MeterRAMGraph", "LineColor",    cRAM)
  SKIN:Bang("!SetOption", "MeterNETAIcon", "FontColor",    cNET)
  SKIN:Bang("!SetOption", "MeterNETBIcon", "FontColor",    second)
  SKIN:Bang("!SetOption", "MeterNETGraph", "LineColor",    cNET)
  SKIN:Bang("!SetOption", "MeterNETGraph", "LineColor2",   second)
  SKIN:Bang("!SetOption", "MeterDISKAIcon","FontColor",    cDISK)
  SKIN:Bang("!SetOption", "MeterDISKBIcon","FontColor",    second)
  SKIN:Bang("!SetOption", "MeterDISKGraph","LineColor",    cDISK)
  SKIN:Bang("!SetOption", "MeterDISKGraph","LineColor2",   second)

  -- Accent bars & grids for the 5 graph modules
  local gMods = {
    { card = "MeterCPUCard",  col = cCPU,  gx = 104, gw = 122 },
    { card = "MeterGPUCard",  col = cGPU,  gx = 104, gw = 122 },
    { card = "MeterRAMCard",  col = cRAM,  gx = 104, gw = 122 },
    { card = "MeterNETCard",  col = cNET,  gx = 132, gw = 94  },
    { card = "MeterDISKCard", col = cDISK, gx = 132, gw = 94  },
  }
  local hYs = {28.0, 33.5, 39.0, 44.5, 50.0}
  for _, gm in ipairs(gMods) do
    SKIN:Bang("!SetOption", gm.card, "Shape",
      string.format("Rectangle %.1f,%.1f,%.1f,%.1f,%.1f | Fill Color %s | StrokeWidth 0",
        14*scale, 13*scale, 3*scale, 34*scale, 1.5*scale, gm.col))
    local sIdx = 2
    for hi, hy in ipairs(hYs) do
      if hi == 1 or hi == 5 then
        SKIN:Bang("!SetOption", gm.card, "Shape" .. sIdx,
          string.format("Line %.1f,%.1f,%.1f,%.1f | StrokeWidth 1 | Stroke Color %s",
            gm.gx*scale, hy*scale, (gm.gx+gm.gw)*scale, hy*scale, gMaj))
      else
        SKIN:Bang("!SetOption", gm.card, "Shape" .. sIdx,
          string.format("Line %.1f,%.1f,%.1f,%.1f | StrokeWidth 1 | Stroke Color %s | StrokeDashes 1,2",
            gm.gx*scale, hy*scale, (gm.gx+gm.gw)*scale, hy*scale, gMin))
      end
      sIdx = sIdx + 1
    end
    for ci = 0, 6 do
      local vx = gm.gx + gm.gw * (ci / 6.0)
      if ci == 0 or ci == 6 then
        SKIN:Bang("!SetOption", gm.card, "Shape" .. sIdx,
          string.format("Line %.1f,%.1f,%.1f,%.1f | StrokeWidth 1 | Stroke Color %s",
            vx*scale, 28*scale, vx*scale, 50*scale, gMaj))
      else
        SKIN:Bang("!SetOption", gm.card, "Shape" .. sIdx,
          string.format("Line %.1f,%.1f,%.1f,%.1f | StrokeWidth 1 | Stroke Color %s | StrokeDashes 1,2",
            vx*scale, 28*scale, vx*scale, 50*scale, gMin))
      end
      sIdx = sIdx + 1
    end
    SKIN:Bang("!SetOption", gm.card, "Shape" .. sIdx,
      string.format("Line %.1f,%.1f,%.1f,%.1f | StrokeWidth 1 | Stroke Color %s",
        gm.gx*scale, 50*scale, (gm.gx+gm.gw)*scale, 50*scale, gBase))
  end

  -- Text colors & fonts
  local fHead = SKIN:GetVariable("FontHead") or "Space Ranger Title"
  local wHead = SKIN:GetVariable("WHead") or "400"
  local fNum  = SKIN:GetVariable("FontNum") or "Segoe UI Variable Display"
  local wNum  = SKIN:GetVariable("WNum") or "600"
  local szNum = tonumber(SKIN:GetVariable("SzNum")) or 1
  local fTxt  = SKIN:GetVariable("FontText") or "Segoe UI Variable Text"
  local wTxt  = SKIN:GetVariable("WText") or "600"
  local szTxt = tonumber(SKIN:GetVariable("SzText")) or 1

  SKIN:Bang("!SetOption", "MeterHost", "FontFace", fHead)
  SKIN:Bang("!SetOption", "MeterHost", "FontWeight", wHead)
  SKIN:Bang("!SetOption", "MeterHost", "FontColor", fg)
  SKIN:Bang("!SetOption", "MeterUptime", "FontFace", fTxt)
  SKIN:Bang("!SetOption", "MeterUptime", "FontColor", faint)
  SKIN:Bang("!SetOption", "MeterGear", "FontColor", faint)

  for _, m in ipairs({"MeterCPUTitle","MeterGPUTitle","MeterRAMTitle","MeterNETTitle","MeterDISKTitle","MeterWEATHERTitle"}) do
    SKIN:Bang("!SetOption", m, "FontFace", fNum)
    SKIN:Bang("!SetOption", m, "FontWeight", wNum)
    SKIN:Bang("!SetOption", m, "FontSize", tostring(7.5*scale*szNum))
    SKIN:Bang("!SetOption", m, "FontColor", dim)
  end
  for _, m in ipairs({"MeterCPUSub","MeterGPUSub","MeterGPUSubNoTemp","MeterRAMSub","MeterNETSub","MeterDISKSub","MeterWEATHERSub"}) do
    SKIN:Bang("!SetOption", m, "FontFace", fTxt)
    SKIN:Bang("!SetOption", m, "FontWeight", wTxt)
    SKIN:Bang("!SetOption", m, "FontSize", tostring(7.5*scale*szTxt))
    SKIN:Bang("!SetOption", m, "FontColor", faint)
  end
  for _, m in ipairs({"MeterCPUValue","MeterGPUValue","MeterRAMValue","MeterWEATHERValue"}) do
    SKIN:Bang("!SetOption", m, "FontFace", fNum)
    SKIN:Bang("!SetOption", m, "FontWeight", wNum)
    SKIN:Bang("!SetOption", m, "FontSize", tostring(19*scale*szNum))
    SKIN:Bang("!SetOption", m, "FontColor", fg)
  end
  for _, m in ipairs({"MeterCPUUnit","MeterGPUUnit","MeterRAMUnit","MeterWEATHERUnit"}) do
    SKIN:Bang("!SetOption", m, "FontFace", fTxt)
    SKIN:Bang("!SetOption", m, "FontWeight", wTxt)
    SKIN:Bang("!SetOption", m, "FontSize", tostring(9.5*scale*szTxt))
    SKIN:Bang("!SetOption", m, "FontColor", dim)
  end
  for _, m in ipairs({"MeterNETAValue","MeterNETBValue","MeterDISKAValue","MeterDISKBValue"}) do
    SKIN:Bang("!SetOption", m, "FontFace", fNum)
    SKIN:Bang("!SetOption", m, "FontWeight", wNum)
    SKIN:Bang("!SetOption", m, "FontSize", tostring(11.5*scale*szNum))
    SKIN:Bang("!SetOption", m, "FontColor", fg)
  end
  for _, m in ipairs({"MeterNETAUnit","MeterNETBUnit","MeterDISKAUnit","MeterDISKBUnit"}) do
    SKIN:Bang("!SetOption", m, "FontFace", fTxt)
    SKIN:Bang("!SetOption", m, "FontWeight", wTxt)
    SKIN:Bang("!SetOption", m, "FontSize", tostring(7.5*scale*szTxt))
    SKIN:Bang("!SetOption", m, "FontColor", dim)
  end
  SKIN:Bang("!SetOption", "MeterWEATHERCond", "FontFace", fTxt)
  SKIN:Bang("!SetOption", "MeterWEATHERCond", "FontColor", fg)
  SKIN:Bang("!SetOption", "MeterWEATHERDetails", "FontFace", fTxt)
  SKIN:Bang("!SetOption", "MeterWEATHERDetails", "FontColor", dim)

  -- Re-apply layout (sizes, glows, radius, weather bar, visibility) without !Refresh!
  ApplyLayout()
end
