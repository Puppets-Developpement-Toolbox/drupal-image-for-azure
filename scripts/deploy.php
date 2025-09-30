<?php
/**
 * This file will copied to web/ on deploy,
 * called from the azure pipeline on deploy,
 * and deleted
 */

use Symfony\Component\Process\Process;


require_once "autoload.php";
header("Content-Type: text/event-stream");
header("Cache-Control: no-cache");

function run($cmd) {
  $appRoot = __DIR__ . "/..";
  $process = new Process($cmd, $appRoot);
  $process->setTimeout(15 * 60);
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
}

// Run deploy scripts
$isSuccessful = run(["drupal-deploy"]);


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
