import AndroidXmlFormatter from '../../src/format/AndroidXml';
import { expectXmlEqual } from '../testutil';

describe('AndroidXmlFormatter', () => {

    it('should exist', () => {
        return expect(AndroidXmlFormatter).not.toBeNull();
    });

    it('should handle regular string --> FormatString --> string', () => {
        var str = '<string name="LOGIN.PHOTO">Photo</string>';
        var result = AndroidXmlFormatter.stringOut(AndroidXmlFormatter.stringIn(str));
        return expectXmlEqual(result, str);
    });

    it('should handle plural string --> FormatString --> string', () => {
        var str = `<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
    <item quantity="one">{links} Helpful Link</item>
    <item quantity="other">{links} Helpful Links</item>
</plurals>`;
        var result = AndroidXmlFormatter.stringOut(AndroidXmlFormatter.stringIn(str));
        return expectXmlEqual(result, str);
    });

    it('should handle <purals> elements with only one <item>', () => {
        var str = `<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
    <item quantity="one">{links} Helpful Link</item>
</plurals>`;
        var result = AndroidXmlFormatter.stringOut(AndroidXmlFormatter.stringIn(str));
        return expectXmlEqual(result, str);
    });

    it('should handle entire files', () => {
        var str = '<resources xmlns:messageformat="https://github.com/jivesoftware/messageformat-converter">  <string name="DASHBOARD.WELCOME">Welcome to {community}</string>  <plurals messageformat:pluralkey="count" name="DASHBOARD.NOTIFICATIONS">    <item quantity="one">{count} notification</item>    <item quantity="other">{count} notifications</item>  </plurals></resources>';
        var result = AndroidXmlFormatter.fileOut(AndroidXmlFormatter.fileIn(str));
        return expectXmlEqual(result, str);
    });

    it('should handle files without plurals', () => {
        var str = '<resources xmlns:messageformat="https://github.com/jivesoftware/messageformat-converter"><string name="DASHBOARD.WELCOME">Arr, welcome to {community}</string></resources>';
        var result = AndroidXmlFormatter.fileOut(AndroidXmlFormatter.fileIn(str));
        return expectXmlEqual(result, str);
    });
});

