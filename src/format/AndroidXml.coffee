#
# Formatter for Android XML format. Note that the body of a string in Android XML is a valid
# MessageFormat string, so this thing depends on and pipes through the MessageFormatFormatter.
#

util                   = require 'util'
xmlBuilder             = require 'xmlBuilder'
xml2js                 = require 'xml2js'
xmlParse               = xml2js.Parser().parseString
MessageFormatFormatter = require './MessageFormat'

module.exports = AndroidXmlFormatter =

    ALLOWED_PLURAL_KEYS: ["zero", "one", "two", "few", "many", "other"]

    # For ease of use, this thing can take either an Android XML `<plurals>` or `<string>` or
    # the xml2js-converted version of the same.
    stringIn: (str) ->
        mfconv = require '../messageformat-converter'
        parsed = null

        if typeof str is 'object'
            parsed = str
        else
            # looks like a callback but isn't. xml2js runs sync.
            xmlParse str, (err, result) ->
                throw new Error err if err?
                parsed = result

        elements = Object.keys(parsed)
        if (elements.length isnt 1)
            throw new Error 'AndroidXmlFormatter only takes exactly one XML element'

        type = elements[0]
        body = parsed[type]

        if util.isArray body
            throw new Error "more than one <#{type}> passed into AndroidXmlFormatter. Use the file handler instead."

        key = body.$.name
        output = null

        # Case 1: <string>. Just pipe it through MessageFormatFormatter and we're good.
        if type is 'string'
            output = MessageFormatFormatter.stringIn [key, body._]

        # Case 2: <plurals>. Create a conversionString with one PluralBit.
        else if type is 'plurals'
            pluralKey = body.$['messageformat:pluralkey']
            unless pluralKey?
                throw new Error "<plurals> element without a messageformat:pluralkey attribute. I don't know upon which variable I should be switching."
            output = new mfconv.ConversionString key
            pluralBit = new mfconv.PluralBit pluralKey
            output.bits.push pluralBit
            unless util.isArray body.item
                body.item = [body.item]
            for item in body.item
                pluralAmount = item.$.quantity
                unless pluralAmount in AndroidXmlFormatter.ALLOWED_PLURAL_KEYS
                    throw new Error "Unknown plural key: #{pluralKey}"
                itemString = MessageFormatFormatter.stringIn [pluralAmount, item._]
                pluralBit.addMapping itemString
        
        else
            throw new Error 'unknown data type passed to AndroidXmlFormatter: ' + type

        return output

    stringOut: (conversionString) ->
        mfconv = require '../messageformat-converter'
        pluralBit = null
        ele = null

        # First make sure there is no more than one plural string in here. Android XML can't handle more than that.
        for bit in conversionString.bits
            if bit.type is 'plural'
                if pluralBit?
                    throw new Error "Can't serialize this string as Android XML -- there is more than one plural clause within it"
                pluralBit = bit

        if pluralBit?
            ele = xmlBuilder.create 'plurals'
            ele.att 'messageformat:pluralkey', pluralBit.pluralKey
            ele.att 'name', conversionString.key

            # Need to turn the conversionString "you have {num, plural, 1{one thing} other{{num} things}}" into
            # "{num, plural, 1{you have one thing} other{you have {num} things}}"
            outputStrings = []
            pluralIdx = conversionString.bits.indexOf pluralBit
            for pluralString in pluralBit.pluralStrings
                unless pluralString.key in AndroidXmlFormatter.ALLOWED_PLURAL_KEYS
                    throw new Error "Unknown plural key: #{pluralString.key}"
                newBits = conversionString.bits.slice 0
                newBits.splice.apply newBits, [pluralIdx, 1].concat  pluralString.bits
                [key, str] = MessageFormatFormatter.stringOut (new mfconv.ConversionString pluralString.key, newBits)
                ele.ele 'item', {quantity: key}, str
        else
            ele = xmlBuilder.create 'string'
            [key, str] = MessageFormatFormatter.stringOut conversionString
            ele.att 'name', key
            ele.txt str
        return ele.toString()

    fileIn: (fileStr) ->
        mfconv = require '../messageformat-converter'
        parsed = null
        xmlParse fileStr, (err, result) ->
            parsed = result

        if (Object.keys(parsed).length isnt 1) or (not parsed.resources?) or util.isArray parsed.resources
            throw new Error 'Android XML files need to be a single <resources> block containing <string>s and <plurals>s'

        # Need to do some XML denormalization because of ugly XML --> JS object conversion
        resources = parsed.resources

        conversionStrings = []

        for type in ['string', 'plurals']
            if resources[type]?
                unless util.isArray resources[type]
                    resources[type] = [resources[type]]
                for str in resources[type]
                    elem = {}
                    elem[type] = str
                    conversionStrings.push AndroidXmlFormatter.stringIn elem 
        return new mfconv.ConversionFile conversionStrings

    fileOut: (conversionFile) ->
        mfconv = require '../messageformat-converter'
        # For the raw XML strings that we're getting from stringOut, it's easier to use xml2js's
        # builder than a proper xmlBuilder interface.
        builder = new xml2js.Builder()
        resources = 
            $:
                'xmlns:messageformat': 'https://github.com/ActiveBuilding/messageformat-converter'
        for conversionString in conversionFile.conversionStrings
            element = AndroidXmlFormatter.stringOut conversionString
            xmlParse element, (err, result) ->
                throw err if err?
                element = result
            type = Object.keys(element)[0]
            resources[type] ?= []
            resources[type].push element[type]
        return builder.buildObject {resources: resources}
