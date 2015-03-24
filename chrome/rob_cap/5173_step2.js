
$(document).ready(function () {
	var location  = window.location.toString();
	
	
	$('#divGameRoleItems input:checked').click();
	$('#liNewRole  input[type=radio]:checked').click();
	$('#txtOldRole,#txtReceivingRole,#txtSureReceivingRole,#txtReOldRole').blur();
	$('a[rel=Star1]').click();
	$('#kf_list li:first').click();
	$('#rdbtnOffPostSaleIndemnity,#PurchaseOrderNew1_rdNoPostSale').attr("checked", "checked");
	$('#PurchaseOrderNew1_btnCreateOrder').click();
	$('#linkOk').click();
	

});