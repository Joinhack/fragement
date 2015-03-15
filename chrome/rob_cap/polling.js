var maxPrice = 0.005;
chrome.extension.sendMessage(null, {
	event:"allowScan"
}, function(event){
	
	if(event == null) return;
	if(event.allow) {
		$(document).ready(function () {
			waitLoading();
			maxPrice = event.maxPrice;
		});
	}
});


	
var timer = null;
var start = new Date();
var nextPage = function() {
	chrome.extension.sendMessage(null, {
		event:"nextServer"
	}, function(){
		window.close();
	});
} 
var waitLoading = function() {
	var now = new Date();
	if(start.getTime() - now.getTime() > 5000) {
		nextPage();
		return;
	}
	if($('#divProgress').length > 0) {
		timer = setTimeout(function() {
				if(timer != null) clearTimeout(timer);
				timer = null;
				waitLoading();
		}, 200);
		return;
	}
	processing();
};

var processing = function() {
	var rows = $('.body', '#list_m2');
	var items = [];
	$(rows).each(function(){
		
		var price = $('.item1', $(this)).contents()[0].textContent;
		var gold = $('.item3', $(this)).contents()[0].textContent;
		var totalPrice = $('.item4', $(this)).contents()[0].textContent;
		var vendor = $('.item8', $(this)).contents()[0].textContent;
		var server = $('.item7', $(this)).contents()[0].textContent;
		var url = $('.itema a', $(this)).attr("href");
		
		var o = {};
		o.price = parseFloat(price);
		if(o.price >= maxPrice )
			return;
		o.gold = parseFloat(gold);
		o.totalPrice = parseFloat(totalPrice);
		o.vendor = vendor;
		o.url = url;
		o.server = server;
		items.push(o);
	});

	chrome.extension.sendMessage(null, {
		event:"data",
		data: items
	}, function(event){
		window.close();
	});
	
}


