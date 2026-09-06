# Thing Riot presentation guide

Storybook royal farce with tactile arcade feedback. Inked silhouettes, restrained shading, brass, ivory dice, biscuit crumbs and officious stationery. Humour belongs to the premise; presentation takes it seriously.

## Visual language
Navy #20283b outlines; cream #fff0c5 highlights; brass #e7bd70 signatures; blue #85c9e0 player accents. Muted world and enemies. Never encode danger with red/green alone: hostile shots are pointed paper darts, XP is a compact diamond, stamps have crosses and a locked boundary.

Keep the moustached King, blue cape, small foot hitbox and Bureaucrab's suit/spectacles. Preserve silhouettes before adding detail. Use a common top-left light and one or two shading steps. Judge outline weights at gameplay scale. Floor texture must remain quieter than actors.

## Attention and effects
Player artwork stays opaque, above friendly projectiles; hostile shots remain above the player. Common shots, pickups and hits receive short local feedback and no global shake. Strong events (damage, dice, bombs) receive one clear shape plus sound. Signatures (Royal Six, meaningful Crumble chains, boss arrival/defeat) receive anticipation, a concise announcement and selective audio ducking. Do not repeat signature announcements on every link.

Ordinary impacts, bomb rings and dice feedback retain separate 32/16/8 caps. Never hide critical telegraphs to save decorative effects. Collision geometry and warning duration are independent of squash/stretch or claw animation.

## Materials
Crown: narrow metallic glint, crisp spark, ringing transient, quiet catch.
Biscuit: warm crumb trail, brittle angular fragments, short noisy crack, subdued persistent patch.
Dice: ivory face and shaded side, separated shadow, diminishing clacks, stable readable result. Keep safe rolling and the 0.55-second real six reveal. Value changes pips, footprint and impact; never six arbitrary colours.

## UI
Compact health/XP upper-left, encounter upper-centre, equipped icons along lower edge. Boss health has a recent-damage trail. Cards use icon, name and concrete improvement with consistent spacing and visible focus. Opening controls fade; full help belongs in pause. Exact health remains available. Settings must work without shake.

## Audio
Bounded groups: three launch voices, three impact voices, one protected damage voice, one signature voice. Routine sounds vary slightly and rate-limit; signature motifs stay stable. Damage/signatures duck routine effects and music. Music uses rests and longer phrases. Avoid cutting hurt sounds with dice or pickup sounds. Audio variation uses its own RNG.

## Signature timing
Damage: contact cue + local ivory flash + shield + HUD loss trail. Royal Six: reveal, seal, blast. Bureaucrab: short arrival banner; claws anticipate existing stamp timings; death disables damage immediately and presents an audit-rejected beat before results.

## Review gate
Inspect ordinary combat, dense combat plus damage, upgrade cards, dice values/reveal and boss stamp/defeat at 1280×800. Listen to a short busy encounter. Verify changed mechanics with the focused fixture; do not substitute historical results. Avoid permanent bright circles, constant screen shake, mismatched pixel/vector UI and repetitive identical beeps. Generated environment/title art is a later, separately scoped pass.
