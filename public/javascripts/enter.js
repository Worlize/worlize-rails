var isFocused = true;

function getSWF(movieName) { 
    if (navigator.appName.indexOf("Microsoft") != -1) 
    { 
        return window[movieName]; 
    } 
    else 
    { 
        return document[movieName]; 
    }
}

jQuery(function($) {
    $(window).bind('focus', function(event) {
        isFocused = true;
    });
    $(window).bind('blur', function(event) {
        isFocused = false;
    });
})

function checkIsFocused() {
    // Can't use document.hasFocus() on Chrome because it returns true for
    // some reason if the document is in a background tab.
    return isFocused;
}

jQuery.extend( jQuery.easing, {
    easeInBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		return c*(t/=d)*t*((s+1)*t - s) + b;
	},
	easeOutBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158;
		return c*((t=t/d-1)*t*((s+1)*t + s) + 1) + b;
	},
	easeInOutBack: function (x, t, b, c, d, s) {
		if (s == undefined) s = 1.70158; 
		if ((t/=d/2) < 1) return c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
		return c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
	}
});

function hideLoadingOverlay() {
    setTimeout(function() {
        var $ = jQuery;
        $('#loading-overlay-container').animate({
            top: -180
        },{
            duration: 500,
            easing: 'easeInBack',
            complete: function() {
                $('#loading-overlay-container').hide();
            }
        });
    }, 1000);
}

function launchCenteredPopup(url, width, height) {
    var left = (window.screen.width/2) - (width/2);
    var top = (window.screen.height/2) - ((height+30)/2);
    var params = "resizable=no,scrollbars=no,status=yes,height=" + height + ",width=" + width + ",left=" + left + ",top=" + top;
    window.open(url, "", params);
}

function logout() {
    if (window.fbLoggedIn) {
        FB.logout(function(response) {
            top.location.href = "/logout";
        });
    }
    else {
        top.location.href = "/logout";
    }
}

var marketplaceShowing = false;
var virtualCurrencyProductsShowing = false;

if (window['FB']) {
    initializeFacebook();
}
else {
    var oldAsyncInitFn = window.fbAsyncInit;
    window.fbAsyncInit = function() {
        oldAsyncInitFn();
        initializeFacebook();
    };
}

function handleLoggedOut() {
    redirectToHomepage();
}

function redirectToHomepage() {
    top.location.href = "/";
}

function checkForDialogs() {
    PromoDialog.checkForDialogs();
}

function initializeFacebook() {
    FB.Event.subscribe('auth.login', handleFacebookLogin);
}

function handleFacebookLogin(response) {
    // Once a user authorizes the app with facebook, make sure to connect
    // their facebook ID to their account in the database.
    if (response.status === 'connected') {
        window.fbLoggedIn = true;
        $.post('/authentications/connect_facebook_via_js', {
            access_token: response.authResponse.accessToken
        });
    }
}

function getFacebookLoginStatus() {
    return window.fbLoggedIn;
}

function namespace(namespace) {
    var parts = namespace.split('.');
    var current = window;
    for (var i=0,len=parts.length; i < len; i ++) {
        var part = parts[i];
        var next = current[part];
        if (typeof(next) !== 'object') {
            next = current[part] = {};
        }
        current = next;
    }
}

function openMarketplace(categoryId) {
    if (marketplaceShowing) { return; }
    if (virtualCurrencyProductsShowing) { closeVirtualCurrencyProducts(); }
    showShim();
    var url;
    marketplaceShowing = true;
    if (categoryId) {
        url = "/marketplace/categories/" + categoryId;
    }
    else {
        url = "/marketplace";
    }
    var marketplaceTemplate =
        '<div id="marketplace">' +
            '<div id="marketplace-close-button">Close Marketplace</div>' +
            '<iframe frameborder="0" sandbox="allow-forms allow-scripts allow-same-origin" src="' + url + '" id="marketplaceIframe">' +
        '</div>';

    var marketplaceElement = $(marketplaceTemplate);
    marketplaceElement.find("#marketplace-close-button").click(function() {
        closeMarketplace();
    });
    
    setTimeout(function() {
        $(document.body).append(marketplaceElement);
    }, 200);
}

