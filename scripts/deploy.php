<?php
/**
 * This file will copied to web/ on deploy,
 * called from the azure pipeline on deploy,
 * and deleted
 */

use Symfony\Component\Process\Process;


// HEAD verb is used to check if the endpoint is available
if ($_SERVER['REQUEST_METHOD'] === 'HEAD' || isset($_GET['healthcheck'])) return;

require_once "autoload.php";
header("Content-Type: text/event-stream");
header("Cache-Control: no-cache");
set_time_limit(20 * 60); // timeline 20minutes

function run($cmd, $arg)
{
    $appRoot = __DIR__ . "/..";
    $process = new Process($cmd, $appRoot, $arg);
    $process->setTimeout(45 * 60);
    try {
        $process->mustRun(function ($type, $buffer) {
            $lines = explode("\n", $buffer);
            $prefix = Process::ERR === $type ? "ERR > " : "OUT > ";
            foreach ($lines as $line) {
                echo "{$prefix}{$line}\n";
            }
            flush();
            ob_flush();
        });
        return $process->isSuccessful();
    } catch (Exception $e) {
        echo "ERR > " . $e->getMessage() . "\n";
        return false;
    }
}

// Get action in _GET
$arg = '';
if(!empty($_GET['action'])){
    $get = $_GET['action'];
    if(in_array($get, ['maint0', 'maint1', 'dump', 'updb', 'cim', 'localupd', 'cr', 'ver', 'rm'])){
        $arg = $get;
    }
}

// Run deploy scripts
$isSuccessful = run(["drupal-deploy"], $arg);


if (!$isSuccessful) {
  $appRoot = __DIR__ . "/..";
  if (file_exists("{$appRoot}/premep.sql")) {
    // restore database
    echo "###### Rolback deploy\n";
    $isSuccessful = run(["drupal-deploy-rollback"]);
  }

  throw new Exception("Error on deploy script");
}

echo "DEPLOY OK";
