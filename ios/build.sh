#!/bin/bash
#
# This script should be launched by root dir's build script.
#
if [ "x$BUILD_IOS" = "xYES" ]; then

    echo -e "${T_BOLD}[BUILD] build/ios${T_RESET}"

    CORDOVA="$LIBS_PATH/cordova/bin/cordova"
    function CORDOVA() {
        PROJECT_PATH= "$CORDOVA" $@
    }
    IOS_PROJECT_PATH="$PROJECT_PATH/build/ios/$PROJECT_NAME"

    if [ "x$conf" = "xwww" ] && test -e "$IOS_PROJECT_PATH"; then
        echo "UNSUPPORTED"
        # Only rebuild www
        # rsync -a build/www/ "$IOS_PROJECT_PATH/www"
        exit 1
    fi

    rm -fr "$PROJECT_PATH/build/ios"
    mkdir -p "$IOS_PROJECT_PATH"

    # Create iOS Project
    log "$CORDOVA" create "$IOS_PROJECT_PATH" "$IOS_BUNDLE_ID" "$PROJECT_NAME"
    CORDOVA create "$IOS_PROJECT_PATH" "$IOS_BUNDLE_ID" "$PROJECT_NAME"

    # Install Cordova Plugins.
    cd "$IOS_PROJECT_PATH"
    log "$CORDOVA" platform add ios
    CORDOVA platform add ios || bash

    # TODO: Some should not be installed for final distribution.
    # INSTALL CDV TestFlight"

    function plugin {
        pname="$1"
        ppath="$2"

        if [ "x${ppath:3:1}" = "x:" ] || [ "x${ppath:4:1}" = "x:" ] || [ "x${ppath:5:1}" = "x:" ]; then
            CORDOVA plugin add "$ppath" || error "Failed to install plugin: $pname"
        else
            CORDOVA plugin add "$DOWNLOADS_PATH$ppath/$pname" || error "Failed to install plugin: $pname"
        fi
    }

    NO_OBJC_ARC=""
    function no-objc-arc {
        NO_OBJC_ARC="$NO_OBJC_ARC $@"
    }

    # plugin "TestflightPlugin"
    plugin "sqlite"
    no-objc-arc SQLitePlugin.m
    plugin "email"
    no-objc-arc EmailComposer.m

    if test -e "$PROJECT_PATH/scripts/ios-plugins.sh"; then
        . "$PROJECT_PATH/scripts/ios-plugins.sh"
    fi
    plugin "cordova-plugin-console"
    plugin "cordova-plugin-device"
    plugin "cordova-plugin-dialogs"
    plugin "cordova-plugin-media"
    plugin "cordova-plugin-splashscreen"
    plugin "cordova-plugin-camera"
    plugin "cordova-plugin-statusbar"

    # Prepare the project.
    CORDOVA prepare ios

    # Patch the project.
    patch -l -p0 << EOF > /dev/null || error "Patch failed"
--- $IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME.xcodeproj/project.pbxproj	2013-03-23 09:24:16.000000000 +0200
+++ $IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME.xcodeproj/project.pbxproj	2013-03-23 11:28:31.000000000 +0200
@@ -530,7 +530,7 @@
            CLANG_WARN_ENUM_CONVERSION = YES;
            CLANG_WARN_INT_CONVERSION = YES;
            CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
-				"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
+				"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "$DEVELOPER_NAME";
            GCC_C_LANGUAGE_STANDARD = c99;
            GCC_THUMB_SUPPORT = NO;
            GCC_VERSION = com.apple.compilers.llvm.clang.1_0;
@@ -556,6 +556,7 @@
                "-all_load",
                "-Obj-C",
            );
+				"PROVISIONING_PROFILE[sdk=iphoneos*]" = "$PROVISIONING_PROFILE_ID";
            SDKROOT = iphoneos;
            SKIP_INSTALL = NO;
            USER_HEADER_SEARCH_PATHS = "";
