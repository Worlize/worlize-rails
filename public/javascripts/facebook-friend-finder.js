(function() {
    namespace('worlize.view');
    
    var FacebookFriendFinder = function(options) {
        // Extend object with configuration options
        for (var key in options) {
            if (options.hasOwnProperty(key)) {
                this[key] = options[key];
            }
        }
    };
    
    worlize.view.FacebookFriendFinder = FacebookFriendFinder;
    
    FacebookFriendFinder.prototype.show = function() {
        var s = this;
        this.showClickCatcher();
        this.render();
        
        // Check to see if the user is already logged in through facebook
        FB.getLoginStatus(function(response) {
            if (response.authResponse) {
                // Logged into facebook and connected
                s.loadData(response.authResponse.accessToken);
            }
            else {
                // not connected through facebook - prompt user to log in
                s.promptFacebookLogin();
            }
        });
    };
    
    FacebookFriendFinder.prototype.hide = function() {
        this.hideClickCatcher();
        this.container.remove();
        this.removeFacebookLoginListener();
    };
    
    FacebookFriendFinder.prototype.showClickCatcher = function() {
        this.clickCatcher = $('<div class="click-catcher"></div>');
        this.clickCatcher.css('z-index', 1000);
        $(document.body).append(this.clickCatcher);
    };
    
    FacebookFriendFinder.prototype.hideClickCatcher = function() {
        this.clickCatcher.remove();
    };
    
    FacebookFriendFinder.prototype.render = function() {
        this.container = $('<div class="popup-window-container">');
        this.container.css('z-index', 2000);
        
        this.el = $('<div class="friend-finder-window popup"></div>');
        this.titleEl = $('<h1>Facebook Friends</h1>');
        this.contentContainer = $('<div class="content-container"></div>');

        this.controlBar = $('<div class="control-bar"></div>');
        this.closeButton = $('<button class="close-button">Cancel</button>');
        this.controlBar.append(this.closeButton);

        this.container.append(this.el);

        this.el.append(this.controlBar);
        this.el.append(this.titleEl);
        this.el.append(this.contentContainer);

        $(document.body).append(this.container);
        
        var s = this;
        this.closeButton.click(function(event) {
            s.hide();
        });

        this.rendered = true;
    };
    
    FacebookFriendFinder.prototype.promptFacebookLogin = function() {
        this.facebookLoginPrompt = $('<div class="facebook-login-prompt"></div>');
        this.facebookLoginPrompt.append('<p>To find your Facebook friends on Worlize,<br>' +
                                           'you must log into your Facebook account.</p>')
        
        this.facebookLoginButton = $('<div class="fb-login-button" data-show-faces="false" data-width="71"></div>');
        this.facebookLoginButton.attr('data-scope', requestedFacebookPermissions);
        this.facebookLoginPrompt.append(this.facebookLoginButton);
        
        this.contentContainer.append(this.facebookLoginPrompt);
        FB.XFBML.parse(this.facebookLoginPrompt[0]);

        this.addFacebookLoginListener();
    };
    
    FacebookFriendFinder.prototype.removeFacebookLoginPrompt = function() {
        if (this.facebookLoginPrompt) {
            this.facebookLoginPrompt.remove();
            this.facebookLoginPrompt = null;
        }
    };
    
    FacebookFriendFinder.prototype.addFacebookLoginListener = function() {
        var s = this;
        if (this.facebookLoginListener) {
            return;
        }

        this.facebookLoginListener = function(response) {
            s.removeFacebookLoginListener();
            if (response.status === 'connected') {
                s.removeFacebookLoginPrompt();
                s.loadData(response.authResponse.accessToken);
            }
        };

        FB.Event.subscribe('auth.login', this.facebookLoginListener);
    };
    
    FacebookFriendFinder.prototype.removeFacebookLoginListener = function() {
        if (this.facebookLoginListener) {
            FB.Event.unsubscribe('auth.login', this.facebookLoginListener);
            this.facebookLoginListener = null;
        }
    };
    
    FacebookFriendFinder.prototype.loadData = function(accessToken) {
        var s = this;
        $.getJSON(
            '/friends/facebook',
            { access_token: accessToken },
            function(data, textStatus, jqXHR) {
                if (textStatus === 'success' && data.success) {
                    console.log(data);
                    this.data = data.data;
                    s.renderFriendLists(this.data);
                }
                else {
                    // handle error
                }
            }
        );
    };
    
    FacebookFriendFinder.prototype.renderFriendLists = function(data) {
        var container = $('<div class="friend-picker"></div>');

        // Render friends already on Worlize
        var friendsOnWorlize = data['not_yet_friended'];
        if (friendsOnWorlize.length > 0) {
            var heading = $('<h1 class="friends-on-worlize"></h1>');
            heading.text("Ready to Connect");
            container.append(heading);
            
            var listContainer = $('<ul class="friends-on-worlize friend-list"></ul>');
            for (var i=0,len=friendsOnWorlize.length; i < len; i ++) {
                var friend = friendsOnWorlize[i];
                var friendEl = $('<li class="friend"></li>');
                friendEl.data('friend', friend);

                var friendImage = $('<img>');
                friendImage.attr('src', friend.picture);
                friendImage.attr('alt', friend.name);

                var friendName = $('<p class="name"></p>');
                friendName.text(friend.name);
                
                var inviteButton = $('<button class="invite-button">Invite</button>');

                friendEl.append(friendImage);
                friendEl.append(friendName);
                friendEl.append(inviteButton);
                listContainer.append(friendEl);
            }
            container.append(listContainer);
        }
        
        // Render friends not yet on Worlize
        var notOnWorlize = data['not_on_worlize'];
        if (notOnWorlize.length > 0) {
            var heading = $('<h1 class="not-on-worlize"></h1>');
            heading.text("Facebook Friends");
            container.append(heading);
            
            var listContainer = $('<ul class="not-on-worlize friend-list"></ul>');
            for (var i=0,len=notOnWorlize.length; i < len; i ++) {
                var friend = notOnWorlize[i];
                var friendEl = $('<li class="friend"></li>');
                friendEl.data('friend', friend);

                var friendImage = $('<img>');
                friendImage.attr('src', friend.picture);
                friendImage.attr('alt', friend.name);

                var friendName = $('<p class="name"></p>');
                friendName.text(friend.name);
                
                var inviteButton = $('<button class="invite-button">Invite</button>');

                friendEl.append(friendImage);
                friendEl.append(friendName);
                friendEl.append(inviteButton);
                listContainer.append(friendEl);
            }
            container.append(listContainer);
        }
        
        this.contentContainer.append(container);
    };
    
    FacebookFriendFinder.prototype.renderFriendsOnWorlize = function(friends) {
        if (this.friendsOnWorlizeContainer) {
            this.friendsOnWorlizeContainer.remove();
        }
    };
    
    
    FacebookFriendFinder.prototype.centerDialog = function() {
        
    };
})();
