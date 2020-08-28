#!/bin/bash
echo "Content-type: text/html"
echo ""

function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
function get_parameter ()
{
	urldecode $(echo "$query" | tr '&' '\n' | grep "^$1=" | head -1 | sed "s/.*=//")
}
if [ "$REQUEST_METHOD" = POST ]; then
	query=$( head --bytes="$CONTENT_LENGTH" )
else
	query="$QUERY_STRING"
fi
ACTION=$(get_parameter 'action')
SID=$(get_parameter 'sid')

CLIENTS=0
MB_IN=0
MB_OUT=0
export LC_NUMERIC=en_US

function header()
{
	cat << EOF
<!DOCTYPE html>
<html>
	<head>
		<title>PiVPN Admin</title>
		<meta http-equiv="content-type" content="text/html; charset=UTF-8">
		<meta charset="utf-8">
		<meta http-equiv="X-UA-Compatible" content="IE=edge">
		<meta name="viewport" content="width=device-width, initial-scale=1">
		<meta content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no" name="viewport">
		<link rel="icon" type="image/png" sizes="32x32" href="/static/img/favicon/favicon-32x32.png">
		<link rel="icon" type="image/png" sizes="16x16" href="/static/img/favicon/favicon-16x16.png">
		<link rel="icon" type="image/png" sizes="96x96" href="/static/img/favicon/favicon-96x96.png">
		<link rel="icon" type="image/png" sizes="192x192" href="/static/img/favicon/favicon-192x192.png">
		<link href="/static/css/bootstrap.min.css" rel="stylesheet">
		<link rel="stylesheet" href="/static/css/font-awesome.min.css">
		<link rel="stylesheet" href="/static/css/ionicons.min.css">
		<link rel="stylesheet" href="/static/css/AdminLTE.min.css">
EOF
}

function body()
{
	cat << EOF
		<link rel="stylesheet" href="/static/css/skins/skin-blue.min.css">
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
								<li$([[ "$ACTION" == "" ]] && echo ' class="active"')>
									<a href="/">Home $([[ "$ACTION" == "" ]] && echo '<span class="sr-only">(current)</span>')</a>
								</li>
								<li$([[ "$ACTION" == "config" ]] && echo ' class="active"')>
									<a href="/?action=config">Configuration $([[ "$ACTION" == "config" ]] && echo '<span class="sr-only">(current)</span>')</a>
								</li>
								<li$([[ "$ACTION" == "certs" ]] && echo ' class="active"')>
									<a href="/?action=certs">Certificates $([[ "$ACTION" == "certs" ]] && echo '<span class="sr-only">(current)</span>')</a>
								</li>
								<li$([[ "$ACTION" == "logs" ]] && echo ' class="active"')>
									<a href="/?action=logs">Logs $([[ "$ACTION" == "logs" ]] && echo '<span class="sr-only">(current)</span>')</a>
								</li>
							</ul>
						</div>
						<div class="navbar-custom-menu">
							<ul class="nav navbar-nav">
								<li class="dropdown user user-menu$([[ "$ACTION" == "profile" ]] && echo ' active')">
									<a href="#" class="dropdown-toggle" data-toggle="dropdown">
										<img src="/static/img/person.png" class="user-image" alt="User Image">
										<span class="hidden-xs">Administrator</span>
									</a>
									<ul class="dropdown-menu">
										<li class="user-header">
											<img src="/static/img/person.png" class="img-circle" alt="User Image">
											<p>
												Administrator
												<small>Created on Aug 28, 2020</small>
											</p>
										</li>
										<li class="user-footer">
											<div class="pull-left">
												<a href="/?action=profile" class="btn btn-default btn-flat">Profile</a>
											</div>
											<div class="pull-right">
												<a href="/?action=logout" class="btn btn-default btn-flat">Sign out</a>
											</div>
										</li>
									</ul>
								</li>
							</ul>
						</div>
					</div>
				</nav>
			</header>
			<div class="content-wrapper" style="min-height: 835px;">
				<div class="container">
					<section class="content-header"><h1>$@</h1></section>
					<section class="content">
						<div class="row">
EOF
}

function footer()
{
	cat << EOF
				  </section>
				</div>
			</div>
			<script src="/static/js/jquery-2.2.3.min.js"></script>
			<script src="/static/js/bootstrap.min.js"></script>
			<script src="/static/js/clipboard.min.js"></script>
			<script src="/static/js/app.js"></script>
			<script src="/static/js/custom.js"></script>
EOF
}

