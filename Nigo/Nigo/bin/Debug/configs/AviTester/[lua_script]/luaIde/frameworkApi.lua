--全局Log函数 将log至factory的log
function gLog(logLevel, str_logString) end

--全局TraceLog 将log至factory的log
function gTraceLog(str_logString ) end

--全局InfoLog 将log至factory的log
function gInfoLog(str_logString ) end

--全局DebugLog 将log至factory的log
function gDebugLog(str_logString ) end

--全局WarnLog 将log至factory的log
function gWarnLog(str_logString ) end

--全局ErrorLog 将log至factory的log
function gErrorLog(str_logString ) end

--全局CriticalLog 将log至factory的log
function gCriticalLog(str_logString ) end

--全局Sleep 
--@param sleepTicks sleep的毫秒数
function gSleep(int_sleepTicks) end



--------------------local  资源 但仍然是每个node 都有的资源--------------------

--node自有的log
function localLog(logLevel, str_logString) end

--node自有的traceLog
function localTraceLog(str_logString) end

--node自有的infoLog
function localInfoLog(str_logString) end

--node自有的debugLog
function localDebugLog(str_logString) end

--node自有的warnLog
function localWarnLog(str_logString) end

--node自有的errorLog
function localErrorLog(str_logString) end

--node自有的criticalLog
function localCriticalLog(str_logString) end

--访问node 自有环境的 一个退出标记
function localNeedStop() end

selfName = "name"
selfFullName = "fullName"
selfTypeName = "typeName"
selfLinkName = "linkName"
lastRunRetStr = ""
selfSubtypeName = ""
selfModuleName = ""



