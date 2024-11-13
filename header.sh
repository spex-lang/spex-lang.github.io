#!/usr/bin/env bash

title="${title:-title}"

escaped_title=$(echo $title | sed 's/ /\+/g')

cat <<EOT
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes">
  <title>$title</title>
  <link rel="stylesheet" href="style.css?modified=2024-11-13">
  <link rel="shortcut icon" type="image/png" href="asset/spex.png">
  <script data-goatcounter="https://spex-lang.goatcounter.com/count"
        async src="//gc.zgo.at/count.js"></script>
</head>
<body>
<header class=box>
  <nav id="navbar" class="menu">
    <a href="index.html"><img class="logo" src="asset/spex.png" alt="Spex glasses">Spex</a>
    <a href="install.html">Install</a>
    <a href="community.html">Community</a>
  </nav>
  <div class="push">
    <a href="https://github.com/spex-lang/spex">Code</a>
  </div>
</header>
<noscript>
  <img src="https://spex-lang.goatcounter.com/count?t=$escaped_title"
       alt="goatcounter">
</noscript>
<main>
EOT