function bottom()
{
	cat << EOF
		</div>
	</body>
</html>
EOF
}

function client_list()
{
	killall -USR2 openvpn
	cat /var/log/openvpn-status.log | grep "^CLIENT_LIST" > /tmp/clients.list
	CLIENTS=$(cat cat /tmp/clients.list | wc -l)
	(if [[ "${CLIENTS}" -gt 0 ]]; then
		cat /tmp/clients.list | (while read a b c d e f g h i j k l m n o p; do 
			cat << EOF
							<tr>
								<td>$b</td>
								<td>$c</td>
								<td>$d</td>
								<td>$(($e / 1024)) KB</td>
								<td>$(($f / 1024)) KB</td>
								<td>$g $h $i $j $k</td>
								<td>$([[ "$m" == "UNDEF" ]] && echo $b || echo $m)</td>
							</tr>
EOF
		done)
	else
		cat << EOF
							<tr>
								<td colspan="7">
									<p style="text-align:center; font-weight: bold;">
										<font size="+1">
											No Clients Connected
										</font>
									</p>
								</td>
							</tr>
EOF
	fi) > /tmp/clients.html
	rm /tmp/clients.list
}

function blocks()
{
cat << EOF
<div class="col-md-3 col-sm-6 col-xs-12">
  	<div class="info-box">
		<span class="info-box-icon bg-green">
	  		<i class="ion ion-network"></i>
		</span>
		<div class="info-box-content">
	  		<span class="info-box-text">
				Clients count: <span class="info-box-number2">${CLIENTS:-"0"}</span>
			</span>
<!--
			<span class="info-box-text">
				In: <span class="info-box-number2">${MB_IN:-"0"} MB</span>
			</span>
			<span class="info-box-text">
				Out: <span class="info-box-number2">${MB_OUT:-"0"} MB </span>
			</span>
-->
		</div>
	</div>
</div>
<div class="col-md-3 col-sm-6 col-xs-12">
	<div class="info-box">
		<span class="info-box-icon bg-aqua">
			<i class="ion ion-ios-pulse"></i>
		</span>
		<div class="info-box-content">
			<span class="info-box-text">Load Average:</span>
			<span class="info-box-number">
				$(uptime | cut -d"," -f 3- | cut -d":" -f 2)<br>
			</span>
	  		<span class="info-box-text">
				CPU count: <span class="info-box-number2">$(grep -c ^processor /proc/cpuinfo)</span>
			</span>
		</div>
	</div>
</div>
<div class="clearfix visible-sm-block"></div>
	<div class="col-md-3 col-sm-6 col-xs-12">
		<div class="info-box">
			<span class="info-box-icon bg-orange">
				<i class="ion ion-arrow-graph-up-right"></i>
			</span>
			<div class="info-box-content">
				<span class="info-box-text">OS uptime:</span>
				<span class="info-box-number">$(uptime -p | cut -d" " -f 2- | cut -d"," -f 1-2 | sed "s/, /<br>/")</span>
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
	  			<span class="info-box-number">$(date +"%Y-%m-%d %T")</span>
			</div>
		</div>
	</div>
</div>
EOF
}

