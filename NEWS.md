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
