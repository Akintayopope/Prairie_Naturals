const { defineConfig } = require("cypress");
module.exports = defineConfig({
  e2e: {
    baseUrl: "http://localhost:3000",   // change if different
    viewportWidth: 1280,
    viewportHeight: 800,
    video: false,
  },
});
