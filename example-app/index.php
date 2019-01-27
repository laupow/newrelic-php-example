<?php

$microseconds_delay = mt_rand(1000, 700000);

echo "Hello, World!";
echo "\n";
echo "Delay " . (int)($microseconds_delay / 1000) . " ms" . "\n";
usleep($microseconds_delay);
echo "Done\n";

if (extension_loaded('newrelic')) {
	newrelic_name_transaction("/ExampleApp/pageview/");
}