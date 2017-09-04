<?php

/**
 * Thx to https://github.com/tcdent/php-restclient/
 *
 * Not finished yet
 */
$restClientPath = __DIR__ . '/restclient.php';

if (!file_exists($restClientPath))
{
    $restClientPath = dirname(__DIR__) . '/libs/restclient.php';
}

require $restClientPath;

$getoptString  = 'h:p:S';
$data          = getopt($getoptString);
$requiredCount = preg_match_all('#[a-zA-Z]:#', $getoptString, $requiredFields);

foreach ($requiredFields[0] as $field)
{
    $field = trim($field, ':');

    if (!isset($data[$field]))
    {
        exit("Need -{$field}\n");
    }
}

$client = new RestClient();

/**
 * get nodes stats
 */
$httpScheme    = isset($data['S']) ? 'https' : 'http';
$baseUrl       = "{$httpScheme}://{$data['h']}:{$data['p']}";
$nodesStatsUrl = "{$baseUrl}/_nodes/stats";
$nodes         = $client->get($nodesStatsUrl)->response;
$nodes         = json_decode($nodes, true);

if (!$nodes || !isset($nodes['nodes']))
{
    exit("Failed to get nodes info\n");
}

uasort($nodes['nodes'], function ($node1, $node2) {
    // JVM heap usage
    if ($node1['jvm']['mem']['heap_used_percent'] > $node2['jvm']['mem']['heap_used_percent'])
    {
        return 1;
    }

    if ($node1['jvm']['mem']['heap_used_percent'] < $node2['jvm']['mem']['heap_used_percent'])
    {
        return -1;
    }

    // load
    if ($node1['os']['load_average'] > $node2['os']['load_average'])
    {
        return 1;
    }

    if ($node1['os']['load_average'] < $node2['os']['load_average'])
    {
        return -1;
    }

    // mem
    if ($node1['os']['mem']['used_percent'] > $node2['os']['mem']['used_percent'])
    {
        return 1;
    }

    if ($node1['os']['mem']['used_percent'] < $node2['os']['mem']['used_percent'])
    {
        return -1;
    }

    // disk
    if ($node1['fs']['total']['free_in_bytes'] > $node2['fs']['total']['free_in_bytes'])
    {
        return -1;
    }

    if ($node1['fs']['total']['free_in_bytes'] < $node2['fs']['total']['free_in_bytes'])
    {
        return 1;
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