function showFacebookDialog(options) {
    // console.log("ShowFacebookDialog", options);
    function doShowDialog() {
        FB.ui(options);
    }
    if (FB.getAuthResponse()) {
        doShowDialog();
    }
    else {
        FB.login(function(response) {
            if (response.authResponse) {
                // console.log("Login complete, showing requestsed dialog.");
                doShowDialog();
            }
        }, { scope: requestedFacebookPermissions })
    }
}

function fbLoginForSnapshot() {
    FB.login(function(response) {
        if (response.authResponse) {
            getSWF('FlashClient').fbLoginForSnapshotComplete();
        }
    }, { scope: requestedFacebookPermissions });
}

function closeMarketplace() {
    marketplaceShowing = false;
    hideShim();
    $('#marketplace').remove();
}

function openVirtualCurrencyProducts() {
    if (virtualCurrencyProductsShowing) { return; }
    if (marketplaceShowing) { closeMarketplace(); }
    showShim();
    virtualCurrencyProductsShowing = true;
    var virtualCurrencyProductsTemplate =
        '<div id="virtual-currency-products">' +
            '<div id="virtual-currency-products-close-button">Close</div>' +
            '<iframe frameborder="0" src="/virtual_currency_products" id="virtual-currency-products-iframe">' +
        '</div>';
    
    var virtualCurrencyProductsElement = $(virtualCurrencyProductsTemplate);
    virtualCurrencyProductsElement.find('#virtual-currency-products-close-button').click(function() {
        closeVirtualCurrencyProducts();
    });
    
    setTimeout(function() {
        $(document.body).append(virtualCurrencyProductsElement);

        var windowWidth = $(window).width();
        var width = virtualCurrencyProductsElement.width();
        virtualCurrencyProductsElement.css({
            left: windowWidth/2 - width/2
        });
    }, 200);
}

function closeVirtualCurrencyProducts() {
    hideShim();
    virtualCurrencyProductsShowing = false;
    $('#virtual-currency-products').remove();
}

var shimRefCount = 0;
function showShim() {
    shimRefCount ++;
    if (shimRefCount === 1) {
        var shim = $('<div id="shim">');
        shim.css({
            'display': 'none',
            'position': 'absolute',
            'top': 0,
            'left': 0,
            'right': 0,
            'bottom': 0,
            'background-color': '#000000',
            'opacity': 0.3,
            'z-index': 1000
        });
        shim.appendTo($(document.body))
        shim.fadeIn(250);
    }
}

function hideShim() {
    shimRefCount --;
    if (shimRefCount <= 0) {
        $('#shim').remove();
    }
}


// Title Bar Flashing
(function() {
    var originalTitle = document.title;
    var flashInterval = null;
    var currentlyFlashing = false;
    var notificationText = null;
    var currentCount;
    var maxCount;

    window.flashTitle = function(newText, count) {
        if (isFocused /* document.hasFocus() */) {
            // console.log("Document has focus.  Not flashing title.");
        }
        // console.log("Flashing text " + count + " times: " + newText);
        reset();
        maxCount = (typeof(count) !== 'number') ? 0xFFFFFFFF : count;
        notificationText = newText;
        currentlyFlashing = true;
        currentCount = 0;
        flashInterval = setInterval(handleFlashInterval, 1000);
    };
    
    window.cancelFlashTitle = function(text) {
        // console.log("cancelFlashTitle: " + text);
        if (notificationText === text) {
            reset();
        }
    };

    var reset = function() {
        // console.log("Reset");
        document.title = originalTitle;
        currentlyFlashing = false;
        notificationText = null;
        if (flashInterval) {
            clearInterval(flashInterval);
            flashInterval = null;
        }
    };

    var handleFlashInterval = function() {
        // console.log("handleFlashInterval");
        if (currentlyFlashing && !isFocused /* document.hasFocus() */) {
            if (document.title === originalTitle) {
                currentCount ++;
                document.title = notificationText;
            }
            else if (currentCount < maxCount) {
                // console.log(currentCount + " < " + maxCount);
                document.title = originalTitle;
            }
            else {
                currentlyFlashing = false;
                if (flashInterval) {
                    clearInterval(flashInterval);
                    flashInterval = null;
                }
            }
        }
        else {
            reset();
        }
    };

    jQuery(function($) {
        $(window).bind('focus', function() {
            // console.log("Window focused.");
            reset();
        });
    });
})();

