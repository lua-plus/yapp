
const luabundle = require("luabundle")
const fs = require("fs")
const path = require("path")

const is_dir = path => fs.lstatSync(path).isDirectory() 
const exists = path => fs.existsSync(path)

/**
 * @param {string} modname 
 */
const rm_trailing_init = (modname) => {
    if (modname.endsWith(".init")) {
        return modname.slice(0, -5)
    }

    return modname
}

const namespace = (modname, modpath) => {
    const modroot = rm_trailing_init(modname)

    const dir = path.dirname(modpath)

    const modules = {}

    for (let file of fs.readdirSync(dir)) {
        const p = path.join(dir, file)
        file = path.parse(file).name

        const sub_mod = modroot + "." + file
        const sub_init = rm_trailing_init(sub_mod)

        if (sub_mod != modname && sub_init != modroot) {            
            if (!is_dir(p) || exists(path.join(p, "init.lua"))) {
                modules[file] = `require("${sub_mod}")`
            }
        }
    }

    return modules
}


const entryname = "src.init"
const entrypath = "src/init.lua"

const lua_bundle = luabundle.bundle(entrypath, {
    preprocess: (module) => {
        let { content, name, resolvedPath } = module

        name = name.replace("__root", entryname)

        content = content.replaceAll("namespace(...)", () => {
            const modules = namespace(name, resolvedPath ?? entrypath)

            return "{" + Object.entries(modules).map(([key, value]) => {
                return `["${key}"] = ${value}`
            }).join(", ") + "}"
        })

        content = content.replace(/local namespace\s+=[^\n\r]+/g, "")

        return content
    },
    paths: ['?', '?.lua', '?/init.lua']
})

fs.writeFile("./bundle.lua", lua_bundle, () => {
    console.log("done!")
})