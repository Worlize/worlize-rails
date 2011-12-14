PromoDialog = function(data) {
    this.promo = data.promo;
    if (this.promo.mode === 'daily_giveaway') {
        this.statusByDate = data.status_by_date;
    }
}

PromoDialog.container = null;

PromoDialog.getDialogContainer = function() {
    if (this.container === null) {
        this.container = $('<div class="promo-dialog-container"></div>');
        $(document.body).append(this.container);
    }
    return this.container;
};

PromoDialog.showDialogContainer = function() {
    this.getDialogContainer().show();
};

PromoDialog.hideDialogContainer = function() {
    this.getDialogContainer().hide();
};

PromoDialog.checkForDialogs = function() {
    jQuery.getJSON('/dialogs/check_for_dialogs', function(data) {
        if (data.success) {
            var dialogs = data.dialogs;
            // TODO: Handle multiple dialogs
            var dialogData = dialogs[0];
            if (dialogData) {
                var dialog = new PromoDialog(dialogData);
                dialog.show();
            }
        }
    });
};

PromoDialog.prototype.show = function() {
    var s = this;
    this.el = $('<div class="promo-dialog"></div>');
    this.el.addClass('promo-dialog-' + this.promo.id);
    
    this.contentEl = $('<div class="promo-dialog-content"></div>');
    this.el.append(this.contentEl);
    
    this.titleEl = $('<h1></h1>');
    this.titleEl.text(this.promo.name);
    this.contentEl.append(this.titleEl);
    
    if (this.promo.mode === 'daily_giveaway') {
        this.giftStatusContainer = $('<div class="gift-status-container"></div>');
        for (var i=0; i < this.statusByDate.length; i ++) {
            var giftStatus = this.statusByDate[i];
            var giftStatusElement = $('<div class="gift-status"></div>');
            giftStatusElement.addClass("status-"+giftStatus.status);

            var giftStatusIconElement = $('<div class="icon"></div>');
            giftStatusElement.append(giftStatusIconElement);

            var giftStatusDayLabel = $('<p class="day-label"></p>');
            giftStatusDayLabel.text("Day " + giftStatus.day_index);
            giftStatusElement.append(giftStatusDayLabel);

            this.giftStatusContainer.append(giftStatusElement)
        }
        this.contentEl.append(this.giftStatusContainer);
    }
    
    this.closeButtonEl = $('<div class="close-button">Close</div>');
    this.closeButtonEl.bind('click', function() {
        s.hide();
    });
    
    this.el.append(this.closeButtonEl);
    PromoDialog.getDialogContainer().append(this.el);
    PromoDialog.showDialogContainer();
}

PromoDialog.prototype.hide = function() {
    this.el.remove();
    PromoDialog.hideDialogContainer();
}