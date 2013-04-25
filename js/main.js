/**
 * @fileoverview Generated by Jackbone.gap
 * DO NOT MODIFY
 */
requirejs.config({
    baseUrl: 'js',

    paths: {
        // Libraries
        jquery:       'libs/jquery/jquery',
        underscore:   'libs/underscore/underscore',
        backbone:     'libs/backbone/backbone',
        jquerymobile: 'libs/jquery.mobile/jquery.mobile',
        handlebars:   'libs/handlebars/dist/handlebars',
        testflight:   'libs/testflight',
        sqlite:       'libs/sqlite',
        kinetic:      'libs/kinetic',
        stacktrace:   'libs/stacktrace-js/stacktrace',
        jackbone:     'libs/jackbone/jackbone',
        kassics:      'libs/kassics/kassics',
        k6particles:  'libs/kassics/plugins/particles'
    },

    shim: {
        underscore: {
            exports: '_'
        },
        backbone: {
            deps: ["underscore", "jquery"],
            exports: "Backbone"
        },
        jquerymobile: {
            deps: ["jquery"]
        },
        jackbone: {
            deps: ["backbone", "jquerymobile"],
            exports: "Jackbone"
        },
        handlebars: {
            exports: 'Handlebars'
        },
        kinetic: {
            exports: 'Kinetic'
        },
        kassics: {
            exports: 'Kassics'
        },
        k6particles: {
            deps: ["kassics"]
        },
        stacktrace: {
            exports: 'printStackTrace'
        }
    }
});

require([
    'jquery',
    'underscore',
    'backbone',
    'jackbone',
    'cdv',
    'testing',
    'logger',
    'appdelegate'
],
function($, _, Backbone, Jackbone, Cordova, Testing, Logger, AppDelegate) {

    function onDeviceReady() {

        var testingEnabled = window.TESTING || false;
        
        // Initialize some plugins.
        Logger.initialize();
        Cordova.initialize();

        // When application is resumed, make sure we re-setup the current view
        // and ask client application to resume execution.
        var onResume = function () {
            if (Jackbone.ViewManager.reSetupCurrent) {
                Jackbone.ViewManager.reSetupCurrent();
            }
            if (AppDelegate.resume) {
                AppDelegate.resume();
            }
        };
        document.addEventListener("resume", onResume, false);

        // When application is paused, ask client application to stop execution.
        var onPause = function () {
            if (AppDelegate.pause) {
                AppDelegate.pause();
            }
        };
        document.addEventListener("pause", onPause, false);

        // Hide splash screen
        Cordova.hideNativeSplash();
        $('.splash-screen').remove();

        // Start client application
        if (AppDelegate.start) {
            AppDelegate.start(testingEnabled);
        }

        // Run the tests if testing is enabled
        if (testingEnabled) {
            AppDelegate.test();
        }
    }
    
    // If cordova (PhoneGap) is present, we'll wait for 'deviceready' before doing anything.
    if (window.cordova)
        document.addEventListener("deviceready", onDeviceReady, false);
    else
        onDeviceReady();
});

