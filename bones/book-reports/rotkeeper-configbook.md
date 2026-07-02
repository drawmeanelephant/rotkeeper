---
title: Rotkeeper Configbook
subtitle: YAML configuration and templates used by rotkeeper
---

<!-- START bones/config/rotkeeper.yaml::4ad3790b -->

title: "Rotkeeper Config"
description: "Minimal valid config for rendering tests"
default_template: "theme-light.html"
<!-- END bones/config/rotkeeper.yaml::4ad3790b -->

<!-- START bones/templates/rotkeeper-blog.html::4ad3790b -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title$</title>
  <link rel="stylesheet" href="$assets_root$css/rotkeeper.css">
</head>
<body class="rk-page rk-page--blog">
  <div class="rk-shell">
    <div class="rk-header">
      <h1 class="rk-title">$title$</h1>
      $if(description)$
      <p class="rk-subtitle">$description$</p>
      $endif$
    </div>
    <div class="rk-article">
      $body$
    </div>
  </div>
<script src="$assets_root$js/search.js"></script>
</body>
</html>
<!-- END bones/templates/rotkeeper-blog.html::4ad3790b -->

<!-- START bones/templates/rotkeeper-doc.html::4ad3790b -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title$</title>
  <link rel="stylesheet" href="$assets_root$css/rotkeeper.css">
</head>
<body class="rk-page rk-page--doc">
  <div class="rk-shell">
    <div class="rk-header">
      <h1 class="rk-title">$title$</h1>
      $if(description)$
      <p class="rk-subtitle">$description$</p>
      $endif$
    </div>
    <div class="rk-article">
      $body$
    </div>
  </div>
<script src="$assets_root$js/search.js"></script>
</body>
</html>
<!-- END bones/templates/rotkeeper-doc.html::4ad3790b -->

<!-- START bones/templates/theme-dark.html::4ad3790b -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title$</title>
  <link rel="stylesheet" href="$assets_root$css/theme-dark.css">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>
<body class="rk-page">
  <div class="rk-container">
    <header class="rk-header">
      <h1 class="rk-title">$title$</h1>
      $if(description)$
      <p class="rk-subtitle">$description$</p>
      $endif$
    </header>
    <main class="rk-article">
      $body$
    </main>
    <footer class="rk-footer">
      <p>Rendered by Rotkeeper</p>
    </footer>
  </div>
<script src="$assets_root$js/search.js"></script>
</body>
</html>
<!-- END bones/templates/theme-dark.html::4ad3790b -->

<!-- START bones/templates/theme-kawaii.html::4ad3790b -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title$</title>
  <link rel="stylesheet" href="$assets_root$css/theme-kawaii.css">
  <link href="https://fonts.googleapis.com/css2?family=Nunito:wght@400;700&display=swap" rel="stylesheet">
</head>
<body class="rk-page rk-page--blog">
  <div class="rk-shell">
    <div class="rk-header">
      <h1 class="rk-title">$title$</h1>
    </div>
    <div class="rk-article">
      $body$
    </div>
  </div>
<script src="$assets_root$js/search.js"></script>
</body>
</html>
<!-- END bones/templates/theme-kawaii.html::4ad3790b -->

<!-- START bones/templates/theme-light.html::4ad3790b -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title$</title>
  <link rel="stylesheet" href="$assets_root$css/theme-light.css">
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600;700&display=swap" rel="stylesheet">
</head>
<body class="rk-page">
  <div class="rk-container">
    <header class="rk-header">
      <h1 class="rk-title">$title$</h1>
      $if(description)$
      <p class="rk-subtitle">$description$</p>
      $endif$
    </header>
    <main class="rk-article">
      $body$
    </main>
    <footer class="rk-footer">
      <p>Rendered by Rotkeeper</p>
    </footer>
  </div>
<script src="$assets_root$js/search.js"></script>
</body>
</html>
<!-- END bones/templates/theme-light.html::4ad3790b -->

<!-- START bones/templates/theme-overgrown.html::4ad3790b -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title$</title>
  <link rel="stylesheet" href="$assets_root$css/theme-overgrown.css">
  <link href="https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,400;0,700;1,400&family=Lora:ital,wght@0,400;0,700;1,400&display=swap" rel="stylesheet">
</head>
<body class="rk-page rk-page--blog">
  <div class="rk-shell">
    <div class="rk-header">
      <h1 class="rk-title">$title$</h1>
    </div>
    <div class="rk-article">
      $body$
    </div>
  </div>
<script src="$assets_root$js/search.js"></script>
</body>
</html>
<!-- END bones/templates/theme-overgrown.html::4ad3790b -->

<!-- START bones/templates/theme-phosphor.html::4ad3790b -->

<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>$title$</title>
  <link rel="stylesheet" href="$assets_root$css/theme-phosphor.css">
  <link href="https://fonts.googleapis.com/css2?family=VT323&display=swap" rel="stylesheet">
</head>
<body class="rk-page rk-page--blog">
  <div class="crt-overlay"></div>
  <div class="rk-shell">
    <div class="rk-header">
      <h1 class="rk-title">> $title$_</h1>
    </div>
    <div class="rk-article">
      $body$
    </div>
  </div>
<script src="$assets_root$js/search.js"></script>
</body>
</html>
<!-- END bones/templates/theme-phosphor.html::4ad3790b -->