function memory_usage()
{
	MEM_TOTAL=MEM_TOTAL=$(vmstat -s | grep "total memory" | cut -d"K" -f 1)
	MEM_TOTAL=$((MEM_TOTAL / 1024))
	MEM_FREE=$(vmstat -s | grep "free memory" | cut -d"K" -f 1)
	MEM_FREE=$((MEM_FREE / 1024))
	MEM_USED=$((MEM_TOTAL - MEM_FREE))
	MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

	VIRT_TOTAL=VIRT_TOTAL=$(vmstat -s | grep "total swap" | cut -d"K" -f 1)
	VIRT_TOTAL=$((VIRT_TOTAL / 1024))
	VIRT_USED=$(vmstat -s | grep "used swap" | cut -d"K" -f 1)
	VIRT_USED=$((VIRT_FREE / 1024))
	VIRT_PERCENT=$((VIRT_USED * 100 / VIRT_TOTAL))

	cat << EOF
<div class="box box-default">
	<div class="box-header with-border">
		<h3 class="box-title">Memory usage</h3>
	</div>
	<div class="box-body">
		<div class="col-md-6">
			<div class="progress-group">
				<span class="progress-text">Memory</span>
				<span class="progress-number">
					<b>$(numfmt --g ${MEM_USED})</b>
					/
					$(numfmt --g ${MEM_TOTAL}) MB
					- ${MEM_PERCENT}%
				</span>
				<div class="progress sm">
					<div class="progress-bar progress-bar-aqua" style="width: ${MEM_PERCENT}%"></div>
				</div>
			</div>
		</div>
		<div class="col-md-6">
			<div class="progress-group">
				<span class="progress-text">Swap</span>
				<span class="progress-number">
					<b>$(numfmt --g ${VIRT_USED})</b>
					/
					$(numfmt --g ${VIRT_TOTAL}) MB
					- ${VIRT_PERCENT}%
				</span>
				<div class="progress sm">
					<div class="progress-bar progress-bar-red" style="width: ${VIRT_PERCENT}%"></div>
				</div>
			</div>
		</div>
	</div>
</div>
EOF
}

function clients()
{
	cat << EOF
<div class="row">
	<div class="col-md-12">
		<div class="box box-default">
			<div class="box-header with-border">
				<h3 class="box-title">Connected clients</h3>
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
						<tbody>
EOF
	cat /tmp/clients.html
	rm /tmp/clients.html
	cat << EOF
						</tbody>
					</table>
				</div>
			</div>
			<div class="box-footer clearfix"></div>
		</div>
	</div>
</div>
EOF
}

function system_info()
{
	cat << EOF
<div class="row">
	<div class="col-md-6 col-sm-12 col-xs-12">
		<div class="info-box">
			<span class="info-box-icon bg-white">
				<i class="ion ion-ios-information-empty"></i>
			</span>
			<div class="info-box-content">
				<span class="info-box-text">
					OpenVPN version: <span class="info-box-number3">$(openvpn --version | head -1)</span>
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
				<span class="info-box-number3">$(lsb_release -a 2>&1 | grep "Distrib" | cut -d":" -f 2)</span>
				<span class="info-box-text">Architecture: </span>
				<span class="info-box-number3">$(dpkg --print-architecture)</span>
			</div>
		</div>
	</div>
	<div class="clearfix visible-sm-block"></div>
</div>
EOF
}

function showLogs()
{
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Last 200 lines of OpenVPN log</h3>
	</div>
	<pre style="font-size: 13px;line-height: 1.4em;">
EOF
sudo cat /var/log/openvpn.log | tail -200 | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
cat << EOF
	</pre>
</div>
EOF
}

