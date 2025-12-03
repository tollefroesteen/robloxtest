--!strict
-- Log.luau
-- Standardized logging utility with DEV_MODE toggle (LO-3)

local Log = {}

-- Toggle verbose logging for development
Log.DEV_MODE = true

--- Logs a warning with standardized prefix
--- @param context string The module/controller name (e.g., "MenuController")
--- @param message string The warning message
function Log.Warn(context: string, message: string)
	warn(string.format("[%s] %s", context, message))
end

--- Logs a debug message only when DEV_MODE is enabled
--- @param context string The module/controller name
--- @param message string The debug message
function Log.Debug(context: string, message: string)
	if Log.DEV_MODE then
		print(string.format("[%s:DEBUG] %s", context, message))
	end
end

--- Logs an info message with standardized prefix
--- @param context string The module/controller name
--- @param message string The info message
function Log.Info(context: string, message: string)
	print(string.format("[%s] %s", context, message))
end

--- Logs an error with standardized prefix
--- @param context string The module/controller name
--- @param message string The error message
function Log.Error(context: string, message: string)
	error(string.format("[%s] %s", context, message))
end

return Log
