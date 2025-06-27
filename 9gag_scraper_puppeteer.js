const puppeteer = require("puppeteer");

console.log("🟢 Script started");

(async () => {
  try {
    const browser = await puppeteer.launch({
      headless: "new",
      args: ["--no-sandbox", "--disable-setuid-sandbox"],
      executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || "/usr/bin/google-chrome",
    });
    console.log("✅ Browser launched");

    await browser.close();
    console.log("🧹 Browser closed");

    console.log("🎉 Script finished OK");
  } catch (err) {
    console.error("❌ Script failed:", err);
  }
})();
