'use strict';

var _slicedToArray = (function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; })();

var _util = require('util');

var _util2 = _interopRequireDefault(_util);

var _xmlbuilder = require('xmlbuilder');

var _xmlbuilder2 = _interopRequireDefault(_xmlbuilder);

var _xml2js = require('xml2js');

var _xml2js2 = _interopRequireDefault(_xml2js);

var _MessageFormat = require('./MessageFormat');

var _MessageFormat2 = _interopRequireDefault(_MessageFormat);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _typeof(obj) { return obj && typeof Symbol !== "undefined" && obj.constructor === Symbol ? "symbol" : typeof obj; } //
// Formatter for Android XML format. Note that the body of a string in Android XML is a valid
// MessageFormat string, so this thing depends on and pipes through the MessageFormatFormatter.
//

var xmlParse = _xml2js2.default.Parser().parseString;

var AndroidXmlFormatter = {
    ALLOWED_PLURAL_KEYS: ["zero", "one", "two", "few", "many", "other"],

    // For ease of use, this thing can take either an Android XML `<plurals>` or `<string>` or
    // the xml2js-converted version of the same.
    stringIn: function stringIn(str) {
        var mfconv = require('../messageformat-converter');
        var parsed = null;

        if ((typeof str === 'undefined' ? 'undefined' : _typeof(str)) === 'object') {
            parsed = str;
        } else {
            // looks like a callback but isn't. xml2js runs sync.
            xmlParse(str, function (err, result) {
                if (typeof err !== "undefined" && err !== null) {
                    throw new Error(err);
                }
                return parsed = result;
            });
        }

        var elements = Object.keys(parsed);
        if (elements.length !== 1) {
            throw new Error('AndroidXmlFormatter only takes exactly one XML element');
        }

        var type = elements[0];
        var body = parsed[type];

        if (_util2.default.isArray(body)) {
            throw new Error('more than one <' + type + '> passed into AndroidXmlFormatter. Use the file handler instead.');
        }

        var key = body.$.name;
        var output = null;

        // Case 1: <string>. Just pipe it through MessageFormatFormatter and we're good.
        if (type === 'string') {
            output = _MessageFormat2.default.stringIn([key, body._]);

            // Case 2: <plurals>. Create a conversionString with one PluralBit.
        } else if (type === 'plurals') {
                var pluralKey = body.$['messageformat:pluralkey'];
                if (!(typeof pluralKey !== "undefined" && pluralKey !== null)) {
                    throw new Error("<plurals> element without a messageformat:pluralkey attribute. I don't know upon which variable I should be switching.");
                }
                output = new mfconv.ConversionString(key);
                var pluralBit = new mfconv.PluralBit(pluralKey);
                output.bits.push(pluralBit);
                if (!_util2.default.isArray(body.item)) {
                    body.item = [body.item];
                }
                for (var i = 0, item; i < body.item.length; i++) {
                    item = body.item[i];
                    var pluralAmount = item.$.quantity;
                    if (!(AndroidXmlFormatter.ALLOWED_PLURAL_KEYS.indexOf(pluralAmount) >= 0)) {
                        throw new Error('Unknown plural key: ' + pluralKey);
                    }
                    var itemString = _MessageFormat2.default.stringIn([pluralAmount, item._]);
                    pluralBit.addMapping(itemString);
                }
            } else {
                throw new Error('unknown data type passed to AndroidXmlFormatter: ' + type);
            }

        return output;
    },
    stringOut: function stringOut(conversionString) {
        var mfconv = require('../messageformat-converter');
        var pluralBit = null;
        var ele = null;

        // First make sure there is no more than one plural string in here. Android XML can't handle more than that.
        for (var i = 0, bit; i < conversionString.bits.length; i++) {
            bit = conversionString.bits[i];
            if (bit.type === 'plural') {
                if (typeof pluralBit !== "undefined" && pluralBit !== null) {
                    throw new Error("Can't serialize this string as Android XML -- there is more than one plural clause within it");
                }
                pluralBit = bit;
            }
        }

        if (typeof pluralBit !== "undefined" && pluralBit !== null) {
            ele = _xmlbuilder2.default.create('plurals');
            ele.att('messageformat:pluralkey', pluralBit.pluralKey);
            ele.att('name', conversionString.key);

            // Need to turn the conversionString "you have {num, plural, 1{one thing} other{{num} things}}" into
            // "{num, plural, 1{you have one thing} other{you have {num} things}}"
            var outputStrings = [];
            var pluralIdx = conversionString.bits.indexOf(pluralBit);
            for (var j = 0, pluralString; j < pluralBit.pluralStrings.length; j++) {
                pluralString = pluralBit.pluralStrings[j];
                var ref = pluralString.key;
                if (AndroidXmlFormatter.ALLOWED_PLURAL_KEYS.indexOf(ref) < 0) {
                    throw new Error('Unknown plural key: ' + pluralString.key);
                }
                var newBits = conversionString.bits.slice(0);
                newBits.splice.apply(newBits, [pluralIdx, 1].concat(pluralString.bits));

                var _MessageFormatFormatt = _MessageFormat2.default.stringOut(new mfconv.ConversionString(pluralString.key, newBits));

                var _MessageFormatFormatt2 = _slicedToArray(_MessageFormatFormatt, 2);

                var key = _MessageFormatFormatt2[0];
                var str = _MessageFormatFormatt2[1];

                ele.ele('item', { quantity: key }, str);
            }
        } else {
            ele = _xmlbuilder2.default.create('string');

            var _MessageFormatFormatt3 = _MessageFormat2.default.stringOut(conversionString);

            var _MessageFormatFormatt4 = _slicedToArray(_MessageFormatFormatt3, 2);

            key = _MessageFormatFormatt4[0];
            str = _MessageFormatFormatt4[1];

            ele.att('name', key);
            ele.txt(str);
        }
        return ele.toString();
    },
    fileIn: function fileIn(fileStr) {
        var mfconv = require('../messageformat-converter');
        var parsed = null;
        xmlParse(fileStr, function (err, result) {
            return parsed = result;
        });

        if (Object.keys(parsed).length !== 1 || !(parsed.resources != null) || _util2.default.isArray(parsed.resources)) {
            throw new Error('Android XML files need to be a single <resources> block containing <string>s and <plurals>s');
        }

        // Need to do some XML denormalization because of ugly XML --> JS object conversion
        var resources = parsed.resources;

        var conversionStrings = [];

        var iterable = ['string', 'plurals'];
        for (var i = 0, type; i < iterable.length; i++) {
            type = iterable[i];
            if (resources[type] != null) {
                if (!_util2.default.isArray(resources[type])) {
                    resources[type] = [resources[type]];
                }
                for (var j = 0, str; j < resources[type].length; j++) {
                    str = resources[type][j];
                    var elem = {};
                    elem[type] = str;
                    conversionStrings.push(AndroidXmlFormatter.stringIn(elem));
                }
            }
        }
        return new mfconv.ConversionFile(conversionStrings);
    },
    fileOut: function fileOut(conversionFile) {
        var mfconv = require('../messageformat-converter');
        // For the raw XML strings that we're getting from stringOut, it's easier to use xml2js's
        // builder than a proper xmlBuilder interface.
        var builder = new _xml2js2.default.Builder();
        var resources = { $: { 'xmlns:messageformat': 'https://github.com/jivesoftware/messageformat-converter' }
        };
        for (var i = 0, conversionString; i < conversionFile.conversionStrings.length; i++) {
            conversionString = conversionFile.conversionStrings[i];
            var element = AndroidXmlFormatter.stringOut(conversionString);
            xmlParse(element, function (err, result) {
                if (typeof err !== "undefined" && err !== null) {
                    throw err;
                }
                return element = result;
            });
            var type = Object.keys(element)[0];
            if (!resources[type]) {
                resources[type] = [];
            }
            resources[type].push(element[type]);
        }
        return builder.buildObject({ resources: resources });
    }
};

module.exports = AndroidXmlFormatter;