import pandas as pd
from pathlib import Path

RESULT_FILES = [
    'tests/results_selenium.csv',
    'tests/results_appium.csv',
    'tests/results_api.csv',
    'tests/results_validation.csv',
    'tests/results_deployment.csv',
    'tests/results_performance.csv',
]
OUT_FILE = 'tests/test_report.xlsx'


def main():
    results = []
    for path in RESULT_FILES:
        file_path = Path(path)
        if not file_path.exists():
            print(f'Warning: {path} not found, skipping.')
            continue
        df = pd.read_csv(path)
        results.append(df)

    if not results:
        print('No results found. Run test generation/execution scripts first.')
        return

    combined = pd.concat(results, ignore_index=True)
    summary = combined.groupby(['framework', 'result']).size().unstack(fill_value=0)
    summary['Total'] = summary.sum(axis=1)

    with pd.ExcelWriter(OUT_FILE, engine='openpyxl') as writer:
        combined.to_excel(writer, sheet_name='All Test Results', index=False)
        summary.to_excel(writer, sheet_name='Summary')

    print(f'Wrote consolidated Excel report with {len(combined)} total test cases -> {OUT_FILE}')


if __name__ == '__main__':
    main()
