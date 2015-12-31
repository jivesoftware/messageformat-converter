
var MessageFormatFormatter = require('../../src/format/MessageFormat');

describe('MessageFormatFormatter', function() {

    it('should exist', function() {
        return expect(MessageFormatFormatter).not.toBeNull();
    });

    it('should handle regular string --> FormatString --> string', function() {
        var tuple = ['LOGIN.WELCOME', 'Welcome to our community!'];
        var result = MessageFormatFormatter.stringOut(MessageFormatFormatter.stringIn(tuple));
        return expect(result).toEqual(tuple);
    });

    it('should handle plural string --> FormatString --> string', function() {
        var key = 'LINKS.COUNT';
        var str = '{links, plural, 1{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}';
        var tuple = [key, str];
        var result = MessageFormatFormatter.stringOut(MessageFormatFormatter.stringIn(tuple));
        return expect(result).toEqual(tuple);
    });

    return it('should handle a file', function() {
        var file =
            {'LINKS': 
                {'COUNT': '{links, plural, 1{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}',
                'GREAT': 'Links are great!'
                },
            'OTHERSTUFF': 'hi'
            };
        file = JSON.stringify(file);
        var result = MessageFormatFormatter.fileOut(MessageFormatFormatter.fileIn(file));
        return expect(result).toEqual(file);
    });
});
