/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  rootDir: "src",
  testMatch: ["**/__tests__/**/*.test.ts"],
  testTimeout: 30000,
  // Runs inside `firebase emulators:exec`, which sets the *_EMULATOR_HOST
  // env vars the Admin SDK auto-detects - no manual emulator lifecycle
  // management needed here.
};
