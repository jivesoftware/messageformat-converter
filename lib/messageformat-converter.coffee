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

    # In a gross oversimplification of messageFormat, `ConversionString`s are comprised of strings
    # of different types of "bits".
    ConversionString: class
        constructor: (key, bits = []) ->
            this.key = key
            this.bits = bits

    # Just a boring ol' string.
    StringBit: class
        type: 'string'
        constructor: (str) ->
            this.str = str

    # Just a boring ol' {variable}
    VariableBit: class
        type: 'variable'
        constructor: (varName) ->
            this.varName = varName

    # Plurals take a mapping of messageFormat plural keys to translation strings.
    PluralBit: class
        type: 'plural'
        constructor: (pluralKey) ->
            this.pluralKey = pluralKey
            this.pluralStrings = []

        addMapping: (pluralString) ->
            this.pluralStrings.push pluralString
