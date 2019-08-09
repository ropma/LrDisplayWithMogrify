local LrView = import "LrView"
local LrPrefs = import "LrPrefs"
local LrLogger = import 'LrLogger'

local prefs = LrPrefs.prefsForPlugin( nil )
local myWriteLog

logLevel = {
  error = 1,
  info  = 2,
  debug = 3,
}

function logLevelInfoProviderSection(viewFactory)
  local bind = LrView.bind
  local logTable = {
    title = "Logging",
    viewFactory:row {
      bind_to_object = prefs,
      spacing = viewFactory:control_spacing(),
      viewFactory:popup_menu {
        title = "Logging level",
        value = bind 'logLevel',
        items = {
          { title = "Error", value = logLevel.error },
          { title = "Info",  value = logLevel.info },
          { title = "Debug", value = logLevel.debug },
        }
      },
    }
  }
  return logTable
end

function init()
  if myWriteLog == nil then
    myWriteLog = LrLogger( prefs.logFileName )
    myWriteLog:enable( "logfile" )
  end
end

function writeLog(level, text)
  init()
  if level <= prefs.logLevel then
    if level == logLevel.error then
      myWriteLog:error(text)
    elseif level == logLevel.info then
      myWriteLog:info(text)
    else
      myWriteLog:debug(text)
    end
  end
end
