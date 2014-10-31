module.exports = 
    # Helper to turn {"FOO": {"BAR": "Eli", "BAZ": "Mallon"}} into {"FOO.BAR": "Eli", "FOO.BAZ": "Mallon"}
    flatten: (obj, base = []) ->
        ret = {}
        for key, value of obj
            if typeof value is 'object'
                ret[k] = v for k, v of module.exports.flatten value, base.concat [key]
            else
                newKey = (base.concat [key]).join '.'
                ret[newKey] = value
        return ret

    # Helper to do the opposite of _flatten
    unflatten: (obj) ->
        ret = {}
        for k, v of obj
            root = ret
            split = k.split '.'
            finalBit = split.pop()
            for bit in split
                root[bit] ?= {}
                root = root[bit]
            root[finalBit] = v
        return ret
