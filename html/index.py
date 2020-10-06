#!/usr/bin/python3
import cgi, cgitb, json, os, datetime, platform, subprocess, html, re, socket
import random, string, sys, traceback, time, urllib
from urllib.parse import urlparse, parse_qs

# Variables this script requires:
PIVPN_ENV = "/etc/openvpn/pivpn.env"
form = cgi.FieldStorage()
ACTION = form.getvalue('action')
settings = {}
changes = {}
SID = ""
REDIRECT = None
REDIRECT_SEC = 0
INLINE = False

#===========================================================================================
# Function that starts the header of the web page:
#===========================================================================================
def header():
	global REDIRECT, REDIRECT_SEC

	print(
"""Content-type: text/html

<!DOCTYPE html><html>
<head>
	<title>PiVPN Admin</title>
	<meta http-equiv="content-type" content="text/html; charset=UTF-8">
	<meta charset="utf-8">
	<meta http-equiv="X-UA-Compatible" content="IE=edge">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">""")
	if REDIRECT != None:
		print(
"""	<meta http-equiv="Refresh" content=""" + '"' + str(REDIRECT_SEC) + "; url='""" + REDIRECT + """'" />""")
	print(
"""	<link rel="icon" type="image/png" sizes="32x32" href="/static/img/favicon/favicon-32x32.png">
	<link rel="icon" type="image/png" sizes="16x16" href="/static/img/favicon/favicon-16x16.png">
	<link rel="icon" type="image/png" sizes="96x96" href="/static/img/favicon/favicon-96x96.png">
	<link rel="icon" type="image/png" sizes="192x192" href="/static/img/favicon/favicon-192x192.png">
	<link href="/static/css/bootstrap.min.css" rel="stylesheet">
	<link rel="stylesheet" href="/static/css/font-awesome.min.css">
	<link rel="stylesheet" href="/static/css/ionicons.min.css">
	<link rel="stylesheet" href="/static/css/AdminLTE.min.css">
	<script src="/static/js/jquery-2.2.3.min.js"></script>
	<script src="/static/js/bootstrap.min.js"></script>
	<script src="/static/js/clipboard.min.js"></script>
	<script src="/static/js/app.js"></script>
	<script src="/static/js/custom.js"></script>""")

#===========================================================================================
# Helper functions for "body" function:
#===========================================================================================
def is_active(name):
	if ACTION == name:
		return ' class="active"'
	return ''

def is_current(name):
	if ACTION == name:
		return '<span class="sr-only">(current)</span>'
	return ''

#===========================================================================================
# Function that ends the header and begins the body of the web page:
#===========================================================================================
def body(title = ""):
	global settings

	print(
"""	<link rel="stylesheet" href="/static/css/skins/skin-blue.min.css">
	<link rel="stylesheet" href="/static/css/custom.css">
</head>
<body class="hold-transition skin-blue layout-top-nav">
	<div class="wrapper">
		<header class="main-header">
			<nav class="navbar navbar-static-top">
				<div class="container">
					<div class="navbar-header">
						<a href="/" class="navbar-brand"><b>PiVPN</b> Admin</a>
						<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar-collapse">
							<i class="fa fa-bars"></i>
        				</button>
      				</div>
					<div class="collapse navbar-collapse pull-left" id="navbar-collapse">
						<ul class="nav navbar-nav">
							<li""" + is_active("") + """>
								<a href="/">Home """ + is_current("") + """</a>
							</li>
							<li class="dropdown">
								<a href="#" class="dropdown-toggle" data-toggle="dropdown">
									Certificates <span class="caret"></span>
								</a>
								<ul class="dropdown-menu" role="menu">
									<li""" + is_active("certs") + """>
										<a href="/certs">Certificates """ + is_current("certs") + """</a>
									</li>
									<li""" + is_active("create") + """>
										<a href="/make">Create Certificate """ + is_current("create") + """</a>
									</li>
								</ul>
							</li>
							<li class="dropdown">
								<a href="#" class="dropdown-toggle" data-toggle="dropdown">
									Configuration <span class="caret"></span>
								</a>
								<ul class="dropdown-menu" role="menu">
									<li""" + is_active("pivpn") + """>
										<a href="/pivpn">PiVPN Server</a>
  									</li>
									<li""" + is_active("webui") + """>
										<a href="/webui">UI Settings</a>
									</li>
								</ul>
							</li>
							<li""" + is_active("logs") + """>
								<a href="/logs">Logs """ + is_current("logs") + """</a>
							</li>
						</ul>
					</div>
					<div class="navbar-custom-menu">
						<ul class="nav navbar-nav">
							<li class="dropdown user user-menu" """ + is_active("profile") + """>
								<a href="#" class="dropdown-toggle" data-toggle="dropdown">
									<img src="/static/img/person.png" class="user-image" alt="User Image">
									<span class="hidden-xs">""" + settings["guiName"] + """</span>
								</a>
								<ul class="dropdown-menu">
									<li class="user-header">
										<img src="/static/img/person.png" class="img-circle" alt="User Image">
										<p>
											""" + settings['guiName'] + """
											<small>""" + settings['guiCreation'] + """</small>
										</p>
									</li>
									<li class="user-footer">
										<div class="pull-left">
											<a href="/profile" class="btn btn-default btn-flat">Profile</a>
										</div>""")
	if settings['DEBUG'] == 0 or settings['LOGIN'] == 1:
		print(
"""										<div class="pull-right">
											<a href="/logout" class="btn btn-default btn-flat">Sign out</a>
										</div>""")
	print(
"""									</li>
								</ul>
							</li>
						</ul>
					</div>
				</div>
			</nav>
		</header>
		<div class="content-wrapper" style="min-height: 835px;">
			<div class="container">
				<section class="content-header"><h1>""" + title + """</h1></section>
				<section class="content">
					<div class="row">""")

#===========================================================================================
# Function that shows the Web UI login box:
#===========================================================================================
def show404():
	global validSession
	print(
"""	<link rel="stylesheet" href="static/plugins/iCheck/square/blue.css">
</head>
<body class="hold-transition login-page">
	<div class="login-box">
		<div class="login-logo">
			<img src="/static/img/favicon/favicon-192x192.png"><br /><b>PiVPN</b> Admin</a>
		</div>

		<div class="login-box-body">
			<span style="text-align: center">
				<div class="login-logo"></p>
					<span style="font-size: +100px">404</span><br />
					Page Not Found!
				</div>
			<span>
			<div class="row">
				<div class="col-xs-8"></div>
				<div class="col-xs-4">""")
	if validSession:
		URL="/"
		MSG="Main Menu"
	else:
		URL="/login"
		MSG="Sign In"
	print(
"""					<a href=""" + '"' + URL + '"' + """ type="submit" class="btn btn-primary btn-block btn-flat">""" + MSG + """</a>
				</div>
			</div>
		</div>
	</div>""")
	footer(False)

#===========================================================================================
# Function that shows the footer of the web page:
#===========================================================================================
def footer(closing = True):
	if closing:
		print(
"""					</section>
					<div class="webui_result"></div>
				</div>
			</div>""")
	if ACTION == "login":
		print(
"""	<script src="/static/plugins/iCheck/icheck.min.js"></script>
	<script>
	  \$(function () {
	    \$('input').iCheck({
	      checkboxClass: 'icheckbox_square-blue',
	      radioClass: 'iradio_square-blue',
      	increaseArea: '20%'
	    });
	    \$("input:text:visible:first").focus();
	  });
	</script>
</div>""")

	print(
"""</body>
</html>""")

