import MessageFormat from 'messageformat';

var mf = new MessageFormat('en');
var mfutil = require('../util');

var MessageFormatFormatter = {

    // MessageFormat comes to us with keys and strings separate from each other, so this function
    // takes a [key, str] tuple.
    stringIn([key, str]) {
        const { ConversionString, StringBit, VariableBit, PluralBit } = require('../messageformat-converter');
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
    stringOut(conversionString) {
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
                    var [innerKey, innerStr] = MessageFormatFormatter.stringOut(pluralString);
                    innerStrings.push(`${innerKey}{${innerStr}}`);
                }
                ret += `{${bit.pluralKey}, plural, ${innerStrings.join(' ')}}`;
            }
        }

        return [conversionString.key, ret];
    },

    fileIn(fileStr) {
        const { ConversionFile } = require('../messageformat-converter');
        if (typeof fileStr === 'string') { var obj = JSON.parse(fileStr); }
        obj = mfutil.flatten(obj);
        var conversionStrings = ((() => {
            var result = [];
            for (var key in obj) {
                var value = obj[key];
                result.push(MessageFormatFormatter.stringIn([key, value]));
            }
            return result;
        })());
        return new ConversionFile(conversionStrings);
    },

    fileOut(conversionFile) {
        var ret = {};
        for (var i = 0, conversionString; i < conversionFile.conversionStrings.length; i++) {
            conversionString = conversionFile.conversionStrings[i];
            var [key, value] = MessageFormatFormatter.stringOut(conversionString);
            ret[key] = value;
        }
        return JSON.stringify(mfutil.unflatten(ret));
    }
};

module.exports = MessageFormatFormatter;
