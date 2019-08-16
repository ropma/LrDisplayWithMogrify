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
local LrTasks = import 'LrTasks'

require "LogUtils"
require "MogrifyUtils"

local function getPhotoSize(photo)
  local sizeString = photo:getFormattedMetadata( "croppedDimensions" )
  local x, y = sizeString:match("([^ ]+) x ([^ ]+)")
  local photoCropWidth = tonumber(x)
  local photoCropHeight = tonumber(y)
  local photoWidth 
  local photoHeight

  local winWidth, winHeight = LrSystemInfo.appWindowSize()
  winWidth = winWidth * .8
  winHeight = winHeight * .8

  writeLog(logLevel.debug, 'getPhotoSize: cropSize ' .. photoCropWidth .. ' ' .. photoCropHeight)
  writeLog(logLevel.debug, 'getPhotoSize: winSize ' .. winWidth .. ' ' .. winHeight)
  
  if (photoCropWidth > photoCropHeight) then
    photoWidth = math.min(photoCropWidth, winWidth)
    photoHeight = photoCropHeight/photoCropWidth * photoWidth
    if photoCropHeight > winHeight then
        photoHeight = math.min(photoCropHeight, winHeight)
        photoWidth = photoCropWidth/photoCropHeight * photoHeight
    end
  else
    photoHeight = math.min(photoCropHeight, winHeight)
    photoWidth = photoCropWidth/photoCropHeight * photoHeight
    if photoWidth > winHeight then
        photoWidth = math.min(photoCropWidth, winWidth)
        photoHeight = photoCropHeight/photoCropWidth * photoWidth
    end
  end

  photoWidth  = math.floor(photoWidth)
  photoHeight = math.floor(photoHeight)
  
  writeLog(logLevel.debug, 'getPhotoSize: thumbnailSize ' .. photoWidth .. ' ' .. photoHeight)
  return photoWidth, photoHeight
end


local function getContentViewFile( fileName, xSize, ySize )
  writeLog(logLevel.debug, 'getContentViewFile: ' .. fileName .. ' ' .. xSize .. ' ' .. ySize)

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
      local xSize, ySize = getPhotoSize(targetPhoto)
      local fileName = MogrifyUtils.createDiskImage(targetPhoto, xSize, ySize)
      local focuspointTable = {
        { x = '100', y = '100' },
        { x = '400', y = '500' },
      }
      MogrifyUtils.drawFocusPoints(focuspointTable)
      content = getContentViewFile(fileName, xSize, ySize )
    else
      errorMsg = "Photo is not available"
    end

    if (errorMsg ~= nil) then
      writeLog(logLevel.error, errorMsg)
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
        writeLog(logLevel.error, errMsg ) 
        LrDialogs.message(fileName .. " " .. errorMsg, nil, nil)
      end
    end

  end)
end

LrTasks.startAsyncTask(showDialog)