#===========================================================================================
# Function that shows OpenVPN logs:
#===========================================================================================
def showLogs():
	print(
"""<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Last 200 lines of OpenVPN log</h3>
	</div>
	<pre style="font-size: 13px;line-height: 1.4em;">""")

	result = subprocess.run(['sudo', 'cat', '/var/log/openvpn.log'], stdout=subprocess.PIPE, encoding='utf-8').stdout.split("\n")
	for line in result[-200:]:
		print(line)

	print(
"""	</pre>
</div>""")

#===========================================================================================
# Function dealing with UTF8 to HTML encodings:
#===========================================================================================
def utf8_to_html(str):
	table = {
		"À": "&Agrave;",
		"Á": "&Aacute;",
		"Â": "&Acirc;",
		"Ã": "&Atilde;",
		"Ä": "&Auml;",
		"Å": "&Aring;",
		"Æ": "&AElig;",
		"Ç": "&Ccedil;",
		"È": "&Egrave;",
		"É": "&Eacute;",
		"Ê": "&Ecirc;",
		"Ë": "&Euml;",
		"Ì": "&Igrave;",
		"Í": "&Iacute;",
		"Î": "&Icirc;",
		"Ï": "&Iuml;",
		"Ð": "&ETH;",
		"Ñ": "&Ntilde;",
		"Ò": "&Ograve;",
		"Ó": "&Oacute;",
		"Ô": "&Ocirc;",
		"Õ": "&Otilde;",
		"Ö": "&Ouml;",
		"Ø": "&Oslash;",
		"Ù": "&Ugrave;",
		"Ú": "&Uacute;",
		"Û": "&Ucirc;",
		"Ü": "&Uuml;",
		"Ý": "&Yacute;",
		"Þ": "&THORN;",
		"ß": "&szlig;",
		"à": "&agrave;",
		"á": "&aacute;",
		"â": "&acirc;",
		"ã": "&atilde;",
		"ä": "&auml;",
		"å": "&aring;",
		"æ": "&aelig;",
		"ç": "&ccedil;",
		"è": "&egrave;",
		"é": "&eacute;",
		"ê": "&ecirc;",
		"ë": "&euml;",
		"ì": "&igrave;",
		"í": "&iacute;",
		"î": "&icirc;",
		"ï": "&iuml;",
		"ð": "&eth;",
		"ñ": "&ntilde;",
		"ò": "&ograve;",
		"ó": "&oacute;",
		"ô": "&ocirc;",
		"õ": "&otilde;",
		"ö": "&ouml;",
		"ø": "&oslash;",
		"ù": "&ugrave;",
		"ú": "&uacute;",
		"û": "&ucirc;",
		"ü": "&uuml;",
		"ý": "&yacute;",
		"þ": "&thorn;",
		"ÿ": "&yuml;"
	}
	for element in table:
		str = str.replace(element, table[element])
	return str

#===========================================================================================
# Function that shows blocks of number of connected clients and system information:
#===========================================================================================
def Home():
	global settings

	#=================================================================
	# Gather information from the OpenVPN status log:
	#=================================================================
	result = subprocess.run(['sudo', 'cat', '/var/log/openvpn-status.log'], stdout=subprocess.PIPE, encoding='utf-8').stdout.split("\n")
	clients = []
	for line in result:
		if line.startswith("TITLE"):
			server_version = line.replace("TITLE\t","")
		elif line.startswith("CLIENT_LIST"):
			clients.append(line)

	#=================================================================
	# Gather data transfer information from "ifconfig":
	#=================================================================
	txt = "{:,}"
	results = subprocess.run(['/sbin/ifconfig', settings['pivpnDEV']], stdout=subprocess.PIPE, encoding='utf-8').stdout.split("\n")
	for line in results:
		parts = line.split()
		try:
			if parts[0] == "RX" and parts[1] == "packets":
				RX_KB = int(int(parts[4]) / 1024)
			elif parts[0] == "TX" and parts[1] == "packets":
				TX_KB = int(int(parts[4]) / 1024)
		except:
			pass

	#=================================================================
	# Get the amount of time the computer has been up and running:
	#=================================================================
	with open('/proc/uptime', 'r') as f:
		uptime_seconds = float(f.readline().split()[0])
		uptime_string = str(datetime.timedelta(seconds = uptime_seconds)).split(".")[0]

	#=================================================================
	# Get the system load averages:
	#=================================================================
	load1, load5, load15 = os.getloadavg()

	#=================================================================
	# Get the server time:
	#=================================================================
	server_time = str(datetime.datetime.now()).split('.')[0].replace(" ", "<br/>")

	#=================================================================
	# First row on first row:
	#=================================================================
	print(
"""<div class="col-md-3 col-sm-6 col-xs-12">
  	<div class="info-box">
		<span class="info-box-icon bg-green">
	  		<i class="ion ion-network"></i>
		</span>
		<div class="info-box-content">
	  		<span class="info-box-text">
				Clients count: <span class="info-box-number2">""" + str(len(clients)) + """</span>
			</span>
			<span class="info-box-text">
				In: <span class="info-box-number2">""" + txt.format(RX_KB) + """ KB</span>
			</span>
			<span class="info-box-text">
				Out: <span class="info-box-number2">""" + txt.format(TX_KB) + """ KB </span>
			</span>
		</div>
	</div>
</div>""")

	#=================================================================
	# Second block on first row:
	#=================================================================
	print(
"""<div class="col-md-3 col-sm-6 col-xs-12">
	<div class="info-box">
		<span class="info-box-icon bg-aqua">
			<i class="ion ion-ios-pulse"></i>
		</span>
		<div class="info-box-content">
			<span class="info-box-text">Load Average:</span>
			<span class="info-box-number">
				""" + str(load1) + """, """ + str(load5) + """, """ + str(load15) + """<br>
			</span>
	  		<span class="info-box-text">
				CPU count: <span class="info-box-number2">""" + str(os.cpu_count()) + """</span>
			</span>
		</div>
	</div>
</div>""")

	#=================================================================
	# Third block on first row:
	#=================================================================
	print(
"""<div class="clearfix visible-sm-block"></div>
	<div class="col-md-3 col-sm-6 col-xs-12">
		<div class="info-box">
			<span class="info-box-icon bg-orange">
				<i class="ion ion-arrow-graph-up-right"></i>
			</span>
			<div class="info-box-content">
				<span class="info-box-text">OS uptime:</span>
				<span class="info-box-number">""" + uptime_string + """</span>
			</div>
		</div>
	</div>
	<div class="col-md-3 col-sm-6 col-xs-12">
  		<div class="info-box">
			<span class="info-box-icon bg-yellow">
	  			<i class="fa ion-ios-clock-outline"></i>
			</span>
			<div class="info-box-content">
	  			<span class="info-box-text">Server time:</span>
	  			<span class="info-box-number">""" + server_time + """</span>
			</div>
		</div>
	</div>
</div>""")

	# Gather the information about memory usage and swapfile usage:
	mem_info = dict((i.split()[0].rstrip(':'),int(i.split()[1])) for i in open('/proc/meminfo').readlines())
	MEM_TOTAL   = int(mem_info['MemTotal'] / 1024)
	MEM_FREE    = int(mem_info['MemFree'] / 1024)
	MEM_USED    = MEM_TOTAL - MEM_FREE
	MEM_PERCENT = int(MEM_USED * 100 / MEM_TOTAL)
	VIRT_TOTAL = int(mem_info['SwapTotal'] / 1024)
	VIRT_FREE  = int(mem_info['SwapFree'] / 1024)
	VIRT_USED  = VIRT_TOTAL - VIRT_FREE
	VIRT_PERCENT = int(VIRT_USED * 100 / max(1, VIRT_TOTAL))

	#=================================================================
	# Second row:
	#=================================================================
	print(
"""	<div class="box box-default">
	<div class="box-header with-border">
		<h3 class="box-title">Memory usage</h3>
	</div>
	<div class="box-body">
		<div class="col-md-6">
			<div class="progress-group">
				<span class="progress-text">Memory</span>
				<span class="progress-number">
					<b>""" + txt.format( MEM_USED ) + """ </b>
					/
					""" + txt.format( MEM_TOTAL ) + """ MB
					- """ + str( MEM_PERCENT ) + """%
				</span>
				<div class="progress sm">
					<div class="progress-bar progress-bar-aqua" style="width: """ + str( MEM_PERCENT ) + """%"></div>
				</div>
			</div>
		</div>
		<div class="col-md-6">
			<div class="progress-group">
				<span class="progress-text">Swap</span>
				<span class="progress-number">
					<b>""" + txt.format( VIRT_USED) + """</b>
					/
					""" + txt.format( VIRT_TOTAL ) + """ MB
					- """ + str( VIRT_PERCENT ) + """%
				</span>
				<div class="progress sm">
					<div class="progress-bar progress-bar-red" style="width: """ + str( VIRT_PERCENT ) + """%"></div>
				</div>
			</div>
		</div>
	</div>
</div>""")

	#=================================================================
	# Third row -> The Client List!
	#=================================================================
	print(
"""<div class="row">
	<div class="col-md-12">
		<div class="box box-default">
			<div class="box-header with-border">
				<h3 class="box-title">Connected Clients</h3>
			</div>
			<div class="box-body">
				<div class="table-responsive">
					<table class="table no-margin">
						<thead>
							<tr>
								<th>Common Name</th>
								<th>Real Address</th>
								<th>Virtual Address</th>
								<th>KB Received</th>
								<th>KB Sent</th>
								<th>Connected Since</th>
								<th>Username</th>
			  					<th></th>
							</tr>
						</thead>
						<tbody>""")
	# Does the array have anything in it?  If not, tell the user:
	if len(clients) == 0:
		print(
"""							<tr>
								<td colspan="7">
									<p style="font-weight: bold;">
										<font size="+1">
											No Clients Connected
										</font>
									</p>
								</td>
							</tr>""")
	# Okay, the array has stuff in it.  Show it to the user:
	else:
		for client in clients:
			parts = client.split("\t")
			parts[4] = int(int(parts[4]) / 1024)
			parts[5] = int(int(parts[5]) / 1024)
			if parts[12] == 'UNDEF':
				parts[12] = parts[1]
			print(
"""							<tr>
								<td>""" + utf8_to_html(parts[1]) + """</td>
								<td>""" + parts[2] + """</td>
								<td>""" + parts[3] + """</td>
								<td>""" + txt.format(parts[4]) + """ KB</td>
								<td>""" + txt.format(parts[5]) + """ KB</td>
								<td>""" + parts[7] + " " + parts[8] + ", " + parts[10] + " " + parts[9] + """</td>
								<td>""" + parts[12] + """</td>
							</tr>""")
	# Finish the block:
	print(
"""						</tbody>
					</table>
				</div>
			</div>
			<div class="box-footer clearfix"></div>
		</div>
	</div>
</div>
""")

	#=================================================================
	# Last row
	#=================================================================
	print(
"""<div class="row">
	<div class="col-md-6 col-sm-12 col-xs-12">
		<div class="info-box">
			<span class="info-box-icon bg-white">
				<i class="ion ion-ios-information-empty"></i>
			</span>
			<div class="info-box-content">
				<span class="info-box-text">
					OpenVPN version: <span class="info-box-number3">""" + server_version + """</span>
				</span>
			</div>
		</div>
	</div>
	<div class="col-md-6 col-sm-12 col-xs-12">
		<div class="info-box">
			<span class="info-box-icon bg-white">
				<i class="ion ion-ios-gear"></i>
			</span>
			<div class="info-box-content">
				<span class="info-box-text">Docker Container Operating system:</span>
				<span class="info-box-number3">""" + platform.linux_distribution()[0] + """</span>
				<span class="info-box-text">Architecture: </span>
				<span class="info-box-number3">""" + platform.machine() + """</span>
			</div>
		</div>
	</div>
	<div class="clearfix visible-sm-block"></div>
</div>""")

