const puppeteer = require("puppeteer");

async function scrape9Gag(category = "funny", postsCount = 2) {
  console.log("🚀 Starting 9GAG Scraper");
  console.log(`🔍 Target category: ${category}, Posts to scrape: ${postsCount}`);

  const browser = await puppeteer.launch({
    headless: "new",
    args: [
      "--no-sandbox",
      "--disable-setuid-sandbox",
      "--disable-dev-shm-usage",
      "--disable-gpu",
      "--window-size=1920,1080",
    ],
    executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || "/usr/bin/google-chrome",
  });

  console.log("✅ Browser launched");

  const page = await browser.newPage();
  await page.setUserAgent(
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.5735.90 Safari/537.36"
  );
  console.log("🧭 New page opened and User-Agent set");

  const postsData = [];

  try {
    const url = `https://9gag.com/tag/${category}`;
    console.log(`🌐 Navigating to ${url}`);
    await page.goto(url, { waitUntil: "networkidle2", timeout: 60000 });
    console.log("✅ Page loaded successfully");

    let scrollTries = 0;

    while (postsData.length < postsCount && scrollTries < 30) {
      console.log(`🔁 Scroll attempt ${scrollTries + 1}`);
      const articles = await page.$$("article");
      console.log(`🔎 Found ${articles.length} articles`);

      for (const article of articles) {
        if (postsData.length >= postsCount) break;

        const hasVideo = await article.$("video");
        if (!hasVideo) continue;

        const videoSrc = await article.$$eval("video source", sources =>
          sources.map(s => s.src).find(src => src.endsWith(".mp4"))
        );
        if (!videoSrc) continue;

        const postUrl = await article.$eval("a[href^='/gag/']", a => "https://9gag.com" + a.getAttribute("href")).catch(() => "");
        const title = await article.$eval("h2", el => el.innerText).catch(() => "No title");
        const thumbnail = await article.$eval("video", el => el.getAttribute("poster")).catch(() => "");
        const tags = await article.$$eval(".post-tags a", els => els.map(el => el.textContent.trim()).join(", ")).catch(() => "");
        const mainTag = await article.$eval(".post-meta__list-view .name", el => el.innerText).catch(() => "");

        console.log(`📌 Post scraped: ${title}`);

        postsData.push({
          title,
          video_url: videoSrc,
          thumbnail_url: thumbnail,
          main_tag: mainTag,
          tags,
          post_url: postUrl,
        });

        if (postsData.length >= postsCount) {
          console.log("✅ Desired number of posts scraped");
          break;
        }
      }

      await page.evaluate(() => window.scrollBy(0, 1000));
      await new Promise(r => setTimeout(r, 2000));
      scrollTries++;
    }
  } catch (err) {
    console.error("❌ Scraping error:", err);
    process.exit(1);
  } finally {
    await browser.close();
    console.log("🧹 Browser closed");
  }

  console.log("✅ Scraping complete. Returning results:\n");
  console.log(JSON.stringify(postsData, null, 2));
  process.exit(0);
}

// Get arguments from command line
const category = process.argv[2] || "funny";
const count = parseInt(process.argv[3] || "2", 10);
scrape9Gag(category, count);
