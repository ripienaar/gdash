$(document).ready(function() {
  if($('#dt_from').val() != 'from')
    $('#toggleDateTimePicker').parent().addClass('active');
  else
    $('#dateTimePicker').hide();
});

$(function() {
  $('#toggleDateTimePicker').click(function() {
    $('#dateTimePicker').toggle(400);
  });
});

$(function() {
  var startDateTextBox = $('#dt_from');
  var endDateTextBox = $('#dt_to');
  startDateTextBox.datetimepicker({
    dateFormat: 'yy-mm-dd',
    onClose: function(dateText, inst) {
      setDestinationDate(startDateTextBox, endDateTextBox, dateText);
    }
  });
  endDateTextBox.datetimepicker({ 
    dateFormat: 'yy-mm-dd',
    onClose: function(dateText, inst) {
      setDestinationDate(endDateTextBox, startDateTextBox, dateText);
    }
  });
});

function getURLParameter(name) {
  return decodeURIComponent(
    (RegExp(name + '=' + '(.+?)(&|$)').exec(location.search)||[,""])[1]
  );
}

function setDestinationDate(srcDateBox, destDateBox, dateText)
{
  if (destDateBox.val() == destDateBox.prop("defaultValue"))
    destDateBox.val(dateText);
  else {
    var startDate = $('#dt_from').datetimepicker('getDate');
    var endDate = $('#dt_to').datetimepicker('getDate');
    if (startDate > endDate)
      destDateBox.datetimepicker('setDate', srcDateBox.datetimepicker('getDate'));
  }
}

function formatSelectedDate(date) {
  return "" + zeroPad(date.getMonth() + 1) + "/" + 
    zeroPad(date.getDate()) + "/" 
    + date.getFullYear() + " " 
    + zeroPad(date.getHours()) + ":" + 
    zeroPad(date.getMinutes());
}

function selectDt() {
  dt_from = $('#dt_from').datetimepicker('getDate');
  dt_to = $('#dt_to').datetimepicker('getDate');
  window.location = buildGraphiteDateUrl(dt_from, dt_to);
  return true;
}

function buildGraphiteDateUrl(dt_from, dt_to)
{
  from = buildGraphiteDateString(dt_from);
  to = buildGraphiteDateString(dt_to);
  params = "time/" + from + "/" + to;
  newurl = document.URL.replace(/#/g, '');
  regex = /((time|\?*&from=|\?*&until=).+)/g;
  if (newurl.match(regex)) {
    newurl = newurl.replace(regex,"");
  }
  return newurl + params;
}

function buildGraphiteDateString(date)
{
  val = zeroPad(date.getHours()) + "%3A" + zeroPad(date.getMinutes()) + "_" + date.getFullYear() + zeroPad(date.getMonth()+1) + zeroPad(date.getDate());
  return val;
}

function zeroPad(num) {
	num = "" + num
	if (num.length == 1) {
		num = "0" + num
	}
	return num
}
