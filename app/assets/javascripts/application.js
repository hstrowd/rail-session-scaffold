// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require turbolinks
//= require_tree .

var SESSION_CONTROLS_SELECTOR = '#session-controls';
var SESSION_DISPLAY_SELECTOR = '#session-content';
var SESSION_ALERTS_SELECTOR = '#session-alerts';

var sessionView = {
    controls: {
        load: {
            getID: function() {
                var $field = $(SESSION_CONTROLS_SELECTOR + ' .control.load input[name=id]');
                if ($field.length < 1) { return null; }
                return $field.val();
            }
        },
        update: {
            getKey: function() {
                var $field = $(SESSION_CONTROLS_SELECTOR + ' .control.update input[name=key]');
                if ($field.length < 1) { return null; }
                return $field.val();
            },
            getValue: function() {
                var $field = $(SESSION_CONTROLS_SELECTOR + ' .control.update input[name=value]');
                if ($field.length < 1) { return null; }
                return $field.val();
            }
        }
    },
    show: {
        update: function(sessionAttrs) {
            $(SESSION_DISPLAY_SELECTOR + ' .attr.id .value').text(sessionAttrs.id);
            $(SESSION_DISPLAY_SELECTOR + ' .attr.class .value').text(sessionAttrs.class);
            $(SESSION_DISPLAY_SELECTOR + ' .attr.keys .value').text(sessionAttrs.keys);
            $(SESSION_DISPLAY_SELECTOR + ' .attr.body .value').text(sessionAttrs.content);
        }
    },
    alert: {
        addWarning: function(message) {
            var alert = $('<div>', {
                class: 'warn alert',
                text: message
            });
            alert.hide();
            $(SESSION_ALERTS_SELECTOR).append(alert);
            alert.delay().slideDown().delay(5000).slideUp();
        }
    }
};

var sessionManager = {
    // Handles AJAX errors in a generic manner for all types of requests.
    onAjaxError: function(actionDescription) {
        return function(jqXHR, textStatus, errorThrown) {
            var response = JSON.parse(jqXHR.responseText);
            var alertMessage = errorThrown;
            if (response.error) {
                alertMessage = response.error;
            }
            sessionView.alert.addWarning(actionDescription + ': ' + alertMessage);
        };
    },


    load: function() {
        var sessionID = sessionView.controls.load.getID();
        if (!sessionID) {
            sessionView.alert.addWarning('No ID found to load.');
            return;
        }

        var self = this;
        var ajaxOpts = {
            url: "/session",
            method: 'POST',
            data: { id: sessionID }
        };
        $.ajax(ajaxOpts)
            .done(function(data, textStatus, jqXHR) {
                self.refresh();
            })
            .fail(this.onAjaxError('Failed to load session'));
    },

    update: function() {
        var key = sessionView.controls.update.getKey();
        var value = sessionView.controls.update.getValue();
        if (!key) {
            sessionView.alert.addWarning('No key found to set or update.');
            return;
        }

        var data = { key: key }
        if (value.length) {
            data.value = value;
        }

        var self = this;
        var ajaxOpts = {
            url: "/session",
            method: 'PUT',
            data: data
        };
        var actionDescription = 'Failed to update session (' + key + ' => ' + value + ')';
        $.ajax(ajaxOpts)
            .done(function(data, textStatus, jqXHR) {
                self.refresh();
            })
            .fail(this.onAjaxError(actionDescription));
    },

    refresh: function() {
        // Pull session details from the server.
        $.ajax({ url: "/session" })
            .done(function(data, textStatus, jqXHR) {
                var sessionAttrs = {
                    id: data.id,
                    class: data.class
                };
                if (data.keys) {
                    sessionAttrs.keys = JSON.stringify(data.keys);
                }
                if (data.content) {
                    sessionAttrs.content = JSON.stringify(data.content);
                }

                sessionView.show.update(sessionAttrs);
            })
            .fail(this.onAjaxError('Failed to refresh session'));
    },

    clear: function() {
        var self = this;
        var ajaxOpts = {
            url: "/session",
            method: 'DELETE'
        };
        $.ajax(ajaxOpts)
            .done(function(data, textStatus, jqXHR) {
                self.refresh();
            })
            .fail(this.onAjaxError('Failed to clear session'));
    }
};
