// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults


// Code reference: http://www.facebook.com/note.php?note_id=126728638774&comments&ref=mf
$(document).ajaxSend(function(event, request, settings) {
  if (settings.type == 'get' || settings.type == 'GET' || typeof(AUTH_TOKEN) == "undefined") return;
  var authTokenRegExp = /authenticity_token=\w{40}/
  settings.data = settings.data || "";
  if (authTokenRegExp.test(settings.data))
  {
    settings.data=settings.data.replace(authTokenRegExp, "access_token=" + encodeURIComponent(AUTH_TOKEN));
  }
  else
  {
    settings.data += (settings.data ? "&" : "") + "access_token=" + encodeURIComponent(AUTH_TOKEN);
  }
})