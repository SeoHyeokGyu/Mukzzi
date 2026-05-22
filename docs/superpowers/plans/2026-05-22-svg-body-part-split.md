# SVG Body Part Split Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Split `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body.svg` into four aligned SVG assets for head, torso, arms, and legs.

**Architecture:** Work from the original SVG as the reference asset. Reconstruct the major silhouette paths for each body part, then reuse original detail paths when they belong cleanly to one part. Keep every output in the original `1024x1024` coordinate system so files align when overlaid.

**Tech Stack:** SVG/XML, shell tools, `xmllint`, macOS `qlmanage` thumbnails, manual vector path editing.

---

### File Structure

**Files:**
- Read: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body.svg`
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_head.svg`
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_torso.svg`
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_arms.svg`
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_legs.svg`
- Create for verification: `/private/tmp/mukzzi2_adult_hungry_body_overlay.html`
- Create for verification: `/private/tmp/mukzzi2_adult_hungry_body_*_preview.png`

The four output SVGs should each include the original `<defs>` block so gradients resolve independently.

### Task 1: Inspect And Classify Original SVG Paths

**Files:**
- Read: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body.svg`

- [ ] **Step 1: Extract path metadata**

Run:

```bash
python3 - <<'PY'
from pathlib import Path
import re, json

src = Path('/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body.svg')
svg = src.read_text()
paths = re.findall(r'<path\b[^>]*>', svg)

def bbox(tag):
    d = re.search(r' d="([^"]+)"', tag).group(1)
    nums = [float(x) for x in re.findall(r'-?\d*\.?\d+(?:e[-+]?\d+)?', d, re.I)]
    xs = nums[0::2]
    ys = nums[1::2]
    return {
        'minX': round(min(xs), 3), 'maxX': round(max(xs), 3),
        'minY': round(min(ys), 3), 'maxY': round(max(ys), 3),
    }

items = []
for i, tag in enumerate(paths):
    fill = re.search(r' fill="([^"]+)"', tag)
    items.append({'i': i, 'fill': fill.group(1) if fill else '', **bbox(tag)})

print(json.dumps({'path_count': len(paths), 'items': items}, indent=2))
PY
```

Expected: JSON listing all original paths, including their bounding boxes.

- [ ] **Step 2: Identify body-part ownership**

Use the path metadata and rendered reference to assign each original detail path to one of:

```text
head: ears, hair, face, brow, eyes, mouth, cheeks, head highlights
torso: central belly/body highlights and torso-only shadows
arms: left and right shoulder/arm/hand detail paths
legs: left and right leg/foot detail paths
```

Expected: a small working note in the terminal or scratch text identifying the path indexes for reused details.

### Task 2: Reconstruct Four Independent SVGs

**Files:**
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_head.svg`
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_torso.svg`
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_arms.svg`
- Create: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_legs.svg`

- [ ] **Step 1: Create head SVG**

Create a full SVG document with the same root attributes as the original SVG, including `width="1024"`, `height="1024"`, and `viewBox="0 0 1024 1024"`. Copy the original `<defs>` block. Add a `<g id="head_layer" data-layer="head">` containing a complete reconstructed head silhouette path. Shape coverage must include head, ears, cheeks, chin, and face area.

Then append original detail paths assigned to head, including all facial expression paths. The head file should render as a complete head with face, not a clipped rectangle.

- [ ] **Step 2: Create torso SVG**

Create a full SVG document with the same root attributes and original `<defs>` block. Add `<g id="torso_layer" data-layer="torso">` containing a complete reconstructed torso and belly silhouette. The shape should start below the head and exclude arms and legs.

Then append torso-only detail paths such as belly highlight/shadow paths. The torso file should not contain face, ears, arms, hands, feet, or obvious straight mask edges.

- [ ] **Step 3: Create arms SVG**

Create a full SVG document with the same root attributes and original `<defs>` block. Add `<g id="arms_layer" data-layer="arms">` containing separate reconstructed left and right arm silhouette paths. Each arm path should cover shoulder area through hand.

Then append original hand and arm detail paths. The arms file should include hands and fingers, because hands are not split separately.

- [ ] **Step 4: Create legs SVG**

Create a full SVG document with the same root attributes and original `<defs>` block. Add `<g id="legs_layer" data-layer="legs">` containing separate reconstructed left and right leg/foot silhouette paths.

Then append original foot/toe detail paths. The legs file should not contain belly, arms, or head fragments.

### Task 3: Validate XML And Renderability

**Files:**
- Verify: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_head.svg`
- Verify: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_torso.svg`
- Verify: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_arms.svg`
- Verify: `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_legs.svg`

- [ ] **Step 1: Run XML validation**

Run:

```bash
xmllint --noout \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_head.svg \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_torso.svg \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_arms.svg \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_legs.svg
```

Expected: no output and exit code `0`.

- [ ] **Step 2: Generate previews**

Run:

```bash
qlmanage -t -s 1024 -o /private/tmp /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_head.svg
qlmanage -t -s 1024 -o /private/tmp /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_torso.svg
qlmanage -t -s 1024 -o /private/tmp /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_arms.svg
qlmanage -t -s 1024 -o /private/tmp /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_legs.svg
```

Expected: PNG thumbnails are created in `/private/tmp`.

- [ ] **Step 3: Inspect previews**

Open the generated PNG thumbnails with the available image viewer. Confirm:

```text
head: complete head and face only
torso: belly/body center only
arms: both arms and hands only
legs: both legs and feet only
```

### Task 4: Verify Overlay Reconstruction

**Files:**
- Create: `/private/tmp/mukzzi2_adult_hungry_body_overlay.html`

- [ ] **Step 1: Create overlay preview**

Create an HTML file that overlays the four SVGs in this order:

```html
<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: white; }
    .stage { position: relative; width: 1024px; height: 1024px; }
    .stage img { position: absolute; inset: 0; width: 1024px; height: 1024px; }
  </style>
</head>
<body>
  <div class="stage">
    <img src="/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_legs.svg">
    <img src="/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_torso.svg">
    <img src="/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_arms.svg">
    <img src="/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_head.svg">
  </div>
</body>
</html>
```

- [ ] **Step 2: Render overlay**

Use browser/Quick Look/manual preview to inspect the overlay.

Expected: the overlaid parts reconstruct the original hungry pose closely, with no obvious extra fragments from the wrong body part.

### Task 5: Final Cleanup And Report

**Files:**
- Verify final outputs in `/Users/seohyeokgyu/Downloads/images`

- [ ] **Step 1: List final files**

Run:

```bash
ls -l \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_head.svg \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_torso.svg \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_arms.svg \
  /Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body_legs.svg
```

Expected: all four files exist and are non-empty.

- [ ] **Step 2: Final response**

Report the four output file paths, validation result, and whether preview/overlay verification passed.
