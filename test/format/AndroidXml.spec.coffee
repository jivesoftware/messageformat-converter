
AndroidXmlFormatter = require '../../src/format/AndroidXml'
expectXmlEqual      = (require '../testutil').expectXmlEqual

describe 'AndroidXmlFormatter', ->

    it 'should exist', ->
        expect(AndroidXmlFormatter).not.toBeNull()

    it 'should handle regular string --> FormatString --> string', ->
        str = '<string name="LOGIN.PHOTO">Photo</string>'
        result = AndroidXmlFormatter.stringOut AndroidXmlFormatter.stringIn str
        expectXmlEqual(result, str)

    it 'should handle plural string --> FormatString --> string', ->
        str = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">{links} Helpful Link</item>
                <item quantity="other">{links} Helpful Links</item>
            </plurals>'
        result = AndroidXmlFormatter.stringOut AndroidXmlFormatter.stringIn str
        expectXmlEqual(result, str)

    it 'should handle <purals> elements with only one <item>', ->
        str = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">{links} Helpful Link</item>
            </plurals>'
        result = AndroidXmlFormatter.stringOut AndroidXmlFormatter.stringIn str
        expectXmlEqual(result, str)

    it 'should handle entire files', ->
        str = '<resources xmlns:messageformat="https://github.com/ActiveBuilding/messageformat-converter">  <string name="DASHBOARD.WELCOME">Welcome to {community}</string>  <plurals messageformat:pluralkey="count" name="DASHBOARD.NOTIFICATIONS">    <item quantity="one">{count} notification</item>    <item quantity="other">{count} notifications</item>  </plurals></resources>'
        result = AndroidXmlFormatter.fileOut AndroidXmlFormatter.fileIn str
        expectXmlEqual(result, str)

    it 'should handle files without plurals', ->
        str = '<resources xmlns:messageformat="https://github.com/ActiveBuilding/messageformat-converter"><string name="DASHBOARD.WELCOME">Arr, welcome to {community}</string></resources>'
        result = AndroidXmlFormatter.fileOut AndroidXmlFormatter.fileIn str
        expectXmlEqual(result, str)

