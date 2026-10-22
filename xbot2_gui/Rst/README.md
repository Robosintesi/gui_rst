# Rst

Robosintesi theme for the Qt Quick GUIs built on this fork, from the Robosintesi visual identity
(PQ Design, 2025). The brand book is an internal document and is not in this repository.

The module is also the Qt Quick Controls style `Rst`, selected by `rst::runApp()`. It draws
Button, CheckBox, Switch, Slider, ProgressBar and Popup; Material draws the other controls, with
the colors that `RstApp/RstWindow.qml` gives it.

## Colors

| Brand book | Hex | Token |
|---|---|---|
| Pantone 4159 C, primary | `#005683` | `brand.blue` |
| 4159 C +20k | `#02496F` | `brand.blue20k` |
| 4159 C +50k | `#01314C` | `brand.blue50k` |
| Pantone Cool Gray 1C, secondary | `#D6D7D5` | `brand.coolGray` |
| Cool Gray 1C +20k | `#B8BAB8` | `brand.coolGray20k` |
| Cool Gray 1C +60k | `#727472` | `brand.coolGray60k` |
| Pantone 4158 C, accent | `#357D97` | `brand.accent` |
| White, black | `#FFFFFF`, `#000000` | `brand.white`, `brand.black` |

Pages use the roles in `colors`: `background` (4159 C +50k), `foreground` (4159 C), `text`
(Cool Gray 1C), `textSecondary` (Cool Gray 1C +20k) and `accent` (4158 C). `status` (`ok`, `warn`,
`err`) is not in the brand book: it shows the state of the robot and of the processes; neither is
`colors.selection` (`#22AAA1`), the selected joint.

Contrast on `background`:

| Token | Ratio | Use for |
|---|---|---|
| `text`, `textSecondary` | 9.4:1, 7.0:1 | any text |
| `status.ok`, `status.warn` | 6.7:1, 5.1:1 | any text |
| `status.err` | 3.3:1 | icons, text from 24 px (19 px bold) |
| `accent` | 2.9:1 | bars and borders, never text |

## Fonts

| Use | Font | Token |
|---|---|---|
| Everything (titles, subtitles, kickers, buttons, values, labels), the default of `RstWindow` | Space Grotesk Bold | `fonts.headline` |
| Running text only: logs, descriptions, text fields | Inter Regular | `fonts.body` |
| Icons (`RstIcon`): thin (FILL 0, weight 300), filled and weight 500 in primary buttons | Material Symbols Rounded, static (`fonts/static_icons.py`) | `fonts.icons`, `fonts.iconsFilled` |

Space Grotesk and Inter are under the SIL Open Font License, Material Symbols under Apache 2.0.

## Logos

`logos` holds the ideogram and the logotype in blue (4159 C), cool gray and black, and the
horizontal lock-up of the two in white (`logotype_horizontal_white.svg`). The brand book also has
a vertical lock-up, not included yet.

- Never rotate or stretch a logo, and never swap its parts: use
  `fillMode: Image.PreserveAspectFit`.
- Allowed pairs, logo on background: white on 4159 C; 4159 C or white on Cool Gray 1C; 4159 C or
  Cool Gray 1C on white. The GUIs use the cool gray logos on `background`.
- Never an accent (4158 C) logo or a logo filled with a gradient.

## Components

Built with the tokens above, for every page of the apps:

| Component | Use |
|---|---|
| `RstButton` | pill with an optional icon: `Primary` (filled), `Secondary` (tonal), `Destructive` (red tonal) |
| `RstIconButton` | round tonal icon button, 48 px or the size the layout gives it |
| `RstToolButton` | 48 px button of the toolbars over a 3D view, icon with label or tooltip |
| `RstIcon` | Material Symbol (`symbols` or the fork's `MaterialSymbolNames`) |
| `RstPanel` | panel of a page, its children in a column |
| `RstKicker` | section title, with an optional detail |
| `RstPill` | icon and label in a tint: connection and status chips |
| `RstReadout` | read-only value with its label and unit, "—" when missing, optional chart icon |
| `RstSegmented` | segmented control; a tap emits `activated`, the owner sets `currentIndex` |
| `RstLog` | log lines (time, level, source, message) with source and level filters |
