(function() {
    function SocialFriendFinder(options) {
        // Extend object with configuration options
        for (var key in options) {
            if (options.hasOwnProperty(key)) {
                this[key] = options[key];
            }
        }
        
    };
    
    SocialFriendFinder.prototype.renderTo = function(selector) {
        this.rootEl = $(selector);
        
        this.el = $('<div></div>');
        this.titleBarEl = $('<h1 class="title-bar"></h1>');
    };
    
    SocialFriendFinder.prototype.loadFriends = function() {
        
    };
})();