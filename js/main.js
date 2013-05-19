/**
 * @fileoverview Generated by Jackbone.gap
 * DO NOT MODIFY
 */
requirejs.config({
    baseUrl: 'js',

    paths: {
        // Libraries
        jquery:        'libs/jquery/jquery',
        underscore:    'libs/underscore/underscore',
        backbone:      'libs/backbone/backbone',
        jquerymobile:  'libs/jquery.mobile/jquery.mobile',
        handlebars:    'libs/handlebars/dist/handlebars',
        testflight:    'libs/testflight',
        sqlite:        'libs/sqlite',
        emailcomposer: 'libs/emailcomposer',
        kinetic:       'libs/kinetic',
        stacktrace:    'libs/stacktrace-js/stacktrace',
        jackbone:      'libs/jackbone/jackbone',
        kassics:       'libs/kassics/kassics',
        k6particles:   'libs/kassics/plugins/particles',
        moment:        'libs/moment/moment'
    },

    shim: {
        underscore: {
            exports: '_'
        },
        backbone: {
            deps: ['underscore', 'jquery'],
            exports: 'Backbone'
        },
        jquerymobile: {
            deps: ['jquery']
        },
        jackbone: {
            deps: ['backbone', 'jquerymobile'],
            exports: 'Jackbone'
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
            deps: ['kassics']
        },
        stacktrace: {
            exports: 'printStackTrace'
        },
        emailcomposer: {
            exports: 'EmailComposer'
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
    'sqlite',
    'appdelegate'
],
function ($, _, Backbone, Jackbone, Cordova, Testing, Logger, SQLite, AppDelegate) {

    'use strict';

    // When application is resumed, make sure we re-setup the current view
    // and ask client application to resume execution.
    var onResume = function () {
        if (Jackbone.reSetup) {
            Jackbone.reSetup();
        }
        if (AppDelegate.resume) {
            AppDelegate.resume();
        }
    };

    // When application is paused, ask client application to stop execution.
    var onPause = function () {
        if (AppDelegate.pause) {
            AppDelegate.pause();
        }
    };

    function addDeviceClass() {
        // Allow CSS rules to be platform dependent
        if (Cordova.isIos) {
            $('body').addClass('ios');
        }
        if (Cordova.isAndroid) {
            $('body').addClass('android');
        }
    }

    function onDeviceReady() {

        var testingEnabled = window.TESTING || false;

        // Initialize some plugins.
        Logger.initialize();
        Cordova.initialize();
        addDeviceClass();

        // Catch pause and resume events.
        document.addEventListener('resume', onResume, false);
        document.addEventListener('pause', onPause, false);

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
    if (window.cordova) {
        document.addEventListener('deviceready', onDeviceReady, false);
    }
    else {
        onDeviceReady();
    }
});

