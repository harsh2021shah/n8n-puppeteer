import json
import sys
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def get_driver():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1920,1080")
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option("useAutomationExtension", False)

    service = Service('/usr/local/bin/chromedriver')
    driver = webdriver.Chrome(service=service, options=chrome_options)
    driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    return driver

def scrape_posts(category, posts_count=2):
    driver = get_driver()
    posts_data = []
    try:
        url = f"https://9gag.com/tag/{category}"
        driver.get(url)
        WebDriverWait(driver, 15).until(EC.presence_of_element_located((By.TAG_NAME, "article")))
        time.sleep(2)

        scroll_attempts = 0
        max_scrolls = 20

        while len(posts_data) < posts_count and scroll_attempts < max_scrolls:
            posts = driver.find_elements(By.TAG_NAME, "article")

            for post in posts:
                if len(posts_data) >= posts_count:
                    break

                try:
                    if not post.find_elements(By.TAG_NAME, "video"):
                        continue

                    # URL
                    try:
                        post_url_element = post.find_element(By.CSS_SELECTOR, "a[href^='/gag/']")
                        post_url = "https://9gag.com" + post_url_element.get_attribute("href").replace("https://9gag.com", "")
                    except:
                        continue

                    # Video
                    video_element = post.find_element(By.TAG_NAME, "video")
                    video_sources = video_element.find_elements(By.TAG_NAME, "source")
                    video_url = next((s.get_attribute("src") for s in video_sources if s.get_attribute("src") and s.get_attribute("src").endswith(".mp4")), None)
                    if not video_url:
                        continue

                    # Title
                    title = post.find_element(By.CSS_SELECTOR, "h2").text if post.find_elements(By.CSS_SELECTOR, "h2") else "No title"

                    # Thumbnail
                    thumbnail_url = video_element.get_attribute("poster") or ""

                    # Main tag
                    main_tag = post.find_element(By.CSS_SELECTOR, ".post-meta__list-view .name").text if post.find_elements(By.CSS_SELECTOR, ".post-meta__list-view .name") else ""

                    # Tags
                    tags = ", ".join([tag.text for tag in post.find_elements(By.CSS_SELECTOR, ".post-tags a")]) if post.find_elements(By.CSS_SELECTOR, ".post-tags a") else ""

                    posts_data.append({
                        "title": title,
                        "video_url": video_url,
                        "thumbnail_url": thumbnail_url,
                        "main_tag": main_tag,
                        "tags": tags,
                        "post_url": post_url
                    })

                except Exception as e:
                    continue

            if len(posts_data) < posts_count:
                driver.execute_script("window.scrollBy(0, 1000);")
                time.sleep(1.5)
                scroll_attempts += 1

    except Exception as e:
        error_output = { "error": str(e) }
        print(json.dumps(error_output), file=sys.stderr)
        sys.exit(1)

    finally:
        driver.quit()

    if not posts_data:
        error_output = { "error": "No posts found. Possibly blocked by 9GAG or dynamic content failed to load." }
        print(json.dumps(error_output), file=sys.stderr)
        sys.exit(1)

    return posts_data

if __name__ == "__main__":
    category = sys.argv[1] if len(sys.argv) > 1 else "funny"
    try:
        posts_count = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    except ValueError:
        print(json.dumps({ "error": "posts_count must be an integer" }), file=sys.stderr)
        sys.exit(1)

    try:
        posts = scrape_posts(category, posts_count)
        print(json.dumps(posts, indent=2))
    except Exception as e:
        print(json.dumps({ "error": f"Unexpected failure: {str(e)}" }), file=sys.stderr)
        sys.exit(1)
