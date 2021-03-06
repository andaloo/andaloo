/**
 * @fileoverview Generated by Jackbone.gap
 * DO NOT MODIFY
 */
require([
    'jquery',
    'underscore',
    'backbone',
    'jackbone',
    'cdv',
    'testing',
    'logger',
    'andaloo',
    'appdelegate'
],
function ($, _, Backbone, Jackbone, Cordova, Testing, Logger, Andaloo, AppDelegate) {

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

        Andaloo.initialize();

        console.log('[andaloo] Device ready');
        var testingEnabled = window.TESTING || false;

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
    console.log('[andaloo] Start');
    if (window.cordova) {
        console.log('[andaloo] Add deviceready listener');
        document.addEventListener('deviceready', onDeviceReady, false);
    }
    else {
        console.log('[andaloo] No cordova, let\'s start');
        onDeviceReady();
    }
});

