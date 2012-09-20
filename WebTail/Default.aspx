<%@ Page Title="WebTail" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
	CodeBehind="Default.aspx.cs" Inherits="WebTail.Default" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" Runat="Server">
<style type="text/css">
	
	
</style>
 
	<link href="Styles/site.css" rel="stylesheet" type="text/css" />
	<script src="Scripts/jquery-1.8.1.min.js" type="text/javascript"></script>
	<script src="Scripts/ServiceProxy.js" type="text/javascript"></script>
	<script src="Scripts/js_extensions.js" type="text/javascript"></script>
</asp:Content>
 
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" Runat="Server">
<div id="ActionPanel" style="width:100%" class="ActionPanel">
   
	<div class="ActionPanelItem">
		# Lines to read&nbsp;<asp:TextBox ID="tbLines" runat="server" Width="50px" style="text-align:right">40</asp:TextBox>
	</div>
	<div class="ActionPanelItem">
		poll interval: <input type="text" id="tailsecs" value="5" style="width: 20px" /> seconds
	</div>
	<div class="menu" >
		<ul>
		<li>
			<a id="tail" href="#">Start Tail</a>
		</li>
		</ul>
	</div>
	<div class="status" id="statusDiv"></div>
</div>
<div id="lastUpdate" class="lastUpdate"></div>
<div id="logDiv" class="logArea" ></div>
 
<script type="text/javascript">

	var lastFileChangedDate = "";
	var interval = null;

	$(document).ready(function () {
		$('#tail').click(function () {
			var $tail = $(this);
			if ($tail.text().indexOf('Stop') >= 0) {
				$tail.text('Start Tail');
				clearInterval(interval);
				interval = null;
				var $status = $('#statusDiv');
				$status.removeClass('activestatus');
			}
			else {
				$tail.text('Stop Tail');
				doTail();
			}
			return false;
		});

		$('#viewLog').click(function () {
			getLogData(getNumRows(), getLogFileName());
			return false;
		});

		$('#tailsecs').keyup(function () {
			setRefreshTime();
		});

		$('#tbLines').keyup(function () {
			setRefreshTime();
		});

		//read from querystring
		if ($.getUrlVar('autostart') == 'true') {
			$('#tail').text('Stop  Tail');
			doTail();
		}
	});

	$.extend({
		getUrlVars: function () {
			var vars = [], hash;
			var hashes = window.location.href.slice(window.location.href.indexOf('?') + 1).split('&');
			for (var i = 0; i < hashes.length; i++) {
				hash = hashes[i].split('=');
				vars.push(hash[0]);
				vars[hash[0]] = hash[1];
			}
			return vars;
		},
		getUrlVar: function (name) {
			return $.getUrlVars()[name];
		}
	});

	function doTail() {
		var $status = $('#statusDiv');
		$status.addClass('activestatus');
		interval = setInterval(function () {
			getLogData(getNumRows(), getLogFileName());
		}, getNumSecs());
	}

	function setRefreshTime() {
		clearInterval(interval);
		interval = null;
		doTail();
	}

	function getLogData(numRows, logFile) {
		document.title = "WebTail - " + logFile;
		var proxy = new ServiceProxy("Default.aspx/");
		proxy.isWcf = false;
		proxy.invoke("GetLogTail", { logname: logFile, numrows: numRows, lastFileChangedDate: lastFileChangedDate },
			function (data) {
				displayLog(logFile, data);
			},
			function (errmsg) {
				clearInterval(interval);
				interval = null;
				alert(errmsg);
			},
			false);        // NOT bare
	}


	function clearLog() {
		$('#logDiv').html('');
	}

	function displayLog(logFile, data) {
		var now = new Date();
		var $log = $('#logDiv');
		var logStr = "";
		var needUpdate = true;
		
		jQuery.each(data, function (i, val) {
			if (i == 0) {
				if (val == lastFileChangedDate) {
					needUpdate = false;
					return;
				}
				lastFileChangedDate = val;
			} else {
				logStr += formatLine(val.toString());
			}
		});
		

		$('#lastUpdate').html("<span style='font-style:italic'>" + logFile + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; last poll: " + now.format("d/m/Y H:i:s ") + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; File Last Changed: " + lastFileChangedDate + "</span>");
		if (needUpdate) {
			$('#title').html("<h1>WebTail <span class='logfilenameheader'> (" + logFile + ") </span></h1>");
			$log.html(logStr);
		}
	}

	function getNumRows() {
		var numRows = 30;
		numRows = parseInt($('#<%=tbLines.ClientID %>').val(), 10);
		if (isNaN(numRows)) { numRows = 45; }
		return numRows;
	}

	function getNumSecs() {
		var numSecs = 5000;
		numSecs = parseInt($('#tailsecs').val(), 10);
		if (isNaN(numSecs)) {
			numSecs = 1000 * 5;
		} else {
			numSecs *= 1000;
		}
		return numSecs;
	}

	function getLogFileName() {

		return $.getUrlVar('LogFile');
	}

	function formatLine(line) {
		//console.log("line: " + line);
		if (line == null)
			return null;
		line = encodeXml(line).toString();
		if (line.toLowerCase().indexOf('info') === 0) {
			return "<span class='info'>" + line + "</span><br/>";
		} else if (line.toLowerCase().indexOf('error') === 0) {
			return "<span class='error'>" + line + "</span><br/>";
		} else if (line.toLowerCase().indexOf('warn') === 0) {
			return "<span class='warn'>" + line + "</span><br/>";
		} else if (line.toLowerCase().indexOf('debug') === 0) {
			return "<span class='debug'>" + line + "</span><br/>";
		} else if (line.toLowerCase().indexOf('success') === 0) {
			return "<span class='success'>" + line + "</span><br/>";
		}
		return "<span>" + line + "</span><br/>";
	}
	
</script>
 
</asp:Content>
