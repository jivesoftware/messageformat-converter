xml2js = require 'xml2js'
xmlParse = xml2js.Parser().parseString
builder = new xml2js.Builder()

module.exports = 
    
    # Simple way to see if two XML strings are equivelent: pipe through xml2js then use jasmine's .isEqual.
    expectXmlEqual: (actualStr, expectedStr) ->
        expected = null
        actual = null
        xmlParse expectedStr, (err, result) ->
            expected = builder.buildObject result
        xmlParse actualStr, (err, result) ->
            actual = builder.buildObject result
        expect(actual).toEqual(expected)
