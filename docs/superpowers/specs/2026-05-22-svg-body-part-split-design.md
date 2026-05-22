# SVG Body Part Split Design

## Goal

Split `/Users/seohyeokgyu/Downloads/images/mukzzi2_adult_hungry_body.svg` into four independent SVG assets:

- `mukzzi2_adult_hungry_body_head.svg`
- `mukzzi2_adult_hungry_body_torso.svg`
- `mukzzi2_adult_hungry_body_arms.svg`
- `mukzzi2_adult_hungry_body_legs.svg`

Each output SVG keeps the original `1024x1024` coordinate system so the four files align correctly when stacked at the same position.

## Layer Boundaries

The head asset includes the head silhouette, ears, hair/detail marks, and all facial expression paths.

The torso asset includes the central body and belly area, excluding arms, legs, and head.

The arms asset includes both arms from shoulder area through hands. Hands are not split into separate files.

The legs asset includes both legs and feet.

## Splitting Approach

Use path reconstruction plus original detail reuse.

Large silhouette paths that currently span multiple body parts should not be split with rectangular `clipPath` masks as the final output. Instead, create clean part-specific outer paths for head, torso, arms, and legs. Reuse original detail paths where they clearly belong to a single part, such as face details, ear details, hand lines, and foot details.

If an original detail path crosses a body-part boundary, rewrite or simplify that path for the target part rather than leaving a visibly clipped straight edge.

## Quality Criteria

Each generated SVG must be valid XML and render on its own.

The four generated SVGs must visually align with the original when overlaid in this order: legs, torso, arms, head.

The parts should be useful as editable/animatable layers. Avoid obvious rectangular cuts, hidden dependency on another layer for basic shape readability, or stray fragments from other body parts.

## Verification

Run `xmllint --noout` on all generated SVGs.

Generate PNG previews of each part and visually inspect them.

Generate or inspect an overlay preview to confirm the four separated assets reconstruct the original pose closely enough for practical layer use.
