(function($){

$(document).ready(function(){
	$('.submit').click(function(){
		$.ajaxUpload({
			form:$('form'),
			type: 'post',
			error: function(data, status, e){
				alert(e);
			},
			success: function(data){
				if(data.code != 0) {
					var msg = $('<div class="alert">' + data.msg + '</div>');
					msg.appendTo($('.bottom'));
					msg.fadeOut(2000, function(){
						$(this).remove();
					});
					return;
				}
				window.location = data.redirect;
		}});
	});

	$('input', 'form').keyup(function(e){
		if(e.keyCode == 13)
			$('.submit').click();
	});

	$('.cancel').click(function(){
		$('input', 'form').val('');
	});
});

})(jQuery);