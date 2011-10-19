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

function launchShareDialog(options) {
    $('<a href="#share-dialog"></a>').fancybox({
        autoDimensions: false,
        width: 500,
        height: 370,
        overlayShow: true,
        overlayColor: "#333",
        overlayOpacity: 0.15,
        transitionIn: 'none',
        transitionOut: 'none'
    }).click();
    
    $('#share-dialog').show();
    
    var baseUrl = window.location.protocol + "//" + window.location.host;
    var userUrl = baseUrl + "/users/" + encodeURIComponent(options.username) + "/join";
    
    var twitterLink = "https://twitter.com/share?";
    var twitterParams = {
        url: userUrl,
        via: "worlize",
        text: "I'm chatting right now in Worlize, a 2d virtual world platform.  Come join me!",
        related: "worlize"
    };
    var temp = [];
    for (var key in twitterParams) {
        if (twitterParams.hasOwnProperty(key)) {
            var value = twitterParams[key];
            temp.push(encodeURIComponent(key) + "=" + encodeURIComponent(value));
        }
    }
    twitterLink = twitterLink + temp.join("&");
    
    $('#share-dialog .twitter-share').unbind('click');
    $('#share-dialog .facebook-share').unbind('click');
    $('#share-dialog .twitter-share').bind('click', function(event) {
        event.preventDefault();
        if (window.twitterShareWindow && !window.twitterShareWindow.closed) {
            window.twitterShareWindow.close();
            window.twitterShareWindow = null;
        }
        var left = (window.screen.width/2) - (550/2);
        var top = (window.screen.height/2) - (480/2);
        window.twitterShareWindow = window.open(
            twitterLink,
            "twitterShareWindow",
            "resizable=no,scrollbars=no,status=yes,height=450,width=550,left=" + left + ",top=" + top
        );
        $.fancybox.close();
    });
    $('#share-dialog .facebook-share').bind('click', function(event) {
        event.preventDefault();
        var obj = {
            method: 'feed',
            link: userUrl,
            picture: 'https://www.worlize.com/images/share-facebook-link-picture.jpg',
            name: 'Come chat with me in Worlize!',
            caption: 'Worlize: Your World, Realized',
            description: "I'm online now, hanging out in Worlize: a place where everyone " +
                         "can create their own virtual world for free!  Come check it out with me!!"
        };
        showFacebookDialog(obj);
        $.fancybox.close();
    });
    $('#share-dialog .link-to-copy').text(userUrl);
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