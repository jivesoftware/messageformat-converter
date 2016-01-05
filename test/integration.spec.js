import { convertString, convertFile } from '../src/messageformat-converter';
var expectXmlEqual = (require('./testutil')).expectXmlEqual;

describe('integration tests', () => {

    describe('string conversion', () => {

        xit('should handle messageFormat --> XML --> messageFormat', function() {
            var expected = ['LOGIN.HELPFUL_LINKS', '{links, plural, one{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}'];
            var xml = convertString(expected).from('MESSAGEFORMAT').to('ANDROID-XML');
            expectXmlEqual(xml, '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS"><item quantity="one">There is one helpful link for you, {name}!</item><item quantity="other">There are {links} helpful links for you, {name}!</item></plurals>');
            var actual = convertString(xml).from('ANDROID-XML').to('MESSAGEFORMAT');
            return expect(actual).toEqual(expected);
        });

        xit('should convert files from messageFormat JSON to Android XML', () => {
            var jsonFile = '{"DASHBOARD":{"WELCOME":"Welcome to {community}","NOTIFICATIONS":"{count, plural, one{{count} notification} other{{count} notifications}}"}}';
            var actual = convertFile(jsonFile).from('MESSAGEFORMAT').to('ANDROID-XML');
            return expectXmlEqual(actual, expected);
        });

        it('should convert files from messageFormat JSON to Smartling Android XML', () => {
            var jsonFile = '{"DASHBOARD":{"WELCOME":"{firstname}, welcome to {community}","NOTIFICATIONS":"{count, plural, one{# notification} other{# notifications}}"}}';
            var expected = '<resources xmlns:messageformat="https://github.com/jivesoftware/messageformat-converter">  <string name="DASHBOARD_WELCOME" messageformat:keys="firstname,community">%1$s, welcome to %2$s</string>  <plurals messageformat:pluralkey="count" name="DASHBOARD_NOTIFICATIONS">    <item quantity="one">%d notification</item>    <item quantity="other">%d notifications</item>  </plurals></resources>';
            var actual = convertFile(jsonFile).from('MESSAGEFORMAT').to('SMARTLING-ANDROID-XML');
            return expectXmlEqual(actual, expected);
        });

        it('should convert files from Android XML to messageFormat JSON', () => {
            var expected = {"DASHBOARD":{"WELCOME":"Welcome to {community}","NOTIFICATIONS":"{count, plural, one{{count} notification} other{{count} notifications}}"}};
            var xml = '<resources xmlns:messageformat="https://github.com/jivesoftware/messageformat-converter">  <string name="DASHBOARD.WELCOME">Welcome to {community}</string>  <plurals messageformat:pluralkey="count" name="DASHBOARD.NOTIFICATIONS">    <item quantity="one">{count} notification</item>    <item quantity="other">{count} notifications</item>  </plurals></resources>';
            var actual = JSON.parse(convertFile(xml).from('ANDROID-XML').to('MESSAGEFORMAT'));
            return expect(actual).toEqual(expected);
        });

        it('should convert files from Smartling Android XML to messageFormat JSON', () => {
            var expected = {"DASHBOARD":{"WELCOME":"{firstname}, welcome to {community}","NOTIFICATIONS":"{count, plural, one{# notification} other{# notifications}}"}};
            var xml = '<resources xmlns:messageformat="https://github.com/jivesoftware/messageformat-converter">  <string name="DASHBOARD_WELCOME" messageformat:keys="firstname,community">%1$s, welcome to %2$s</string>  <plurals messageformat:pluralkey="count" name="DASHBOARD_NOTIFICATIONS">    <item quantity="one">%d notification</item>    <item quantity="other">%d notifications</item>  </plurals></resources>';
            var actual = JSON.parse(convertFile(xml).from('SMARTLING-ANDROID-XML').to('MESSAGEFORMAT'));
            return expect(actual).toEqual(expected);
        });
    });
});
