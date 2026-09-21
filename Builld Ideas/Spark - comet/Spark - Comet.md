# Spark-Comet Campaign Build

The [league launch guide](../../index.html) includes this setup under Campaign > Spark-Comet, alongside Twisters. Campaign Zone Rewards are shared; Spark-Comet uses the vendor regexes below instead of spear progression.

Gem Cutting Priority lists which support to cut and where to socket it, in priority order within each uncut gem tier. Modifier cutoffs in the guide cover extra lightning damage, all Spell Skill levels, and Fire Spell Skill levels (also applicable to Cold and Lightning), using the supplied screenshots.

The regexes below contain Markdown escapes; the guide displays and copies the unescaped regex text for use in game.

The gems table follows the Twisters layout: Icon, Skill, and Supports, with attribute-colored support names and Roman-numeral cutting-level badges. Hover a support name for the support tiers from these notes. Galvanic Field has no cutting levels specified, so its support tiers are shown explicitly instead. Skill icons and support attribute colors are sourced from [PoE2DB](https://poe2db.tw/us/Skill_Gems); icons are stored locally so the guide does not depend on remote image loading.

Support colors use the requirements verified on [PoE2DB's support index](https://poe2db.tw/us/Support_Gems), not elemental tags. Zarokh's Refrain retains the guide's gold Lineage styling (its attribute requirement is +5 Int). The guide uses the canonical names Compressed Duration and Shock Conduction for the corresponding entries below.

## Gem Cutting Priority

Read each tier from left to right:

- **Tier 1:** Pierce I on Spark; Controlled Destruction on Spark; Overabundance I on Orb of Storms; Fortress I on Flame Wall; Spell Cascade on Flame Wall.
- **Tier 2:** Considered Casting on Spark; Controlled Destruction on Orb of Storms (move the existing gem from Spark; do not cut another); Short Fuse I on Frost Bomb; Potent Exposure on Frost Bomb; Harmonic Remnants II on Mana Remnants.
- **Tier 3:** Pierce II on Spark; Prolonged Duration II on Spark; Remnant Potency II on Mana Remnants; Spell Echo on Comet; Elemental Focus on Comet; Fortress II on Flame Wall.
- **Tier 4:** Short Fuse II on Frost Bomb; Remnant Potency III on Mana Remnants.
- **Tier 5:** Pierce III on Spark; Projectile Acceleration III on Spark; Cold Mastery on Siphon Elements.

## Quest Choices

| Quest | Choice |
|-------|--------|
| Valley of the Titans | +1 Charm, 30% Charge Generation (Left) |
| Venom Crypts Vial | Elemental Ailment Threshold |
| Abandoned Prison Chapel | Mana Flask Recovery |
| Halls of the Dead Totems | +5% to Fire, Cold, and Lightning Resistances |
| Qimah The Seven Pillars | +5% to all Elemental Resistances |

## Passive Tree

The supplied screenshot is shown beside Quest Choices in the guide. Click it to enlarge or restore it.

![Spark-Comet Passive Tree](../../icons/Spark_Comet_Tree_Screenshot.png)

## Ascendancy: Stormweaver

Take the connecting small passive first, then its notable:

| Ascendancy | Small passive | Notable |
|------------|---------------|---------|
| 1st | Mana Regeneration | Constant Gale |
| 2nd | Remnant Range | Refracted Infusion |
| 3rd | Shock Chance | Strike Twice |
| 4th | Shock Chance (after Strike Twice) | Shaper of Storms |

The build declares `Sorceress1` (Stormweaver) and includes these eight nodes for levels 1-100, with allocation order in their hover notes. Node IDs and connections are verified against [GGG's passive-tree export](https://github.com/grindinggear/poe2-skilltree-export).

## In-game Build Planner

Import [spark-comet.build](./spark-comet.build) using [GGG's Build Planner instructions](https://www.pathofexile.com/developer/docs/game#buildplanner).

After editing the build, run `.\sync-build.ps1` from the repository root. The [sync script](../../sync-build.ps1) validates the JSON and copies it to `%USERPROFILE%\OneDrive\Documents\My Games\Path of Exile 2\BuildPlanner`, verifying the copied file. It runs once and exits; there is no background watcher.

The 13 skill IDs and 44 unique support IDs were checked against PoE2DB's `ItemType` metadata. Both `Metadata/Items/Gem/` and `Metadata/Items/Gems/` are valid prefixes for different entries; do not normalize them.

All listed skill gems except the weapon-granted Galvanic Field are recommended for character levels 1-100. Fireball is also included so it can be cut for the trigger setups.

| Character levels | Support recommendations |
|------------------|-------------------------|
| 1-46 | Only the 21 entries in Gem Cutting Priority above, attached to their specified skills. Hover notes retain each entry's priority group and order. |
| 47-100 | The complete main-table support pools, including alternatives and successive tiers. Mana Remnants includes both Harmonic Remnants I and II, as confirmed. |

These are recommendation ranges, not overrides of gem requirements or simultaneous socket setups. A support present in both ranges has separate non-overlapping recommendation entries.

The character passive recommendations use the previous final level 53-80 tree for the entire level 1-100 range. Earlier-only branches are removed, final attribute choices replace stage-specific respec instructions, and shared / weapon-set 1 / weapon-set 2 allocations are preserved. This is the final-tree blueprint, not a leveling allocation order or an Atlas tree.

The weapon-slot (`Weapon1`) Build Planner tooltip shows all three modifier cutoff groups from the guide for levels 1-100: extra lightning damage, all Spell Skill levels, and Fire Spell Skill levels (also applicable to Cold and Lightning). Each row lists the modifier tier, minimum item level, and roll. To keep it compact, the tooltip contains only rows, with blank lines between groups and the highest tier first within each group.

GGG currently documents meta gems as unsupported. Cast on Elemental Ailment and Cast on Critical remain experimental entries with warnings; manually socket Flame Wall and Fireball into the chosen trigger. Their recommendation display still requires in-game verification.

Lineage recommendations have been confirmed to display in-game. Zarokh's Refrain remains listed for Comet as an acquisition target: obtain it through drops or trade rather than cutting it from an Uncut Support Gem.

## Build Notes

Galvanic Field -> Chain I, Chain II, Chain III, Bounty I, Bounty II, OverAbundance I, OverAbundance II, Momentum, mobility



Act 1: "ld res|\\d+% i.+mov|ell.\*ge$|^\\+.\*all sp.\*ls$|^\\+.\*re sp.\*ls$|^\\+.\*ld sp.\*ls$|^\\+.\*ng sp.\*ls$|^\\+.\*ile skills$|o sp|s: st"



Act 2:

"(re|ng) res|\\d+% i.+mov|ell.\*ge$|^\\+.\*all sp.\*ls$|^\\+.\*re sp.\*ls$|^\\+.\*ng sp.\*ls$|^\\+.\*ile skills$|o sp|st spe|s: st"



Act 3,4

"(ld|os) res|(\[32]0|\[21]5)% i.+mov|ell.\*ge$|^\\+.\*all sp.\*ls$|^\\+.\*re sp.\*ls$|^\\+.\*ng sp.\*ls$|^\\+.\*ile skills$|o sp|st spe|s: st"



Act 5,6:

"(ld|os) res|(\[32]0|25)% i.+mov|ell.\*ge$|^\\+.\*all sp.\*ls$|^\\+.\*re sp.\*ls$|^\\+.\*ng sp.\*ls$|^\\+.\*ile skills$|o sp|st spe|s: st"



Maps Vendor

"(re|ld|ng|os) res|(30|25)% i.+mov|ell.\*ge$|^\\+.\*all sp.\*ls$|^\\+.\*ile skills$|o sp|st spe|s: st"



contagion



Spark ->
Lvl 1 -> Pierce I, Controlled Destruction, Projectile Acceleration I/Prolonged Duration I /Unleash

Lvl 2 -> Considered Casting, Lightning Pen (optional)

lvl 3 -> Prolonged Duration II, Pierce II

lvl 4 -> Projectile Acceleration II

lvl 5 -> Pierce III, Projectile Acceleration III



Orb of Storms
lvl 1 OverAbundance I, Compress Duration I, Innervate, Controlled Destruction (move the existing gem from Spark; do not cut another)
lvl 2 Harmonic Remnants I
lvl 3 Harmonic Remnants II, Compress Duration II
lvl 5 Shock Conductions, Chain III



Frost Bomb ->
lvl 1 -> Magnified area I, Innvervate
lvl 2 -> Short Fuse I, Potent Exposure, Harmonic Remnants I, Overabundance I, Spell Echo
lvl 3 -> Harmonic Remnants II, Second Wind II
lvl 4 -> Short fuse II, cooldown Recovery II,
lvl 5 -> Second Wind III



Flame Wall ->
lvl1 -> fortress I, spell cascade
lvl3 -> fortress II



Mana Remnants requires gem 4 ->
lvl 2 -> Harmonic Remnants I, Remnant Potency I
lvl 3 -> Harmonic Remnants I, Remnant Potency II
lvl 4 -> Remnant Potency III



Mana Tempest requires gem 7

lvl 2 -> cooldown recovery II

lvl 5 -> Lightning mastery



Siphon Elements requires gem 8

lvl 3 -> Harmonic Remnants II

lvl 5 -> cold mastery



Comet requires lvl 11 gem
lvl 2 -> Considered Casting, Rising Tempest
lvl 3 -> spell echo, Elemental Focus, Ambrosia II (notes: once 100+ charges mana flask), Execute II

lvl 5 -> Zarokh's Refrain



Elemental Conflux requires gem 14
lvl 4 -> prolonged duration II, compressed duration II
lvl 5 -> cold mastery



cast on elemental ailment requires gem 14 (100 spirit and use before swapping to crit on notes)
Skill Gems -> Flamewall, fireball
lvl 2 -> boundless Energy I
lvl 3 -> Ignite II, energy retention
lvl 4 -> boundless Energy II

cast on critical requires gem 14 (+90 spirit, replace Cast on elemental ailment after crit swap on notes)

Skill Gems -> Flamewall, fireball
lvl 2 -> boundless Energy I
lvl 3 -> Ignite II, energy retention
lvl 4 -> boundless Energy II
