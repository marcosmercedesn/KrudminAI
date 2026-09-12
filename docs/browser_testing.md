# Browser, Accessibility, And Visual Regression Policy

## Driver And Flake Budget

The companion browser suite uses Rails system tests with Selenium WebDriver and headless Google Chrome. It is the only supported browser driver for the beta evidence suite. Tests use deterministic tenant-scoped fixtures, a fixed initial viewport, explicit page assertions, and no arbitrary waits.

The CI flake budget is **zero automatic retries**. A browser failure is actionable until a maintainer reproduces and classifies it as runner or driver infrastructure. A classification must include the failed command, Chrome/Selenium versions, and a linked remediation before any retry policy can be changed. Tests must not rescue browser failures or add timing delays to hide them.

## Required Coverage

`demo/test/system/admin_visual_regression_test.rb` runs at desktop, tablet, and mobile dimensions. It captures list, new, edit, show, dashboard, association-editor, navigation-rail, and drawer states in light and dark themes. Its pre-capture checks require:

- a primary page heading, main landmark, and navigation landmark;
- rendered Lucide icons and no document-level horizontal overflow;
- visible focus after programmatic and keyboard traversal;
- names for visible buttons and form controls;
- a minimum 32px visible form-control target;
- empty/filter, validation-error, action, nested-editor, and mobile drawer interactions.

Reduced-motion behavior is covered by the engine stylesheet's `prefers-reduced-motion` rule and requires a browser assertion before the capability can be upgraded beyond companion evidence. The suite does not yet provide independent generated-host coverage or a formal screen-reader audit.

## Screenshot Review

The system suite writes PNGs to `demo/tmp/visual_regression/`. CI uploads this directory for every browser run, including failures. Screenshots are evidence artifacts, not checked-in golden images: reviewers compare the named capture against the previous successful CI artifact when UI changes are intentional.

The screenshot names are stable. Each capture runs DOM checks for required primary content, icons, landmarks, and overflow before writing the image, so blank, missing-content, missing-icon, and horizontal-layout regressions fail the test rather than silently producing an artifact. Pixel-diff baselines remain deferred until generated-host fixtures and a cross-platform font/rendering policy are established.

## Local Commands

```sh
cd demo
bundle exec bin/rails test:system test/system/admin_visual_regression_test.rb
```

Run this command before changing generated resource UI, dashboard UI, nested editors, navigation, themes, or shared accessibility primitives. Inspect regenerated captures under `tmp/visual_regression/` when the visual result is intentional.