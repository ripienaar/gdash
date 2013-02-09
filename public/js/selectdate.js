$(document).ready(function() {
  $.cookie.json = true
  setDateFromCookie();
  hideDateTimePicker();
});

$(function() {
  var startDateTextBox = $('#dt_from');
  var endDateTextBox = $('#dt_to');
  startDateTextBox.datetimepicker({ 
    onClose: function(dateText, inst) {
      if (endDateTextBox.val() != '') {
        var testStartDate = startDateTextBox.datetimepicker('getDate');
        var testEndDate = endDateTextBox.datetimepicker('getDate');
        if (testStartDate > testEndDate)
          endDateTextBox.datetimepicker('setDate', testStartDate);
      }
      else {
        endDateTextBox.val(dateText);
      }
    },
    onSelect: function (selectedDateTime){
      endDateTextBox.datetimepicker('option', 'minDate', startDateTextBox.datetimepicker('getDate') );
    }
  });
  endDateTextBox.datetimepicker({ 
    onClose: function(dateText, inst) {
      if (startDateTextBox.val() != '') {
        var testStartDate = startDateTextBox.datetimepicker('getDate');
        var testEndDate = endDateTextBox.datetimepicker('getDate');
        if (testStartDate > testEndDate)
          startDateTextBox.datetimepicker('setDate', testEndDate);
      }
      else {
        startDateTextBox.val(dateText);
      }
    },
    onSelect: function (selectedDateTime){
      startDateTextBox.datetimepicker('option', 'maxDate', endDateTextBox.datetimepicker('getDate') );
    }
  });
});

function setDateFromCookie() {
  value = $.cookie("dateSelected")
  if(value) {
    $('#dt_from').val(formatSelectedDate(new Date(value.from)));
    $('#dt_to').val(formatSelectedDate(new Date(value.to)));
  }
}

function formatSelectedDate(date) {
  return "" + zeroPad(date.getMonth() + 1) + "/" + 
    zeroPad(date.getDate()) + "/" 
    + date.getFullYear() + " " 
    + zeroPad(date.getHours()) + ":" + 
    zeroPad(date.getMinutes());
}

function storeDatesToCookie(dt_from, dt_to) {
  value = { from: dt_from, to: dt_to }
  $.cookie('dateSelected', value , { expires: 14, path: '/' });
}

function hideDateTimePicker() {
  $('#dateTimePicker').hide();
  $('#toggleDateTimePicker').click(function() {
    $('#dateTimePicker').toggle(400);
  });
}

function selectDt() {
  dt_from = $('#dt_from').datetimepicker('getDate');
  dt_to = $('#dt_to').datetimepicker('getDate');
  storeDatesToCookie(dt_from, dt_to);
  window.location = buildGraphiteDateUrl(dt_from, dt_to);
  return true;
}

function buildGraphiteDateUrl(dt_from, dt_to)
{
  from = buildGraphiteDateString(dt_from);
  to = buildGraphiteDateString(dt_to);
  params =  "?&from=" + from + "&until=" + to;
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
