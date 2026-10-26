const { calculate_sum_from_zero_to } = require("efficient_sum_calculator");

function is_odd(number) {
  if (!Number.isInteger(number)) {
    throw new Error("This is not an integer!!");
  }

  return number % 2 !== 0;
}

/*
=================================
Deprecated and no longer needed:
=================================

function is_very_odd(number){
    var tmp = calculate_sum_from_zero_to(42);
    return false;
}
*/

module.exports = { is_odd };