#===========================================================================================
# Function that shows all certificates on the system (revoked and valid):
#===========================================================================================
def showCerts():
	global settings

	# Start the certificates page:
	VALID_STR=""
	if settings["ONLY_VALID"] == "1":
		VALID_STR="Valid "
	print(
"""	<div class="row">
		<div class="col-md-12">
			<div class="box box-info">
				<div class="box-header with-border">
					<h3 class="box-title">""" + VALID_STR + """Clients Certificates</h3>
				</div>
				<div class="box-body">
					<div class="table-responsive">
						<table class="table no-margin">
							<thead>
								<tr>
									<th>Name</th>
									<th>State</th>
									<th>Expiration</th>
									<th>Revocation</th>
									<th>Actions</th>
								</tr>
							</thead>
							<tbody>""")

	# List all certificates, with exception of the server certificate:
	COUNT = 0
	current = time.strftime('%Y%m%d')
	result = cgi.escape(subprocess.run(['/usr/local/bin/read_certs', 'list'], stdout=subprocess.PIPE, encoding='utf-8').stdout).split("\n")
	if len(result) > 0:
		for cert in result:
			if COUNT > 0:
				parts = cert.split(":")
				if len(parts) > 1:
					NAME = parts[5].split('=')[-1]
					UTF8 = utf8_to_html(parts[6])
					S_EXPIRES = parts[1]
					if len(S_EXPIRES) == 13:
						S_EXPIRES = "20" + S_EXPIRES
					STATE=parts[0]
					EXPIRES = datetime.datetime.strptime(S_EXPIRES[0:8], '%Y%m%d').strftime("%b %d, %Y")
					ACTIONS = ""
					if STATE == "R":
						IS_VALID = "Revoked"
						REVOKED = parts[1]
						if len(REVOKED) == 13:
							REVOKED = "20" + REVOKED
						REVOKED = datetime.datetime.strptime(REVOKED[0:8], '%Y%m%d').strftime("%b %d, %Y")
					else:
						if STATE == "E" or S_EXPIRES[0:8] < current:
							IS_VALID = "Expired"
						elif STATE == "V":
							IS_VALID = "Valid"
							if parts[7] == "Y" and STATE != "E":
								ACTIONS = """<a href="/revoke?name=""" + NAME + """" class="label label-warning">Revoke Certificate</a>"""
								UTF8 = """<a href="/download/""" + NAME + """.ovpn">""" + UTF8 + """</a>"""
						else:
							IS_VALID = "Unknown"
						REVOKED = ""

					if settings["ONLY_VALID"] == 0 or STATE == "V":
						print(
	"""								<tr>
										<td>""" + UTF8 + """</td>
										<td>""" + IS_VALID + """</td>
										<td>""" + EXPIRES + """</td>
										<td>""" + REVOKED + """</td>
										<td>""" + ACTIONS + """</td>
									</tr>""")
			COUNT += 1
	else:
		print(
"""									<tr>
										<td colspan="5">
											<p style="font-weight: bold;">
												<font size="+1">
													No Certificates Present
												</font>
											</p>
										</td>
									</tr>""")
		

	# Close the certificates page:
	print(
"""							</tbody>
						</table>
					</div>
				<div class="box-footer clearfix"></div>
			</div>
			<div class="box-footer">
				<a href="/make" class="btn btn-primary">Create Certificate</a>
			</div>
				</div>
		</div>
	</div>""")

