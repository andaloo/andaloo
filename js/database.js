/**
 * @fileoverview This module manages the SQL backend.
 *
 * Changed SQL backend to Web SQL,
 * as it's supported natively by iOS and Android
 * using an SQLite backend already.
 */
/* global Backbone */
define(["logger", "underscore", "events", "jackbone", "andaloo"],
function (Logger, _, Events, Jackbone, Andaloo) {
    "use strict";

    /**
     * Database initialization.
     *
     * @name Database
     * @class [database] Database management.
     * @constructor
     */
    var Database = _.extend({}, Backbone.Events);

    /** Set to true to log in Jackbone.profiler all SQL calls timings */
    Database.profilingEnabled = false;

    /** Set to true to log all SQL requests */
    Database.loggingEnabled = false;

    /** Request wether transactions (BEGIN/COMMIT) are supported */
    Database.supportsTransactions = false;

    /** Open a database from its name.
     *
     * @param name Database name
     * @param collections List of all collections
     * @param callback Function called when the operation is done.
     */
    Database.open = function (name, collections, callback) {
        this.collections = collections;

        if (Andaloo.SQL && Andaloo.SQL.openDatabase) {

            // Adjust config
            Database.supportsTransactions = true;
            Database.exec = plugin_exec;

            // Open DB
            Logger.log("Loading SQLite Plugin.");
            this.db = Andaloo.SQL.openDatabase({name: name});
        }
        else {
            Logger.log("SQLite Plugin Not Loaded.");
            if (window.TESTING) {
                // Ask for 4MB of storage when testing (phantomjs fails above 5MB)
                this.db = openDatabase(name, "1.0", "Database " + name, 4 * 1024 * 1024);
            }
            else {
                // Ask for 100MB of storage!
                this.db = openDatabase(name, "1.0", "Database " + name, 100 * 1024 * 1024);
            }
        }

        var createOK = _.after(collections.length, callback);
        _.each(collections, function (c) {
            if (c.dbCreate) {
                c.dbCreate(createOK);
            } else {
                createOK();
            }
        });
    };

    var webSQL_executeSql = function (tx, query, args, success, error, log, context) {
        // Log the request
        var sqlId, loggingEnabled = Database.loggingEnabled;
        if (loggingEnabled && log !== false) {
            sqlId = _.uniqueId("SQL");
            Logger.log(sqlId + ": " + query);
        }

        tx.executeSql(query, args, function (tx, results) {

            // Load all rows in memory
            var rows = [];
            var len = results.rows.length, i;
            for (i = 0; i < len; i++) {
                rows.push(_.clone(results.rows.item(i)));
            }

            // Log success of the request
            if (loggingEnabled && log !== false) {
                Logger.log(sqlId + ": ok: " +
                            (rows.length ? (rows.length + " rows") : ""));
            }

            // Callback
            if (typeof success === "function") {
                success.call(context, rows);
            }
        },
        function (tx, err) {
            // Some logs for the user.
            if (log !== false) {
                if (Database.loggingEnabled) {
                    Logger.log(sqlId + ": error");
                }
                Logger.log("SQL ERROR: " + err.message);
                Logger.log("...query: " + query);
                Logger.log("...args: " + JSON.stringify(args));
            }

            // Callback
            if (typeof error === "function") {
                error.call(context, err.message);
            }
        });
    };

    var webSQL_execTransaction = function (requests) {
        Database.db.transaction(function (tx) {
            for (var i = 0, l = requests.length; i < l; ++i) {
                var r = requests[i];
                webSQL_executeSql(tx, r.query, r.args, r.success, r.error, undefined, r);
            }
        });
    };
    var webSQL_exec = function (query, args, success, error, log) {
        Database.db.transaction(function (tx) {
            webSQL_executeSql(tx, query, args, success, error, log, Database);
        });
    };

    var plugin_exec = function (query, args, success, error, log) {
        // Log the request
        var sqlId,
            loggingEnabled = Database.loggingEnabled;
        if (loggingEnabled && log !== false) {
            sqlId = _.uniqueId("SQL");
            Logger.log(sqlId + ": " + query);
        }

        // Start profiling the request.
        var timerId,
            profilingEnabled = Database.profilingEnabled;
        if (profilingEnabled && log !== false) {
            timerId = Jackbone.profiler.onStart();
        }

        // Launch it in synchronous mode
        Database.db.executeSql(query, args, function (results) { /*Now*/
            var rows = results.rows;

            if (log !== false) {
                // Inform profiler that request is done.
                if (profilingEnabled) {
                    Jackbone.profiler.onEnd(timerId, query);
                }

                // Log
                if (loggingEnabled) {
                    Logger.log(sqlId + ": ok: " +
                                (rows.length ? (rows.length + " rows") : ""));
                }
            }

            // Callback
            if (typeof success === "function") {
                success(rows);
            }
        },
        function (err) {
            // Some logs for the user.
            if (log !== false) {
                if (Database.loggingEnabled) {
                    Logger.log(sqlId + ": error");
                }
                Logger.log("SQL ERROR: " + err.message);
                Logger.log("...query: " + query);
                Logger.log("...args: " + JSON.stringify(args));

                // Inform profiler that request is done (even if it failed).
                if (profilingEnabled) {
                    Jackbone.profiler.onEnd(timerId, query);
                }
            }
            else {
                console.log("SQL ERROR: " + err.message);
                console.log("...query: " + query);
                console.log("...args: " + JSON.stringify(args));
            }

            // Callback
            if (typeof error === "function") {
                error(err.message);
            }
        });
    };

    /** Execute an SQL query on the database
     *
     * @param query SQL query string.
     * @param args array of parameters for the query.
     * @param callback a function taking an array of rows as argument.
     * @return JSON output.
     */
    Database.exec = webSQL_exec;
    Database.execTransaction = webSQL_execTransaction;


    /** Delete everything from the database.
     * @param callback Function called when the operation is done.
     */
    Database.reset = function (callback) {
        var opDone = _.after(this.collections.length, callback);
        _.each(this.collections, function (c) {
            // Create first (so drop don't fail)
            if (c.dbCreate && c.dbDrop) {
                c.dbCreate(function () { c.dbDrop(function () { c.dbCreate(opDone); }); });
            } else {
                opDone();
            }
        });
    };

    /** Prototype for a collection using a database table */
    Database.Collection = Backbone.Collection.extend({
        /** Create table */
        dbCreate: function (callback) { callback(); },
        /** Drop table */
        dbDrop:   function (callback) {
            Database.exec("DROP TABLE " + this.dbStorage.name, [], callback);
        },
        /** Delete all entries from the table */
        dbClear: function (callback) {
            Database.exec("DELETE FROM " + this.dbStorage.name, [], callback);
        }
    });

    return Database;
});
