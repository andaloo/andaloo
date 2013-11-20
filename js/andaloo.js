/**
 * @fileoverview This module manages the api entry point.
 *
 * Changed SQL backend to Web SQL,
 * as it's supported natively by iOS and Android
 * using an SQLite backend already.
 */
/* global Backbone */
define(["logger", "cdv"],
function (Logger, Cordova) {
    "use strict";
    return {
        initialize: function () {
 
            this.SQL    = window.SQLitePlugin;
            this.Email  = window.EmailComposer;
            this.Logger = Logger;

            // Initialize some plugins.
            Logger.initialize();
            Cordova.initialize();
        }
    };
});