// Desktop Notifications
(function() {
    var notifications = window.webkitNotifications;
    
    var activeNotifications = {};
    
    NotificationManager = {
        currentId: 0,
        isSupported: function() {
            return (window.webkitNotifications) ? true : false;
        },
        hasPermission: function() {
            if (!this.isSupported()) { return false; }
            return notifications.checkPermission() === 0;
        },
        displayPermissionRequestDialog: function() {
            if (!this.isSupported()) { return; }
            if (notifications.checkPermission() === 2) { return; } // 2 == PERMISSION_DENIED
            var el = $('<div class="notifications-permission-prompt">' + 
                        '<div class="text-container">' +
                         '<h1>Enable Desktop Notifications</h1> - ' +
                         '<p>Never miss a beat!</p>' +
                        '</div>' +
                       '</div>');
            var acceptButton = $('<div class="accept-button">Yes, please!</div>');
            var rejectButton = $('<div class="reject-button">No, thanks.</div>');
            el.append(acceptButton);
            el.append(rejectButton);
            el.append($('<div class="clearfix"></div>'));
            
            acceptButton.bind('click', function() {
                el.remove();
                NotificationManager.requestPermission();
            });
            rejectButton.bind('click', function() {
                el.remove();
            });
            
            $('object').before(el);
        },
        requestPermission: function() {
            // console.log("requestPermission");
            if (!this.isSupported() || this.hasPermission()) { return; }
            notifications.requestPermission();
        },
        displayNotification: function(options) {
            // console.log("displayNotification", options);
            if (!this.isSupported() || !this.hasPermission()) { return; }
            var notification = this.createNotificationInstance(options);
            activeNotifications[notification.worlizeId] = notification;
            notification.show();
            return notification.worlizeId;
        },
        clearNotification: function(notificationId) {
            var notification = activeNotifications[notificationId];
            if (notification) {
                notification.clear();
                delete activeNotifications[notificationId];
            }
        },
        clearAllNotifications: function() {
            if (!this.isSupported()) { return; }
            // console.log("Clearing notifications", activeNotifications);
            for (var notificationId in activeNotifications) {
                var notification = activeNotifications[notificationId];
                notification.cancel();
                delete activeNotifications[notificationId];
            }
        },
        createNotificationInstance: function(options) {
            // console.log("createNotificationInstance", options);
            if (!this.isSupported()) { return; }
            
            if (typeof(options.icon) !== 'string') {
                var server = document.location.protocol + "//" + document.location.host;
                options.icon = server + "/images/notifications/default_icon.jpg"
                // console.log(options.icon);
            }
            if (typeof(options.title) !== 'string') {
                options.title = "Worlize";
            }
            if (typeof(options.content) !== 'string') {
                options.content = "";
            }
            var notification;
            if (options.notificationType == 'simple') {
                notification = notifications.createNotification(
                    options.icon,
                    options.title,
                    options.content
                );
            } else if (options.notificationType == 'html') {
                notification = notifications.createHTMLNotification(options.htmlContentURL);
            }
            notification.worlizeId = this.currentId++;
            notification.onclose = function() {
                delete activeNotifications[notification.worlizeId];
            }
            notification.onclick = function() {
                window.focus();
            }
            return notification;
        }
    };

    if (NotificationManager.isSupported()) {
        jQuery(function($) {
            $(window).bind('focus', function() {
                NotificationManager.clearAllNotifications();
            })
        });
    }

})();











