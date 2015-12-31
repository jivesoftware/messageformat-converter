var xml2js = require('xml2js');
var xmlParse = xml2js.Parser().parseString;
var builder = new xml2js.Builder();

module.exports = 
    
    // Simple way to see if two XML strings are equivelent: pipe through xml2js then use jasmine's .isEqual.
    {expectXmlEqual(actualStr, expectedStr) {
        var expected = null;
        var actual = null;
        xmlParse(expectedStr, function(err, result) {
            return expected = builder.buildObject(result);
        });
        xmlParse(actualStr, function(err, result) {
            return actual = builder.buildObject(result);
        });
        return expect(actual).toEqual(expected);
    }
    };
