<?php

echo "
  <!DOCTYPE HTML>
  <html lang='en-US'>
    <head>
	    <meta charset='UTF-8'>
	    <title>GitHub pull request</title>
    </head>
    <body style='background-color: #000000; color: #FFFFFF; font-weight: bold; padding: 0 10px;''>
    <pre>";

// Check whether client is allowed to trigger an update
$allowed_ips = array(
  '127.0.0.', '::1', '.', '140.82.115.' // GitHub
);
$allowed = false;
$headers = apache_request_headers();
if (@$headers["X-Forwarded-For"]) {
    $ips = explode(",",$headers["X-Forwarded-For"]);
    $ip  = $ips[0];
} else {
    $ip = $_SERVER['REMOTE_ADDR'];
}
foreach ($allowed_ips as $allow) {
    if (stripos($ip, $allow) !== false) {
        $allowed = true;
        break;
    }
}

if ( $_REQUEST['key'] != 'GitHubPullKey' ) $allowed = false;

if (!$allowed) {
	header('HTTP/1.1 403 Forbidden');
 	echo "<span style='color: #ff0000'>Access denied</span>\n";
    echo "</pre></body></html>";
    exit;
}
flush();

$data = json_decode(file_get_contents('php://input'), true);

$branch = explode('/',$data['ref']);
$branch = $branch[count($branch)-1];

if ( $branch == '' ) {
  header('HTTP/1.1 403 Forbidden');
 	echo "<span style='color: #ff0000'>Wrong branch</span>\n";
    echo "</pre></body></html>";
    exit;
}

$bash = "
  echo ------------- ".date('Y-m-d H:i:s'). " -----------------\n
  echo 'Waiting for previous build finish'\n
  while [ `ps -ax | grep yarn | grep -v grep -c` -ne 0 ]; do\n
   sleep 5\n
  done\n
";

shell_exec("echo ${branch} > /opt/voicetech/compiled/log.txt &");

echo "<span style='color: #6BE234;'>\$</span> <span style='color: #729FCF;''>Build started</span>";
echo "</pre></body></html>";

?>
<?php
