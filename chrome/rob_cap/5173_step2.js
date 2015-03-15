
$(document).ready(function () {
	var location  = window.location.toString();
	$('#rdOldRole').attr('checked', 'checked');
	if(window.chang) {
		chang($('#rdOldRole'), 1);
	}
	
	$('#divGameRoleItems input:checked').click();
	$('#liNewRole  input[type=radio]:checked').click();
	$('#txtOldRole,#txtReceivingRole,#txtSureReceivingRole,#txtReOldRole').blur();
	$('a[rel=Star1]').click();
	$('#kf_list li:first').click();
	$('#rdbtnOffPostSaleIndemnity,#PurchaseOrderNew1_rdNoPostSale').attr("checked", "checked");
	$('#PurchaseOrderNew1_btnCreateOrder').click();
	$('#linkOk').click();
	

});