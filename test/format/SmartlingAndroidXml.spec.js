import SmartlingAndroidXmlFormatter from '../../src/format/SmartlingAndroidXml';
import { expectXmlEqual } from '../testutil';

describe('SmartlingAndroidXmlFormatter', () => {

    it('should exist', () => {
        return expect(SmartlingAndroidXmlFormatter).not.toBeNull();
    });

    it('should handle regular string --> FormatString --> string', () => {
        var str = '<string name="login_photo">Photo</string>';
        var result = SmartlingAndroidXmlFormatter.stringOut(SmartlingAndroidXmlFormatter.stringIn(str));
        return expectXmlEqual(result, str);
    });

    it('should handle plural string --> FormatString --> string', () => {
        var str = `<plurals messageformat:pluralkey="count" name="login_helpful__links">
    <item quantity="one">%d Helpful Link</item>
    <item quantity="other">%d Helpful Links</item>
</plurals>`;
        var result = SmartlingAndroidXmlFormatter.stringOut(SmartlingAndroidXmlFormatter.stringIn(str));
        return expectXmlEqual(result, str);
    });

    it('should handle <purals> elements with only one <item>', () => {
        var str = `<plurals messageformat:pluralkey="count" name="login_helpful__links">
    <item quantity="one">%d Helpful Link</item>
</plurals>`;
        var result = SmartlingAndroidXmlFormatter.stringOut(SmartlingAndroidXmlFormatter.stringIn(str));
        return expectXmlEqual(result, str);
    });

    it('should handle entire files', () => {
        var str = '<resources xmlns:messageformat="https://github.com/jivesoftware/messageformat-converter">  <string name="dashboard_welcome" messageformat:keys="community">Welcome to %1$s</string>  <plurals messageformat:pluralkey="count" name="dashboard_notifications">    <item quantity="one">%d notification</item>    <item quantity="other">%d notifications</item>  </plurals></resources>';
        var result = SmartlingAndroidXmlFormatter.fileOut(SmartlingAndroidXmlFormatter.fileIn(str));
        return expectXmlEqual(result, str);
    });

    return it('should handle files without plurals', () => {
        var str = '<resources xmlns:messageformat="https://github.com/jivesoftware/messageformat-converter"><string name="dashboard_welcome" messageformat:keys="community">Arr, welcome to %1$s</string></resources>';
        var result = SmartlingAndroidXmlFormatter.fileOut(SmartlingAndroidXmlFormatter.fileIn(str));
        return expectXmlEqual(result, str);
    });
});

