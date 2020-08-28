#!/bin/bash
source func.sh

CLIENTS=0
MB_IN=0
MB_OUT=0
CPU_COUNT=0
export LC_NUMERIC=en_US

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
			<span class="info-box-text">
				In: <span class="info-box-number2">${MB_IN:-"0"} MB</span>
			</span>
			<span class="info-box-text">
				Out: <span class="info-box-number2">${MB_OUT:-"0"} MB </span>
			</span>
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
				<span class="info-box-number">$(uptime -p | cut -d" " -f 2- | sed "s/, /<br>/")</span>
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
	killall -USR2 openvpn
	cat /var/log/openvpn-status.log | grep "^CLIENT_LIST" > /tmp/clients.list
	LINES=$(cat cat /tmp/clients.list | wc -l)
	if [[ "${LINES}" -gt 0 ]]; then
		cat /tmp/clients.list | (while read a b c d e f g h i j k l m n o p; do cat << EOF
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
	fi
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

header "Status"
blocks
memory_usage
clients
system_info
footer
