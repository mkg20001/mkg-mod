<?php

if (!isset($_SERVER['PHP_AUTH_USER'])) {
	echo "Missing HTTP Auth User";
	exit;
}

$command = "sudo @jit6bin@ 2>&1";

echo `$command`;
