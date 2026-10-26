const assert = require("node:assert/strict");
const { calculate_sum_from_zero_to } = require("./index");

assert.strictEqual(calculate_sum_from_zero_to(0), 0, "sum to 0 should be 0");
assert.strictEqual(calculate_sum_from_zero_to(1), 1, "sum to 1 should be 1");
assert.strictEqual(calculate_sum_from_zero_to(5), 15, "sum to 5 should be 15");
assert.strictEqual(
  calculate_sum_from_zero_to(10),
  55,
  "sum to 10 should be 55",
);

assert.throws(
  () => calculate_sum_from_zero_to(-1),
  /integer|non-negative/i,
  "negative numbers should be rejected",
);
assert.throws(
  () => calculate_sum_from_zero_to(3.14),
  /integer/i,
  "non-integer values should be rejected",
);
assert.throws(
  () => calculate_sum_from_zero_to("7"),
  /integer/i,
  "string input should be rejected",
);

console.log("All sum calculator tests passed.");
