--[[

MIT License

Copyright (c) 2019 ropma

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

--]]

local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrTasks = import 'LrTasks'
local LrPrefs = import "LrPrefs"

require "LogUtils"

local prefs = LrPrefs.prefsForPlugin( nil )
local fileName
local dim = 30


MogrifyUtils = { }    -- class

MogrifyUtils.POINTTYPE_AF_SELECTED_INFOCUS = "af_selected_infocus"    -- The AF-point is selected and in focus
MogrifyUtils.POINTTYPE_AF_INFOCUS = "af_infocus"                      -- The AF-point is in focus
MogrifyUtils.POINTTYPE_AF_SELECTED = "af_selected"                    -- The AF-point is selected but not in focus
MogrifyUtils.POINTTYPE_AF_INACTIVE = "af_inactive"                    -- The AF-point is inactive
MogrifyUtils.POINTTYPE_FACE = "face" 

-- local helper functions
local function exportToDisk(photo, xSize, ySize)
  local thumb = photo:requestJpegThumbnail(xSize, ySize, function(data, errorMsg)
    if data == nil then
      writeLog(logLevel.error, 'exportToDisk: No thumbnail data')
    else
      local orgPath = photo:getRawMetadata("path")
      local leafName = LrPathUtils.leafName( orgPath )
      local leafWOExt = LrPathUtils.removeExtension( leafName )
      local tempPath = LrPathUtils.getStandardFilePath( "temp" )
      fileName = LrPathUtils.child( tempPath, leafWOExt .. "-fpoints.jpg" )
      writeLog(logLevel.debug, 'exportToDisk: ' .. fileName ) 

      local localFile = io.open(fileName, "w+b")
      localFile:write(data)
      localFile:close()
    end
  end)
end

local function mogrifyResize(xSize, ySize)
  local cmdline = '\"' .. prefs.mogrifyPath .. '\" ' 
  cmdline = cmdline .. '-resize ' .. xSize .. 'x' .. ySize .. ' ' .. fileName
  writeLog(logLevel.debug, 'mogrifyResize: ' .. cmdline) 
  local stat = LrTasks.execute( '\"' .. cmdline .. '\"' )
  if stat ~= 0 then
    writeLog(logLevel.error, 'Error calling: ' .. cmdline)
  end
end

local function buildCmdLine(focuspointsTable)
  local cmdline = '\"' .. prefs.mogrifyPath .. '\" ' 
  cmdline = cmdline .. '-strokewidth 2 -stroke red -fill none '
  -- -draw \"roundRectangle 100,100 200,200 1,1\"
  for i, fp in ipairs(focuspointsTable) do
    local x1 = tonumber(fp.x) - dim/2 
    local y1 = tonumber(fp.y) - dim/2
    local x2 = x1 + dim
    local y2 = y1 + dim
    local tmp = '-draw \"roundRectangle ' .. x1 .. ',' .. y1 .. ' ' .. x2 .. ',' .. y2 .. ' 1,1\" '
    writeLog(logLevel.debug, 'buildCmdLine: [' .. i .. '] ' .. tmp) 
    cmdline = cmdline .. tmp
  end
  cmdline = cmdline .. fileName
  return cmdline
end
  
local function mogrifyDraw(cmdline)
  writeLog(3, 'mogrifyDraw: ' .. cmdline) 
  local stat = LrTasks.execute( '\"' .. cmdline .. '\"' )
  if stat ~= 0 then
    writeLog(logLevel.error, 'Error calling: ' .. cmdline)
  end
end


function MogrifyUtils.createDiskImage(photo, xSize, ySize)
  writeLog(logLevel.info, 'MogrifyUtils:createDiskImage: ' .. photo:getFormattedMetadata( 'fileName' ) .. ' ' .. xSize .. ' ' .. ySize) 
  exportToDisk(photo, xSize, ySize)
  mogrifyResize(xSize, ySize)
  return fileName
end


function MogrifyUtils.drawFocusPoints(focuspointsTable)
  writeLog(logLevel.info, 'MogrifyUtils:drawFocusPoints: ')
  local cmdLine = buildCmdLine(focuspointsTable)  
  mogrifyDraw(cmdLine)
end