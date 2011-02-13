function openMarketplace() {
    showShim();
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

function closeMarketplace() {
    hideShim();
    $('#marketplace').remove();
}

function showShim() {
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

function hideShim() {
    $('#shim').remove();
}