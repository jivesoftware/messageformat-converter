
mfax = require '../lib/mfax'

# Simple way to see if two XML strings are equivelent: pipe through xml2js then use jasmine's .isEqual.
xmlParse = (require 'xml2js').Parser().parseString

# Helper for comparing two XML strings.
compareXml = (expectedStr, actualStr, done) ->
    xmlParse expectedStr, (err, expected) ->
        xmlParse actualStr, (err, actual) ->
            expect(actual).toEqual(expected)
            done()

describe 'mfax', ->

    it 'should exist', ->
        expect(mfax).not.toBeNull()

    describe 'toXml', ->
        it 'should handle basic strings', (done) ->
            expected = '<string name="LOGIN.PHOTO">Photo</string>'
            actual = mfax.toXml 'LOGIN.PHOTO', 'Photo'
            compareXml expected, actual, done

        it 'should handle plural strings', (done) ->
            expected = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">{links} Helpful Link</item>
                <item quantity="other">{links} Helpful Links</item>
            </plurals>'
            actual = mfax.toXml 'LOGIN.HELPFUL_LINKS', '{links} Helpful {links, plural, 1{Link} other{Links}}'
            compareXml expected, actual, done

        it 'should handle complicated plural strings', (done) ->
            expected = '<plurals messageformat:pluralkey="links" name="LOGIN.HELPFUL_LINKS">
                <item quantity="one">There is one helpful link for you, {name}!</item>
                <item quantity="other">There are {links} helpful links for you, {name}!</item>
                </plurals>'
            actual = mfax.toXml 'LOGIN.HELPFUL_LINKS', 'There {links, plural, 1{is one helpful link} other{are {links} helpful links}} for you, {name}!'
            compareXml expected, actual, done

        it 'should handle entire files', (done) ->
            expected = '<?xml version="1.0" encoding="utf-8"?>
                <resources>
                    <string name="LOGIN.PREFERENCES">Login Preferences</string>
                    <!-- The name used to login on the site -->
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
            actual = mfax.toXml
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
