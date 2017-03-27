<?php
    $indice = isset($argv[1]) ? $argv[1] : '';
    $esHost = isset($argv[2]) ? $argv[2] : '';
    $esPort = isset($argv[3]) ? $argv[3] : '';

    if (!$argv[1] && !$argv[2] && !$argv[3])
    {
        exit(1);
    }

    $url = "http://{$esHost}:{$esPort}/{$indice}/_stats";

    try {
        $ret = file_get_contents($url);
    } catch (Exception $e) {
        exit(1);
    }

    $ret = json_decode($ret, true);

    if (!isset($ret['_shards']['total'])) {
        exit(1);
    }

    if (!isset($ret['_all']['total']['docs']['count'])) {
        echo 0;
        exit(0);
    }

    echo $ret['_all']['total']['docs']['count'];
    exit(0);
