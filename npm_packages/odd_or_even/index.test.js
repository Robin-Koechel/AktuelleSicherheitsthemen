const assert = require("node:assert/strict");
const { is_odd } = require("./index");

assert.strictEqual(is_odd(3), true, "3 should be odd");
assert.strictEqual(is_odd(4), false, "4 should be even");
assert.strictEqual(is_odd(0), false, "0 should be even");
assert.strictEqual(is_odd(-7), true, "-7 should be odd");

assert.throws(() => is_odd(3.14), /integer/i, "non-integers should throw");
assert.throws(() => is_odd("8"), /integer/i, "strings should throw");

console.log("All odd/even tests passed.");
