<%@ Page Title="WebTail" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
	CodeBehind="Default.aspx.cs" Inherits="WebTail.Default" %>

<asp:Content ID="Content1" ContentPlaceHolderID="HeadContent" Runat="Server">
	<style type="text/css">	
	</style>
	<script src="Scripts/jquery-1.8.1.min.js" type="text/javascript"></script>
	<script src="Scripts/ServiceProxy.js" type="text/javascript"></script>
	<script src="Scripts/js_extensions.js" type="text/javascript"></script>
</asp:Content>
 
<asp:Content ID="Content3" ContentPlaceHolderID="MainContent" Runat="Server">
<div id="ActionPanel" style="width:100%" class="ActionPanel">
   
	<div class="ActionPanelItem">
	    # Lines to read&nbsp;<input id="tbLines" type="number" name="lines" min="1" max="500" style="text-align:right; width:50px" value="40" />
	</div>
	<div class="ActionPanelItem">
		poll interval: <input type="number" id="tailsecs" min="1" max="600"  style="text-align:right; width:50px" value="5"/> seconds
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
    $(document).ready(function () {
        var w = WebTail;
        
        //button clicked
	    $('#tail').click(function () {
	        var $tailbutton = $('#tail');
	        if ($tailbutton.text().indexOf('Stop') >= 0) {
	            w.stopTail();
	            w.running = false;
	        }
	        else {
	            w.doTail();
	        }
			return false;
		});

        //watch for settings changed
	    $('#tailsecs').bind("keyup click",function () {
		    w.applySettings();
		});
	    $('#tbLines').bind("keyup click", function () {
		    w.applySettings();
		});
		
		//start if set autostart from querystring
		if ($.getUrlVar('autostart') == 'true') {
			w.doTail();
		}
	});
	
	var WebTail = {
	    logFile: null,
	    fileLastChangedDate : "",
        FileCreatedDate : "",
        interval : null,
        running : false,
        settingsTimeout : null,
	    
        stopTail: function () {
            var w = WebTail;
            var $tailbutton = $('#tail');
            clearInterval(w.interval);
            w.interval = null;
            $tailbutton.text('Start Tail');
            var $status = $('#statusDiv');
            $status.removeClass('activestatus');
        },
	    
        applySettings: function () {
            var w = WebTail;
	        clearTimeout(w.settingsTimeout);
	        w.settingsTimeout = setTimeout(function() { w.setRefreshTime(); }, 1000);
	    },

        doTail: function () {
            var w = WebTail;
            var $status = $('#statusDiv');
            var $tailbutton = $('#tail');
            
	        $status.addClass('activestatus');
	        $tailbutton.text('Stop Tail');
	        if (w.logFile == null) {
	            w.logFile = w.getLogFileName();
	        }
	        w.getLogData(w.getNumRows());
	        w.interval = setInterval(function() {
	            w.getLogData(w.getNumRows());
	        }, w.getNumSecs());
	        w.running = true;
	    },

        setRefreshTime: function () {
            var w = WebTail;
            w.stopTail();
	        if (w.running == true) {
	            w.doTail();
	        }
	    },

	    getLogData: function (numRows) {
	        var w = WebTail;
	        if (w.logFile == null) {
	            w.logFile = w.getLogFileName();
	        }
	        document.title = "WebTail - " + w.logFile;
	        var proxy = new ServiceProxy("Default.aspx/");
	        proxy.isWcf = false;
	        proxy.invoke("GetLogTail", { logname: w.logFile, numrows: numRows, fileLastChangedDate: w.fileLastChangedDate },
	            function(data) {
	                w.displayLog(data);
	            },
	            function(errmsg) {
	                w.stopTail();
	                alert(errmsg);
	            },
	            false); // NOT bare
	    },

	    clearLog: function() {
	        $('#logDiv').html('');
	    },

	    displayLog: function (data) {
	        var w = WebTail;
	        var now = new Date();
	        var $log = $('#logDiv');
	        var logStr = "";
	        var needUpdate = true;

	        jQuery.each(data, function(i, val) {
	            if (i == 0) {
	                if (val == w.fileLastChangedDate) {
	                    needUpdate = false;
	                    return;
	                }
	                w.fileLastChangedDate = val;
	            } else if (i == 1) {
	                w.FileCreatedDate = val;
	            } else {
	                logStr += w.formatLine(val.toString());
	            }
	        });

	        var logFileLink = w.logFile.replace("d:\\SonInternalLink\\", "http://ilonsysfs02/SonettoBuildLogs/");
	        if (logFileLink != w.logFile) {
	            logFileLink = "<a href='" + logFileLink + "'>" + w.logFile + "</a>";
	        }

	        $('#lastUpdate').html("<span style='font-style:italic'>" + logFileLink + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; File Created: " + w.FileCreatedDate + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; last poll: " + now.format("d/m/Y H:i:s ") + "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; File Last Changed: " + w.fileLastChangedDate + "</span>");
	        if (needUpdate) {
	            $('#title').html("<h1>WebTail <span class='logfilenameheader'> (" + w.logFile + ") </span></h1>");
	            $log.html(logStr);
	        }
	    },

	    getNumRows: function() {
	        var numRows;
	        numRows = parseInt($('#tbLines').val(), 10);
	        if (isNaN(numRows)) {
	            numRows = 45;
	        }
	        return numRows;
	    },

	    getNumSecs: function() {
	        var numSecs;
	        numSecs = parseInt($('#tailsecs').val(), 10);
	        if (isNaN(numSecs)) {
	            numSecs = 1000 * 5;
	        } else {
	            numSecs *= 1000;
	        }
	        return numSecs;
	    },

	    getLogFileName: function() {
	        return $.getUrlVar('LogFile');
	    },

	    formatLine: function(line) {
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
	};
</script>
 
</asp:Content>