function configuration()
{
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit configuration</h3>
	</div>
	<form role="form" action="/ov/config" method="post">
		<div class="box-body">
			<div class="form-group">
				<label for="name">Profile</label>
				<input type="text" class="form-control" name="Profile" id="Profile" disabled value="default">
			</div>
			<div class="form-group">
				<label for="name">Port</label>
				<input type="text" class="form-control" name="Port" id="Port" placeholder="" Value="1194">
				<span class="help-block">Which TCP/UDP port should OpenVPN listen on</span>
			</div>
			<div class="form-group">
				<label for="name">Proto</label>
				<input type="text" class="form-control" name="Proto" id="Proto" placeholder="Enter network name" value="udp">
				<span class="help-block">TCP or UDP server</span>
			</div>
			<div class="form-group">
				<label for="name">CA cert</label>
				<input type="text" class="form-control" name="Ca" id="Ca" placeholder="Enter CA certificate path" value="keys/ca.crt">
			</div>
			<div class="form-group">
				<label for="name">Server certificate</label>
				<input type="text" class="form-control" name="Cert" id="Cert" placeholder="Enter server certificate path" value="keys/server.crt">
				<span id="helpBlock" class="help-block"></span>
			</div>
			<div class="form-group">
				<label for="name">Server key</label>
				<input type="text" class="form-control" name="Key" id="Key" placeholder="Enter server private key path" Value="keys/server.key">
				<span id="helpBlock" class="help-block"></span>
			</div>
			<div class="form-group">
				<label for="name">Cipher</label>
				<input type="text" class="form-control" name="Cipher" id="Cipher" placeholder="" value="AES-256-CBC">
				<span id="helpBlock" class="help-block"></span>
			</div>
			<div class="form-group">
				<label for="name">Keysize</label>
				<input type="text" class="form-control" name="Keysize" id="Keysize" placeholder="" value="256">
				<span id="helpBlock" class="help-block"></span>
			</div>
			<div class="form-group">
				<label for="name">Auth</label>
				<input type="text" class="form-control" name="Auth" id="Auth" placeholder="" value="SHA256">
				<span id="helpBlock" class="help-block"></span>
			</div>
			<div class="form-group">
				<label for="name">Dh</label>
				<input type="text" class="form-control" name="Dh" id="Dh" placeholder="" value="dh2048.pem">
				<span id="helpBlock" class="help-block">Diffie hellman parameters</span>
			</div>
			<div class="form-group">
				<label for="name">Server</label>
				<input type="text" class="form-control" name="Server" id="Server" placeholder="" value="10.8.0.0 255.255.255.0">
				<span id="helpBlock" class="help-block">Configures server mode and supply a VPN subnet for OpenVPN to draw client addresses from.</span>
			</div>
			<div class="form-group">
				<label for="name">Keepalive</label>
				<input type="text" class="form-control" name="Keepalive" id="Keepalive" placeholder="" value="10 120">
				<span id="helpBlock" class="help-block">
					The keepalive directive causes ping-like messages to be sent back and forth  over the link
					so that each side knows when the other side has gone down.  Ping every 10 seconds, assume
					that remote peer is down if no ping received during a 120 second time period.
				</span>
			</div>
			<div class="form-group">
				<label for="name">IfconfigPoolPersist</label>
				<input type="text" class="form-control" name="IfconfigPoolPersist" id="IfconfigPoolPersist" placeholder="" value="ipp.txt">
				<span id="helpBlock" class="help-block">
					Maintain a record of client &lt;-> virtual IP address associations in this file.  If OpenVPN goes down or is restarted,
					reconnecting clients can be assigned the same virtual IP address from the pool that was previously assigned.
				</span>
      		</div>
			<div class="form-group">
				<label for="name">MaxClients</label>
				<input type="text" class="form-control" name="MaxClients" id="MaxClients" placeholder="" value="100">
				<span id="helpBlock" class="help-block">The maximum number of concurrently connected clients we want to allow.</span>
			</div>
			<div class="form-group">
				<label for="name">Management</label>
				<input type="text" class="form-control" name="Management" id="Management" placeholder="" value="0.0.0.0 2080">
				<span id="helpBlock" class="help-block"></span>
			</div>
      		<input type="hidden" name="_xsrf" value="Gdi61EN8fjQd4D1lVF1c7AInKoW6XCdy" />
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save and apply</button>
		</div>
	</form>
</div>
EOF
}

function showCerts()
{
	INDEX="/etc/openvpn/easy-rsa/pki/index.txt"

	cat << EOF
	<div class="row">
		<div class="col-md-12">
			<div class="box box-info">
				<div class="box-header with-border">
					<h3 class="box-title">Clients certificates</h3>
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
									<th>Details</th>
									<th></th>
									<th></th>
								</tr>
							</thead>
							<tbody>
EOF
	sudo cat ${INDEX} | while read -r line || [ -n "$line" ]; do
		NAME=$(echo "$line" | awk -FCN= '{print $2}')
		EXPIRES=$(echo "$line" | awk '{if (length($2) == 15) print $2; else print "20"$2}' | cut -b 1-8 | date +"%b %d %Y" -f -)
		STATE=$(echo "$line" | awk '{print $1}')
		case "$STATE" in
			R)
				IS_VALID="Revoked"
				REVOKED=$(echo "$line" | awk '{if (length($3) == 15) print $2; else print "20"$3}' | cut -b 1-8 | date +"%b %d %Y" -f -)
				SERIAL=$(echo "$line" | awk -FCN= '{print $4}')
				DETAILS=$(echo "$line" | awk -FCN= '{print $5}')
				;;
			*)
				IS_VALID="Unknown"
				[[ "${STATE}" == "V" ]] && IS_VALID="Valid"
				REVOKED=""
				SERIAL=$(echo "$line" | awk -FCN= '{print $3}')
				DETAILS=$(echo "$line" | awk -FCN= '{print $4}')
				;;
		esac
		cat << EOF
								<tr>
									<td>${NAME}</td>
									<td>${IS_VALID}</td>
									<td>${EXPIRES}</td>
									<td>${REVOKED}</td>
									<td>${DETAILS}</td>
									<td></td>
								</tr>
