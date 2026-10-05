# 01_generate.py
# Purpose: create the three "raw" synthetic data files (deliberately made a little messy), that the rest of the project reads. 

from pathlib import Path
import numpy as np
import pandas as pd
root = Path(__file__).resolve().parents[1]
raw = root / "data" / "raw"
raw.mkdir(parents=True, exist_ok=True)

# random-number generator

rng = np.random.default_rng(20260906)

# Create Synthetic District Data Values for DiD estimation.

district_rows = []
panel_rows = []

for j in range(1, 41):
    district_id = f"D{j:03d}"
    treated = int(j <= 20)
    district_rows.append([district_id, treated])
    baseline = 50 + 6 * treated + rng.normal(0, 3)  # 50 days for everyone, +6 extra days if it's a treated district
    shock = rng.normal(0, 2) # initial random "shock" value for this district's time series.

    
    for year in range(2015, 2023):
        post = int(year >= 2019)
        shock = 0.5 * shock + rng.normal(0, 2) # Update the shock as 50% of last year's shock plus new noise, so shocks are "serially correlated" 
        delay = baseline + 0.5 * (year - 2015) # Start delay at this district's baseline plus a common upward trend, over time (shared by every district, treated or not).
        delay = delay - 4 * treated * post + shock # Subtract 4 days ONLY for treated districts in post-reform years; ( Fake DiD Treatment Effect)
        panel_rows.append([district_id, year, delay])


lookup = pd.DataFrame(district_rows, columns=["district_id", "treated"])
panel = pd.DataFrame(panel_rows, columns=["district_id", "year", "delay_days"])

# Sanity check:
assert not lookup.duplicated("district_id").any()
assert not panel.duplicated(["district_id", "year"]).any()
assert len(panel) == 320

# Create Synthetic Case Data Values for RD estimation.

score = rng.uniform(30, 70, 1000)
eligible = (score >= 50).astype(int)
# Case duration: a baseline of 60, a small linear slope in the score, minus 5 days if eligible (the true RD treatment effect we want to recover).
duration = 60 + 0.4 * (score - 50) - 5 * eligible
# Add independent random noise
duration = duration + rng.normal(0, 8, 1000)

# Build the case-level table: an id, the score, and the (noisy) duration.
cases = pd.DataFrame({
    "case_id": [f"C{i:04d}" for i in range(1, 1001)],
    "score": score,
    "duration_days": duration
})
# Sanity check:
assert not cases.duplicated("case_id").any()
assert cases["score"].between(30, 70).all()

# Adding some noise to delays_days (missing or sentinel-coded outcome)

u = rng.uniform(size=len(panel))
panel.loc[u < 0.03, "delay_days"] = np.nan
panel.loc[(u >= 0.03) & (u < 0.05), "delay_days"] = -99

# Adding some noise to duration_days (missing or sentinel-coded outcome)
u = rng.uniform(size=len(cases))
cases.loc[u < 0.03, "duration_days"] = np.nan
cases.loc[(u >= 0.03) & (u < 0.05), "duration_days"] = -99

# Add stray leading/trailing spaces around ids, a common messy-data

panel["district_id"] = " " + panel["district_id"] + " "
cases["case_id"] = " " + cases["case_id"] + " "

# add some duplicates

panel = pd.concat([panel, panel.iloc[:4]], ignore_index=True)
cases = pd.concat([cases, cases.iloc[:5]], ignore_index=True)

# Save Data 
lookup.to_csv(raw / "districts.csv", index=False)
panel.to_csv(raw / "district_panel.csv", index=False)
cases.to_csv(raw / "cases.csv", index=False)
print("Saved three synthetic raw files.")