#===========================================================================================
# Function that allows the user to download a certificate from the container:
#===========================================================================================
def downloadOVPN(USER = None):
	global URL_QUERY, settings

	# Determine the filename we are aiming for.  If not exist, return with error code 1:
	if USER == None:
		try:
			USER = URL_QUERY['name'][0]
		except:
			return False
	if USER == None:
		return False

	# Send the file:
	print(
"""Content-Type: application/octet-stream
Content-Description: File Transfer
Content-Disposition: attachment; filename=""" + USER + """.ovpn
Expires: 0
Cache-Control: must-revalidate
Pragma: public""")
	print( cgi.escape(subprocess.run(['/usr/local/bin/read_certs', 'get', USER], stdout=subprocess.PIPE, encoding='utf-8').stdout) )
	exit()

#===========================================================================================
# Function that revokes a OpenVPN certficate:
#===========================================================================================
def revokeOVPN(USER = None):
	print(
"""<div class="box box-primary">
	<pre style="font-size: 13px;line-height: 1.4em;">""")

	if USER == None:
		try:
			USER = URL_QUERY['name'][0]
		except:
			return False
	if USER == None:
		print("Requires Username to be passed!")
	else:
		result = cgi.escape(subprocess.run(['/usr/local/bin/read_certs', 'revoke', USER], stdout=subprocess.PIPE, encoding='utf-8').stdout)
		print( utf8_to_html(result) )
	print(
"""	</pre>
	<div class="box-footer">
		<a href="/certs" class="btn btn-primary">Back to Certificates</a>
	</div>
</div>""")

#===========================================================================================
# Function that shows all certificates on the system (revoked and valid):
#===========================================================================================
def makeCert():
	print(
"""<div class="box box-primary">
		<div class="box-header with-border">
			<h3 class="box-title">Create a new certificate</h3>
		</div>
		<form role="form" action="/create" method="post">
			<div class="box-body">
				<div class="form-group">
					<label for="name">Name</label>
					<input type="text" class="form-control" id="name" name="name" placeholder="Username">
				</div>
				<div class="form-group">
					<label for="pass">Password</label>
					<input type="password" class="form-control" id="pass" name="pass" placeholder="Password that is minimum 4 characters long">
				</div>
				<div class="form-group">
					<label for="pass2">Password</label>
					<input type="password" class="form-control" id="pass2" name="pass2" placeholder="Repeat your password">
				</div>
				<div class="form-group">
					<label for="days">Days Until Expires</label>
					<input type="number" class="form-control" id="days" name="days" placeholder="Number of days" value="3650" oninput="this.value = this.value.replace(/[^0-9]/g, '').replace(/(\..*)\./g, '$1');">
				</div>
				<span class="help-block"></span>
			</div>
			<div class="box-footer">
				<button type="submit" class="btn btn-primary">Create</button>
			</div>
		</form>
	</div>""")

#===========================================================================================
# Function that creates a OpenVPN certificate:
#===========================================================================================
def createOVPN(USER = None, PASS = None):
	print(
"""<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Output of User Creation</h3>
	</div>
	<pre style="font-size: 13px;line-height: 1.4em;">""")
	if USER == None:
		USER = form.getvalue('name')
	if USER == None:
		print("Requires Username to be passed!")
	else:
		if PASS == None:
			PASS = form.getvalue('pass')
		if PASS == None:
			print("Requires Password to be passed!")
		else:
			try:
				days = max(0, min( 3650, int(form.getvalue('days')) ))
			except:
				days = 3650
			USER = USER.replace('\\', '\\\\')
			result = cgi.escape( subprocess.run(['sudo', '/usr/local/bin/pivpn', 'add', '-d', '3650', '-n', USER, '-p', PASS], stdout=subprocess.PIPE, encoding='utf-8').stdout)
			print( utf8_to_html(result) )
	print(
"""	</pre>
	<div class="box-footer">
		<a href="/certs" class="btn btn-primary">Back to Certificates</a>
	</div>
</div>""")

#===========================================================================================
# Helper function for PiVPN server options:
#===========================================================================================
def is_selected(set, val):
	if set == val:
		return "selected"
	return ""

#===========================================================================================
# Function that shows the PiVPN server options:
#===========================================================================================
def PiVPN():
	global settings

	#pivpnKeepAlive=${pivpnKeepAlive:-"15 120"}
	print(
"""<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit PiVPN Server configuration</h3>
	</div>
	<form role="form" action="/savepivpn" method="post">
		<div class="box-body">
			<div class="form-group">
				<label for="pivpnHOST">Host Address</label>
				<input type="text" class="form-control" name="pivpnHOST" id="pivpnHOST" placeholder="" value=""" + '"' + settings['pivpnHOST'] + '"' + """>
				<span class="help-block">Static IP Address or Domain Name of the PiVPN server</span>
			</div>
			<div class="form-group">
				<label for="pivpnPORT">Port</label>
				<input type="text" class="form-control" name="pivpnPORT" id="pivpnPORT" placeholder="" value=""" + '"' + str(settings['pivpnPORT']) + '"' + """ oninput="this.value = this.value.replace(/[^0-9]/g, '').replace(/(\..*)\./g, '$1');" >
				<span class="help-block">Which TCP/UDP port should OpenVPN listen on</span>
			</div>
			<div class="form-group">
				<label for="pivpnPROTO">VPN Protocall</label>
				<select name="pivpnPROTO" id="pivpnPROTO" class="form-control">
					<option value="udp" """ + is_selected(settings['pivpnPROTO'], "udp") + """>UDP</option>
					<option value="tcp" """ + is_selected(settings['pivpnPROTO'], "tcp") + """>TCP</option>
				</select>
				<span class="help-block">TCP or UDP server</span>
			</div>
			<div class="form-group">
				<label for="pivpnDNS1">Primary DNS Server</label>
				<input type="text" class="form-control" name="pivpnDNS1" id="pivpnDNS1" placeholder="" value=""" + '"' + settings['pivpnDNS1'] + '"' + """>
				<span class="help-block">IP address of primary domain name server</span>
			</div>
			<div class="form-group">
				<label for="pivpnDNS2">Secondary DNS Server</label>
				<input type="text" class="form-control" name="pivpnDNS2" id="pivpnDNS2" placeholder="" value=""" + '"' + settings['pivpnDNS2'] + '"' + """>
				<span class="help-block">IP address of secondary domain name server.  Use <b>none</b> to disable.</span>
			</div>
			<div class="form-group">
				<label for="pivpnSEARCHDOMAIN">Custom Search Domain</label>
				<input type="text" class="form-control" name="pivpnSEARCHDOMAIN" id="pivpnSEARCHDOMAIN" placeholder="" value=""" + '"' + settings['pivpnSEARCHDOMAIN'] + '"' + """>
				<span id="helpBlock" class="help-block"></span>
			</div>
			<div class="form-group">
				<label for="pivpnNET">Host IP Address and subnet</label>
				<input type="text" class="form-control" name="pivpnNET" id="pivpnNET" placeholder="" value=""" + '"' + settings['pivpnNET'] + '/' + str(settings['subnetClass']) + '"' + """>
				<span id="helpBlock" class="help-block">Configures server mode and supply a subnet mask (&quot;<b>/24</b>&quot; is the most common subnet mask used) for OpenVPN to draw client addresses from.</span>
			</div>
			<div class="form-group">
				<label for="pivpnKeepAlive">Keepalive</label>
				<input type="text" class="form-control" name="pivpnKeepAlive" id="pivpnKeepAlive" placeholder="" value=""" + '"' + settings['pivpnKeepAlive'] + '"' + """>
				<span id="helpBlock" class="help-block">
					The keepalive directive causes ping-like messages to be sent back and forth  over the link
					so that each side knows when the other side has gone down.<br />
					<b>Current Setting:</b> Ping every $(echo ${pivpnKeepAlive} | cut -d" " -f 1) seconds, assume
					that remote peer is down if no ping received during a $(echo ${pivpnKeepAlive} | cut -d" " -f 2) second time period.
				</span>
			</div>
			<div class="form-group">
				<label for="pivpnWEB_MGMT">OpenVPN Management Port</label>
				<input type="text" class="form-control" name="pivpnWEB_MGMT" id="pivpnWEB_MGMT" placeholder="" value=""" + '"' + str(settings['pivpnWEB_MGMT']) + '"' + """ oninput="this.value = this.value.replace(/[^0-9\-]/g, '').replace(/(\..*)\./g, '$1');">
				<span id="helpBlock" class="help-block">OpenVPN management port to use.  Specify <b>-1</b> to use one port up from web UI, or <b>0</b> to disable.</span>
			</div>
			<div class="form-group">
				<label for="pivpnDEV">PiVPN Network Adapter Name</label>
				<input type="text" class="form-control" name="pivpnDEV" id="pivpnDEV" placeholder="" value=""" + '"' + settings['pivpnDEV'] + '"' + """>
				<span id="helpBlock" class="help-block">The global network adapter name, similar to <b>eth0</b>, the PiVPN server will use while it is running.</span>
			</div>
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save and apply</button>
		</div>
	</form>
</div>""")

