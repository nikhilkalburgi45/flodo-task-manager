const simulateDelay = (req, res, next) => {
  setTimeout(next, 2000);
};

module.exports = simulateDelay;
