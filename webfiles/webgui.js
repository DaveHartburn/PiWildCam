/* PiWildCam java script, makes the web gui a bit more friendly */

function updateVisibleFields() {
  var capmode=document.getElementById('capmode');
  var newmode=capmode.value;
  switch (newmode) {
    case 's':
      var showElms=['stillOnly', 'bothMotion'];
      var hideElms=['videoOnly', 'timelapse'];
      break;
    case 'v':
      var showElms=['videoOnly', 'bothMotion'];
      var hideElms=['stillOnly', 'timelapse'];
      break;
    case 't':
      var showElms=['timelapse'];
      var hideElms=['videoOnly', 'stillOnly', 'bothMotion'];
      break;
  }
  for(i=0; i<showElms.length; i++) {
    var items=document.getElementsByClassName(showElms[i]);
    for(j=0; j<items.length; j++) {
      items[j].style.display="table-row";
    }
  }
  for(i=0; i<hideElms.length; i++) {
    var items=document.getElementsByClassName(hideElms[i]);
    for(j=0; j<items.length; j++) {
      items[j].style.display="none";
    }
  }
}