#===========================================================================================
# Helper function to deal with settings:
#===========================================================================================
def is_valid_ipv4_address(address):
    try:
        socket.inet_pton(socket.AF_INET, address)
    except AttributeError:  # no inet_pton here, sorry
        try:
            socket.inet_aton(address)
        except socket.error:
            return False
        return address.count('.') == 3
    except socket.error:  # not a valid address
        return False

    return True

def is_valid_ipv6_address(address):
    try:
        socket.inet_pton(socket.AF_INET6, address)
    except socket.error:  # not a valid address
        return False
    return True

def doChange(changed, key, newval, msg=""):
	global changes, settings

	out = "[ changed=N ]"
	if changed == "Invalid":
		out = "[  Invalid  ]"
	elif changed:
		changes[key] = newval
		out = "[ changed=Y ]"
	if settings['DEBUG'] == 1:
		if msg != "":
			msg = " (" + msg + ")"
		print(out + " " + key + "=" + str(newval) + msg)

#===========================================================================================
# Function that saves the PiVPN server options:
#===========================================================================================
def savePiVPN():
	global settings, changes, INLINE

	# Open the debugging message section if we are debugging:
	if settings['DEBUG'] == 1:
		print('<pre>')

	# Has the OpenVPN host name changed?  If so, store the change!
	webHOST = form.getvalue('pivpnHOST')
	changed = webHOST != None and webHOST != "" and settings['pivpnHOST'] != webHOST
	doChange(changed, 'pivpnHOST', webHOST)

	# Has the OpenVPN port changed?  If so, store the change!  Note: MUST be an integer!
	webPORT = form.getvalue('pivpnPORT')
	try:
		webPORT = int(webPORT)
		changed = settings['pivpnPORT'] != webPORT
		if webPORT >=0 and webPORT <= 65535:
			doChange(changed, 'pivpnPORT', webPORT)
		else:
			doChange('Invalid', 'pivpnPORT', webPORT, 'Invalid Port')
	except:
		doChange('Invalid', 'pivpnPORT', webPORT, 'Invalid Port')

	# Has the OpenVPN protocol changed?  If so, store the change!
	webPROTO = form.getvalue('pivpnPROTO')
	changed = webPROTO != None and webPROTO != "" and settings['pivpnPROTO'] != webPROTO
	if webPROTO == 'udp' or webPROTO == 'tcp':
		doChange(changed, 'pivpnPROTO', webPROTO)
	else:
		doChange('Invalid', 'pivpnPROTO', webPROTO, "Invalid Protocol")

	# Has the primary DNS changed?  If so, store the change!
	webDNS1 = str(form.getvalue('pivpnDNS1'))
	changed = webDNS1 != "" and settings['pivpnDNS1'] != webDNS1
	if is_valid_ipv4_address(webDNS1) or is_valid_ipv6_address(webDNS1):
		doChange(changed, 'pivpnDNS1', webDNS1)
	else:
		doChange('Invalid', 'pivpnDNS1', webDNS1, 'Invalid IP address')

	# Has the secondary DNS changed?  If so, store the change!
	webDNS2 = form.getvalue('pivpnDNS2')
	changed = webDNS2 != "" and settings['pivpnDNS2'] != webDNS2
	if is_valid_ipv4_address(webDNS2) or is_valid_ipv6_address(webDNS2):
		doChange(changed, 'pivpnDNS2', webDNS2)
	else:
		doChange('Invalid', 'pivpnDNS2', webDNS2, 'Invalid IP address')

	# Has the OpenVPN search domain changed?  If so, store the change!
	webSEARCHDOMAIN = form.getvalue('pivpnSEARCHDOMAIN')
	changed = webSEARCHDOMAIN != None and webSEARCHDOMAIN != "" and settings['pivpnSEARCHDOMAIN'] != webSEARCHDOMAIN
	doChange(changed, 'pivpnSEARCHDOMAIN', webSEARCHDOMAIN)

	# Has the OpenVPN subnet mask changed?  If so, store the change!
	webNET = str(form.getvalue('pivpnNET')).split('/')
	try:
		webSUBNET = int(webNET[1])
		changed = settings['subnetClass'] != webSUBNET
		if webSUBNET >= 0 and webSUBNET <= 24:
			doChange(changed, 'subnetClass', webSUBNET)
		else:
			doChange('Invalid', 'subnetClass', webSUBNET, 'Invalid Subnet Mask')
	except:
		try:
			doChange('Invalid', 'subnetClass', webSUBNET, 'Invalid Subnet Mask')
		except:
			doChange('Invalid', 'subnetClass', '', 'No Subnet Specified')

	# Has the OpenVPN IP subnet changed?  If so, store the change!
	webNET = webNET[0]
	changed = webNET != None and webNET != "" and settings['pivpnNET'] != webNET
	if is_valid_ipv4_address(webNET) or is_valid_ipv6_address(webNET):
		doChange(changed, 'pivpnNET', webNET)
	else:
		doChange('Invalid', 'pivpnNET', webNET, 'Invalid IP address')

	# Has the OpenVPN tunnel name changed?  If so, store the change!
	webDEV = form.getvalue('pivpnDEV')
	changed = webDEV != None and webDEV != "" and settings['pivpnDEV'] != webDEV
	doChange(changed, 'pivpnDEV', webDEV)

	# Has the OpenVPN management port changed?  If so, store the change!
	webWEB_MGMT = form.getvalue('pivpnWEB_MGMT')
	try:
		webWEB_MGMT = int(webWEB_MGMT)
		changed = settings['pivpnWEB_MGMT'] != webWEB_MGMT and webWEB_MGMT != settings['pivpnWEB_PORT']
		if webWEB_MGMT >= -1 and webWEB_MGMT <= 65536:
			doChange(changed, 'pivpnWEB_MGMT', webWEB_MGMT)
		else:
			doChange('Invalid', 'pivpnWEB_MGMT', webWEB_MGMT, 'Invalid Port Specified')
	except:
		doChange('Invalid', 'pivpnWEB_MGMT', webWEB_MGMT, 'Invalid Port Specified')

	# Close the debugging message section:
	if settings['DEBUG'] == 1:
		print('</pre>')
	if not INLINE:
		print(
"""	<div class="box-body">
		<a href="/?action=pivpn" class="btn btn-primary">Back to PiVPN Settings</a>
	</div>""")

	saveChanged(PIVPN_ENV)

