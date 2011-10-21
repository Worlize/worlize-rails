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
    top.location.href = "/";
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

function openMarketplace() {
    if (marketplaceShowing) { return; }
    if (virtualCurrencyProductsShowing) { closeVirtualCurrencyProducts(); }
    showShim();
    marketplaceShowing = true;
    var marketplaceTemplate =
        '<div id="marketplace">' +
            '<div id="marketplace-close-button">Return to Worlize</div>' +
            '<iframe frameborder="0" sandbox="allow-forms allow-scripts allow-same-origin" src="/marketplace" id="marketplaceIframe">' +
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
            '<iframe frameborder="0" sandbox="allow-forms allow-scripts allow-same-origin" src="/virtual_currency_products" id="virtual-currency-products-iframe">' +
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