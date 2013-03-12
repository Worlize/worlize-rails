
// remap jQuery to $
(function($){

  /************************************************************************************
  ** jQuery Placehold version 0.3
  ** (cc) Jason Garber (http://sixtwothree.org and http://www.viget.com)
  ** Licensed under the CC-GNU GPL (http://creativecommons.org/licenses/GPL/2.0/)
  *************************************************************************************/
	$.fn.placehold = function( placeholderClassName ) {
		var placeholderClassName = placeholderClassName || "placeholder",
			supported = $.fn.placehold.is_supported();

		function toggle() {
			for ( i = 0; i < arguments.length; i++ ) {
				arguments[i].toggle();
			}
		}

		return supported ? this : this.each( function() {
			var $elem = $( this ),
				placeholder_attr = $elem.attr( "placeholder" );

			if ( placeholder_attr ) {
				if ( !$elem.val() || $elem.val() == placeholder_attr ) {
					$elem.addClass( placeholderClassName ).val( placeholder_attr );
				}

				if ( $elem.attr( "type" ) == "password" ) {
				  var field_size = $elem.attr('size');
				  var shiv_options = {
						"class": $elem.attr( "class" ) + " " + placeholderClassName,
						"value": placeholder_attr,
						"type": "text"
					};
					if (field_size) {
					  shiv_options['size'] = field_size;
					}
					var $pwd_shiv = $( "<input />", shiv_options);

					$pwd_shiv.bind( "focus.placehold", function() {
						toggle( $elem, $pwd_shiv );
						$elem.focus();
					});

					$elem.bind( "blur.placehold", function() {
						if ( !$elem.val() ) {
							toggle( $elem, $pwd_shiv );
						}
					});

					$elem.hide().after( $pwd_shiv );
				}

				$elem.bind({
					"focus.placehold": function() {
						if ( $elem.val() == placeholder_attr ) {
							$elem.removeClass( placeholderClassName ).val( "" );
						}
					},
					"blur.placehold": function() {
						if ( !$elem.val() ) {
							$elem.addClass( placeholderClassName ).val( placeholder_attr );
						}
					}
				});

				$elem.closest( "form" ).bind( "submit.placehold", function() {
					if ( $elem.val() == placeholder_attr ) {
						$elem.val( "" );
					}

					return true;
				});
			}
		});
	};

	$.fn.placehold.is_supported = function() {
		return "placeholder" in document.createElement( "input" );
	};



})(this.jQuery);

(function($) {
	$.fn.ellipsis = function(enableUpdating){
		var s = document.documentElement.style;
		if (!('textOverflow' in s || 'OTextOverflow' in s)) {
			return this.each(function(){
				var el = $(this);
				if(el.css("overflow") == "hidden"){
					var originalText = el.html();
					var w = el.width();
					
					var t = $(this.cloneNode(true)).hide().css({
                        'position': 'absolute',
                        'width': 'auto',
                        'overflow': 'visible',
                        'max-width': 'inherit'
                    });
					el.after(t);
					
					var text = originalText;
					while(text.length > 0 && t.width() > el.width()){
						text = text.substr(0, text.length - 1);
						t.html(text + "...");
					}
					el.html(t.html());
					
					t.remove();
					
					if(enableUpdating == true){
						var oldW = el.width();
						setInterval(function(){
							if(el.width() != oldW){
								oldW = el.width();
								el.html(originalText);
								el.ellipsis();
							}
						}, 200);
					}
				}
			});
		} else return this;
	};
})(jQuery);

(function() {

// usage: log('inside coolFunc',this,arguments);
// paulirish.com/2009/log-a-lightweight-wrapper-for-consolelog/
window.log = function(){
  log.history = log.history || [];   // store logs to an array for reference
  log.history.push(arguments);
  if(this.console){
    console.log( Array.prototype.slice.call(arguments) );
  }
};


// catch all document.write() calls
(function(doc){
  var write = doc.write;
  doc.write = function(q){ 
    log('document.write(): ',arguments); 
    if (/docwriteregexwhitelist/.test(q)) write.apply(doc,arguments);  
  };
})(document);

})();