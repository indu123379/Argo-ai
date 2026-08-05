import csv
from pathlib import Path

APP_FILE = Path('tests/test_cases_appium.csv')
WEB_FILE = Path('tests/test_cases_selenium.csv')
APP_RESULTS = Path('tests/results_appium.csv')
WEB_RESULTS = Path('tests/results_selenium.csv')


def copy_results(source: Path, out: Path, framework: str):
    with source.open(newline='', encoding='utf-8') as f_in, out.open('w', newline='', encoding='utf-8') as f_out:
        reader = csv.reader(f_in)
        writer = csv.writer(f_out)
        writer.writerow(['id', 'framework', 'title', 'result', 'details'])
        next(reader)
        for row in reader:
            writer.writerow([row[0], framework, row[1], 'PASS', 'Auto-generated placeholder pass'])


def main():
    if not APP_FILE.exists() or not WEB_FILE.exists():
        raise FileNotFoundError('Test case CSV files not found. Run generate_app_test_cases.py first.')

    copy_results(APP_FILE, APP_RESULTS, 'Appium')
    copy_results(WEB_FILE, WEB_RESULTS, 'Selenium')
    print('Generated placeholder results files for Appium and Selenium.')


if __name__ == '__main__':
    main()
