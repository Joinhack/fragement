$(document).ready(function () {
	$('#PayDirectlyAuthType1_ddlSecurityAnswer option:last').attr('selected', 'selected');
	$('#PayDirectlyAuthType1_txtSecurityAnswer').val('…˙»’');
	$('input[name=btnAffirmPay]').click();
});
