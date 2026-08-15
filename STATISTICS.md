# Statistics accounting

vGambler distinguishes completed matches from the tie-break rounds that can occur
inside them:

- `games` counts resolved, non-draw matches. A player's `games` count includes
  every match they participated in, including draws.
- `draw` counts matches that ended without a winner or loser.
- `SessionGames` and the `sessiongames` maximum count resolved, non-draw matches
  observed during the current login session.
- `ties` counts tie-break rounds, not matches. Each tied participant also receives
  one player `ties` increment for every tie-break round they enter, so one match
  may add more than one tie.
- `tieswon` and `tieslost` count final match outcomes. They are incremented once
  for the winner and loser when a resolved match contained one or more tie-break
  rounds, regardless of how many tie-break rounds were required.

The host ignores its own addon result messages and accounts locally. Other clients
account the received events through the same routines, keeping saved aggregate and
player statistics identical for the same sequence of match events.
