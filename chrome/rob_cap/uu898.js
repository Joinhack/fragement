chrome.extension.sendMessage(null, {
	event:"allowuu898"
}, function(event){
	console.log(event);
	if(event == null) return;
	if(event.allow) {
		var location  = window.location.toString();
		$(document).ready(function(){
			if(location.indexOf('http://www.uu898.com/consignInfo.aspx') == 0 ||
				location.indexOf('http://www.uu898.com/escortInfo.aspx') == 0
				) {

				if($('#ctl00_ContentPlaceHolder1_btnBuy').length > 0) {
					var policy = {};
					policy["server"] = $("a", $('.crumbs li')[4]).text();
					policy["game"] = $("a", $('.crumbs li')[5]).attr('title');
					chrome.extension.sendMessage(null, {
						event:"queryPoicy",
						queryCond:policy
					}, function(rs){
						var policy = rs.policy;
						if(policy == null || policy.price == null || policy.price > policy.settingPrice) {
							processNext();
							return	
						}

						addjs(chrome.extension.getURL('uu898_step1.js'));
					});
					
				} else {
					processNext();
				}
			}
			if(location.indexOf('http://www.uu898.com/createOrder.aspx') == 0) {
				chrome.extension.sendMessage(null, {
					event:"currentPoicy",
					queryCond:policy
				}, function(rs){
					var policy = rs.policy;
					
					$('#txtGameAccount').val(policy.name);
					$('#txtGameAccountR').val(policy.name);
					$('input[name=txtLevel]').val(policy.level);
					addjs(chrome.extension.getURL('uu898_step2.js'));
				});
			}
			if(location.indexOf('http://user.uu898.com/pay.aspx') == 0) {
				$('#uv1_txtZhifuPass').val(policy.payPasswd);
				addjs(chrome.extension.getURL('uu898_step3.js'));
			}
			if(location.indexOf('http://www.uu898.com/orderInfo.aspx') == 0) {
				processNext();
			}
		});
		

	}
});

