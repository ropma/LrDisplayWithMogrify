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

local LrView = import "LrView"
local LrPrefs = import "LrPrefs"
local LrDialogs = import "LrDialogs"

local bind = LrView.bind

local function startDialog( propertyTable )
end

local function endDialog( propertyTable )
end

local function sectionsForBottomOfDialog( viewFactory, _ )
end

local function sectionsForTopOfDialog( viewFactory, propertyTable )
  local prefs = LrPrefs.prefsForPlugin( nil )
  return {
    {
      title = "Logging",
      viewFactory:row {
        bind_to_object = prefs,
        spacing = viewFactory:control_spacing(),
        viewFactory:popup_menu {
          title = "Logging level",
          value = bind 'logLevel',
          items = {
            { title = "Error", value = 1},
            { title = "Info", value = 2},
            { title = "Debug", value = 3},
          }
        },
      },
    },

    {
      title = "Mogrify",
      viewFactory:row {
        bind_to_object = prefs,
        spacing = viewFactory:control_spacing(),
        viewFactory:edit_field {
          fill = 1,
          width_in_chars = 30,
          value = bind 'mogrifyPath',
        },
        viewFactory:push_button {
          title = "Browse",
          enabled = true,
          action = function ()
            local path = LrDialogs.runOpenPanel(
              { title = "Select Mogrify Executable" },
              { canChooseFiles = true },
              { canChooseDirectories = false },
              { canCreateDirectories = false },
              { allowsMultipleSelection = false },
              { fileTypes = '*.EXE' } )
            if path then
              prefs.mogrifyPath = path[1]
            end
          end
        },
      },
    },
  }
end

return{

    startDialog = startDialog,
    sectionsForBottomOfDialog = sectionsForBottomOfDialog,
    sectionsForTopOfDialog = sectionsForTopOfDialog,

}
