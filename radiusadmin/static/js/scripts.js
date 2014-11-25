//left side accordion

$(function() {
    $('#nav-accordion').dcAccordion({
        eventType: 'click',
        saveState: true,
        disableLink: true,
        autoExpand:false,
        autoClose:true,
        cookie:"dcjq-accordion"
    });

});


$(function() {

jQuery.validator.addMethod("re", function(value, element) {
	var re = new RegExp($(element).attr("re"));
	return this.optional(element) || (re.test(value)); 
}, "无效格式");



});

$.fn.dataTableExt.oApi.formatAOData = function(tab, aoData) {
	var order = "asc";
	var orderCol = 0;
	var offset = 0;
	var limit = 0;
	for(var i = 0; i < aoData.length; i++) {
		if(aoData[i].name == "iDisplayStart") {
			offset =  aoData[i].value;
		}
		if(aoData[i].name == "iDisplayLength") {
			limit =  aoData[i].value;
		}
		if(aoData[i].name == "iSortCol_0") {
			orderCol = aoData[i].value;
		}
		if(aoData[i].name == "sSortDir_0") {
			order = aoData[i].value;
		}
	}
	aoData.splice(0);
	aoData.push({"name":"order", "value":order});
	aoData.push({"name":"orderCol", "value":orderCol});
	aoData.push({"name":"offset", "value":offset});
	aoData.push({"name":"limit", "value":limit});
}


$('.sidebar-toggle-box .fa-bars').click(function (e) {
        $('#sidebar').toggleClass('hide-left-bar');
    $('#main-content').toggleClass('merge-left');
    e.stopPropagation();
    if( $('#container').hasClass('open-right-panel')){
        $('#container').removeClass('open-right-panel')
    }
    if( $('.right-sidebar').hasClass('open-right-bar')){
        $('.right-sidebar').removeClass('open-right-bar')
    }

    if( $('.header').hasClass('merge-header')){
        $('.header').removeClass('merge-header')
    }



});
