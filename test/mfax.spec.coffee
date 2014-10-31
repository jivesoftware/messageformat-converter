
mfconv = require '../lib/messageformat-converter'

# Simple way to see if two XML strings are equivelent: pipe through xml2js then use jasmine's .isEqual.
xmlParse = (require 'xml2js').Parser().parseString

# Helper for comparing two XML strings.
expectXmlEqual = (expectedStr, actualStr, done) ->
    xmlParse expectedStr, (err, expected) ->
        xmlParse actualStr, (err, actual) ->
            expect(actual).toEqual(expected)
            done()

xdescribe 'mfconv', ->

    it 'should exist', ->
        expect(mfconv).not.toBeNull()

    describe 'toXml', ->
        it 'should handle basic strings', (done) ->
            expected = '<string name="LOGIN.PHOTO">Photo</string>'
            actual = mfconv.toXml 'LOGIN.PHOTO', 'Photo'
            compareXml expected, actual, done

        it 'should handle plural strings', (done) ->
            expected = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">{links} Helpful Link</item>
                <item quantity="other">{links} Helpful Links</item>
            </plurals>'
            actual = mfconv.toXml 'LOGIN.HELPFUL_LINKS', '{links} Helpful {links, plural, 1{Link} other{Links}}'
            compareXml expected, actual, done

        it 'should handle complicated plural strings', (done) ->
            expected = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">There is one helpful link for you, {name}!</item>
                <item quantity="other">There are {links} helpful links for you, {name}!</item>
                </plurals>'
            actual = mfconv.toXml 'LOGIN.HELPFUL_LINKS', 'There {links, plural, 1{is one helpful link} other{are {links} helpful links}} for you, {name}!'
            compareXml expected, actual, done

        it 'should handle entire files', (done) ->
            expected = '<?xml version="1.0" encoding="utf-8"?>
                <resources>
                    <string name="LOGIN.PREFERENCES">Login Preferences</string>
                    <string name="LOGIN.USER">Username</string>
                    <string name="LOGIN.PASSWORD">Password</string>
                    <string name="LOGIN.PHOTO">Photo</string>
                    <string name="LOGIN.VIDEO">Video</string>
                    <string name="LINKS.CURRENTLYONLINE">There are currently {num} users online on the community {community}</string>
                    <plurals messageformat:pluralkey="links" name="LINKS.HELPFUL_LINKS">
                        <item quantity="one">There is one helpful link for you, {name}!</item>
                        <item quantity="other">There are {links} helpful links for you, {name}!</item>
                    </plurals>
                </resources>'
            actual = mfconv.toXml
                LOGIN:
                    PREFERENCES: 'Login Preferences'
                    USER: 'Username'
                    PASSWORD: 'Password'
                    PHOTO: 'Photo'
                    VIDEO: 'Video'
                LINKS:
                    CURRENTLYONLINE: 'There are currently {num} users online on the community {community}'
                    HELPFUL_LINKS: 'There {links, plural, 1{is one helpful link} other{are {links} helpful links}} for you, {name}!'
            compareXml expected, actual, done

    describe 'toMessageFormat', ->
        it 'should handle de-XMLing one string', ->
            expected =
                LOGIN:
                    USER: 'Username'
            actual = mfconv.toMessageFormat '<string name="LOGIN.USER">Username</string>'
            expect(actual).toEqual(expected)

        it 'should handle de-XMLing an entire file', ->
            expected =
                LOGIN:
                    PREFERENCES: 'Login Preferences'
                    USER: 'Username'
                    PASSWORD: 'Password'
                    PHOTO: 'Photo'
                    VIDEO: 'Video'
                LINKS:
                    CURRENTLYONLINE: 'There are currently {num} users online on the community {community}'
                    HELPFUL_LINKS: '{links, plural, 1{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}'
            actual = mfconv.toMessageFormat '<?xml version="1.0" encoding="utf-8"?>
                <resources>
                    <string name="LOGIN.PREFERENCES">Login Preferences</string>
                    <string name="LOGIN.USER">Username</string>
                    <string name="LOGIN.PASSWORD">Password</string>
                    <string name="LOGIN.PHOTO">Photo</string>
                    <string name="LOGIN.VIDEO">Video</string>
                    <string name="LINKS.CURRENTLYONLINE">There are currently {num} users online on the community {community}</string>
                    <plurals messageformat:pluralkey="links" name="LINKS.HELPFUL_LINKS">
                        <item quantity="one">There is one helpful link for you, {name}!</item>
                        <item quantity="other">There are {links} helpful links for you, {name}!</item>
                    </plurals>
                </resources>'
            expect(actual).toEqual(expected)

    describe 'back and forth', ->
        it 'should handle messageFormat --> XML --> messageFormat', ->
            messageFormat =
                LOGIN:
                    PREFERENCES: 'Login Preferences'
                    USER: 'Username'
                    PASSWORD: 'Password'
                    PHOTO: 'Photo'
                    VIDEO: 'Video'
                LINKS:
                    CURRENTLYONLINE: 'There are currently {num} users online on the community {community}'
                    HELPFUL_LINKS: '{links, plural, 1{There is one helpful link for you, {name}!} other{There are {links} helpful links for you, {name}!}}'
            xml = mfconv.toXml messageFormat
            result = mfconv.toMessageFormat xml
            expect(result).toEqual(messageFormat)

        it 'should handle XML --> messageFormat --> XML', (done) ->
            xml = '<?xml version="1.0" encoding="utf-8"?>
                <resources>
                    <string name="LOGIN.PREFERENCES">Login Preferences</string>
                    <string name="LOGIN.USER">Username</string>
                    <string name="LOGIN.PASSWORD">Password</string>
                    <string name="LOGIN.PHOTO">Photo</string>
                    <string name="LOGIN.VIDEO">Video</string>
                    <string name="LINKS.CURRENTLYONLINE">There are currently {num} users online on the community {community}</string>
                    <plurals messageformat:pluralkey="links" name="LINKS.HELPFUL_LINKS">
                        <item quantity="one">There is one helpful link for you, {name}!</item>
                        <item quantity="other">There are {links} helpful links for you, {name}!</item>
                    </plurals>
                </resources>'
            messageFormat = mfconv.toMessageFormat xml
            result = mfconv.toXml messageFormat
            compareXml xml, result, done
