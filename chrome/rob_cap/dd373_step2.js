window.alert = function(){};
$(document).ready(function  () {
	if(window.DialogHide) {
		DialogHide();
	}
	$($('#promit option')[1]).attr('selected', 'selected');
	
	$('input[name=verify_paypassword]').val('oy666999');
	$('.ClassSub').click();
	$("#succesform").submit();
});