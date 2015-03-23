window.alert = function(){};
$(document).ready(function  () {
	if(window.DialogHide) {
		DialogHide();
	}
	$($('#promit option')[1]).attr('selected', 'selected');
	
	
	$('.ClassSub').click();
	$("#succesform").submit();
});