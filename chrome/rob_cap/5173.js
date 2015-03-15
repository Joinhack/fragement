chrome.extension.sendMessage(null, {
	event:"allow5173"
}, function(event){
	console.log(event);
	if(event == null) return;
	if(event.allow) {
		var location  = window.location.toString();
		$(document).ready(function(){
			if(location.indexOf('http://danbao.5173.com/detail') == 0) {
				if($('.btn_o140.btn_left').length > 0) {
					var policy = {};
					policy["server"] = $('#hlGameArea').text();
					policy["game"] = $('#hlGameServer').text();
					chrome.extension.sendMessage(null, {
						event:"queryPoicy",
						queryCond:policy
					}, function(rs){
						var policy = rs.policy;
						if(policy == null || policy.price == null || policy.price > policy.settingPrice) {

							processNext();
							return	
						}

						addjs(chrome.extension.getURL('5173_step1.js'));
					});
				} else
					processNext();
			} 
			 
			if(location.indexOf('http://consignment.5173.com/detail') == 0 ) {
				if($('#linkCreateOrder').length > 0) {
					var policy = {};
					policy["server"] = $('#HLAreas').text();
					policy["game"] = $('#HLServe').text();
					chrome.extension.sendMessage(null, {
						event:"queryPoicy",
						queryCond:policy
					}, function(rs){
						var policy = rs.policy;
						if(policy == null || policy.price == null || policy.price > policy.settingPrice) {
							processNext();
							return	
						}
						addjs(chrome.extension.getURL('5173_step1.js'));
					});
				} else
					processNext();
			}
			if(location.indexOf("http://danbao.5173.com/auction/buynew/PurchaseOrderNew.aspx") == 0) {
				chrome.extension.sendMessage(null, {
						event:"currentPoicy",
						queryCond:policy
					}, function(rs){
						var policy = rs.policy;
						var fill = true;
						$('#divGameRoleItems label').each(function(){
							if($(this).text() == policy.name) {
								$('#'+$(this).attr('for')+'').attr('checked', "checked");
								fill = false;
							}
						});
						if(fill) {
							$('#PurchaseOrderNew1_BuyerGameRoleInfo1_txtGameRole,#PurchaseOrderNew1_BuyerGameRoleInfo1_txtGameRoleValidate').val(policy.name);
						}
						
						$('#PurchaseOrderNew1_txtRoleGrade').val(policy.level);
						addjs(chrome.extension.getURL('5173_step2.js'));
					});
			} 
			if(location.indexOf("http://consignment.5173.com/PurchaseProcess/fillOrder.aspx") == 0) {
				chrome.extension.sendMessage(null, {
						event:"currentPoicy",
						queryCond:policy
					}, function(rs){
						var policy = rs.policy;
						var fill = true;
						$('#liNewRole  span[for]').each(function(){
							if($(this).text() == policy.name) {
								$('#'+$(this).attr('for')+'').attr('checked', "checked");
								fill = false;
							}
						});
						if(fill) {
							$('#txtOldRole,#txtReceivingRole,#txtSureReceivingRole,#txtReOldRole').val(policy.name);
						}
						
						$('#PurchaseOrderNew1_txtRoleGrade').val(policy.level);
						addjs(chrome.extension.getURL('5173_step2.js'));
					});
			}
			if(location.indexOf("http://consignment.5173.com/PurchaseProcess/goPayFor.aspx") == 0) {
				addjs(chrome.extension.getURL('5173_step3.js'));
			}
			if(location.indexOf("http://danbao.5173.com/auction/Pay/GoPayfor.aspx") == 0) {
				addjs(chrome.extension.getURL('5173_step3.js'));
			}
			

			if(location.indexOf("https://mypay.5173.com/payorder/paydirectly.aspx") == 0) {
				addjs(chrome.extension.getURL('5173_step4.js'));
			} 

			if(location.indexOf("http://consignment.5173.com/PurchaseProcess/getGoods.aspx") == 0 ||location.indexOf("http://danbao.5173.com/auction/buy/Common.aspx") ==0) {
					processNext();
			}

		});
		

	}
});

