function calculate_sum_from_zero_to(number) {
  if (!Number.isInteger(number) || number < 0) {
    throw new Error("The input is not a non-negative integer!");
  }

  return (number * (number + 1)) / 2;
}

module.exports = { calculate_sum_from_zero_to };
