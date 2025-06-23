import json
import sys
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time

def get_driver():
    chrome_options = Options()
    chrome_options.add_argument("--headless")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--window-size=1920,1080")
    chrome_options.add_argument("--disable-blink-features=AutomationControlled")
    chrome_options.add_argument("--disable-extensions")
    chrome_options.add_argument("--disable-plugins")
    chrome_options.add_argument("--disable-images")  # Faster loading
    
    # Use a more recent user agent that matches the Chrome version
    chrome_options.add_argument("--user-agent=Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")
    
    # Disable automation flags
    chrome_options.add_experimental_option("excludeSwitches", ["enable-automation"])
    chrome_options.add_experimental_option('useAutomationExtension', False)
    
    service = Service('/usr/local/bin/chromedriver')
    driver = webdriver.Chrome(service=service, options=chrome_options)
    
    # Execute script to remove webdriver property
    driver.execute_script("Object.defineProperty(navigator, 'webdriver', {get: () => undefined})")
    
    return driver

def scrape_posts(category, posts_count=2):
    driver = get_driver()
    posts_data = []
    processed_urls = set()  # Track processed posts to avoid duplicates
    
    try:
        url = f"https://9gag.com/tag/{category}"
        driver.get(url)
        
        # Wait for page to load
        wait = WebDriverWait(driver, 15)
        wait.until(EC.presence_of_element_located((By.TAG_NAME, "article")))
        time.sleep(3)
        
        # Scroll and find posts
        scroll_attempts = 0
        max_scrolls = 25
        consecutive_no_new_posts = 0
        max_consecutive_no_new = 3
        
        while len(posts_data) < posts_count and scroll_attempts < max_scrolls and consecutive_no_new_posts < max_consecutive_no_new:
            posts = driver.find_elements(By.TAG_NAME, "article")
            initial_count = len(posts_data)
            
            for post in posts:
                if len(posts_data) >= posts_count:
                    break
                    
                # Check if post has video
                video_elements = post.find_elements(By.TAG_NAME, "video")
                if not video_elements:
                    continue
                
                try:
                    # Extract post data
                    video_element = video_elements[0]
                    
                    # Get post URL first to check for duplicates
                    post_url = ""
                    try:
                        post_url_element = post.find_element(By.CSS_SELECTOR, "a[href^='/gag/']")
                        post_url = "https://9gag.com" + post_url_element.get_attribute("href").replace("https://9gag.com", "")
                    except:
                        continue
                    
                    # Skip if already processed
                    if post_url in processed_urls:
                        continue
                    
                    processed_urls.add(post_url)
                    
                    # Get video URL
                    video_sources = video_element.find_elements(By.TAG_NAME, "source")
                    video_url = ""
                    for source in video_sources:
                        src = source.get_attribute("src")
                        if src and src.endswith(".mp4"):
                            video_url = src
                            break
                    
                    if not video_url:
                        continue
                    
                    # Get title
                    try:
                        title_element = post.find_element(By.CSS_SELECTOR, "h2")
                        title = title_element.text.strip()
                    except:
                        title = "No title"
                    
                    # Get thumbnail
                    thumbnail_url = video_element.get_attribute("poster") or ""
                    
                    # Get main tag
                    try:
                        main_tag_element = post.find_element(By.CSS_SELECTOR, ".post-meta__list-view .name")
                        main_tag = main_tag_element.text.strip()
                    except:
                        main_tag = ""
                    
                    # Get all tags
                    try:
                        tags_elements = post.find_elements(By.CSS_SELECTOR, ".post-tags a")
                        tags = ", ".join([tag.text.strip() for tag in tags_elements if tag.text.strip()])
                    except:
                        tags = ""
                    
                    post_data = {
                        "title": title,
                        "video_url": video_url,
                        "thumbnail_url": thumbnail_url,
                        "main_tag": main_tag,
                        "tags": tags,
                        "post_url": post_url
                    }
                    
                    posts_data.append(post_data)
                    
                except Exception as e:
                    print(f"Error extracting post: {e}", file=sys.stderr)
                    continue
            
            # Check if we found new posts
            if len(posts_data) == initial_count:
                consecutive_no_new_posts += 1
            else:
                consecutive_no_new_posts = 0
            
            # Scroll down if we need more posts
            if len(posts_data) < posts_count:
                driver.execute_script("window.scrollBy(0, 1000);")
                time.sleep(2)
                scroll_attempts += 1
    
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        return []
    
    finally:
        driver.quit()
    
    return posts_data

if __name__ == "__main__":
    # Get parameters from command line
    category = sys.argv[1] if len(sys.argv) > 1 else "funny"
    posts_count = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    
    # Scrape posts
    posts = scrape_posts(category, posts_count)
    
    # Output as JSON for n8n to parse
    print(json.dumps(posts, indent=2))
