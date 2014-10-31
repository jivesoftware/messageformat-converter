
AndroidXmlFormatter    = require '../../lib/format/AndroidXml'
MessageFormatFormatter = require '../../lib/format/MessageFormat'
expectXmlEqual         = (require '../testutil').expectXmlEqual

describe 'integration tests', ->

    it 'should handle messageFormat --> XML --> messageFormat', ->
        expected = ['LOGIN.HELPFUL_LINKS', '{links, plural, 1{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}']
        actual = MessageFormatFormatter.out AndroidXmlFormatter.in AndroidXmlFormatter.out MessageFormatFormatter.in expected
        expect(actual).toEqual(expected)

    it 'should handle XML --> messageFormat --> XML', ->
        expected = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">{links} Helpful Link</item>
                <item quantity="other">{links} Helpful Links</item>
            </plurals>'
        actual = AndroidXmlFormatter.out MessageFormatFormatter.in MessageFormatFormatter.out AndroidXmlFormatter.in expected
        expectXmlEqual(actual, expected)
