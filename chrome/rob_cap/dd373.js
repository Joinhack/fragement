chrome.extension.sendMessage(null, {
	event:"allowdd373"
}, function(event){
	console.log(event);
	if(event == null) return;
	if(event.allow) {
		var location  = window.location.toString();
		$(document).ready(function(){
			if(location.indexOf('http://www.dd373.com/buy/third-') == 0) {
				if($('.TIBtn').length == 0)
					processNext();
				else {
					var policy = {};
					policy["server"] = $($('.CurrNave a')[1]).text();
					policy["game"] = $($('.CurrNave a')[2]).text();
					chrome.extension.sendMessage(null, {
						event:"queryPoicy",
						queryCond:policy
					}, function(rs){
						var policy = rs.policy;
						if(policy == null || policy.price == null || policy.price > policy.settingPrice) {
							processNext();
							return	
						}
						addjs(chrome.extension.getURL('dd373_step1.js'));
					});
					
				}
			} 
			 
			if(location.indexOf('http://www.dd373.com/buy/four.html') == 0) {
				chrome.extension.sendMessage(null, {
					event:"currentPoicy",
					queryCond:policy
				}, function(rs){
					var policy = rs.policy;
					var gr = $('input[type=radio][name=RoleName][value='+policy.name+']')
					gr.attr('checked', 'checked');
					if(gr.length == 0) {
						$('input[type=radio][name=RoleName][value=]').attr('checked', 'checked');
						$('input[name=Weike_b9b2eb9c-99fa-4930-bb4b-989d3c3d65da]').val(policy.name);
					}
					$('input[name=Weike_105afd79-a7af-4c51-88ac-d0f001e0fe82]').val(policy.role);
					
					$('input[name=Weike_90a66fec-8acc-4376-aef4-dbda1ee0de41]').val(policy.phone);
					$('input[name=Weike_1e524ee5-f040-45b9-8eed-a74bbd023c4d]').val(policy.gameRule);
					$('input[name=verify_paypassword]').val(policy.payPasswd);
					addjs(chrome.extension.getURL('dd373_step2.js'));
				});
			}
			if(location.indexOf('http://www.dd373.com/buy/finish.html') == 0) {
				processNext("finish");
			}
		});
		
	}
});

