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

local LrSystemInfo = import 'LrSystemInfo'
local LrFunctionContext = import 'LrFunctionContext'
local LrApplication = import 'LrApplication'
local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrColor = import 'LrColor'
local LrTasks = import 'LrTasks'
local LrFileUtils = import 'LrFileUtils'
local LrPathUtils = import 'LrPathUtils'
local LrErrors = import 'LrErrors'
local LrPrefs = import "LrPrefs"
local LrLogger = import 'LrLogger'

local prefs = LrPrefs.prefsForPlugin( nil )
local mywriteLog = LrLogger( 'DisplayWithMogrify' )
mywriteLog:enable( "logfile" )

local fileName

local function writeLog(level, text)
  if level <= prefs.logLevel then
    if level == 1 then
      mywriteLog:error(text)
    elseif level == 2 then
      mywriteLog:info(text)
    else
      mywriteLog:debug(text)
    end
  end 
end

local function getPhotoSize( photo )
  local appWidth, appHeight = LrSystemInfo.appWindowSize()
  local photoWidth = appWidth * .7
  local photoHeight = appHeight * .7
  photoWidth  = math.floor( photoWidth )
  photoHeight = math.floor( photoHeight )
  return photoWidth, photoHeight
end

local function exportToDisk( photo )
  local xSize, ySize = getPhotoSize(photo)
  local thumb = photo:requestJpegThumbnail(xSize, ySize, function(data, errorMsg)
    if data == nil then
      LrDialogs.message(errorMsg, nil, nil)
    else
      local orgPath = photo:getRawMetadata("path")
      local leafName = LrPathUtils.leafName( orgPath )
      local leafWOExt = LrPathUtils.removeExtension( leafName )
      local tempPath = LrPathUtils.getStandardFilePath( "temp" )
      fileName = LrPathUtils.child( tempPath, leafWOExt .. "-fpoints.jpg" )
      writeLog(3, fileName ) 

      local localFile = io.open(fileName, "w+b")
      localFile:write(data)
      localFile:close()
    end
  end)
end

local function mogrifyDraw()
  local cmdline = '\"' .. prefs.mogrifyPath .. '\" ' 
  cmdline = cmdline .. '-strokewidth 3 -stroke red -fill \"#00000000\" -draw \"roundRectangle 100,100 200,200 1,1\" '
  cmdline = cmdline .. fileName
  writeLog(3, cmdline) 
  local stat = LrTasks.execute( '\"' .. cmdline .. '\"' )
  if stat ~= 0 then
    writeLog(1, 'Error calling: ' .. cmdline)
  end
end

local function getContentViewDirect( photo )
  local xSize, ySize = getPhotoSize(photo)

  local viewFactory = LrView.osFactory()
  local photoToDisplay = viewFactory:catalog_photo {
    width  = xSize, 
    height = ySize,
    photo  = photo,
  }

  local photoView = viewFactory:view {
    photoToDisplay,
  }
  return photoView
end

local function getContentViewFile( photo )
  local xSize, ySize = getPhotoSize(photo)

  local viewFactory = LrView.osFactory()
     
  local photoView = viewFactory:view {
    viewFactory:static_text {
      title       = " Display: " .. fileName,
    },
    viewFactory:picture {
      width  = xSize,
      height = ySize,
      value = fileName, 
    },
  }
  return photoView
end

local function showDialog()
  LrFunctionContext.callWithContext("showDialog", function(context)
    local catalog     = LrApplication.activeCatalog()
    local targetPhoto = catalog:getTargetPhoto()
    local errorMsg    = nil
    local dialogScope = nil
    local content     = nil

    if (targetPhoto:checkPhotoAvailability()) then
      exportToDisk( targetPhoto )
      mogrifyDraw()
      --content = getContentViewDirect( targetPhoto )
      content = getContentViewFile( targetPhoto )
    else
      errorMsg = "Photo is not available"
    end

    if (errorMsg ~= nil) then
      writeLog(1, errorMsg)
      LrDialogs.message(errorMsg, nil, nil)
      return
    else
      LrDialogs.presentModalDialog {
        title = "Display with Mogrify",
        cancelVerb = "< exclude >",
        actionVerb = "OK",
        contents = content
      }
    end

    -- delete temporary file
    if fileName ~= nil then
      resultOK, errorMsg  = LrFileUtils.delete( fileName )
      if errorMsg ~= nil then
        LrDialogs.message(fileName .. " " .. errorMsg, nil, nil)
      end
    end

  end)
end

LrTasks.startAsyncTask(showDialog)















