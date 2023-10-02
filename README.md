# apple_tax.sh

This is a shellscript for signing, notarizing, and stapling an application on macOS.

To use this you need:

1. an Apple developer account
2. a code-signing certificate from Apple

I won't go into how to get all that - there are plenty of sites for that.

What wasn't clear to me, however, was how to do all this on the command line without using XCode. A lot of information online (including Apple's) was out-of-date or incomplete.

So hopefully this will be a useful reference for people who must pay Apple's extortion fees and jump through their hoops in order to avoid scary dialogs when running their applications.

## How To Use

1. You will need to set `SIGNING_ID` in the script to your signing ID. This is the one which looks like:

   ```
   Developer ID Application: COMPANY (TEAM_ID)
   ```

   (I could have made this an argument to the script, but for me it won't change.)

2. For the next step, you need an "application specific" password from Apple. See:

   https://support.apple.com/en-us/102654

   I just named mine "notarytool" since that's the executable which needs it.

3. Add credentials to your keychain for the notarytool executable:

   ```
   xcrun notarytool store-credentials "notarytool"
                 --apple-id <apple id>
                 --team-id <team id>
                 --password <2FA_password>
   ```

4. Run the script on your application like this: `./apple_tax.sh MyApp.app`

   You should see something like this:

   ```
   Application: /path/to/MyApp.app
   ** Signing: /path/to/MyApp.app
   ** Verifying: /path/to/MyApp.app
   Executable=/path/to/MyApp.app/Contents/MacOS/MyApp
   Identifier=MyApp
   [...other stuff...]

   \*\* Notarizing: /path/to/MyApp.app.zip
   [16:48:22.242Z] Debug [MAIN] Running notarytool version: 1.0.0 (27), date: 2023-10-02T16:48:22Z, command: /Applications/Xcode.app/Contents/Developer/usr/bin/notarytool submit /path/to/MyApp.app.zip --keychain-profile notarytool --verbose --wait
   Conducting pre-submission checks for MyApp.app.zip and initiating connection to the Apple notary service...
   [16:48:22.254Z] Debug [PREFLIGHT] MyApp.app.zip is a zip archive.

   [...it will poll & wait on the "notarization" to finish...]

   [16:55:48.168Z] Info [API] Submission in terminal status: Accepted
   Processing complete
     id: SOME-ID
     status: Accepted
   ```

   If notarization fails, you can use the following command to write the errors to a JSON file (where `SOME-ID` comes from the processing result):

   ```
   xcrun notarytool log SOME-ID --keychain-profile "notarytool" error.json
   ```

### Entitlements

I'm not currently using entitlements, so that path is untested, but if you want to try it, pass them in on the command line like this:

```
./apple_tax.sh MyApp.app entitlements.plist
```