EOF
    echo -n .
    if test -e "$PROJECT_PATH/ios/Info.plist"; then
        cp "$PROJECT_PATH/ios/Info.plist" "$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/$PROJECT_NAME-Info.plist"
    fi
    if test -e "$PROJECT_PATH/ios/config.xml"; then
        cp "$PROJECT_PATH/ios/config.xml" "$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/config.xml"
    fi
    cp "$JACKBONEGAP_PATH/ios/release-dev" "$IOS_PROJECT_PATH/platforms/ios/cordova/release-dev"
    cp "$JACKBONEGAP_PATH/ios/build-dev" "$IOS_PROJECT_PATH/platforms/ios/cordova/build-dev"

    # Disable ARC for some files
    for file in $NO_OBJC_ARC; do
        sed -i "" "s/\/\* $file \*\/; };/\/\* $file \*\/; settings = {COMPILER_FLAGS = \"-fno-objc-arc\"; }; };/g" "$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME.xcodeproj/project.pbxproj"
    done

    cd "$PROJECT_PATH"

    # Generate icons and splash screens.
    echo -n .
    . "$JACKBONEGAP_PATH/ios/generate-assets.sh"

    # Remove useless assets.
    rm -fr "$IOS_PROJECT_PATH/platforms/ios/www/res"

    # Adjust the mess (lib install doesn't work... testflight.js file is unneeded)
    #mkdir -p "$IOS_PROJECT_PATH/build"
    #rm -fr "$IOS_PROJECT_PATH/www/testflight.js"
    ## cp "$DOWNLOADS_PATH/TestflightPlugin/src/ios/libTestFlight.a" "$IOS_PROJECT_PATH/build/"
    #ln -s "$DOWNLOADS_PATH"/*/src/ios/*.a "$IOS_PROJECT_PATH/build/" || true
    #ln -s "$DOWNLOADS_PATH"/*/src/ios/*.a "$IOS_PROJECT_PATH/" || true

    # Install libs
    mkdir -p "$IOS_PROJECT_PATH/platforms/ios/build/"
    # cp "$IOS_PROJECT_PATH/plugins"/*/src/ios/*.a "$IOS_PROJECT_PATH/platforms/ios/"
    # cp "$IOS_PROJECT_PATH/plugins"/*/src/ios/*.a "$IOS_PROJECT_PATH/platforms/ios/build/"
    
    # Get default PhoneGap files
    # rsync -a build/ios/www/ ios/www
    # Patch them with our own files
    rsync -a build/www/ "$IOS_PROJECT_PATH/www"
    rsync -a build/www/ "$IOS_PROJECT_PATH/platforms/ios/www"
    # Remove version number from cordova.js
    # . "$JACKBONEGAP_PATH/package.sh" # PHONEGAP_VERSION is stored here.
    # if test -e "$IOS_PROJECT_PATH/www/cordova-$PHONEGAP_VERSION.js"; then
    #     mv "$IOS_PROJECT_PATH/www/cordova-$PHONEGAP_VERSION.js" "$IOS_PROJECT_PATH/www/js/cordova.js"
    # fi

    # Copy TestFlight lib to iOS folder... YAH
    #That's a bloody hack... but it works.
    #for d in "~/Library/Developer/Xcode/DerivedData/$PROJECT_NAME"-*/Build/Products/Debug-iphoneos/; do
    #    test -e "$d" && cp "$IOS_PROJECT_PATH/build/libTestFlight.a" "$d"
    #done

    # Add project version into the info.plist file.
    if test -e /usr/libexec/PlistBuddy && test -e "$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/$PROJECT_NAME-Info.plist"; then
        VERSION=`cat "$PROJECT_PATH/VERSION"`
        V1=`echo $VERSION|cut -d. -f1`
        /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/$PROJECT_NAME-Info.plist"
        /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $V1" "$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/$PROJECT_NAME-Info.plist" 2> /dev/null \
          || /usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $V1" "$IOS_PROJECT_PATH/platforms/ios/$PROJECT_NAME/$PROJECT_NAME-Info.plist"
    fi

    if [ "x$target" = "xios-dev" ]; then
        devext="-dev"
    fi
    # Build
    if [ "x$BUILD_RELEASE" = "xYES" ]; then
        "$IOS_PROJECT_PATH/platforms/ios/cordova/release$devext" | tee "$EFILE" | awk '{ if ((i = (i+1) % 16) == 0) { printf "."; fflush; } }' || error "iOS build failed"
    else
        "$IOS_PROJECT_PATH/platforms/ios/cordova/build$devext"  | tee "$EFILE" | awk '{ if ((i = (i+1) % 16) == 0) { printf "."; fflush; } }' || error "iOS build failed"
    fi
    cat "$EFILE" | grep "BUILD SUCCEEDED" > /dev/null || error "iOS build failed"
    rm "$EFILE"

    echo ok
else
    echo "This script should be launched by root dir's build script."
    exit 1
fi