#===========================================================================================
# Function that shows the Web UI server options:
#===========================================================================================
def WebUI():
	global settings
	print(
"""<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit Web UI configuration</h3>
	</div>
	<form role="form" action="/savewebui" method="post">
		<div class="box-body">
			<div class="form-group">
				<label for="pivpnWEB_PORT">PiVPN Web UI Port</label>
				<input type="text" class="form-control" name="pivpnWEB_PORT" id="pivpnWEB_PORT" placeholder="" value=""" + '"' + str(settings['pivpnWEB_PORT']) + '"' + """ oninput="this.value = this.value.replace(/[^0-9\-]/g, '').replace(/(\..*)\./g, '$1');">
				<span id="helpBlock" class="help-block">What port this UI uses on the host system.  Specify <b>0</b> to disable.</span>
			</div>
			<div class="form-group">
				<label for="DEBUG">Show Valid Certificates Only</label>
				<select name="ONLY_VALID" id="ONLY_VALID" class="form-control">
					<option value="0" """ + is_selected(settings['ONLY_VALID'], 0) + """>Disabled</option>
					<option value="1" """ + is_selected(settings['ONLY_VALID'], 1) + """>Enabled</option>
				</select>
			</div>
			<div class="form-group">
				<label for="DEBUG">Web UI Debug Mode</label>
				<select name="DEBUG" id="DEBUG" class="form-control">
					<option value="0" """ + is_selected(settings['DEBUG'], 0) + """>Disabled</option>
					<option value="1" """ + is_selected(settings['DEBUG'], 1) + """>Enabled</option>
				</select>
				<span id="helpBlock" class="help-block">Enables debugging messages site-wide, as well as the ability to disable login requirement option.</span>
			</div>""")
	if settings['DEBUG'] == 1:
		print(
"""			<div class="form-group">
				<label for="DEBUG">Login Required</label>
				<select name="LOGIN" id="LOGIN" class="form-control">
					<option value="0" """ + is_selected(settings['LOGIN'], 0) + """>Disabled</option>
					<option value="1" """ + is_selected(settings['LOGIN'], 1) + """>Enabled</option>
				</select>
				<span id="helpBlock" class="help-block">Disabling the login requirement disables the security provided!  Anyone can get or create credentials!</span>
			</div>""")
	print(
"""			<div class="form-group">
				<label for="pivpnWEB_PORT">Main Page Refresh Rate (in seconds)</label>
				<input type="text" class="form-control" name="REDIRECT_SEC" id="REDIRECT_SEC" placeholder="" value=""" + '"' + str(settings['REDIRECT_SEC']) + '"' + """ oninput="this.value = this.value.replace(/[^0-9\-]/g, '').replace(/(\..*)\./g, '$1');">
				<span id="helpBlock" class="help-block">Specifies the refresh rate in seconds for the main page.  Specify under <b>30</b> to disable.</span>
			</div>
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save and apply</button>
		</div>
	</form>
</div>""")

#===========================================================================================
# Function that saves the Web UI server options:
#===========================================================================================
def saveWebUI():
	global settings, changes, INLINE

	# Open the debugging message section if needed:
	if settings['DEBUG'] == 1:
		print('<pre>')

	# Has the web server port changed?  If so, store the change!
	webWEB_PORT = form.getvalue('pivpnWEB_PORT')
	try:
		webWEB_PORT = int(webWEB_PORT)
		changed = settings['pivpnWEB_PORT'] != webWEB_PORT and settings['pivpnWEB_MGMT'] != webWEB_PORT
		if webWEB_PORT >= 0 and webWEB_PORT <= 65535:
			doChange(changed, 'pivpnWEB_PORT', webWEB_PORT)
		else:
			doChange('Invalid', 'pivpnWEB_PORT', webWEB_PORT, 'Invalid port specified')
	except:
		doChange('Invalid', 'pivpnWEB_PORT', webWEB_PORT, 'Invalid port specified')

	# Has the "show revoked certificates" setting changed?  If so, store the change!
	webONLY_VALID = form.getvalue('ONLY_VALID')
	try:
		webONLY_VALID = int(webONLY_VALID)
		changed = settings['ONLY_VALID'] != webONLY_VALID
		if webONLY_VALID == 0 or webONLY_VALID == 1:
			doChange(changed, 'ONLY_VALID', webONLY_VALID)
		else:
			doChange('Invalid', 'ONLY_VALID', webONLY_VALID, 'Invalid Value')
	except:
		doChange('Invalid', 'ONLY_VALID', webONLY_VALID, 'Invalid Value')

	# Has the debug setting changed?  If so, store the change!
	webDEBUG = form.getvalue('DEBUG')
	try:
		webDEBUG = int(webDEBUG)
		changed = settings['DEBUG'] != webDEBUG
		if webDEBUG == 0 or webDEBUG == 1:
			doChange(changed, 'DEBUG', webDEBUG)
		else:
			doChange('Invalid', 'DEBUG', webDEBUG, 'Invalid Value')
	except:
		doChange('Invalid', 'DEBUG', webDEBUG, 'Invalid Value')

	# Has the login requirement setting changed AND debug is enabled?  If so, store the change!
	if settings['DEBUG'] == 1:
		webLOGIN = form.getvalue('LOGIN')
		try:
			webLOGIN = int(webLOGIN)
			changed = settings['LOGIN'] != webLOGIN
			if webLOGIN == 0 or webLOGIN == 1:
				doChange(changed, 'LOGIN', webLOGIN)
			else:
				doChange('Invalid', 'LOGIN', webLOGIN, 'Invalid Value')
		except:
			doChange('Invalid', 'LOGIN', webLOGIN, 'Invalid Value')

	# Has the refresh rate changed?  If so, store the change:
	REDIRECT_SEC = form.getvalue('REDIRECT_SEC')
	try:
		REDIRECT_SEC = int(REDIRECT_SEC)
		changed = settings['REDIRECT_SEC'] != REDIRECT_SEC and settings['REDIRECT_SEC'] != REDIRECT_SEC
		if REDIRECT_SEC >= 0:
			doChange(changed, 'REDIRECT_SEC', REDIRECT_SEC)
		else:
			doChange('Invalid', 'REDIRECT_SEC', REDIRECT_SEC, 'Invalid Refresh Rate!')
	except:
		doChange('Invalid', 'REDIRECT_SEC', REDIRECT_SEC, 'Invalid Refresh Rate!')

	# Redirect user to new web server port if web server port has changed:
	URL = ""
	if 'pivpnWEB_PORT' in changes:
		try:
			URL = os.environ['HTTP_HOST'].split(':')[0]
			if changes['pivpnWEB_PORT'] != 80:
				URL = URL + ":" + str(changes['pivpnWEB_PORT'])
		except:
			pass

	# Close the debugging message section:
	if settings['DEBUG'] == 1:
		print('</pre>')

	if not INLINE:
		print(
"""	<div class="box-body">
		<a href=""" + '"' + URL + """/webui" class="btn btn-primary">Back to Web UI Settings</a>
	</div>""")

	saveChanged(PIVPN_ENV)

