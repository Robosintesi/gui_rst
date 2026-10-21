"""Static Material Symbols Rounded fonts for RstIcon, from the variable font of Google.

Qt applies neither the FILL axis nor the glyph substitution the font does at FILL 1 (send ->
send.fill), so RstIcon uses two static fonts: thin (FILL 0, weight 300) and filled (FILL 1,
weight 500, its code points mapped to the .fill glyphs).

    python static_icons.py "MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf"

The variable font is in https://github.com/google/material-design-icons (variablefont/).
"""

import sys

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer


def fill_glyphs(font: TTFont) -> dict:
    """glyph -> glyph.fill, from the GSUB feature variation of the FILL axis."""
    gsub = font['GSUB'].table
    mapping = {}
    for record in gsub.FeatureVariations.FeatureVariationRecord:
        for substitution in record.FeatureTableSubstitution.SubstitutionRecord:
            for index in substitution.Feature.LookupListIndex:
                for table in gsub.LookupList.Lookup[index].SubTable:
                    mapping.update(getattr(table, 'mapping', {}))
    return mapping


def make(source: str, family: str, fill: int, weight: int, output: str) -> None:
    font = TTFont(source)
    fills = fill_glyphs(font) if fill else {}
    font = instancer.instantiateVariableFont(font, {'FILL': fill, 'wght': weight, 'opsz': 24, 'GRAD': 0})
    for table in font['cmap'].tables:
        table.cmap = {cp: fills.get(glyph, glyph) for cp, glyph in table.cmap.items()}
    # code points only: no ligatures, no layout tables, only the glyphs the cmap reaches
    options = subset.Options()
    options.layout_features = []
    options.name_IDs = ['*']
    subsetter = subset.Subsetter(options)
    subsetter.populate(unicodes=font.getBestCmap().keys())
    subsetter.subset(font)
    for record in font['name'].names:
        if record.nameID in (1, 4, 16):
            record.string = family
        elif record.nameID == 6:
            record.string = family.replace(' ', '')
    font.save(output)


if __name__ == '__main__':
    make(sys.argv[1], 'Material Symbols Rounded Thin', 0, 300, 'MaterialSymbolsRoundedThin.ttf')
    make(sys.argv[1], 'Material Symbols Rounded Filled', 1, 500, 'MaterialSymbolsRoundedFilled.ttf')
