xml2js = require 'xml2js'
xmlBuilder = require 'xmlBuilder'
xmlParse = xml2js.Parser().parseString

MessageFormat = require 'messageformat'
mf = new MessageFormat 'en'

PLURAL_PLACEHOLDER = {}

# Maps messageformat quantities to Android quantities
QUANTITY_MAP =
    '1': 'one'
    '0': 'zero'
    'other': 'other'

module.exports = 

    Statement: class
        constructor: (key, rootNode) ->
            this.key = key
            this.plural = false

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
                        if this.plural is true
                            throw new Error 'Two plural statements present in string.'
                        this.plural = true
                        this.plurals = []
                        this.eleName = 'plurals'
                        for pluralForm in leaf.elementFormat.val.pluralForms
                            statement = new module.exports.Statement QUANTITY_MAP[pluralForm.key], pluralForm.val, 'item'
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
            if this.plural
                ele = xmlBuilder.create 'plurals'
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
        try
            parsed = mf.parse formatStr
        catch e
            throw new Error 'Hmm, this appears to not be a messageFormat string:', formatStr
        statement = new this.Statement key, parsed.program
        return statement.toXml().toString({ pretty: true, indent: '  ', offset: 1, newline: '\n' })

    _recursiveFlatten: (obj, base = []) ->
        ret = {}
        for key, value of obj
            if typeof value is 'object'
                ret[k] = v for k, v of this._recursiveFlatten value, base.concat [key]
            else
                newKey = (base.concat [key]).join '.'
                ret[newKey] = value
        return ret

    _mfObjectToXml: (obj) ->
        flattened = this._recursiveFlatten obj
        root = xmlBuilder.create 'resources'
        for key, value of flattened
            try
                parsed = mf.parse value
            catch e
                throw new Error 'Hmm, this appears to not be a messageFormat string:', formatStr
            statement = new this.Statement key, parsed.program
            root.importXMLBuilder statement.toXml()
        return root.toString({ pretty: true, indent: '  ', offset: 1, newline: '\n' })

    toXml: (key, formatStr) ->
        if typeof key is 'string'
            return this._mfStringToXml key, formatStr
        else
            return this._mfObjectToXml key
