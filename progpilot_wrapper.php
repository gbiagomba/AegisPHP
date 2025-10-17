#!/usr/bin/env php
<?php
/**
 * ProgPilot Wrapper Script for PHALANX
 * This script wraps ProgPilot library to provide JSON output
 */

require_once '/home/phalanx/progpilot/vendor/autoload.php';

// Check if target directory is provided
if ($argc < 2) {
    fwrite(STDERR, "Usage: {$argv[0]} <target_directory>\n");
    exit(1);
}

$targetDir = $argv[1];

// Validate target directory
if (!is_dir($targetDir)) {
    fwrite(STDERR, "Error: Target directory does not exist: $targetDir\n");
    exit(1);
}

// Initialize ProgPilot
try {
    $context = new \progpilot\Context;
    $analyzer = new \progpilot\Analyzer;

    // Find all PHP files in target directory
    $phpFiles = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($targetDir, RecursiveDirectoryIterator::SKIP_DOTS),
        RecursiveIteratorIterator::SELF_FIRST
    );

    $fileCount = 0;
    foreach ($phpFiles as $file) {
        if ($file->isFile() && $file->getExtension() === 'php') {
            $context->inputs->setFile($file->getPathname());
            $fileCount++;
        }
    }

    if ($fileCount === 0) {
        // No PHP files found, output empty results
        echo json_encode(['results' => []]);
        exit(0);
    }

    // Run analysis
    $analyzer->run($context);

    // Get results
    $results = $context->outputs->getResults();

    // Format output as JSON
    $output = ['results' => []];
    foreach ($results as $result) {
        $output['results'][] = [
            'file' => $result->getSourceFile() ?? '',
            'line' => $result->getSourceLine() ?? 0,
            'description' => $result->getMessage() ?? '',
            'message' => $result->getMessage() ?? '',
            'severity' => strtolower($result->getSeverity() ?? 'medium'),
            'rule_name' => $result->getCategory() ?? '',
            'code' => $result->getSourceCode() ?? ''
        ];
    }

    echo json_encode($output, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
    exit(0);

} catch (Exception $e) {
    fwrite(STDERR, "ProgPilot Error: " . $e->getMessage() . "\n");
    // Output empty results on error
    echo json_encode(['results' => []]);
    exit(1);
}
