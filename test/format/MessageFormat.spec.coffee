
MessageFormatFormatter = require '../../src/format/MessageFormat'

describe 'MessageFormatFormatter', ->

    it 'should exist', ->
        expect(MessageFormatFormatter).not.toBeNull()

    it 'should handle regular string --> FormatString --> string', ->
        tuple = ['LOGIN.WELCOME', 'Welcome to our community!']
        result = MessageFormatFormatter.stringOut MessageFormatFormatter.stringIn tuple
        expect(result).toEqual(tuple)

    it 'should handle plural string --> FormatString --> string', ->
        key = 'LINKS.COUNT'
        str = '{links, plural, 1{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}'
        tuple = [key, str]
        result = MessageFormatFormatter.stringOut MessageFormatFormatter.stringIn tuple
        expect(result).toEqual(tuple)

    it 'should handle a file', ->
        file =
            'LINKS': 
                'COUNT': '{links, plural, 1{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}'
                'GREAT': 'Links are great!'
            'OTHERSTUFF': 'hi'
        file = JSON.stringify file
        result = MessageFormatFormatter.fileOut MessageFormatFormatter.fileIn file
        expect(result).toEqual(file)