EOF
	done
 	cat << EOF
						</tbody>
					</table>
				</div>
			</div>
			<div class="box-footer clearfix"></div>
		</div>
	</div>
</div>
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Create a new certificate</h3>
	</div>
	<form role="form" action="/certificates" method="post">
		<div class="box-body">
			<div class="form-group " >
				<label for="name">Name</label>
				<input type="text" class="form-control" id="Name" name="Name">
			</div>
			<span class="help-block"></span>
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Create</button>
		</div>
	</form>
</div>
EOF
}

function loginBox()
{
	cat << EOF
	<link rel="stylesheet" href="static/plugins/iCheck/square/blue.css">
</head>
<body class="hold-transition login-page">
	<div class="login-box">
		<div class="login-logo">
			<a href="#"><b>PiVPN</b> Admin</a>
		</div>
	  
		<div class="login-box-body">
			<p class="login-box-msg">Sign in to start your session</p>
			<form action="/login" method="post">
				<div class="form-group has-feedback">
					<input type="text" class="form-control" name="login" placeholder="Login">
					<span class="glyphicon glyphicon-user form-control-feedback"></span>
				</div>
				<div class="form-group has-feedback">
					<input type="password" class="form-control" name="password" placeholder="Password">
					<span class="glyphicon glyphicon-lock form-control-feedback"></span>
				</div>
				<div class="row">
					<div class="col-xs-8"></div>
					<input type="hidden" name="_xsrf" value="yf6Z13mUH0Ce0ITAfA5AfIWupDqivGr4" />
					<div class="col-xs-4">
						<button type="submit" class="btn btn-primary btn-block btn-flat">Sign In</button>
					</div>
				</div>
			</form>
		</div>  
	</div>
EOF
}

function loginBoxPost()
{
	cat << EOF
<script src="static/plugins/iCheck/icheck.min.js"></script>
<script>
  $(function () {
    $('input').iCheck({
      checkboxClass: 'icheckbox_square-blue',
      radioClass: 'iradio_square-blue',
      increaseArea: '20%' 
    });
    $("input:text:visible:first").focus();
  });
</script>
EOF
}

function showProfile()
{
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit your profile</h3>
	</div>
	<form role="form" action="/profile" method="post">
		<div class="box-body">
			<div class="form-group">
				<label for="name">Login</label>
				<input type="text" class="form-control" id="login" name="Login" disabled value="admin">
			</div>
			<div class="form-group " >
				<label for="name">Name</label>
				<input type="text" class="form-control" id="name" name="Name" placeholder="Enter name" value="Administrator">
				<span class="help-block"> </span>
			</div>
			<div class="form-group ">
				<label for="email">Email address</label>
				<div class="input-group">
					<span class="input-group-addon"><i class="fa fa-envelope"></i></span>
					<input type="email" class="form-control" id="email" name="Email" placeholder="Enter email" value="root@localhost">
				</div>
				<span class="help-block"> </span>
			</div>
			<div class="form-group ">
				<label for="password">Password</label>
				<input type="password" class="form-control" id="password" name="Password" placeholder="Password">
				<span class="help-block"> </span>
			</div>
			<div class="form-group ">
				<label for="Repassword">Repeat password</label>
				<input type="password" class="form-control" id="Repassword" name="Repassword" placeholder="Repeat password">
				<span class="help-block"> </span>
			</div>
			<input type="hidden" name="_xsrf" value="yf6Z13mUH0Ce0ITAfA5AfIWupDqivGr4" />
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save</button>
		</div>
	</form>
</div>
EOF
}

header
case "${ACTION}" in
	"login")
		loginBox
		;;

	"profile")
		body "Profile"
		showProfile
		;;

	"logs")
		body "Logs"
		showLogs
		;;

	"certs")
		body "Certificates"
		showCerts
		;;

	"config")
		body "Configuration"
		configuration
		;;

	*)
		body "Status"
		client_list
		blocks
		memory_usage
		clients
		system_info
		;;
esac
footer
[[ "${ACTION}" == "login" ]] && loginBoxPost
bottom
