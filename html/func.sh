#!/bin/bash
echo "Content-type: text/html"
echo ""

function header()
{
	ACTIVE=$(echo $0 | sed "s|/var/www/html/||")
	cat << EOF
<!DOCTYPE html>
<html>
	<head>
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
		<link rel="stylesheet" href="/static/css/skins/skin-blue.min.css">
		<link rel="stylesheet" href="/static/css/custom.css">
		<title>PiVPN Admin</title>
	</head>
	<body class="skin-blue layout-top-nav">
		<div class="wrapper">
			<header class="main-header">
		  		<nav class="navbar navbar-static-top">
					<div class="container">
						<div class="navbar-header">
							<a href="http://doug-pc.local:8080/" class="navbar-brand"><b>PiVPN</b> Admin</a>
							<button type="button" class="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar-collapse">
								<i class="fa fa-bars"></i>
							</button>
						</div>
						<div class="collapse navbar-collapse pull-left" id="navbar-collapse">
							<ul class="nav navbar-nav">
								<li$([[ "$ACTIVE" = "index.sh" ]] && echo ' class="active"')>
									<a href="/">Home <span class="sr-only">(current)</span></a>
								</li>
								<li$([[ "$ACTIVE" = "config.sh" ]] && echo ' class="active"')>
									<a href="config.sh">Configuration <span class="sr-only">(current)</span></a>
								</li>
								<li$([[ "$ACTIVE" = "certs.sh" ]] && echo ' class="active"')>
									<a href="certs.sh">Certificates</a>
								</li>
								<li$([[ "$ACTIVE" = "logs.sh" ]] && echo ' class="active"')>
									<a href="logs.sh">Logs</a>
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
		</div>
	</body>
</html>
EOF
}
