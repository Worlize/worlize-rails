jQuery(function($) {
      // Get data items
    var carousel = $('#carousel');
    var thumbsContainer;
    var banners = [];
    
    var currentBanner = null;
    
    var currentItem = 0;
    var totalItems = null;
    
    var cycleDelay = 7000;
    
    function nextItem() {
        currentItem = (currentItem + 1) % totalItems;
        
        var prevBanner = currentBanner;
        currentBanner = banners[currentItem].bannerElement;
        prevBanner.css('z-index', 0)
        currentBanner.css('z-index', 10);
        currentBanner.fadeIn(700, function() {
            prevBanner.hide();
        });
        
        thumbsContainer.animate(
            { top: -100 },
            {
                complete: function() {
                    var childToMove = $('#carousel-thumbs .carousel-thumb:first-child').detach();
                    thumbsContainer.css('top', 0);
                    thumbsContainer.append(childToMove);
                    setTimeout(nextItem, cycleDelay);
                }
            }, 1300);
    }
    
    function initCarousel() {
        var itemsLoaded = 0;
        
        function imageLoad() {
            itemsLoaded ++;
            if (itemsLoaded == totalItems*2) {
                $('#carousel').
                css({
                    "visibility": "visible",
                    "opacity": 0
                }).
                animate({
                    "opacity": 1
                }, 500);
                
                setTimeout(nextItem, cycleDelay);
            }
        }

        thumbsContainer = $('#carousel-thumbs');
        
        carousel.find('.carousel-banner').each(function(i, elem) {
            elem = $(elem);
            var link = elem.find('a');
            var image = elem.find('img');
            banners.push({
                bannerElement: elem,
                name: image.attr('alt'),
                bannerImageElement: image,
                bannerURL: image.data('banner-src'),
                thumbnailURL: image.data('thumb-src'),
                type: link.data('type'),
                link: link.attr('href')
            });
        });
        totalItems = banners.length;
        
        // Initialize Thumbnails
        for (var i=0; i < totalItems; i++) {
            var def = banners[i];
            def.thumbElement = $('<div>');
            def.thumbElement.addClass('carousel-thumb');
            var linkElement = $('<a>');
            linkElement.attr('data-type', def.type);
            linkElement.attr('href', def.link);
            var thumbImageElement = $('<img>');
            thumbImageElement.bind('load', imageLoad);
            def.bannerImageElement.bind('load', imageLoad);
            thumbImageElement.attr('src', def.thumbnailURL);
            def.bannerImageElement.attr('src', def.bannerURL);
            
            linkElement.append(thumbImageElement);
            def.thumbElement.append(linkElement);
    
            // Put the first thumb last in the thumbanils container
            if (i == 0) {
                var firstThumb = def.thumbElement
                thumbsContainer.append(firstThumb);

                // Show the first image...
                currentBanner = def.bannerElement;
                currentBanner.show().css('z-index', 10);
            }
            else {
                firstThumb.before(def.thumbElement);
                // Hide other images...
                def.bannerElement.hide();
                def.bannerElement.css('z-index', 0);
            }
        }
    }
    
    if (carousel[0]) {
        initCarousel();
    }
    
});