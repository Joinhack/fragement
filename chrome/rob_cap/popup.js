$(document).ready(function () {

function openOptions() {
  var url = "capture.htm";

  var fullUrl = chrome.extension.getURL(url);
  chrome.tabs.create({
    url:url
  });
  window.close();
  // chrome.tabs.getAllInWindow(null, function (tabs) {
  //     for (var i in tabs) { // check if Options page is open already
  //         if (tabs.hasOwnProperty(i)) {
  //             var tab = tabs[i];
  //             if (tab.url == fullUrl) {
  //                 chrome.tabs.update(tab.id, { selected:true }); // select the tab
  //                 return;
  //             }
  //         }
  //     }
  //     chrome.tabs.getSelected(null, function (tab) { // open a new tab next to currently selected tab
         
  //     });
      
  // });
}

$('#capture').click(function () {
	openOptions();
});
});