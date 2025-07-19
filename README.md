
# Yet Another Primitives Plus

Yet Another Prmitives Plus (or YAPP) is yet another library designed to provide
extended functionality to Lua's standard library. It also includes a few
'polyfill' versions of present and deprecated standard library functions.

YAPP is still in early development. APIs are subject to (unannounced) change
until version `1.0.0`. Documentation is also currently severely lacking.

# Namespaces
 - **`yapp`**
   - `chalk` - Like the familiar `chalk` NPM package, for Lua!
   - `class` - More complex 'non-primitive' types
   - `debug` - Polyfills for `debug.traceback` and `warn`
     - `env` - Polyfills for `getfenv` and `setfenv`
     - `fn` - Utilities for introspecting functions
   - `fs` - Filesystem operations that are non-trivial in Lua's standard library.
     - `path` - Filepath manipulation utilities
   - `io` - Serializing/Deserializing helpers
   - `math` - Polyfills for modern math operations, and `math.round`
   - `op` - Callable functions that represent every current operator metatable event.
     - `bit` - Polyfills for bitwise operators
   - `os` - A few utilities for understanding the system Lua is running under
   - `package` - Polyfill for `package.searchers` and a module that returns the extension of shared libraries.
   - `string` - String manipulation helpers
   - `table` - Table manipulation helpers
     - `list` - Helpers for tables that only contain ordered integer keys