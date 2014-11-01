
convertString  = (require '../src/messageformat-converter').convertString
convertFile    = (require '../src/messageformat-converter').convertFile
expectXmlEqual = (require './testutil').expectXmlEqual

describe 'integration tests', ->

    describe 'string conversion', ->

        it 'should handle messageFormat --> XML --> messageFormat', ->
            expected = ['LOGIN.HELPFUL_LINKS', '{links, plural, one{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}']
            xml = convertString(expected).from('MESSAGEFORMAT').to('ANDROID-XML')
            expectXmlEqual xml, '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS"><item quantity="one">There is one helpful link for you, {name}!</item><item quantity="other">There are {links} helpful links for you, {name}!</item></plurals>'
            actual = convertString(xml).from('ANDROID-XML').to('MESSAGEFORMAT')
            expect(actual).toEqual(expected)

        it 'should convert files from messageFormat JSON to Android XML', ->
            jsonFile = '{"DASHBOARD":{"WELCOME":"Welcome to {community}","NOTIFICATIONS":"{count, plural, one{{count} notification} other{{count} notifications}}"}}'
            expected = '<resources xmlns:messageformat="">  <string name="DASHBOARD.WELCOME">Welcome to {community}</string>  <plurals messageformat:pluralkey="count" name="DASHBOARD.NOTIFICATIONS">    <item quantity="one">{count} notification</item>    <item quantity="other">{count} notifications</item>  </plurals></resources>'
            actual = convertFile(jsonFile).from('MESSAGEFORMAT').to('ANDROID-XML')
            expectXmlEqual(actual, expected)

        it 'should convert files from Android XML to messageFormat JSON', ->
            expected = {"DASHBOARD":{"WELCOME":"Welcome to {community}","NOTIFICATIONS":"{count, plural, one{{count} notification} other{{count} notifications}}"}}
            xml = '<resources xmlns:messageformat="">  <string name="DASHBOARD.WELCOME">Welcome to {community}</string>  <plurals messageformat:pluralkey="count" name="DASHBOARD.NOTIFICATIONS">    <item quantity="one">{count} notification</item>    <item quantity="other">{count} notifications</item>  </plurals></resources>'
            actual = JSON.parse convertFile(xml).from('ANDROID-XML').to('MESSAGEFORMAT')
            expect(actual).toEqual(expected)
