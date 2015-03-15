if (!String.prototype.trim) {
  (function() {
    // Make sure we trim BOM and NBSP
    var rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g;
    String.prototype.trim = function() {
      return this.replace(rtrim, '');
    };
  })();
}

function addjs (url) {
	var s = document.createElement('script');
	s.src = url;
	s.onload = function() {
    this.parentNode.removeChild(this);
	};
	(document.head||document.documentElement).appendChild(s);
}

function processNext() {
	chrome.extension.sendMessage(null, {
		event:"processnext"
	}, function(event){
		window.close();
	});
	
}