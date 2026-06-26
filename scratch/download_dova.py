import re
import os
import sys
import urllib.request
import urllib.parse
import http.cookiejar

def download_dova(play_url, dest_path):
    print(f"Resolving: {play_url}")
    
    # Initialize CookieJar to handle session cookies (needed for CSRF)
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    opener.addheaders = [
        ('User-Agent', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'),
        ('Referer', play_url)
    ]
    
    # 1. Fetch the play page
    try:
        with opener.open(play_url) as response:
            html = response.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"Error fetching play page: {e}")
        return False
        
    # 2. Find the download page link
    # Example: /en/bgm/detail/21357/download or /bgm/detail/21357/download
    # or for SE: /en/se/detail/1413/download
    match = re.search(r'href="(/[a-zA-Z\-]+/bgm/detail/\d+/download|/bgm/detail/\d+/download|/[a-zA-Z\-]+/se/detail/\d+/download|/se/detail/\d+/download)"', html)
    if not match:
        # Try alternate pattern
        match = re.search(r'href="([^"]+/detail/\d+/download)"', html)
        if not match:
            print("Could not find download page URL in the play page.")
            return False
            
    dl_rel_url = match.group(1)
    dl_url = urllib.parse.urljoin(play_url, dl_rel_url)
    print(f"Found download page: {dl_url}")
    
    # 3. Fetch the download page
    try:
        opener.addheaders = [
            ('User-Agent', 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'),
            ('Referer', play_url)
        ]
        with opener.open(dl_url) as response:
            dl_html = response.read().decode('utf-8', errors='ignore')
    except Exception as e:
        print(f"Error fetching download page: {e}")
        return False
        
    # 4. Extract CSRF token
    # <input type="hidden" name="csrfmiddlewaretoken" value="z53ZSkesNCZLGRVHYcqO0QwIEnRred8g9YCDC6uy6pr2DLDs7qAjOr3upqqlRLFx">
    csrf_match = re.search(r'name="csrfmiddlewaretoken" value="([^"]+)"', dl_html)
    if not csrf_match:
        print("Could not find CSRF token on download page.")
        # Sometimes DOVA-S has direct link if it's already generated or if it doesn't need CSRF, but let's fail here
        return False
        
    csrf_token = csrf_match.group(1)
    
    # 5. POST to download page
    post_data = urllib.parse.urlencode({
        'csrfmiddlewaretoken': csrf_token,
        'track': '1' # Default to track 1
    }).encode('utf-8')
    
    try:
        # Update headers with CSRF and Referer
        headers = {
            'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Referer': dl_url,
            'Origin': 'https://dova-s.jp'
        }
        
        # We need to construct a Request object to send POST data with custom headers
        req = urllib.request.Request(dl_url, data=post_data, headers=headers)
        
        with opener.open(req) as response:
            content_type = response.headers.get('Content-Type', '')
            print(f"Response Content-Type: {content_type}")
            
            # Read response
            data = response.read()
            
            if 'html' in content_type.lower() or len(data) < 10000:
                # If we got HTML, it might be an error or redirect page
                resp_text = data.decode('utf-8', errors='ignore')
                print(f"Warning: Received HTML/short response instead of binary audio.")
                # Look for a direct audio link or redirect link inside the HTML
                # Sometimes DOVA-S returns a landing page with a refresh or direct link:
                direct_match = re.search(r'href="([^"]+\.mp3)"', resp_text)
                if direct_match:
                    direct_url = urllib.parse.urljoin(dl_url, direct_match.group(1))
                    print(f"Found direct MP3 link: {direct_url}")
                    # Fetch direct link
                    with opener.open(direct_url) as direct_resp:
                        data = direct_resp.read()
                else:
                    # Let's check if the response redirected to a download path
                    print("Could not download file. HTML response:")
                    print(resp_text[:500])
                    return False
            
            # Save the file
            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
            with open(dest_path, 'wb') as f:
                f.write(data)
                
            print(f"Successfully downloaded to: {dest_path} ({len(data)} bytes)")
            return True
            
    except Exception as e:
        print(f"Error during POST download: {e}")
        return False

# Quick test
if __name__ == '__main__':
    download_dova("https://dova-s.jp/EN/bgm/play21385.html", "assets/music/test_dova.mp3")
