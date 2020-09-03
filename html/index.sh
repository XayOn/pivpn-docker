#!/bin/bash

#===========================================================================================
# Function that starts the header of the web page:
#===========================================================================================
function header()
{
	cat << EOF
<!DOCTYPE html><html>
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

#===========================================================================================
# Function that ends the header and begins the body of the web page:
#===========================================================================================
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
							<button type="button" class="navbar-toggle collapsudo sed" data-toggle="collapse" data-target="#navbar-collapse">
								<i class="fa fa-bars"></i>
            				</button>
          				</div>
						<div class="collapse navbar-collapse pull-left" id="navbar-collapse">
							<ul class="nav navbar-nav">
								<li$([[ "$ACTION" == "" ]] && echo ' class="active"')>
									<a href="/?sid=${SID}">Home $([[ "$ACTION" == "" ]] && echo '<span class="sr-only">(current)</span>')</a>
								</li>
								<li$([[ "$ACTION" == "certs" ]] && echo ' class="active"')>
									<a href="/?action=certs&sid=${SID}">Certificates $([[ "$ACTION" == "certs" ]] && echo '<span class="sr-only">(current)</span>')</a>
								</li>
								<li class="dropdown">
									<a href="#" class="dropdown-toggle" data-toggle="dropdown">
										Configuration <span class="caret"></span>
									</a>
									<ul class="dropdown-menu" role="menu">
										<li$([[ "$ACTION" == "pivpn" ]] && echo ' class="active"')>
											<a href="/?action=pivpn&sid=${SID}">PiVPN Server</a>
      									</li>
										<li$([[ "$ACTION" == "webui" ]] && echo ' class="active"')>
											<a href="/?action=webui&sid=${SID}">UI Settings</a>
										</li>
									</ul>
								</li>
								<li$([[ "$ACTION" == "logs" ]] && echo ' class="active"')>
									<a href="/?action=logs&sid=${SID}">Logs $([[ "$ACTION" == "logs" ]] && echo '<span class="sr-only">(current)</span>')</a>
								</li>
							</ul>
						</div>
						<div class="navbar-custom-menu">
							<ul class="nav navbar-nav">
								<li class="dropdown user user-menu$([[ "$ACTION" == "profile" ]] && echo ' active')">
									<a href="#" class="dropdown-toggle" data-toggle="dropdown">
										<img src="/static/img/person.png" class="user-image" alt="User Image">
										<span class="hidden-xs">${guiName:-"Adminstrator"}</span>
									</a>
									<ul class="dropdown-menu">
										<li class="user-header">
											<img src="/static/img/person.png" class="img-circle" alt="User Image">
											<p>
												${guiName:-"Adminstrator"}
												<small>${guiCreation}</small>
											</p>
										</li>
										<li class="user-footer">
											<div class="pull-left">
												<a href="/?action=profile&sid=${SID}" class="btn btn-default btn-flat">Profile</a>
											</div>
											<div class="pull-right">
												<a href="/?action=logout&sid=${SID}" class="btn btn-default btn-flat">Sign out</a>
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

#===========================================================================================
# Function that shows the footer of the web page:
#===========================================================================================
function footer()
{
	[[ ! -z "${FOOTER_CALLED}" ]] && return
	FOOTER_CALLED=1
	[[ "$1" != "skip" ]] && cat << EOF
				  </section>
				</div>
			</div>
EOF
	cat << EOF
			<script src="/static/js/jquery-2.2.3.min.js"></script>
			<script src="/static/js/bootstrap.min.js"></script>
			<script src="/static/js/clipboard.min.js"></script>
			<script src="/static/js/app.js"></script>
			<script src="/static/js/custom.js"></script>
EOF
}

#===========================================================================================
# Function that ends the body of the web page:
#===========================================================================================
function bottom()
{
	[[ "$ACTION" != "login" ]] && echo -n "</div>"
	cat << EOF
</body>
</html>
EOF
}

#===========================================================================================
# Function that gathers the client list of the OpenVPN server:
#===========================================================================================
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

#===========================================================================================
# Function that shows blocks of number of connected clients, server load, CPU count and time
#===========================================================================================
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
				<span class="info-box-number">$(uptime -p | cut -d" " -f 2- | cut -d"," -f 1-2 | sudo sed "s/, /<br>/")</span>
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

#===========================================================================================
# Function that displays memory and swap usage for the machine:
#===========================================================================================
function memory_usage()
{
	MEM_TOTAL=MEM_TOTAL=$(vmstat -s | grep "total memory" | cut -d"K" -f 1)
	MEM_TOTAL=$((MEM_TOTAL / 1024))
	MEM_FREE=$(vmstat -s | grep "free memory" | cut -d"K" -f 1)
	MEM_FREE=$((MEM_FREE / 1024))
	MEM_USED=$((MEM_TOTAL - MEM_FREE))
	MEM_PERCENT=$((MEM_USED * 100 / MEM_TOTAL))

	VIRT_TOTAL=$(vmstat -s | grep "total swap" | cut -d"K" -f 1)
	VIRT_TOTAL=$((VIRT_TOTAL / 1024))
	VIRT_USED=$(vmstat -s | grep "usudo sed swap" | cut -d"K" -f 1)
	VIRT_USED=$((VIRT_FREE / 1024))
	VIRT_PERCENT=0
	[[ "${VIRT_TOTAL}" -gt 0 ]] && VIRT_PERCENT=$((VIRT_USED * 100 / VIRT_TOTAL))

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

#===========================================================================================
# Function that displays the client list generated by "client_list" function:
#===========================================================================================
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

#===========================================================================================
# Function that displays some information about the PiVPN container:
#===========================================================================================
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

#===========================================================================================
# Function that shows the OpenVPN logs:
#===========================================================================================
function showLogs()
{
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Last 200 lines of OpenVPN log</h3>
	</div>
	<pre style="font-size: 13px;line-height: 1.4em;">
EOF
	sudo cat /var/log/openvpn.log | tail -200 | html_encode
	cat << EOF
	</pre>
</div>
EOF
}

#===========================================================================================
# Function that shows a list of certificates in the system:
#===========================================================================================
function showCerts()
{
	cat << EOF
	<div class="row">
		<div class="col-md-12">
			<div class="box box-info">
				<div class="box-header with-border">
					<h3 class="box-title">$([[ "${SHOW_REVOKED}" -eq 0 ]] && echo "Valid ")Clients Certificates</h3>
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
							<tbody>
EOF
	FIRST=1
	INDEX="/etc/openvpn/easy-rsa/pki/index.txt"
	sudo cat ${INDEX} | while read -r line || [ -n "$line" ]; do
		if [[ "${FIRST}" -eq 0 ]]; then
			NAME=$(echo "$line" | awk -FCN= '{print $2}')
			EXPIRES=$(echo "$line" | awk '{if (length($2) == 15) print $2; else print "20"$2}' | cut -b 1-8 | date +"%b %d %Y" -f -)
			STATE=$(echo "$line" | awk '{print $1}')
			case "$STATE" in
				R)
					IS_VALID="Revoked"
					REVOKED=$(echo "$line" | awk '{if (length($3) == 15) print $2; else print "20"$3}' | cut -b 1-8 | date +"%b %d %Y" -f -)
					;;
				*)
					IS_VALID="Unknown"
					[[ "${STATE}" == "V" ]] && IS_VALID="Valid"
					ACTIONS="<a href=\"/?action=revoke&name=${NAME}&sid=${SID}\" class=\"label label-warning\">Revoke Certificate</a>"
					[[ -f /home/pivpn/ovpns/"${NAME}".ovpn ]] && NAME="<a href=\"/?action=download&name=${NAME}&sid=${SID}\">${NAME}</a>"
					;;
			esac
			[[ "$SHOW_REVOKED" -eq 1 || "${STATE}" != "R" ]] && cat << EOF
								<tr>
									<td>${NAME}</td>
									<td>${IS_VALID}</td>
									<td>${EXPIRES}</td>
									<td>${REVOKED}</td>
									<td>${ACTIONS}</td>
								</tr>
EOF
		fi
		FIRST=0
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
		<form role="form" action="/?sid=${SID}" method="get">
			<input type="hidden" name="action" value="create" />
			<div class="box-body">
				<div class="form-group " >
					<label for="name">Name</label>
					<input type="text" class="form-control" id="name" name="name">
				</div>
				<div class="form-group " >
					<label for="name">Password</label>
					<input type="password" class="form-control" id="pass" name="pass">
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

#===========================================================================================
# Function that allows the user to download a certificate from the container:
#===========================================================================================
function downloadOVPN()
{
	FILE="$(get_parameter 'name')"
	FILE="/home/pivpn/ovpns/$(basename "$FILE").ovpn"
	[[ ! -f "${FILE}" ]] && return 1

	cat << EOF
Content-Description: File Transfer
Content-Type: application/octet-stream
Content-Disposition: attachment; filename=$(basename ${FILE})
Expires: 0
Cache-Control: must-revalidate
Pragma: public
Content-Length: $(sudo wc -c "${FILE}" | cut -d" " -f 1)

EOF
	sudo cat "$FILE"
	exit 0
}

#===========================================================================================
# Function that revokes a OpenVPN certficate:
#===========================================================================================
function revokeOVPN()
{
	cat << EOF
<div class="box box-primary">
	<pre style="font-size: 13px;line-height: 1.4em;">
EOF
	USER="$(get_parameter 'name')"
	if [[ -z "${USER}" ]]; then
		echo "Requires Username to be passudo sed!"
	else
		pivpn revoke ${USER} -y | html_encode
	fi
	cat << EOF
	</pre>
	<div class="box-footer">
		<a href="/?action=certs&sid=${SID}" class="btn btn-primary">Back to Certificates</a>
	</div>
</div>
EOF
}

#===========================================================================================
# Function that creates a OpenVPN certificate:
#===========================================================================================
function createOVPN()
{
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Output of User Creation</h3>
	</div>
	<pre style="font-size: 13px;line-height: 1.4em;">
EOF
	USER="$(get_parameter 'name')"
	if [[ -z "${USER}" ]]; then
		echo "Requires Username to be passudo sed!"
	else
		PASS="$(get_parameter 'pass')"
		if [[ -z "${PASS}" ]]; then
			PASS="nopass"
		else
			PASS="--password $PASS"
		fi
		CONF=/etc/pivpn/openvpn/setupVars.conf
		sudo cp ${CONF} ${CONF}.bak
		echo "HELP_SHOWN=1" | sudo tee -a ${CONF} >& /dev/null
		pivpn add -d 3650 --name $USER $PASS | html_encode
		sudo mv ${CONF}.bak ${CONF}
	fi
	cat << EOF
	</pre>
	<div class="box-footer">
		<a href="/?action=certs&sid=${SID}" class="btn btn-primary">Back to Certificates</a>
	</div>
</div>
EOF
}

#===========================================================================================
# Function that shows the Profile settings:
#===========================================================================================
function showProfile()
{
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit your profile</h3>
	</div>
	<form role="form" action="/?sid=${SID}" method="get">
		<input type="hidden" name="action" value="profile" />
		<input type="hidden" name="save" value="true" />
		<div class="box-body">
			<div class="form-group">
				<label for="name">Username</label>
				<input type="text" class="form-control" id="username" name="username" value="${guiUsername:-"admin"}">
			</div>
			<div class="form-group" >
				<label for="name">Name</label>
				<input type="text" class="form-control" id="admin_name" name="admin_name" placeholder="Enter name" value="${guiName:-"Administrator"}">
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
			<input type="hidden" name="sid" value="${SID}" />
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save</button>
		</div>
	</form>
</div>
EOF
}

#===========================================================================================
# Function that saves the profile settings:
#===========================================================================================
function saveProfile()
{
	! debug && echo "<script>window.history.go(-1)</script>"

	webUSERNAME="$(get_parameter username)"
	webUSERNAME=${webUSERNAME,,}
	[[ ! -z "${webUSERNAME}" && "${webUSERNAME}" != "${guiUSERNAME}" ]] && set_var guiUSERNAME ${webUSERNAME}
	debug && echo "<pre>[ changed=${USERNAME_changed:-"0"} ] guiUSERNAME=${webUSERNAME}"

	webADMIN="$(get_parameter admin_name)"
	[[ ! -z "${webADMIN}" && "${webADMIN}" != "${guiNAME}" ]] && ADMIN_changed=1 && set_var guiNAME ${webADMIN}
	debug && echo "[ changed=${ADMIN_changed:-"0"} ] guiNAME=${webADMIN}"

	webPASSWORD="$(get_parameter password)"
	if [[ ! -z "${webPASSWORD}" ]]; then
		webSALT=$(echo ${webUSERNAME,,} | md5sum | cut -d" " -f 1)
		[[ "${webSALT}" != "${guiSALT}" ]] && webSALT_changed=1 && set_var guiSALT "${webSALT}"
		webPASSWORD="$(echo ${webSALT}$(echo ${webPASSWORD} | md5sum | cut -d" " -f 1) | sha256sum | cut -d" " -f 1)"
		[[ "${webPASSWORD}" != "${guiPASSWORD}" ]] && webPASSWORD_changed=1 && set_var guiPASSWORD "${webPASSWORD}"
	fi
	echo "[ changed=${webSALT_changed:-"0"} ] guiSALT=${webSALT}"
	echo "[ changed=${webPASSWORD_changed:-"0"} ] guiPASSWORD=${webPASSWORD}"

	debug && cat << EOF
	</pre>
	<div class="box-body">
		<a href="/?action=profile&sid=${SID}" onclick="window.history.go(-1); return false;" class="btn btn-primary">Back to Profile</a>
	</div>
EOF
}

#===========================================================================================
# Function that shows the PiVPN server options:
#===========================================================================================
function PiVPN()
{
	pivpnKeepAlive=${pivpnKeepAlive:-"15 120"}
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit PiVPN Server configuration</h3>
	</div>
	<form role="form" action="/?sid=${SID}" method="get">
		<input type="hidden" name="action" value="pivpn" />
		<input type="hidden" name="save" value="true" />
		<div class="box-body">
			<div class="form-group">
				<label for="pivpnHOST">Host Address</label>
				<input type="text" class="form-control" name="pivpnHOST" id="pivpnHOST" placeholder="" Value="${pivpnHOST}">
				<span class="help-block">Static IP Address or Domain Name of the PiVPN server</span>
			</div>
			<div class="form-group">
				<label for="pivpnPORT">Port</label>
				<input type="text" class="form-control" name="pivpnPORT" id="pivpnPORT" placeholder="" Value="${pivpnPORT:-"1194"}">
				<span class="help-block">Which TCP/UDP port should OpenVPN listen on</span>
			</div>
			<div class="form-group">
				<label for="pivpnPROTO">VPN Protocall</label>
				<select name="pivpnPROTO" id="pivpnPROTO" class="form-control">
					<option value="udp"$([[ "${pivpnPROTO:-"udp"}" == "udp" ]] && echo " selected")>UDP</option>
					<option value="tcp"$([[ "${pivpnPROTO:-"udp"}" == "tcp" ]] && echo " selected")>TCP</option>
				</select>
				<span class="help-block">TCP or UDP server</span>
			</div>
			<div class="form-group">
				<label for="pivpnDNS1">Primary DNS Server</label>
				<input type="text" class="form-control" name="pivpnDNS1" id="pivpnDNS1" placeholder="" value="${pivpnDNS1:-"8.8.8.8"}">
				<span class="help-block">IP address of primary domain name server</span>
			</div>
			<div class="form-group">
				<label for="pivpnDNS2">Secondary DNS Server</label>
				<input type="text" class="form-control" name="pivpnDNS2" id="pivpnDNS2" placeholder="" value="${pivpnDNS2:-"8.8.4.4"}">
				<span class="help-block">IP address of secondary domain name server.  Use <b>none</b> to disable.</span>
			</div>
			<div class="form-group">
				<label for="pivpnSEARCHDOMAIN">Custom Search Domain</label>
				<input type="text" class="form-control" name="pivpnSEARCHDOMAIN" id="pivpnSEARCHDOMAIN" placeholder="" value="${pivpnSEARCHDOMAIN:-""}">
				<span id="helpBlock" class="help-block"></span>
			</div>
			<div class="form-group">
				<label for="pivpnNET">Host IP Address and subnet</label>
				<input type="text" class="form-control" name="pivpnNET" id="pivpnNET" placeholder="" value="${pivpnNET:-"10.8.0.0"}/${subnetClass:-"24"}">
				<span id="helpBlock" class="help-block">Configures server mode and supply a subnet mask (&quot;<b>/24</b>&quot; is the most common subnet mask used) for OpenVPN to draw client addresses from.</span>
			</div>
			<div class="form-group">
				<label for="pivpnKeepAlive">Keepalive</label>
				<input type="text" class="form-control" name="pivpnKeepAlive" id="pivpnKeepAlive" placeholder="" value="${pivpnKeepAlive}">
				<span id="helpBlock" class="help-block">
					The keepalive directive causes ping-like messages to be sent back and forth  over the link
					so that each side knows when the other side has gone down.<br />
					<b>Current Setting:</b> Ping every $(echo ${pivpnKeepAlive} | cut -d" " -f 1) seconds, assume
					that remote peer is down if no ping received during a $(echo ${pivpnKeepAlive} | cut -d" " -f 2) second time period.
				</span>
			</div>
			<div class="form-group">
				<label for="pivpnWEB_MGMT">OpenVPN Management Port</label>
				<input type="text" class="form-control" name="pivpnWEB_MGMT" id="pivpnWEB_MGMT" placeholder="" value="${pivpnWEB_MGMT:-"49081"}">
				<span id="helpBlock" class="help-block">Unless specified, it is one up from the web UI port (<b>${pivpnWEB_PORT}</b>).  Specify <b>0</b> to disable.</span>
			</div>
			<div class="form-group">
				<label for="pivpnDEV">PiVPN Network Adapter Name</label>
				<input type="text" class="form-control" name="pivpnDEV" id="pivpnDEV" placeholder="" value="${pivpnDEV:-"pivpn"}">
				<span id="helpBlock" class="help-block">The global network adapter name, similar to <b>eth0</b>, the PiVPN server will use while it is running.</span>
			</div>
      		<input type="hidden" name="sid" value="${SID}" />
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save and apply</button>
		</div>
	</form>
</div>
EOF
}

#===========================================================================================
# Function that saves the PiVPN server options:
#===========================================================================================
function savePiVPN()
{
	! debug && echo "<script>window.history.go(-1)</script>"

	changes=0
	webHOST="$(get_parameter pivpnHOST)"
	[[ "${webHOST}" != "" && "${webHOST}" != "${pivpnHOST}" ]] && pivpnHOST_changed=1 && changes=$((changes + 1)) && set_var pivpnHOST ${webHOST}
	debug && echo "<pre>[ changed=${pivpnHOST_changed:-"0"} ] pivpnHOST=${webHOST}"

	webPORT="$(get_parameter pivpnPORT)"
	[[ "${webPORT}" =~ ^[0-9]+$  && "${webPORT}" != "${pivpnPORT}" ]] && pivpnPORT_changed=1 && changes=$((changes + 1)) && set_var pivpnPORT ${webPORT}
	debug && echo "[ changed=${pivpnPORT_changed:-"0"} ] pivpnPORT=${webPORT}"

	webPROTO="$(get_parameter pivpnPROTO)"
	[[ "${webPROTO}" == "udp" || "${webPROTO}" == "tcp" ]] && [[ "${webPROTO}" != "${pivpnPROTO}" ]] && pivpnPROTO_changed=1 && changes=$((changes + 1)) && set_var pivpnPROTO ${webPROTO}
	debug && echo "[ changed=${pivpnPROTO_changed:-"0"} ] pivpnPROTO=${webPROTO}"

 	webDNS1="$(get_parameter pivpnDNS1)"
	valid_ip "${webDNS1}" && [[ "${webDNS1}" != "${pivpnDNS1}" ]] && pivpnDNS1_changed=1 && changes=$((changes + 1)) && set_var pivpnDNS1 ${webDNS1}
	debug && echo "[ changed=${pivpnDNS1_changed:-"0"} ] pivpnDNS1=${webDNS1}"

	webDNS2="$(get_parameter pivpnDNS1)"
	valid_ip "${webDNS2}" && [[ "${webDNS2}" != "${pivpnDNS2}" ]] && pivpnDNS2_changed=1 && changes=$((changes + 1)) && set_var pivpnDNS2 ${webDNS2}
	debug && echo "[ changed=${pivpnDNS2_changed:-"0"} ] pivpnDNS2=${webDNS2}"

	webSEARCHDOMAIN="$(get_parameter pivpnSEARCHDOMAIN)"
	[[ "${webSEARCHDOMAIN}" != "${pivpnSEARCHDOMAIN}" ]] && pivpnSEARCHDOMAIN_changed=1 && changes=$((changes + 1)) && set_var pivpnSEARCHDOMAIN ${webSEARCHDOMAIN}
	debug && echo "[ changed=${pivpnSEARCHDOMAIN_changed:-"0"} ] pivpnSEARCHDOMAIN=${webSEARCHDOMAIN}"

	webNET="$(get_parameter pivpnNET)"
	webSUBNET=$(echo ${webNET} | cut -d"/" -f 2)
	[[ "${webSUBNET}" =~ ^[0-9]+$ && "${webSUBNET}" != "${subnetClass}" ]] && subnetClass_changed=1 && changes=$((changes + 1)) && set_var subnetClass ${webSUBNET}
	debug && echo "[ changed=${subnetClass_changed:-"0"} ] subnetClass=${webSUBNET}"

	webNET=$(echo ${pivpnNET} | cut -d"/" -f 1)
	valid_ip "${webNET}" && [[ "${webNET}" != "${pivpnNET}" ]] && pivpnNET_changed=1 && changes=$((changes + 1)) && set_var pivpnNET ${webNET}
	debug && echo "[ changed=${pivpnNET_changed:-"0"} ] pivpnNET=${webNET}"

	webDEV="$(get_parameter pivpnHOST)"
	[[ "${webDEV}" != "" && "${webDEV}" != "${pivpnDEV}" ]] && pivpnDEV_changed=1 && changes=$((changes + 1)) && set_var pivpnDEV ${webDEV}
	debug && echo "[ changed=${pivpnDEV_changed:-"0"} ] pivpnDEV=${webDEV}"

	webWEB_MGMT="$(get_parameter pivpnWEB_MGMT)"
	[[ "${webWEB_MGMT}" =~ ^[0-9]+$ && "${webWEB_MGMT}" != "${pivpnWEB_MGMT}" ]] && pivpnWEB_MGMT_changed=1 && changes=$((changes + 1)) && set_var pivpnWEB_MGMT ${webWEB_MGMT}
	debug && echo "[ changed=${pivpnWEB_MGMT_changed:-"0"} ] pivpnWEB_MGMT=${webWEB_MGMT}"

	debug && cat << EOF
	</pre>
	<div class="box-body">
		<a href="/?action=profile&sid=${SID}" onclick="window.history.go(-1); return false;" class="btn btn-primary">Back to PiVPN Server</a>
	</div>
EOF
}

#===========================================================================================
# Function that shows the Web UI server options:
#===========================================================================================
function WebUI()
{
	cat << EOF
<div class="box box-primary">
	<div class="box-header with-border">
		<h3 class="box-title">Edit Web UI configuration</h3>
	</div>
	<form role="form" action="/?sid=${SID}" method="get">
		<input type="hidden" name="action" value="webui" />
		<input type="hidden" name="save" value="true" />
		<div class="box-body">
			<div class="form-group">
				<label for="pivpnWEB_PORT">PiVPN Web UI Port</label>
				<input type="text" class="form-control" name="pivpnWEB_PORT" id="pivpnWEB_PORT" placeholder="" value="${pivpnWEB_PORT:-"49080"}">
				<span id="helpBlock" class="help-block">What port this UI uses on the host system.  Specify <b>0</b> to disable.</span>
			</div>
			<div class="form-group">
				<label for="DEBUG">Show Revoked Certificates</label>
				<select name="SHOW_REVOKED" id="SHOW_REVOKED" class="form-control">
					<option value="0"$([[ "${SHOW_REVOKED:-"0"}" -eq 0 ]] && echo " selected")>Disabled</option>
					<option value="1"$([[ "${SHOW_REVOKED:-"0"}" -eq 1 ]] && echo " selected")>Enabled</option>
				</select>
			</div>
			<div class="form-group">
				<label for="DEBUG">Web UI Debug Mode</label>
				<select name="DEBUG" id="DEBUG" class="form-control">
					<option value="0"$([[ "${DEBUG:-"0"}" -eq 0 ]] && echo " selected")>Disabled</option>
					<option value="1"$([[ "${DEBUG:-"0"}" -eq 1 ]] && echo " selected")>Enabled</option>
				</select>
			</div>
      		<input type="hidden" name="sid" value="${SID}" />
		</div>
		<div class="box-footer">
			<button type="submit" class="btn btn-primary">Save and apply</button>
		</div>
	</form>
</div>
EOF
}

#===========================================================================================
# Function that saves the Web UI server options:
#===========================================================================================
function saveWebUI()
{
	webDEBUG="$(get_parameter DEBUG)"
	[[ "${webDEBUG}" =~ ^[01]$ && "${webDEBUG}" != "${DEBUG}" ]] && DEBUG_changed=1 && set_var DEBUG ${webDEBUG}
	[[ ${webDEBUG} -eq 0 ]] && echo "<script>window.history.go(-1)</script>"
	[[ ${webDEBUG} -eq 1 ]] && echo "[ changed=${DEBUG_changed:-"0"} ] DEBUG=${webDEBUG}"

	webWEB_PORT="$(get_parameter pivpnWEB_PORT)"
	[[ "${webWEB_PORT}" =~ ^[0-9]+$ && "${webWEB_PORT}" != "${pivpnWEB_PORT}" ]] && pivpnWEB_PORT_changed=1 && set_var pivpnWEB_PORT ${webWEB_PORT}
	debug && echo "<pre>[ changed=${pivpnWEB_PORT_changed:-"0"} ] pivpnWEB_PORT=${webWEB_PORT}"

	webSHOW_REVOKED="$(get_parameter SHOW_REVOKED)"
	[[ "${webSHOW_REVOKED}" =~ ^[01]$ && "${webSHOW_REVOKED}" != "${SHOW_REVOKED}" ]] && webSHOW_REVOKED_changed=1 && set_var SHOW_REVOKED ${webSHOW_REVOKED}
	debug && echo "[ changed=${webSHOW_REVOKED_changed:-"0"} ] webSHOW_REVOKED=${webSHOW_REVOKED}"

	debug && cat << EOF
	</pre>
	<div class="box-body">
		<a href="/?action=profile&sid=${SID}" onclick="window.history.go(-1); return false;" class="btn btn-primary">Back to Web UI Settings</a>
	</div>
EOF
}

#===========================================================================================
# Function that shows the Web UI login box:
#===========================================================================================
function showLogin()
{
	SID=$(date +%s | sha256sum | cut -d" " -f 1)
	cat << EOF
	<link rel="stylesheet" href="static/plugins/iCheck/square/blue.css">
</head>
<body class="hold-transition login-page">
	<div class="login-box">
		<div class="login-logo">
			<img src="/static/img/favicon/favicon-192x192.png"><br /><b>PiVPN</b> Admin</a>
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
					<input type="hidden" name="sid" value="${SID}" />
					<div class="col-xs-4">
						<button type="submit" class="btn btn-primary btn-block btn-flat">Sign In</button>
					</div>
				</div>
			</form>
		</div>
	</div>
EOF
	footer skip
	cat << EOF
	<script src="static/plugins/iCheck/icheck.min.js"></script>
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
EOF
}

#===========================================================================================
# Function that checks the password hash and salt:
#===========================================================================================
function checkLogin()
{
	USERNAME="$(get_parameter 'login')"
	[[ "${USERNAME}" != "${guiUSERNAME}" ]] && return 1
	PASSWORD="$(get_parameter 'password')"
	webPASSWORD="$(echo ${guiSALT}${PASSWORD} | sha256sum | cut -d" " -f 1)"
	[[ "${webPASSWORD}" != "${guiPASSWORD}" ]] && return 1
	SID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
	echo "${SID}=$((NOW + 3600))" | sudo tee -a "${SESSIONS}" >& /dev/null
}	

#===========================================================================================
# Miscellaneous functions
#===========================================================================================
# Removes whitespaces and line returns from the output:
function minify() {
	if [[ "${MINIFY}" -eq 1 ]]; then
		sudo sed -e "s/^[ \t]*//g" -e "/^$/d" | sudo sed ':a;N;$!ba;s/>\s*</></g'
	else
		cat
	fi
}

# Sets the variable in "/etc/openvpn/.params" to the passed value:
function set_var()
{
	(cat ${PARAMS} | grep -v "^${1}="; echo "${1}=\"${2}\"") > /tmp/.params
	sudo mv /tmp/.params ${PARAMS}
}

# Encodes certain characters to HTML characters to avoid leaks:
function html_encode() {
	sudo sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&#39;/g'
}

# Decodes the URL passed to it:
function urldecode() {
	: "${*//+/ }"; echo -e "${_//%/\\x}"
}

# Gets the specified parameter from the passed mess:
function get_parameter ()
{
	urldecode $(echo "$query" | tr '&' '\n' | grep "^$1=" | head -1 | sudo sed "s/.*=//")
}

# Returns 0 if we are in debug state:
function debug()
{
	[[ "${DEBUG:-"1"}" -eq 0 ]] && return 1
}

# Checks to make sure the parameter is a valid IP address:
function valid_ip()
{
	local  ip=$1
	local  stat=1

	if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		OIFS=$IFS
		IFS='.'
		ip=($ip)
		IFS=$OIFS
		[[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]] && return 0
	fi
	return 1
}

# Removes all expired sessions, then checks to see if specified session is still in the list.
# If it still exists, extend the session for an hour from the current time.
function sessionValid()
{
	[[ -z "${SID}" || ! -f "${SESSIONS}" ]] && return 1
	sudo cat "${SESSIONS}" | while IFS== read -r key val; do
		[[ "${NOW}" -gt "${val}" ]] && sudo sed -i "/^${key}=/d" "${SESSIONS}"
	done
	sudo cat "${SESSIONS}" | grep "^${SID}=" || return 1
	sudo sed -i "s|^${SID}=.*|${SID}=$((NOW + 3600))|" "${SESSIONS}"
}			

#===========================================================================================
# Main decision making portion of the script:
#===========================================================================================
# Needed variables:
if [ "$REQUEST_METHOD" = POST ]; then
	query=$( head --bytes="$CONTENT_LENGTH" )
else
	query="$QUERY_STRING"
fi
NOW=$(date +%s)
ACTION="$(get_parameter 'action')"
SAVE="$(get_parameter 'save')"
SID="$(get_parameter 'sid')"
SID=$(date +%s | md5sum | cut -d" " -f 1)
DEBUG=0
MINIFY=0
SHOW_REVOKED=0
PARAMS=/etc/openvpn/.params
SESSIONS=/etc/openvpn/.sessions
source /tmp/vars
source ${PARAMS}

# Session or password checking code bracket:
if [[ "${ACTION}" == "checkLogin" ]]; then
	#checkLogin || ACTION="login"
	echo -n ""
else
	#sessionValid || ACTION="login"
	echo -n ""
fi

# Are we downloading a OVPN?  If so, try and do so.  If it fails, show a 404:
if [[ "${ACTION}" == "download" ]]; then
	downloadOVPN || ACTION=404
fi

# Otherwise, we are doing what the action tells us to do:
echo "Content-type: text/html"
echo ""
(header
case "${ACTION}" in
	"login")
		showLogin
		;;

	"profile")
		body "Profile"
		if [[ ! -z "${SAVE}" ]]; then
			saveProfile
		else
			showProfile
		fi
		;;

	"logs")
		body "Logs"
		showLogs
		;;

	"certs")
		body "Certificates"
		showCerts
		;;

	"pivpn")
		body "PiVPN Configuration"
		if [[ ! -z "${SAVE}" ]]; then
			savePiVPN
		else
			PiVPN
		fi
		;;

	"webui")
		body "PiVPN Admin Settings"
		if [[ ! -z "${SAVE}" ]]; then
			saveWebUI
		else
			WebUI
		fi
		;;

	"revoke")
		body "Revoke Certificate"
		revokeOVPN
		;;

	"create")
		body "Create Certificate"
		createOVPN
		;;

	"404")
		body
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
bottom) | minify
