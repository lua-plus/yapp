local class = require("lib.30log.30log") --[[ @as unknown ]]

if false then
    ---@generic T
    ---@alias Log.ClassExtender (fun(self: LogClass, name: string, properties: T): LogClass<T>)|(fun(self: LogClass, name: string): LogClass<table>)

    ---@class Log.BaseFunctions
    ---@operator call:(Log.BaseFunctions | { extend: Log.ClassExtender<{}> })
    ---@field public init fun(self: LogClass, ...: any) abstract function to initialize the class. return value ignored
    ---@field public new function interally used by 30log. do not modify
    ---@field instanceOf fun(self: LogClass, class: Log.BaseFunctions): boolean check if an object is an instance of a class
    ---@field instances fun(self: LogClass, filter?: fun(instance: LogClass, ...: any), ...: any): LogClass[]
    -- TODO :cast
    ---@field classOf fun(self: LogClass, possibleSubClass: any): boolean check if a given object is a subclass of this class
    ---@field subclassOf fun(self: LogClass, possibleParentClass: any): boolean check if a given object is this class's parent class
    ---@field subclasses fun(self: LogClass): LogClass[]
    ---@field extend Log.ClassExtender
    ---@field super LogClass?
    ---
    ---@field with fun(self: LogClass, mixin: table)
    ---@field without fun(self: LogClass, mixin: table)
    ---
    ---@field class LogClass
    
    --- Function here allows @overload signatures
    ---@alias LogClass<T> 
    ---| Log.BaseFunctions 
    ---| { extend: Log.ClassExtender<T> } 
    ---| T 
    ---| function
    
    ---@generic T
    ---@alias LogEntrypoint
    ---| fun(name: string, properties: T): LogClass<T>
    ---| fun(name: string): LogClass<table>
    ---| { isClass: fun(class: any): boolean }
    ---| { isInstance: fun(instance: any): boolean }

    ---@type LogEntrypoint
    class = function (name, properties)
        return nil
    end
end

return class