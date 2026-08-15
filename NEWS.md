# peeblestoolbox 0.3.0.9000

- Development version following the v0.3.0 release.

# peeblestoolbox 0.3.0

- Detect and remove leading UTF byte-order marks from warehouse column names
  and character values, with audit details and duplicate-name protection.
- Added conservative warehouse text profiling and cleaning helpers that audit
  changes and stop on invalid encodings by default.
- Added schema validation and dry-run load planning.
- Added an opt-in chunk writer that only appends to an existing table, requires
  exact column order, and reconciles row counts after loading.
- Warehouse loading helpers never create, drop, truncate, or replace tables.

# peeblestoolbox 0.2.0

- Added a national July 2023 OMB county-to-MSA lookup covering all 50 states,
  the District of Columbia, and Puerto Rico.
- Added `msa_counties()`, `add_msa()`, and `is_msa_county()` with support for
  cross-state MSAs, county GEOIDs, and multistate data.
- Added `peebles_state()` and `set_peebles_state()`; Georgia remains the
  default when no preference is configured.
- Added state-aware Census and boundary helpers while preserving all existing
  Georgia-specific functions for backward compatibility.
- Expanded the MSA output with metropolitan-division, combined-statistical-
  area, state, county GEOID, central/outlying, and delineation-date fields.
