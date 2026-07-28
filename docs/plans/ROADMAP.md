# Roadmap

Lightweight running list of future feature ideas — not detailed plans. When one of these is
picked up, give it a BRAVE breakdown card in `docs/plans/` instead.

- **Sort the leaderboard by games won.** Currently unsorted (insertion/id order). The system spec's
  `expect_row_stats` helper in `spec/system/leaderboards_spec.rb` was deliberately kept even after
  the test was reworked to look up rows by user name, so it's ready to reuse once sorting lands.
