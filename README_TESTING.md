# Appium + Selenium Test Case Generation

This repository includes mobile and web test cases for the Argo-ai app.

## Test files
- `tests/test_cases_appium.csv` — 100 Appium mobile test cases
- `tests/test_cases_selenium.csv` — 100 Selenium web test cases
- `tests/appium/test_runner.py` — placeholder Appium runner template
- `tests/selenium/test_runner.py` — placeholder Selenium runner template
- `tests/generate_report.py` — combines Appium and Selenium run results into `test_report.xlsx`

## Generate test case CSVs
Run:

```bash
python tests/generate_app_test_cases.py
```

## Run Appium tests
1. Start Appium server
2. Configure `tests/appium/test_runner.py` caps and locators
3. Run:

```bash
python tests/appium/test_runner.py
```

## Run Selenium tests
1. Ensure ChromeDriver is installed and available
2. Update `URL` in `tests/selenium/test_runner.py`
3. Run:

```bash
python tests/selenium/test_runner.py
```

## Generate combined report
After running both test runners:

```bash
python tests/generate_report.py
```

This will produce `tests/test_report.xlsx` with a combined results sheet and summary.
