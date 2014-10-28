#
# Main library file. Handles turning thing into other thing.
#

xml2js        = require 'xml2js'
xmlBuilder    = require 'xmlBuilder'
util          = require 'util'
MessageFormat = require 'messageformat'

xmlParse = xml2js.Parser().parseString
mf = new MessageFormat 'en'

PLURAL_PLACEHOLDER = {}

# Maps messageformat quantities to Android quantities
ANDROID_XML_PLURALS =
    '1': 'one'
    '0': 'zero'
    'other': 'other'

# Flip that map to go the other way
MESSAGEFORMAT_PLURALS = do ->
    ret = {}
    ret[v] = k for k, v of ANDROID_XML_PLURALS
    return ret

module.exports = 

    Statement: class

        # rootNode can either be a "statements" having node of a messageFormat tree or a raw messageFormat string
        constructor: (key, rootNode) ->
            if typeof rootNode is 'string'
                try
                    parsed = mf.parse rootNode
                    rootNode = parsed.program
                catch e
                    throw new Error 'Hmm, this appears to not be a messageFormat string:', formatStr
            this.key = key
            this.pluralKey = null

            # First thing -- messageformat parses into a nested pattern tree for optimization purposes.
            # We only care about the leafs of that, so let's go ahead and traverse that tree.

            leaves = []
            fringe = rootNode.statements
            while fringe.length > 0
                thisNode = fringe.shift()
                if thisNode.statements
                    fringe = thisNode.statements.concat fringe
                else
                    leaves.push thisNode

            this.strParts = []
            # Cool. Now populate our strParts array with basic strings OR an array if its the plural.
            for leaf in leaves
                if leaf.type is 'string'
                    this.strParts.push leaf.val
                else if leaf.type is 'messageFormatElement'
                    if leaf.elementFormat?
                        unless leaf.elementFormat.key is 'plural'
                            throw new Error 'Unsupported format type: ' + leaf.elementFormat.key 
                        if this.pluralKey?
                            throw new Error 'Two plural statements present in string.'
                        this.pluralKey = leaf.argumentIndex
                        this.plurals = []
                        for pluralForm in leaf.elementFormat.val.pluralForms
                            statement = new module.exports.Statement ANDROID_XML_PLURALS[pluralForm.key], pluralForm.val, 'item'
                            if statement.plural
                                throw new Error 'Nested plural statements present in string.'
                            this.plurals.push statement
                        this.strParts.push PLURAL_PLACEHOLDER

                    else
                        this.strParts.push '{' + leaf.argumentIndex + '}'

        toString: ->
            if this.plural
                throw new Error "Can't call toString on a plural string."
            return this.strParts.join ''

        toXml: ->
            ele = null
            if this.pluralKey?
                ele = xmlBuilder.create 'plurals'
                ele.att 'messageformat:pluralkey', this.pluralKey
                ele.att 'name', this.key
                for pluralStatement in this.plurals
                    str = ''
                    for part in this.strParts
                        if part is PLURAL_PLACEHOLDER
                            str += pluralStatement.toString()
                        else
                            str += part
                    ele.ele 'item', {quantity: pluralStatement.key}, str
            else
                ele = xmlBuilder.create 'string'
                ele.att 'name', this.key
                ele.txt this.toString()
            return ele

    _mfStringToXml: (key, formatStr) ->
        statement = new this.Statement key, formatStr
        return statement.toXml().toString({ pretty: true, indent: '  ', offset: 1, newline: '\n' })

    # Helper to turn {"FOO": {"BAR": "Eli", "BAZ": "Mallon"}} into {"FOO.BAR": "Eli", "FOO.BAZ": "Mallon"}
    _flatten: (obj, base = []) ->
        ret = {}
        for key, value of obj
            if typeof value is 'object'
                ret[k] = v for k, v of this._flatten value, base.concat [key]
            else
                newKey = (base.concat [key]).join '.'
                ret[newKey] = value
        return ret

    # Helper to do the opposite of _flatten
    _unflatten: (obj) ->
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


    _mfObjectToXml: (obj) ->
        flattened = this._flatten obj
        root = xmlBuilder.create 'resources'
        for key, value of flattened
            statement = new this.Statement key, value
            root.importXMLBuilder statement.toXml()
        return root.toString({ pretty: true, indent: '  ', offset: 1, newline: '\n' })

    # Public-facing section: just toXml and toMessageFormat functions.

    toXml: (key, formatStr) ->
        if typeof key is 'string'
            return this._mfStringToXml key, formatStr
        else
            return this._mfObjectToXml key

    toMessageFormat: (xmlStr) ->
        parsed = null
        # don't be fooled -- the following few lines all happen in order.
        xmlParse xmlStr, (err, result) ->
            throw new Error err if err?
            parsed = result

        # First, treat everything as if it has a "resources" root
        if parsed.string?
            parsed = {resources: parsed}

        if parsed.plurals?
            parsed = {resources: parsed}

        resources = parsed.resources
        resources.string ?= []
        resources.plurals ?= []

        # Then, treat everything as if it is an array of objects
        if resources.string and not util.isArray(resources.string)
            resources.string = [resources.string]

        if resources.plurals and not util.isArray(resources.plurals)
            resources.plurals = [resources.plurals]

        ret = {}

        # Cool, gross XML data has been normalized. Now iterate over the stuff.
        for string in resources.string
            ret[string.$.name] = string._

        for plural in resources.plurals when resources.plurals
            inner = []
            unless util.isArray plural.item
                plural.item = [plural.item]
            for item in plural.item
                itemStr = ''
                itemStr += MESSAGEFORMAT_PLURALS[item.$.quantity]
                itemStr += '{'
                itemStr += item._
                itemStr += '}'
                inner.push itemStr
            pluralKey = plural.$['messageformat:pluralkey']
            ret[plural.$.name] = "{#{pluralKey}, plural, #{inner.join(' ')}}"

        ret = this._unflatten ret
        return ret