#===========================================================================================
# Function that shows the Profile settings:
#===========================================================================================
def showProfile():
	global settings, SID

	print("""
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit your profile</h3>
	</div>
	<form role="form" action="/saveprofile" method="post">
		<div class="box-body">
			<div class="form-group">
				<label for="name">Username</label>
				<input type="text" class="form-control" id="username" name="username" value=""" + '"' + settings['guiUsername'] + '"' + """>
			</div>
			<div class="form-group" >
				<label for="name">Name</label>
				<input type="text" class="form-control" id="admin_name" name="admin_name" placeholder="Enter name" value=""" + '"' + settings['guiName' ] + '"' + """>
				<span class="help-block"> </span>
			</div>
			<div class="form-group">
				<label for="password">Password</label>
				<input type="password" class="form-control" id="password" name="password" placeholder="Password">
				<span class="help-block"> </span>
			</div>
			<div class="form-group">
				<label for="Repassword">Repeat password</label>
				<input type="password" class="form-control" id="Repassword" name="password2" placeholder="Repeat password">
				<span class="help-block"> </span>
			</div>
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save</button>
		</div>
	</form>
</div>""")

#===========================================================================================
# Function that saves the profile settings:
#===========================================================================================
def saveProfile():
	global settings, changes, INLINE

	# Open the debugging message section if needed:
	if settings['DEBUG'] == 1:
		print('<pre>')

	# Has the username changed?  If so, store the change:
	webUSERNAME = form.getvalue('webUSERNAME')
	changed = webUSERNAME != None and webUSERNAME != "" and settings['guiUSERNAME'] != webUSERNAME
	doChange(changed, 'guiUSERNAME', webUSERNAME)

	# Has the admin name changed?  If so, store the change:
	webADMIN = form.getvalue('admin_name')
	changed = webADMIN != None and webADMIN != "" and settings['guiNAME'] != webADMIN
	doChange(changed, 'guiNAME', webADMIN)

	# Has the password changed?  If so, store the change:
	webPASSWORD = form.getvalue('password')
	changed = webPASSWORD != None and webPASSWORD != "" and settings['guiPassword'] != guiPassword
	doChange(changed, 'guiPassword', webPASSWORD)

	# Close the debugging message section:
	if settings['DEBUG'] == 1:
		print('</pre>')
	if not INLINE:
		print(
"""	<div class="box-body">
		<a href="/?action=profile" class="btn btn-primary">Back to Profile Settings</a>
	</div>""")

	saveChanged(PIVPN_ENV)

#===========================================================================================
# Function that shows the Web UI login box:
#===========================================================================================
def showLogin():
	print(
"""	<link rel="stylesheet" href="static/plugins/iCheck/square/blue.css">
</head>
<body class="hold-transition login-page">
	<div class="login-box">
		<div class="login-logo">
			<img src="/static/img/favicon/favicon-192x192.png"><br /><b>PiVPN</b> Admin</a>
		</div>

		<div class="login-box-body">
			<p class="login-box-msg">Sign in to start your session</p>
			<form action="/checklogin" method="post">
				<div class="form-group has-feedback">
					<input type="text" class="form-control" name="username" placeholder="User Name">
					<span class="glyphicon glyphicon-user form-control-feedback"></span>
				</div>
				<div class="form-group has-feedback">
					<input type="password" class="form-control" name="password" placeholder="Password">
					<span class="glyphicon glyphicon-lock form-control-feedback"></span>
				</div>
				<div class="row">
					<div class="col-xs-8"></div>
					<div class="col-xs-4">
						<button type="submit" class="btn btn-primary btn-block btn-flat">Sign In</button>
					</div>
				</div>
			</form>
		</div>
	</div>""")
	footer(False)
	print(
"""	<script src="/static/plugins/iCheck/icheck.min.js"></script>
	<script>
	  \$(function () {
	    \$('input').iCheck({
	      checkboxClass: 'icheckbox_square-blue',
	      radioClass: 'iradio_square-blue',
      	increaseArea: '20%'
	    });
	    \$("input:text:visible:first").focus();
	  });
	</script>""")

#===========================================================================================
# Helper functions dealing with sessions and cookies:
#===========================================================================================
def get_random_alphanumeric_string(length):
	letters_and_digits = string.ascii_letters + string.digits
	result_str = ''.join((random.choice(letters_and_digits) for i in range(length)))
	return result_str

def getRemoteAddr():
	try:
		return os.environ['REMOTE_ADDR']
	except:
		return ""

def getCookies():
	# Parse the cookie list to get the session ID.
	my_dict = {}
	if 'HTTP_COOKIE' in os.environ:
		cookies = os.environ['HTTP_COOKIE']
		cookies = cookies.split('; ')
		for cookie in cookies:
			cookie = cookie.split('=')
			my_dict[ cookie[0] ] = cookie[1]
	return my_dict

def setCookie(key, val, expires = 0):
	print("Set-Cookie: " + key + "=" + val + "; expires=" + time.strftime("%a, %d-%b-%Y %T GMT", time.gmtime( expires )))

def readSessions():
	global sessions

	# Read the session file:
	try:
		file = open('/tmp/sessions.json', 'r')
	except:
		return {}
	data = file.read()
	list = json.loads(data)
	file.close()

	# Is the session still valid?
	sessions = {}
	current = int(time.time())
	if list != None:
		for key in list:
			if list[key]['expires'] > current:
				sessions[key] = list[key]

def writeSessions():
	global sessions
	file = open('/tmp/sessions.json', 'w')
	file.write(json.dumps(sessions, indent=4))
	file.close()

#===========================================================================================
# Function that process the login information provided:
#===========================================================================================
def checkLogin():
	global settings, REDIRECT

	# Check to see if the username/password combo is correct:
	username = str(form.getvalue('username'))
	password = str(form.getvalue('password'))
	if settings['guiUsername'] != username or settings['guiPassword'] != password:
		return False

	# Generate SID and add it to the array:
	SID = get_random_alphanumeric_string(32)
	sessions[SID] = {
		'expires': int(time.time()) + 60*60,
		'remote': getRemoteAddr()
	}

	# Output a cookie for the user:
	setCookie('sid', SID, sessions[SID]['expires'])

	# Finally, set up the web redirect to the main page:
	REDIRECT="/"
	return True

#===========================================================================================
# Function to validate the session ID:
#===========================================================================================
def checkSession():
	global sessions

	# If the specified session exists, add an hour and return True:
	try:
		SID = cookies['sid']
		result = getRemoteAddr() == sessions[ SID ]['remote']
		if result:
			sessions[ SID ]['expires'] = int(time.time()) + 60
			setCookie('sid', SID, sessions[SID]['expires'])
		return result
	except KeyError:
		return False

#===========================================================================================
# Function to log the user out:
#===========================================================================================
def logOut():
	global sessions
	cookies = getCookies()
	try:
		sessions.pop(cookies['sid'])
	except:
		pass
	setCookie('sid', SID)

