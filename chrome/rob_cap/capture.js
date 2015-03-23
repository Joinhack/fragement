if (!String.prototype.trim) {
  (function() {
    // Make sure we trim BOM and NBSP
    var rtrim = /^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g;
    String.prototype.trim = function() {
      return this.replace(rtrim, '');
    };
  })();
}

$(document).ready(function () {

var allow = false;
var index = 0;
var domain = "http://www.yxdr.com/bijiaqi/bns/youxibi/";
var priceLimit = 0.005;
var totalPriceLimit = 50;
var delay = 2;
var ready = {};
var setting = {};
var currentPay = null;
var currentTab = null;
var currentPolicy = null;
var servers = [
	"dianxin2kuafu",
	"dianxinyiqukuafu",
	"dianxin3kuafu",
	"dianxinwuqukuafu",
	"dianxin6kuafu",
	"dianxin7kuafu",
	"dianxin8kuafu",
	"dianxin9kuafu",
	"dianxin10kuafu",
	"dianxinhongfuqukuafu",
	"dianxinchuanshuokuafu",
	"aoxuequkuafu",
	"dianxinshengshikuafu",
	"wangtongyiqukuafu",
	"wangtong2kuafu",
	"wangtong3kuafu",
	"wangtong5kuafu",
	"wangtongbinghunqukuafu",
	"wangtongkaitaikuafu",
	"nantianguokuafu"
];

chrome.extension.onMessage.addListener(function(msg, sender, sendResponse) {
	if(msg.event == "allowScan") {
		sendResponse({
			allow:allow,
			maxPrice: priceLimit
		});
		return;
	}

	if(msg.event == "allow5173") {
		var ok = allow && currentPay != null && currentPay.vendor == "5173";
		sendResponse({
			allow:ok
		});
		return;
	}
	if(msg.event == "allowdd373") {
		console.log(currentPay.vendor);
		var ok = allow && currentPay != null && currentPay.vendor == "DD373";
		sendResponse({
			allow:ok
		});
		return;
	}
	if(msg.event == "allowuu898") {
		console.log(currentPay.vendor);
		var ok = allow && currentPay != null && currentPay.vendor == "UU898";
		sendResponse({
			allow:ok
		});
		return;
	}

	if(msg.event == "queryPoicy") {
		var server = policies[msg.queryCond["server"]];
		var policy = null;
		currentPolicy = null;
		if(server != null) {
				var game = msg.queryCond["game"];
				if(game.indexOf("/") == -1)
					policy = $.extend({'price':currentPay.price}, setting , server[game]);
				else {
					var games = game.split("/");
					for(var i = 0; i < games.length; i++) {
						if(server[games[i].trim()] != null) {
							policy = $.extend({'price':currentPay.price}, setting , server[games[i].trim()]);
							break;
						}
					}
				}
				currentPolicy = policy;
		}
		sendResponse({
			policy:currentPolicy
		});
		return;
	}

	if(msg.event == "currentPoicy") {
		sendResponse({
			policy:currentPolicy
		});
		return;
	}

	$("#servers .server").css("color", "#000000");
	if(msg.event == "data") {
		sendResponse();
		processingData(msg.data);
		//next(false);
	}
	if(msg.event == "next") {
		sendResponse();
		next(false);
	}
	if(msg.event == "processnext") {
		sendResponse();
		try{
			chrome.tabs.remove(currentTab.id);
		}catch(e){}
		startPay();
	}
});

var processingData = function(data) {
	$(data).each(function(){
		if(ready[this.url] != null)
			return;
		var div = $("<div />").append("单价:" + this.price + " 总价:"  + this.totalPrice + " 平台:" + this.vendor + " server:" + this.server);
		div.append("  状态：");
		div.append($('<span class="state"/>').append("ready"));
		console.log(this);
		ready[this.url] = this;
		this.view = div;
		this.state = 'ready';
		$("#result").append(div);
	});
	startPay();
}

var startPay = function() {
	if(currentPay != null) {
		currentPay.state = "finish";
		$(".state", currentPay.view).contents().remove();
		$(".state", currentPay.view).append(currentPay.state);
		$(".state", currentPay.view).css('color', 'green');
		currentPay = null;
	}
	if(Object.keys(ready).length == 0) {
		next(false);
		return;
	}
	for(k in ready) {
		if(ready[k].state == 'ready') {
				currentPay = ready[k];
				break;
		} else {
			continue;
		}
	}
	if(currentPay == null) {
		next(false);
		return;
	}
	currentPay.state = "start";
	$(".state", currentPay.view).contents().remove();
	$(".state", currentPay.view).append(currentPay.state);
	$(".state", currentPay.view).css('color', 'yellow');
	chrome.tabs.create({
  	  url:currentPay.url
	}, function(tab){
		currentTab = tab;
	});
}



var delayTimer = null;

function next(noDelay) {
	var runNext = function() {
		$('#servers').children().remove();
		for(k in ready) {
			if(ready[k].state == 'finish' && ready[k].view) {
				ready[k].view.remove();
				ready[k].view = null;
			}
		}
		chrome.tabs.create({
  	  url:domain + servers[index] + "?p2=" + totalPriceLimit
		});
		index++;
		if(index >= servers.length)
			index = 0;
		$('#servers').append($("<div />").append(domain + servers[index]));
	};
	if(noDelay) {
		runNext();
	} else {
		if(delayTimer != null) clearTimeout(delayTimer);
		delayTimer = setTimeout(function(){
			runNext();
		}, delay*1000);
	}
}

$('#policy').change(function(){
	$('#policyBtn').show();
});

var polciyText = localStorage.getItem('polciyText');
if(polciyText != null)
	$('#policy').val(polciyText);

$('#policyBtn').click(function(){
	buildPolicy();
	localStorage.setItem('polciyText',$('#policy').val());
	$('#policyBtn').hide();
});

var policies = {};

(function(){

})();

var buildPolicy = function(){
	var policyText = $('#policy').val();
	var lines = policyText.split('\n');
	for(var i = 0; i < lines.length; i++) {
		var line = lines[i];
		if(line == '' || line[0] == '#')
			continue;
		var items = line.split("|");
		if(items.length != 7) {
			console.log("line:" + i + line);
			continue;
		}
		var server = policies[items[1]];
		if(server == null) {
			server = {};
			policies[items[1]] = server;
		}
		var game = server[items[2]];
		if(game != null) {
				console.log("policy already exist:" + line);
		} else {
			game = {};	
		}
		game["name"] = items[3];
		game["role"] = items[4];
		game["level"] = items[5];
		game["settingPrice"] = parseFloat(items[6]);
		server[items[2]] = game;
	}
}


buildPolicy();
for(var k in policies) {
	$('#qpolicysel').append($('<option value='+k+'>'+k+'</option>'));	
}

$('#qpolicybtn').click(function(){
	var sserv = $('#qpolicysel').val();
	var qv = $('#qpolicyval').val();
	var rs = "";
	for(var s in policies) {
		for(var g in policies[s]) {
			var game = policies[s][g];
			var price = sserv==s?qv:game["settingPrice"];
			rs += "腾讯|" + s + "|" + g + "|" + game["name"] + "|" + game["role"] + "|" + game["level"] + "|" + price + "\n";
		}
	}
	$('#policy').val(rs);
	$('#policy').change();
});

$('#capture').click(function(){
	allow = true;
	setting.phone = $('#phone').val();
	setting.gameRule = $('#gameRule').val();
	setting.secAnswer = $('#secAnswer').val();
	setting.payPasswd = $('#payPasswd').val();
	setting.danbao5173 = $('#danbao5173').prop("checked");
	setting.secType = parseInt($('#secType').val());
	priceLimit = parseFloat($('#price').val());
	totalPriceLimit = parseFloat($('#totalPrice').val());
	delay = parseInt($('#delay').val());
	if(confirm("单价限制:" + priceLimit + "总价限制:" + totalPriceLimit)) {
		buildPolicy();
		next(true);
	}
});

$('#stop').click(function(){
	allow = false;
});

});


