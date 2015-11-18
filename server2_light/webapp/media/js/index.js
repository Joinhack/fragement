(function($){
$(document).ready(function(){

$('.select').selectlist({click:function(){
	$('.select').selectlist("reset");
}});


var areachange = function(n, target, lastCall) {
	target.selectlist('clear');
	$.getJSON('/region/children/' + n.value, function(d){
		if(d.code != 0) {
			alert(d.msg);
			return d;
		}
		for(var i = 0; i < d.data.length; i++) {
			var data = d.data[i];
			target.selectlist("dataAppend", data);	
		}
		if(lastCall)
			lastCall(target);
	});
};

var sectionchange = function(n, target, lastCall) {
	target.selectlist('clear');
	$.getJSON('/community/list/' + n.value, function(d){
		if(d.code != 0) {
			alert(d.msg);
			return d;
		}
		for(var i = 0; i < d.data.length; i++) {
			var data = d.data[i];
			target.selectlist("dataAppend", data);	
		}
		if(lastCall)
			lastCall();
	});
};


function dialogMsg(msg) {
	$('.content', '.globalMsg').contents().remove();
	$('.content', '.globalMsg').append(msg);
	$('.globalMsg').dialog('show', true);
}

var addCommunityOkClick = function() {
	if(!$.validate($("[v-regex][v-regex!='']", ".addCommunity")))
		return;
	var that = this;
	dialogMsg('信息录入中');
	$('.addCommunity form').ajaxUpload({success: function(d){
		if(d.code != 0 || !d.data) {
			alert(d.msg);
			return d;
		}
		$('.select[name=community]', '.addHouse').selectlist('dataPrepend', d.data);
		$('.select[name=community]', '.addHouse').selectlist('select', d.data);
		$('.select', '.addCommunity').selectlist('select', null);
		$('input[type=text],input[type=hidden]', '.addCommunity').val('');
		$('.globalMsg').dialog('fadeOut', 1000);
	}});
	return;
}

var bindAddCommunityEvent = function(content) {
	
	$('.select[name="area"]', content).data('data', $('.select[name="area"]').data('data'));
	$('.select', content).selectlist();


	$('.select[name="area"]', content).selectlist("change", function(n){
		if(!n || !n.value)
			return;
		areachange(n, $('.select[name="section"]', content), function(){appendAddSection(content)});
	});
	$('.save-btn', content).click(function(){
		addCommunityOkClick();
	});
	$('.save-btn', content).submit(function(){
		
	});
	$("[v-regex][v-regex!='']", content).validate();
	content.show();
}

var clickAddCommunity = function(cb) {
	if($('.addCommunity').length > 0) {
		$('.addCommunity').dialog("show", true);
		return;
	}
	var that = this;
	$.getJSON('/community/add', function(d){
		if(d.code != 0) {
			alert(d.msg);
			return d;
		}
		var content = $(d.content);
		$('.t-body').append(content);
		bindAddCommunityEvent(content);
		cb();
	});
}

$('.select[name="section"]', '.addHouse').selectlist('change', function(n){
	if(!n || !n.value)
		return;
	var target = $('.select[name="community"]', '.addHouse');

	sectionchange(n,target, function(){
		target.selectlist("dataAppend",  {content:"<div style='color:blue;'>添加楼盘</div>", click: clickAddCommunity});
	});
});

var addSectionOkClick = function() {
	var that  = this;
	if(!$.validate($("[v-regex][v-regex!='']", ".addSection")))
		return;
	$('.addSection form').ajaxUpload({success: function(d){
		if(d.code != 0) {
			alert(d.msg);
			return;
		}
		$('.select[name=section]', '.addCommunity').selectlist("dataPrepend", d.data);
		$('input[type=text],input[type=hidden]', '.addSection').val('');
		$('.select','.addSection').selectlist("select", null);
		$(that).dialog("show", false);
	}});
	return;
}

$('form','.addSection').submit(function(){
	$('.addSection').dialog("okclick");
	return false;
});

$('.addSection').dialog({close:function(){
	$('.select[name=area]', ".addSection").selectlist("select", null);
	$('input[name=section]', ".addSection").val('');
}, ok:addSectionOkClick});

$('.globalMsg').dialog({disableClose:true, disableOk: true});

var appendAddSection = function(p){
	$('.select[name="section"]', p).selectlist("dataAppend", {content:"<div style='color:blue;'>添加商圈</div>", click:function(){
		var selected = $('.select[name=area]', p).selectlist("selected");
		if(selected)
			$('.select[name=area]', '.addSection').selectlist("select", selected);
		 $('.addSection').dialog("show", true);
	}});
}

$("[v-regex][v-regex!='']").validate();

$('input[name=community]').autoCompleteEditor({'url':'/community/q','processData':function(d){
	var rs = [];
	$(d.data).each(function(){
		rs.push({value:this.content, data:this.value});
	});
	return rs;
}});

$('.t-header .t-menu li a').mouseover(function(){
	$('.t-header .t-menu li a').removeClass('hover');
	$(this).addClass('hover');
}).mouseout(function(){
	$(this).removeClass('hover');
}).click(function(){
	var urls = {
		'addCommunity' : ''
	};
	$('.t-header .t-menu li a').removeClass('active');

	var cls = $(this).attr('bind');
	var target = $('.' + cls, '.t-body');
	$('.t-body>div').hide();
	var that = this;
	var active = function(){
		$(that).addClass('active');
	};
	if(target.length  > 0) {
		target.show(true);
		active();
		return;
	}
	var url = urls[cls];
	clickAddCommunity(active);
}); 

});

})(jQuery);