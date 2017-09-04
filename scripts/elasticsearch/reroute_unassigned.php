<?php

ini_set('memory_limit', '1G');

/**
 * Thx to https://github.com/tcdent/php-restclient/
 *
 * Not finished yet
 */

function is200($httpResponseStatusLine)
{
    if (is_array($httpResponseStatusLine))
    {
        $httpResponseStatusLine = $httpResponseStatusLine[0];
    }

    return strpos($httpResponseStatusLine, '200') !== false;
}

function getArrayValue($array, $path)
{
    $path = explode('.', $path);

    $value = $array;

    foreach ($path as $p)
    {
        if ($p == '' || !isset($value[$p]))
        {
            continue;
        }

        $value = $value[$p];
    }

    return $value;
}

function compareArrayByPath($v1, $v2, $path, $greaterReturn = 1)
{
    if (getArrayValue($v1, $path) > getArrayValue($v2, $path))
    {
        return $greaterReturn;
    }
    else
    {
        if (getArrayValue($v1, $path) < getArrayValue($v2, $path))
        {
            return -1 * $greaterReturn;
        }
    }

    return 0;
}

$restClientPath = __DIR__ . '/restclient.php';

if (!file_exists($restClientPath))
{
    $restClientPath = dirname(__DIR__) . '/libs/restclient.php';
}

require $restClientPath;

$getoptConfig  = [
    'h:' => ['required' => true],
    'p:' => ['required' => true],
    'k:' => ['required' => false],
    'S'  => ['required' => false],
];
$getoptString  = join('', array_keys($getoptConfig));
$cmdArgv       = getopt($getoptString);
$requiredCount = preg_match_all('#[a-zA-Z]:#', $getoptString, $requiredFields);

foreach ($getoptConfig as $field => $config)
{
    $field = trim($field, ':');

    if (isset($config['required']) && $config['required'] && !isset($cmdArgv[$field]))
    {
        exit("Need -{$field}\n");
    }
}

$client     = new RestClient();
$httpScheme = isset($cmdArgv['S']) ? 'https' : 'http';
$baseUrl    = "{$httpScheme}://{$cmdArgv['h']}:{$cmdArgv['p']}";

/**
 * check cluster status first
 */
$clusterHealthUrl = "{$baseUrl}/_cluster/health";
$resp = $client->get($clusterHealthUrl);

if (!is200($resp->response_status_lines))
{
    exit("ES not return 200\n");
}

$clusterHealth = json_decode($resp->response, true);

if ($clusterHealth['status'] == 'green')
{
    exit("ES runs well, status is GREEN\n");
}

/**
 * get nodes stats
 */

$nodesStatsUrl = "{$baseUrl}/_nodes/stats";
$resp = $client->get($nodesStatsUrl);

if (!is200($resp->response_status_lines))
{
    exit("ES not return 200\n");
}

$nodes         = $client->get($nodesStatsUrl)->response;
$nodes         = json_decode($nodes, true);

if (!$nodes || !isset($nodes['nodes']))
{
    exit("Failed to get nodes info\n");
}

$compareRules = [
    ['path' => 'jvm.mem.heap_used_percent', 'greater' => 1],
    ['path' => 'os.load_average', 'greater' => 1],
    ['path' => 'os.mem.used_percent', 'greater' => 1],
    ['path' => 'fs.total.free_in_bytes', 'greater' => -11],
];

uasort($nodes['nodes'], function ($node1, $node2) use ($compareRules) {
    foreach ($compareRules as $compareRule)
    {
        $compareResult = compareArrayByPath($node1, $node2, $compareRule['path'], $compareRule['greater']);

        if (0 == $compareResult)
        {
            continue;
        }

        return $compareResult;
    }

    return 0;
});

vprintf("%-20s%-14s%-14s%-14s%-20s\n", [
    'name',
    'heap_used(%)',
    'load_average',
    'mem_used(%)',
    'disk_free(GB)',
]);

foreach ($nodes['nodes'] as $nodeKey => $node)
{
    vprintf("%-20s%-14s%-14s%-14s%-20s\n", [
        $node['name'],
        $node['jvm']['mem']['heap_used_percent'],
        $node['os']['load_average'],
        $node['os']['mem']['used_percent'],
        round($node['fs']['total']['free_in_bytes'] / 1024 / 1024 / 1024, 2),
    ]);
}

echo "\n";

$nodesForReroute = [];

foreach ($nodes['nodes'] as $nodeKey => $node)
{
    $nodesForReroute[] = $node['name'];
}

/**
 * get unassigned shards
 */
$unassignedShardsUrl = "{$baseUrl}/_cat/shards";
$resp                = $client->get($unassignedShardsUrl);
$shards              = $resp->response;

if (!is200($resp->response_status_lines))
{
    exit("ES not return 200\n");
}

// git-2016.06.05             3 p STARTED     10   21.3kb 192.168.1.111 es_node_1
$shards           = explode("\n", $shards);
$unassignedShards = [];

foreach ($shards as $shard)
{
    $shard = preg_split('#\s+#', $shard);

    if (isset($shard[3]) && $shard[3] == 'UNASSIGNED')
    {
        if (isset($cmdArgv['k']) && $cmdArgv['k'] && !preg_match("#{$cmdArgv['k']}#", $shard[0]))
        {
            continue;
        }

        $unassignedShards[] = $shard;
    }
}

$shards = [];
unset($shards);

$rerouteShardUrl = "{$baseUrl}/_cluster/reroute";

foreach ($unassignedShards as $unassignedShard)
{
    foreach ($nodesForReroute as $nodeForReroute)
    {
        echo "Try to reroute {$unassignedShard[0]} {$unassignedShard[1]} to $nodeForReroute\n";
        $postData = [
            'commands' => [
                [
                    'allocate' => [
                        'index'         => $unassignedShard[0],
                        'shard'         => $unassignedShard[1],
                        'node'          => $nodeForReroute,
                        'allow_primary' => true,
                    ]
                ]
            ]
        ];

        $resp = $client->post($rerouteShardUrl, json_encode($postData));

        if (is200($resp->response_status_lines))
        {
            echo "Success to reroute {$unassignedShard[0]} {$unassignedShard[1]} to $nodeForReroute\n";
            break;
        }
    }
}
