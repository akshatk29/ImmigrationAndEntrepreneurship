"""
Main Thesis - Download & Process Raw Data

Downloads the only programmatically-available raw input used in the paper and
turns it into an analysis-ready CSV:

  1. Download QCEW high-level county wage data (BLS open data, no API key), one
     ZIP per year 1990-2023, extracted to data/0_raw_data/qcew_data/{year}/.
  2. Concatenate the county rows of every year into one file,
     data/0_raw_data/qcew_data/wage_data_combined.csv.

Manual prerequisites (cannot be auto-downloaded; place by hand before running
the build step, see code/README.md):
  - data/0_raw_data/ImmigrationShock.dta        immigration instrument (Tarek Hassan)
  - data/0_raw_data/bds2023_st_cty.csv          county BDS
  - data/0_raw_data/bds2023_st_cty_eac.csv      county BDS by firm-age cohort
  - data/0_raw_data/pums.csv                    2007 SBO PUMS
  - data/0_raw_data/county_population.dta        county population (NBER intercensal)

Last Updated: 26th June, 2026
Created by: Akshat Kumar
"""
import os
import time
import urllib.request
import zipfile

import pandas as pd

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

# Project root = the parent of this script's directory (code/..). Auto-resolves so
# the package runs from any clone location without editing paths.
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

QCEW_DIR     = os.path.join(ROOT, "data", "0_raw_data", "qcew_data")
WAGE_OUTFILE = os.path.join(QCEW_DIR, "wage_data_combined.csv")
YEARS        = range(1990, 2024)   # QCEW county high-level files, 1990-2023

# ---------------------------------------------------------------------------
# Download QCEW wage data (BLS open data)
# ---------------------------------------------------------------------------

def make_url(year):
    """Return the BLS open-data URL for the high-level county ZIP of `year`."""
    return f"https://data.bls.gov/cew/data/files/{year}/xls/{year}_all_county_high_level.zip"


def download_data(url, path):
    """Download `url` to `path`, printing a message on success or failure."""
    try:
        urllib.request.urlretrieve(url, path)
        print("Download complete.")
    except Exception as e:
        print(f"An error occurred during download: {e}")


def extract_zip(zip_path, extract_to):
    """Extract `zip_path` into `extract_to`, then delete the ZIP."""
    os.makedirs(extract_to, exist_ok=True)

    with zipfile.ZipFile(zip_path, "r") as zip_file:
        zip_file.extractall(extract_to)

    os.remove(zip_path)
    print("Saved and extracted data to " + extract_to)


def download_wage_data(year_range, download_directory):
    """Download and extract the QCEW high-level county ZIP for each year."""
    start_time = time.time()

    for year in year_range:
        url = make_url(year)
        zip_path = os.path.join(download_directory, f"{year}_all_county_high_level.zip")
        extract_to = os.path.join(download_directory, f"{year}")

        download_data(url, zip_path)
        extract_zip(zip_path, extract_to)

    end_time = time.time()
    print(f"Total time taken: {round((end_time - start_time) / 60, 2)} minutes")

# ---------------------------------------------------------------------------
# Process QCEW wage data into a single CSV
# ---------------------------------------------------------------------------

def process_file(file_path):
    """Read one QCEW Excel file and keep the County-level rows."""
    df = pd.read_excel(file_path, sheet_name="US_St_Cn_MSA")
    df = df[df["Area Type"] == "County"]
    return df


def process_wage_data(input_dir, output_file):
    """Concatenate the county rows of every yearly QCEW file into `output_file`."""
    all_data = pd.DataFrame()

    for i in range(1990, 2024):
        print(f"Processing data for year: {i}")
        yr_suffix = str(i)[-2:]
        excel_sheet = os.path.join(input_dir, f"{i}", f"allhlcn{yr_suffix}.xlsx")
        yearly_data = process_file(excel_sheet)
        all_data = pd.concat([all_data, yearly_data], ignore_index=True)

    print(all_data.shape)
    print(all_data["Year"].value_counts())

    all_data.to_csv(output_file, index=False)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    download_wage_data(YEARS, QCEW_DIR)
    process_wage_data(QCEW_DIR, WAGE_OUTFILE)


if __name__ == "__main__":
    main()
