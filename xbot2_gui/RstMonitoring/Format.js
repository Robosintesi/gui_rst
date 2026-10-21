.pragma library

// decimals of each unit, the same in the list (at most 2), the detail, the command and the badge
const DECIMALS = { "rad": 3, "rad/s": 3, "Nm": 2, "Nm/rad": 0, "Nm·s/rad": 0, "°C": 1, "V": 1, "A": 1 }

function valid(v) {
    return typeof v === 'number' && !isNaN(v)
}

function decimals(unit) {
    return DECIMALS[unit] ?? 2
}

// number with a typographic minus and no plus; '—' when the value is missing
function number(v, decimals) {
    if (!valid(v)) {
        return '—'
    }
    let s = Math.abs(v).toFixed(decimals)
    return Number(s) === 0 || v > 0 ? s : '−' + s
}
