//
// Main library file. Handles turning thing into other thing.
//

import xml2js from 'xml2js';
import xmlBuilder from 'xmlbuilder';
import util from 'util';
import MessageFormat from 'messageformat';

var mfconv = {
    formatters: {
        'MESSAGEFORMAT': require('./format/MessageFormat'),
        'ANDROID-XML': require('./format/AndroidXml')
    },

    convertString: startingData => new mfconv.StringConverter(startingData),

    convertFile: startingData => new mfconv.FileConverter(startingData),

    StringConverter: class {
        constructor(startingData) {
            this.startingData = startingData;
        }

        from(format) {
            if (!mfconv.formatters[format]) {
                throw new Error(`Unknown format: ${format}`);
            }

            return mfconv.formatters[format].stringIn(this.startingData);
        }
    },

    FileConverter: class {
        constructor(fileData) {
            this.fileData = fileData;
        }

        from(format) {
            if (!mfconv.formatters[format]) {
                throw new Error(`Unknown format: ${format}`);
            }

            return mfconv.formatters[format].fileIn(this.fileData);
        }
    },

    // In a gross oversimplification of messageFormat, `ConversionString`s are comprised of lists of
    // different kinds of "bits"
    ConversionString: class {
        constructor(key, bits = []) {
            this.key = key;
            this.bits = bits;
        }

        to(format) {
            if (!mfconv.formatters[format]) {
                throw new Error(`Unknown format: ${format}`);
            }
            return mfconv.formatters[format].stringOut(this);
        }
    },

    ConversionFile: class {
        constructor(conversionStrings) {
            this.conversionStrings = conversionStrings;
        }

        to(format) {
            if (!mfconv.formatters[format]) {
                throw new Error(`Unknown format: ${format}`);
            }

            return mfconv.formatters[format].fileOut(this);
        }
    },

    // Just a boring ol' string.
    StringBit: class {
        type = 'string';

        constructor(str) {
            this.str = str;
        }
    },

    // Just a boring ol' {variable}
    VariableBit: class {
        type = 'variable';

        constructor(varName) {
            this.varName = varName;
        }
    },

    // Plurals take a mapping of messageFormat plural keys to translation strings.
    PluralBit: class {
        type = 'plural';

        constructor(pluralKey) {
            this.pluralKey = pluralKey;
            this.pluralStrings = [];
        }

        addMapping(pluralString) {
            this.pluralStrings.push(pluralString);
        }
    }
};

module.exports = mfconv;