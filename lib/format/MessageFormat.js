'use strict';

var _slicedToArray = (function () { function sliceIterator(arr, i) { var _arr = []; var _n = true; var _d = false; var _e = undefined; try { for (var _i = arr[Symbol.iterator](), _s; !(_n = (_s = _i.next()).done); _n = true) { _arr.push(_s.value); if (i && _arr.length === i) break; } } catch (err) { _d = true; _e = err; } finally { try { if (!_n && _i["return"]) _i["return"](); } finally { if (_d) throw _e; } } return _arr; } return function (arr, i) { if (Array.isArray(arr)) { return arr; } else if (Symbol.iterator in Object(arr)) { return sliceIterator(arr, i); } else { throw new TypeError("Invalid attempt to destructure non-iterable instance"); } }; })();

var _messageformat = require('messageformat');

var _messageformat2 = _interopRequireDefault(_messageformat);

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var mf = new _messageformat2.default('en');
var mfutil = require('../util');

var MessageFormatFormatter = {

    // MessageFormat comes to us with keys and strings separate from each other, so this function
    // takes a [key, str] tuple.

    stringIn: function stringIn(_ref) {
        var _ref2 = _slicedToArray(_ref, 2);

        var key = _ref2[0];
        var str = _ref2[1];

        var _require = require('../messageformat-converter');

        var ConversionString = _require.ConversionString;
        var StringBit = _require.StringBit;
        var VariableBit = _require.VariableBit;
        var PluralBit = _require.PluralBit;

        var output = new ConversionString(key);

        // We're going to use this function to recurse plurals, so optionally parse the input string
        // into a messageFormat tree.
        var rootNode = str;

        if (typeof rootNode === 'string') {
            try {
                var parsed = mf.parse(rootNode);
                rootNode = parsed.program;
            } catch (e) {
                throw new Error('Hmm, this appears to not be a messageFormat string:', str, e);
            }
        }

        // First thing -- messageformat parses into a nested pattern tree for optimization purposes.
        // We only care about the leafs of that, so let's go ahead and traverse that tree.
        var leaves = [];
        var fringe = rootNode.statements;
        while (fringe.length > 0) {
            var thisNode = fringe.shift();
            if (thisNode.statements) {
                fringe = thisNode.statements.concat(fringe);
            } else {
                leaves.push(thisNode);
            }
        }

        this.strParts = [];
        // Cool. Now traverse and handle accordingly.
        for (var i = 0, leaf; i < leaves.length; i++) {

            // Case 1: basic string.
            leaf = leaves[i];
            if (leaf.type === 'string') {
                output.bits.push(new StringBit(leaf.val));
            } else if (leaf.type === 'messageFormatElement') {

                // Case 2: variable string.
                if (!(leaf.elementFormat != null)) {
                    output.bits.push(new VariableBit(leaf.argumentIndex));

                    // Case 3: plural stuff. (Or something else that will make us explode.)
                } else {
                        if (!(leaf.elementFormat.key === 'plural')) {
                            throw new Error('Unsupported format type: ' + leaf.elementFormat.key);
                        }
                        var pluralBit = new PluralBit(leaf.argumentIndex);
                        output.bits.push(pluralBit);
                        for (var j = 0, pluralForm; j < leaf.elementFormat.val.pluralForms.length; j++) {
                            pluralForm = leaf.elementFormat.val.pluralForms[j];
                            pluralBit.addMapping(MessageFormatFormatter.stringIn([pluralForm.key, pluralForm.val]));
                        }
                    }
            }
        }

        return output;
    },

    // Returns a [key, str] tuple.
    stringOut: function stringOut(conversionString) {
        var ret = '';
        for (var i = 0, bit; i < conversionString.bits.length; i++) {

            // StringBit
            bit = conversionString.bits[i];
            if (bit.type === 'string') {
                ret += bit.str;
            }

            // VariableBit
            if (bit.type === 'variable') {
                ret += '{' + bit.varName + '}';
            }

            // PluralBit
            if (bit.type === 'plural') {
                var innerStrings = [];
                for (var j = 0, pluralString; j < bit.pluralStrings.length; j++) {
                    pluralString = bit.pluralStrings[j];

                    var _MessageFormatFormatt = MessageFormatFormatter.stringOut(pluralString);

                    var _MessageFormatFormatt2 = _slicedToArray(_MessageFormatFormatt, 2);

                    var innerKey = _MessageFormatFormatt2[0];
                    var innerStr = _MessageFormatFormatt2[1];

                    innerStrings.push(innerKey + '{' + innerStr + '}');
                }
                ret += '{' + bit.pluralKey + ', plural, ' + innerStrings.join(' ') + '}';
            }
        }

        return [conversionString.key, ret];
    },
    fileIn: function fileIn(fileStr) {
        var _require2 = require('../messageformat-converter');

        var ConversionFile = _require2.ConversionFile;

        if (typeof fileStr === 'string') {
            var obj = JSON.parse(fileStr);
        }
        obj = mfutil.flatten(obj);
        var conversionStrings = (function () {
            var result = [];
            for (var key in obj) {
                var value = obj[key];
                result.push(MessageFormatFormatter.stringIn([key, value]));
            }
            return result;
        })();
        return new ConversionFile(conversionStrings);
    },
    fileOut: function fileOut(conversionFile) {
        var ret = {};
        for (var i = 0, conversionString; i < conversionFile.conversionStrings.length; i++) {
            conversionString = conversionFile.conversionStrings[i];

            var _MessageFormatFormatt3 = MessageFormatFormatter.stringOut(conversionString);

            var _MessageFormatFormatt4 = _slicedToArray(_MessageFormatFormatt3, 2);

            var key = _MessageFormatFormatt4[0];
            var value = _MessageFormatFormatt4[1];

            ret[key] = value;
        }
        return JSON.stringify(mfutil.unflatten(ret));
    }
};

module.exports = MessageFormatFormatter;