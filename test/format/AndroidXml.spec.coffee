
AndroidXmlFormatter = require '../../lib/format/AndroidXml'
expectXmlEqual      = (require '../testutil').expectXmlEqual

describe 'AndroidXmlFormatter', ->

    it 'should exist', ->
        expect(AndroidXmlFormatter).not.toBeNull()

    it 'should handle regular string --> FormatString --> string', ->
        str = '<string name="LOGIN.PHOTO">Photo</string>'
        result = AndroidXmlFormatter.out AndroidXmlFormatter.in str
        expectXmlEqual(result, str)

    it 'should handle plural string --> FormatString --> string', ->
        str = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">{links} Helpful Link</item>
                <item quantity="other">{links} Helpful Links</item>
            </plurals>'
        result = AndroidXmlFormatter.out AndroidXmlFormatter.in str
        expectXmlEqual(result, str)

    it 'should handle <purals> elements with only one <item>', ->
        str = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">{links} Helpful Link</item>
            </plurals>'
        result = AndroidXmlFormatter.out AndroidXmlFormatter.in str
        expectXmlEqual(result, str)
