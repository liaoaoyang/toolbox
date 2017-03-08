<?php
    $extName = isset($argv[1]) ? $argv[1] : '';

    if (!$extName) {
        echo "Need ext name\n";
        exit(1);
    }

    if (!extension_loaded($extName)) {
        echo "{$extName} not loaded\n";
        exit(1);
    }

    $ext = new ReflectionExtension($extName);
    echo "{$extName}: " . $ext->getVersion() . "\n";
