
convertString  = (require '../lib/messageformat-converter').convertString
expectXmlEqual = (require './testutil').expectXmlEqual

describe 'integration tests', ->

    describe 'string conversion', ->

        it 'should handle messageFormat --> XML --> messageFormat', ->
            expected = ['LOGIN.HELPFUL_LINKS', '{links, plural, one{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}']
            xml = convertString(expected).from('MESSAGEFORMAT').to('ANDROID-XML')
            expectXmlEqual xml, '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS"><item quantity="one">There is one helpful link for you, {name}!</item><item quantity="other">There are {links} helpful links for you, {name}!</item></plurals>'
            actual = convertString(xml).from('ANDROID-XML').to('MESSAGEFORMAT')
            expect(actual).toEqual(expected)
