import pandas as pd
from pathlib import Path

APP_RESULTS = 'tests/results_appium.csv'
SEL_RESULTS = 'tests/results_selenium.csv'
OUT_FILE = 'tests/test_report.xlsx'


def main():
    results = []
    for path in (APP_RESULTS, SEL_RESULTS):
        file_path = Path(path)
        if not file_path.exists():
            print(f'Warning: {path} not found, skipping.')
            continue
        df = pd.read_csv(path)
        results.append(df)

    if not results:
        print('No results found. Run the test runners first.')
        return

    combined = pd.concat(results, ignore_index=True)
    summary = combined.groupby(['framework', 'result']).size().unstack(fill_value=0)

    with pd.ExcelWriter(OUT_FILE, engine='openpyxl') as writer:
        combined.to_excel(writer, sheet_name='Results', index=False)
        summary.to_excel(writer, sheet_name='Summary')

    print(f'Wrote {OUT_FILE}')


if __name__ == '__main__':
    main()
