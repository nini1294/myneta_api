# MyNeta API

An API *scraped* together to make it easy to see and work with MP and MLA data submitted at the time of elections.

## Supported Years

**MPs (Members of Parliament):** 2004, 2009, 2014, 2019, 2024

## Example Usage

## Base URL: https://nish.space/my_neta/

### 1. MPs
#### Endpoint : ['/mps'](https://nish.space/my_neta/mps)
#### Parameters : '/mps[/year][/state or union_territory]'
#### Examples :
* [/mps/2004](https://nish.space/my_neta/mps/2004)
* [/mps/2014/goa](https://nish.space/my_neta/mps/2014/goa)
* [/mps/2019](https://nish.space/my_neta/mps/2019)
* [/mps/2024](https://nish.space/my_neta/mps/2024)

### 2. MLAs
#### Endpoint : ['/mlas'](https://nish.space/my_neta/mlas)
#### Parameters : '/mlas[/state]'
#### Examples :
- [/mlas/maharashtra](https://nish.space/my_neta/mlas/maharashtra)
- [/mlas/andhra_pradesh](https://nish.space/my_neta/mlas/andhra_pradesh)

## Scraping Data

The scraper has been updated to work with the current myneta.info website structure. It handles both the old format (pre-2019) and new format (2019+) automatically.

### Scrape All Data

```bash
# Scrape both MPs and MLAs
rake db:scrape
```

### Scrape MPs by Year

```bash
# Scrape all available MP years (2004, 2009, 2014, 2019, 2024)
rake db:scrape_mps

# Scrape specific years
rake db:scrape_mps[2024]
rake db:scrape_mps[2019,2024]
rake db:scrape_mps[2004,2009,2014]
```

### Re-Scrape (Delete and Replace)

To re-scrape a year (deletes existing data first):

```bash
# Re-scrape 2024 (with confirmation prompt)
rake db:rescrape_mps[2024]

# Re-scrape multiple years
rake db:rescrape_mps[2019,2024]
```

## Adding New Election Years

To add data for new election years (e.g., 2029):

### 1. Update the YEARS constant

Edit `my_neta.rb` and add the new year to the `YEARS` array:

```ruby
YEARS = %w(2004 2009 2014 2019 2024 2029)
```

### 2. Add known URL

Edit `lib/neta_scraper.rb` and add the known URL for the new year to `KNOWN_MP_URLS`:

```ruby
KNOWN_MP_URLS = {
  '2024' => 'https://myneta.info/LokSabha2024/index.php?action=show_winners&sort=default',
  '2019' => 'https://myneta.info/LokSabha2019/index.php?action=show_winners&sort=default',
  '2014' => 'https://myneta.info/ls2014/index.php?action=show_winners&sort=default',
  '2009' => 'https://myneta.info/ls2009/index.php?action=show_winners&sort=default',
  '2004' => 'https://myneta.info/LokSabha2004/index.php?action=show_winners&sort=default',
  '2029' => 'https://myneta.info/LokSabha2029/index.php?action=show_winners&sort=default'  # Add here
}.freeze
```

### 3. Scrape the new data

```bash
# Scrape the new year
rake db:scrape_mps[2029]
```

### Verify the data

```bash
# Check count for the new year
curl https://nish.space/my_neta/mps/2029

# Or with the API running locally
curl http://localhost:9292/mps/2029
```

## Scraper Notes

- **State Extraction**: For 2019+, the scraper fetches individual candidate pages to extract state information. This is cached to avoid repeated requests.
- **New Structure**: The 2024+ site uses 8 columns (vs 16 in older years). The scraper automatically detects and handles both formats.
- **Rate Limiting**: The scraper adds small delays between candidate page fetches to be respectful of the server.
- **Fallback**: If state extraction fails, a constituency-to-state mapping is used as a fallback.
