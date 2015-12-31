module.exports = {
    // Helper to turn {"FOO": {"BAR": "Eli", "BAZ": "Mallon"}} into {"FOO.BAR": "Eli", "FOO.BAZ": "Mallon"}
    flatten(obj, base = []) {
        var ret = {};
        for (var key in obj) {
            var value = obj[key];
            if (typeof value === 'object') {
                var iterable;
                for (var k in (iterable = module.exports.flatten(value, base.concat([key])))) {
                    var v = iterable[k];
                    ret[k] = v;
                }
            } else {
                var newKey = (base.concat([key])).join('.');
                ret[newKey] = value;
            }
        }
        return ret;
    },

    // Helper to do the opposite of _flatten
    unflatten(obj) {
        var ret = {};
        for (var k in obj) {
            var v = obj[k];
            var root = ret;
            var split = k.split('.');
            var finalBit = split.pop();
            for (var i = 0, bit; i < split.length; i++) {
                bit = split[i];
                if (!root[bit]) {
                    root[bit] = {};
                }
                root = root[bit];
            }
            root[finalBit] = v;
        }
        return ret;
    }
};
