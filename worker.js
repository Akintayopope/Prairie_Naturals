console.log('Worker dyno started - processing background jobs...');

// Simple background job processor
setInterval(() => {
  console.log('Processing background jobs...', new Date().toISOString());
  // Add your background job logic here
}, 30000); // Run every 30 seconds

// Keep worker alive
process.on('SIGTERM', () => {
  console.log('Worker shutting down...');
  process.exit(0);
});