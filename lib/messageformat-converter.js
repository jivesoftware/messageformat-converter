'use strict';

var _createClass = (function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; })(); //
// Main library file. Handles turning thing into other thing.
//

var _xml2js = require('xml2js');

var _xml2js2 = _interopRequireDefault(_xml2js);

var _xmlbuilder = require('xmlbuilder');

var _xmlbuilder2 = _interopRequireDefault(_xmlbuilder);

var _util = require('util');

var _util2 = _interopRequireDefault(_util);

var _messageformat = require('messageformat');

var _messageformat2 = _interopRequireDefault(_messageformat);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

var mfconv = {
    formatters: {
        'MESSAGEFORMAT': require('./format/MessageFormat'),
        'ANDROID-XML': require('./format/AndroidXml'),
        'SMARTLING-ANDROID-XML': require('./format/SmartlingAndroidXml')
    },

    convertString: function convertString(startingData) {
        return new mfconv.StringConverter(startingData);
    },

    convertFile: function convertFile(startingData) {
        return new mfconv.FileConverter(startingData);
    },

    StringConverter: (function () {
        function StringConverter(startingData) {
            _classCallCheck(this, StringConverter);

            this.startingData = startingData;
        }

        _createClass(StringConverter, [{
            key: 'from',
            value: function from(format) {
                if (!mfconv.formatters[format]) {
                    throw new Error('Unknown format: ' + format);
                }

                return mfconv.formatters[format].stringIn(this.startingData);
            }
        }]);

        return StringConverter;
    })(),

    FileConverter: (function () {
        function FileConverter(fileData) {
            _classCallCheck(this, FileConverter);

            this.fileData = fileData;
        }

        _createClass(FileConverter, [{
            key: 'from',
            value: function from(format) {
                if (!mfconv.formatters[format]) {
                    throw new Error('Unknown format: ' + format);
                }

                return mfconv.formatters[format].fileIn(this.fileData);
            }
        }]);

        return FileConverter;
    })(),

    // In a gross oversimplification of messageFormat, `ConversionString`s are comprised of lists of
    // different kinds of "bits"
    ConversionString: (function () {
        function ConversionString(key) {
            var bits = arguments.length <= 1 || arguments[1] === undefined ? [] : arguments[1];

            _classCallCheck(this, ConversionString);

            this.key = key;
            this.bits = bits;
        }

        _createClass(ConversionString, [{
            key: 'to',
            value: function to(format) {
                if (!mfconv.formatters[format]) {
                    throw new Error('Unknown format: ' + format);
                }
                return mfconv.formatters[format].stringOut(this);
            }
        }]);

        return ConversionString;
    })(),

    ConversionFile: (function () {
        function ConversionFile(conversionStrings) {
            _classCallCheck(this, ConversionFile);

            this.conversionStrings = conversionStrings;
        }

        _createClass(ConversionFile, [{
            key: 'to',
            value: function to(format) {
                if (!mfconv.formatters[format]) {
                    throw new Error('Unknown format: ' + format);
                }

                return mfconv.formatters[format].fileOut(this);
            }
        }]);

        return ConversionFile;
    })(),

    // Just a boring ol' string.
    StringBit: function StringBit(str) {
        _classCallCheck(this, StringBit);

        this.type = 'string';

        this.str = str;
    },

    // Just a boring ol' {variable}
    VariableBit: function VariableBit(varName) {
        _classCallCheck(this, VariableBit);

        this.type = 'variable';

        this.varName = varName;
    },

    // Plurals take a mapping of messageFormat plural keys to translation strings.
    PluralBit: (function () {
        function PluralBit(pluralKey) {
            _classCallCheck(this, PluralBit);

            this.type = 'plural';

            this.pluralKey = pluralKey;
            this.pluralStrings = [];
        }

        _createClass(PluralBit, [{
            key: 'addMapping',
            value: function addMapping(pluralString) {
                this.pluralStrings.push(pluralString);
            }
        }]);

        return PluralBit;
    })()
};

module.exports = mfconv;