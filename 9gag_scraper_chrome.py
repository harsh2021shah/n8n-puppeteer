import json
import sys
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

def get_driver():
    options = Options()
    options.add_argument("--headless")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--user-agent=Mozilla/5.0")

    service = Service('/usr/local/bin/chromedriver')
    driver = webdriver.Chrome(service=service, options=options)
    driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    return driver

def scrape_posts(category, post_limit):
    posts_data = []
    driver = get_driver()

    try:
        url = f"https://9gag.com/tag/{category}"
        driver.get(url)

        wait = WebDriverWait(driver, 10)
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "article")))
        time.sleep(3)

        attempts = 0
        while len(posts_data) < post_limit and attempts < 10:
            posts = driver.find_elements(By.TAG_NAME, "article")
            for post in posts:
                if len(posts_data) >= post_limit:
                    break

                try:
                    video = post.find_elements(By.TAG_NAME, "video")
                    if not video:
                        continue

                    post_url_elem = post.find_element(By.CSS_SELECTOR, "a[href^='/gag/']")
                    post_url = "https://9gag.com" + post_url_elem.get_attribute("href")

                    source = video[0].find_elements(By.TAG_NAME, "source")
                    video_url = next((s.get_attribute("src") for s in source if s.get_attribute("src").endswith(".mp4")), None)
                    if not video_url:
                        continue

                    title_elem = post.find_elements(By.CSS_SELECTOR, "h2")
                    title = title_elem[0].text if title_elem else "No title"

                    poster = video[0].get_attribute("poster") or ""

                    tags_elem = post.find_elements(By.CSS_SELECTOR, ".post-tags a")
                    tags = ", ".join([tag.text for tag in tags_elem]) if tags_elem else ""

                    posts_data.append({
                        "title": title,
                        "video_url": video_url,
                        "thumbnail_url": poster,
                        "tags": tags,
                        "post_url": post_url
                    })

                except Exception as e:
                    continue

            driver.execute_script("window.scrollBy(0, 1000);")
            time.sleep(2)
            attempts += 1

        return posts_data

    except Exception as e:
        return {"error": str(e)}
    finally:
        driver.quit()

if __name__ == "__main__":
    try:
        category = sys.argv[1] if len(sys.argv) > 1 else "funny"
        count = int(sys.argv[2]) if len(sys.argv) > 2 else 2

        result = scrape_posts(category, count)
        print(json.dumps(result, indent=2))
    except Exception as err:
        print(json.dumps({"error": str(err)}))
