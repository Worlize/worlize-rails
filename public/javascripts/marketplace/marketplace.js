jQuery(function($) {
    
    var marketplaceItemId;
    var mustBeLoggedInTooltip;
    
    // Wire up ajax item detail popups...
    $('ul.item-thumbnail-container > li > a, a[data-type=MarketplaceItem]').live('click', function(event) {
        var spinner;
        var image;
        var link = $(event.target).closest('a');
        event.preventDefault();
        $.ajax({
            dataType: 'script',
            url: link.attr('href'),
            cache: true,
            beforeSend: function() {
                // show loading spinner
                image = $(event.target).closest('li').find('img');
                var width = image.outerWidth();
                var height = image.outerHeight();
                var offset = image.offset();
                
                spinner = $('<div class="loading-spinner">');
                $(event.target).closest('li').append(spinner);
                spinner.offset({
                    top: offset.top + (height/2 - 4),
                    left: offset.left + (width/2 - 8)
                });
                
                image.animate({'opacity': 0.3}, 200);
            },
            complete: function () {
                // hide loading spinner
                spinner.remove();
                image.animate({'opacity': 1}, 200);
            },
            error: function(xhr, textStatus, errorThrown) {
                $('<a>').fancybox({
                    content: "<h1>Uhoh!</h1>" +
                             "<p>There was an error loading item details.  " +
                             "Please try again in a few minutes.</p>",
                    overlayOpacity: 0.2
                }).click();
            }
        });
    });
    
    $('.overlay-dialog .cancel-button').live('click', function(event) {
        $.fancybox.close();
    });
    
    $('.confirm-purchase-dialog .confirm-button').live('click', function(event) {
        $.ajax({
            dataType: 'json',
            url: "/marketplace/items/" + marketplaceItemId + "/buy",
            type: "POST",
            headers: {
                'accept': 'application/json'
            },
            error: function(xhr, errorType, exception) {
                var errors;
                var errorString;
                if (window.JSON) {
                    try {
                        data = JSON.parse(xhr.responseText);
                        if (data.formatted_coins) {
                            $('#coins-balance').html(data.formatted_coins);
                        }
                        if (data.formatted_bucks) {
                            $('#bucks-balance').html(data.formatted_bucks);
                        }
                        errors = data.errors;
                    }
                    catch(e) {
                        errors = [];
                    }
                }
                
                if (errors.length > 0) {
                    errorString = '<ul class="errors">';
                    for (var i=0; i < errors.length; i++) {
                        errorString = errorString +
                            "<li>" + errors[i] + "</li>";
                    }
                    errorString = errorString + "</ul>";
                }

                var confirmTemplate = $(
                    '<div class="overlay-dialog error">' +
                        '<h1>There was an error while purchasing your item.</h1>' +
                        ((errors.length > 0) ? errorString : '') +
                        '<div class="option-buttons">' +
                          '<div class="cancel-button">Close</div>' +
                        '</div>' +
                    '</div>'
                );
                $('<a>').fancybox({
                    content: confirmTemplate,
                    overlayOpacity: 0.2
                }).click();
            },
            success: function(data, textStatus, xhr) {
                var confirmTemplate = $(
                    '<div class="overlay-dialog purchase-confirmed">' +
                        '<h1>Thank you for your purchase!</h1>' +
                        '<div class="option-buttons">' +
                          '<div class="cancel-button">Close</div>' +
                        '</div>' +
                    '</div>'
                );
                if (data.formatted_coins) {
                    $('#coins-balance').html(data.formatted_coins);
                }
                if (data.formatted_bucks) {
                    $('#bucks-balance').html(data.formatted_bucks);
                }
                $('<a>').fancybox({
                    content: confirmTemplate,
                    overlayOpacity: 0.2
                }).click();
            }
        })
    });
    
    function showConfirmation(itemId, thumbnail, price) {
        var confirmationDialog = $(
            '<div class="overlay-dialog confirm-purchase-dialog">' +
                '<img>' +
                '<h1>Are you sure you want to purchase this item for ' + price + '?</h1>' +
                '<div class="option-buttons">' +
                  '<div class="cancel-button">Cancel</div>' +
                  '<div class="confirm-button">Confirm</div>' +
                '</div>' +
            '</div>'
        );
        confirmationDialog.find('img').attr('src', thumbnail);
        confirmationDialog.data('link', "/marketplace/items/" + itemId);
        $('<a>').fancybox({
            content: confirmationDialog,
            overlayOpacity: 0.2
        }).click();
    }
    
    if (loggedIn) {
        $('.buy-button').live('click', function(event) {
            var container = $(event.target).closest('li, div.item-detail');
            marketplaceItemId = container.data('marketplace-item-id');
            var currency = (container.data('currency-id') == '1') ? "bucks" : "coins";
            var price = parseInt(container.data('price'), 10);
            if (price == 0) {
                price = "free";
            }
            else {
                price = price + " " + currency;
            }
            var thumbnailImage = container.data('thumbnail-image-url');
            showConfirmation(marketplaceItemId, thumbnailImage, price);
        });
    }
    else {
        $('.buy-button').live('mouseover', function(event) {
            if (!mustBeLoggedInTooltip) {
                mustBeLoggedInTooltip = $('<div id="must-be-logged-in-tooltip">');
                mustBeLoggedInTooltip.html('You&nbsp;must&nbsp;be&nbsp;logged&nbsp;in&nbsp;to&nbsp;buy.');
                mustBeLoggedInTooltip.hide();
                mustBeLoggedInTooltip.css({ position: 'absolute', 'z-index': 99999 })
                $(document.body).append(mustBeLoggedInTooltip);
                console.log("Created tooltip");
            }
            mustBeLoggedInTooltip
            .offset({
                top: event.pageY+10,
                left: event.pageX+20
            })
            .show();
        });
        $('.buy-button').live('mousemove', function(event) {
            if (mustBeLoggedInTooltip) {
                mustBeLoggedInTooltip.offset({
                    top: event.pageY+10,
                    left: event.pageX+20
                });
            }
        });
        $('.buy-button').live('mouseout', function(event) {
            if (mustBeLoggedInTooltip) {
                mustBeLoggedInTooltip.hide();
            }
        });
    }
    
    
});