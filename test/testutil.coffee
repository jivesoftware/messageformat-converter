xmlParse = (require 'xml2js').Parser().parseString

module.exports = 
    
    # Simple way to see if two XML strings are equivelent: pipe through xml2js then use jasmine's .isEqual.
    expectXmlEqual: (actualStr, expectedStr) ->
        expected = null
        actual = null
        xmlParse expectedStr, (err, result) ->
            expected = result
        xmlParse actualStr, (err, result) ->
            actual = result
        expect(actual).toEqual(expected)