#===========================================================================================
# Functions dealing with PiVPN docker container settings:
#===========================================================================================
def readSettings(FILE):
	global settings
	if os.path.exists(FILE):
		with open(FILE) as f:
			for line in f:
				parts = line.strip().split("=")
				try:
					settings[ parts[0] ] = int( parts[1] )
				except ValueError:
					settings[ parts[0] ] = parts[1]
				except IndexError:
					pass

def saveChanged(FILE):
	global changes, settings

	# Uncomment to show the contents of the "changes" dictionary:
	#print(json.dumps(changes, indent=4)); exit()

	# Return to caller if no changes to be made:
	if len(changes) == 0:
		return

	# Save contents of settings dict, then read in the existing variable file into settings:
	old_settings = settings
	settings = {}
	readSettings(FILE)

	# Apply the changes to the variable dictionary:
	for key in changes:
		try:
			settings[key] = int(changes[key])
		except ValueError:
			settings[key] = '"' + changes[key] + '"'

	# Uncomment to show the contents of the "env" dictionary:
	#print(json.dumps(env, indent=4)); exit()

	# Write the updated variable dictionary to disk:
	with open(FILE, "w") as f:
		for key in settings:
			try:
				f.write(key + '=' + str(int(settings[key])) + "\n")
			except ValueError:
				f.write(key + '="' + settings[key].replace('"', '') + '"' + "\n")

	# Restore contents of the settings dictionary:
	settings = old_settings

def defaultSetting(key, default_value, FILE = None):
	global settings, changes
	try:
		settings[key]
	except KeyError:
		settings[key] = default_value
		if FILE != None:
			changes[key] = default_value
			saveChanged(FILE)

#===========================================================================================
# Function doing all the main decision-making:
#===========================================================================================
def Main():
	global PIVPN_ENV, form, ACTION, settings, changes, SID, INLINE, validSession
	global REDIRECT, REDIRECT_SEC, URL_QUERY, cookies, sessions, parsed

	# Uncomment to force a particular action.  Helpful during debugging... :p
	#ACTION="certs"

	# Get all the session IDs and cookies:
	cookies = getCookies()
	sessions = readSessions()

	# Quotes are there for BASH.  Let's remove them for us:
	for key in settings:
		try:
			settings[key] = settings[key].replace('"', '')
		except:
			pass

	# Parse the URI to get the parameters passed:
	parsed = []
	URL_QUERY = {}
	try:
		parsed = urllib.parse.urlparse(os.environ['REQUEST_URI'])
		#print(json.dumps(parsed, indent=4)); exit()
		URL_QUERY = parse_qs(parsed.query)
		#print(json.dumps(URL_QUERY, indent=4)); exit()
	except:
		pass

	# If we have been redirected to the 404, see if we can figure out the action requested:
	if ACTION == "404":
		try:
			ACTION = parsed[2].split('?')[0][1:]
			parts = ACTION.split('/')
			if parts[0] == "download":
				ACTION = parts[0]
				URL_QUERY['name'] = [ '/'.join(parts[1:]).replace('.ovpn', '') ]
			else:
				ACTION = os.path.basename(parsed[2].split('?')[0])
		except:
			pass

	# Is the "inline" parameter in the URL_QUERY variable:
	INLINE = 'inline' in URL_QUERY

	# If either of the following is true:
	# 1) debug is disabled, OR 
	# 2) debug is enabled and login requirement is enabled
	# Then check if the session ID isn't valid for any reason.  If the session ID isn't valid, force a login:
	validSession = True
	if settings['DEBUG'] == 1 and settings['LOGIN'] == 0:
		if ACTION == "checklogin" or ACTION == "login" or ACTION == "logout":
			REDIRECT = "/"
			ACTION = ""
		validSession = True
	elif settings['DEBUG'] == 0 or settings['LOGIN'] == 1:
		validSession = checkSession()
		if ACTION == "checklogin":
			if checkLogin():
				ACTION=""
		elif ACTION != "404":
			if not validSession:
				ACTION = "login"

	# Actions that don't require the header and footer to be sent:
	if ACTION == "download":
		if not downloadOVPN():
			ACTION = "404"
	elif ACTION == "404":
		print('HTTP/1.1 404 Not Found')
	elif ACTION == "logout":
		REDIRECT = "/login"

	# Call these functions only if we aren't being called as an inline function:
	elif ACTION == "saveprofile":
		if INLINE:
			saveProfile()
			exit()
		if settings['DEBUG'] == 0:
			REDIRECT = "/profile"
	elif ACTION == "savepivpn":
		if INLINE:
			savePiVPN()
			exit()
		if settings['DEBUG'] == 0:
			REDIRECT = "/pivpn"
	elif ACTION == "savewebui":
		if INLINE:
			saveWebUI()
			exit()
		if settings['DEBUG'] == 0:
			REDIRECT = "/webui"

	# Set up automatic refresh for main page ONLY if refresh time >= 30:
	if ACTION == "" or ACTION == None:
		try:
			REDIRECT_SEC = int(settings['REDIRECT_SEC'])
		except:
			pass
		if REDIRECT_SEC >= 30:
			REDIRECT = "/"
		
	# All the other actions:
	header()
	if ACTION == "" or ACTION == None:
		body("Status")
		Home()
	elif ACTION == "logs":
		body("Logs")
		showLogs()
	elif ACTION == "certs":
		body("Certificates")
		showCerts()
	elif ACTION == "revoke":
		body("Revoke Certificate")
		revokeOVPN()
	elif ACTION == "create":
		body("Create Certificate")
		createOVPN()
	elif ACTION == "profile":
		body("Profile Settings")
		showProfile()
	elif ACTION == "pivpn":
		body("PiVPN Settings")
		PiVPN()
	elif ACTION == "make":
		body("Create Certificate")
		makeCert()
	elif ACTION == "webui":
		body("Web UI Settings")
		WebUI()
	elif ACTION == "logout":
		REDIRECT = "/login"
		body("Logout")
		logOut()
	elif ACTION == "login" or ACTION == "checklogin":
		showLogin()
	elif ACTION == "saveprofile":
		body("Profile Settings")
		saveProfile()
	elif ACTION == "savepivpn":
		body("PiVPN Settings")
		savePiVPN()
	elif ACTION == "savewebui":
		body("Web UI Settings")
		saveWebUI()
	else:
		show404()
	footer()

#===========================================================================================
# Core code section:
#===========================================================================================
# Read our settings files:
readSettings("/tmp/vars")
readSettings(PIVPN_ENV)
#print(json.dumps(settings, indent=4)); exit()

# We need to define some defaults, in case the variables weren't already defined:
defaultSetting('guiCreation',  datetime.datetime.now().strftime("%b %d, %Y"), PIVPN_ENV)
defaultSetting('guiName',      'Adminstrator')
defaultSetting('guiUsername',  'admin')
defaultSetting('guiPassword',  'password')
defaultSetting('pivpnWEB_MGMT', 49081)
defaultSetting('DEBUG',         0)
defaultSetting('LOGIN',         1)
defaultSetting('ONLY_VALID',    1)
defaultSetting('REDIRECT_SEC',  0)

# Run the Main function.  Use try/except bracket to capture error messages ONLY if debug is enabled:
if settings['DEBUG'] == 1:
	sys.stderr = sys.stdout
	try:
		Main()
	except SystemExit:
		pass
	except:
		print("\n\n<pre>")
		traceback.print_exc()
else:
	Main()
writeSessions()
