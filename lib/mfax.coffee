xml2js = require 'xml2js'
xmlParse = xml2js.Parser().parseString
xmlBuilder = new xml2js.Builder()

MessageFormat = require 'messageformat'
mf = new MessageFormat 'en'

PLURAL_PLACEHOLDER = {}

# Maps messageformat quantities to Android quantities
QUANTITY_MAP =
    '1': 'one'
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
                        for pluralForm in leaf.elementFormat.val.pluralForms
                            statement = new module.exports.Statement QUANTITY_MAP[pluralForm.key], pluralForm.val
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
            ret = {}
            if this.plural
                ret.plurals = {}
                ret.plurals.$ = {name: this.key}
                ret.plurals.item = []
                for pluralStatement in this.plurals
                    item = {}
                    ret.plurals.item.push item
                    item.$ = {quantity: pluralStatement.key}
                    item._ = ''
                    for part in this.strParts
                        if part is PLURAL_PLACEHOLDER
                            item._ += pluralStatement.toString()
                        else
                            item._ += part
            else
                ret.string = {}
                ret.string.$ = {name: this.key}
                ret.string._ = this.toString()
            return xmlBuilder.buildObject ret




    _mfStringToXml: (key, formatStr) ->
        try
            parsed = mf.parse formatStr
        catch e
            throw new Error 'Hmm, this appears to not be a messageFormat string:', formatStr
        statement = new this.Statement key, parsed.program
        return statement.toXml()

    _mfObjectToXml: (obj) ->


    toXml: (key, formatStr) ->
        if typeof key is 'string'
            return this._mfStringToXml key, formatStr
        else


