# Gameplay compatibility: legacy vGambler vs. current vGambler

## Scope and method

This is a static code audit of the playable lifecycle in
`OldReference/vGambler/vGambler.lua` against the current implementation in
`Elements/Game.lua`, `Elements/Comms.lua`, `Elements/Interface.lua`, and
`Elements/Settings.lua`. It follows the host-visible flow from opening a game
through settlement. It does not claim an in-client World of Warcraft test;
that remains necessary because chat and system-roll events are game APIs.

“Same” below means the externally visible legacy rules and controls, not merely
that the current implementation can finish a game.

## Legacy gameplay contract

### 1. Configure and start

1. The legacy defaults are a **1,000 gold** maximum roll and **Raid** chat.
   Party, Raid, and Guild are supported.
2. Pressing **New Game** only resets first when the previous `Rolls` table is
   non-empty. It announces:

   > `vGambler: New game started! Current roll is for <wager>g, type 1 to enter (-1 to leave).`

3. The host registers the selected channel's chat events and enables Last Call,
   Roll, Reset Game, and Enter.

### 2. Read entry and withdrawal chat

While entry is open, the host listens only to the selected channel (including
Party/Raid leader variants). It strips the realm suffix from the sender.

- Exact message `1`: if the sender is banned, announce the ban (and optional
  reason). Otherwise add that sender once; duplicate `1` messages do nothing.
- Exact message `-1`: remove the first matching entrant; a message from a
  non-entrant does nothing.
- All other messages are ignored.

The host can enter through **Enter**, which sends `1` to the same channel.

### 3. Last call and close entries

- **Last Call** announces the last call once and disables itself.
- **Roll** with fewer than two entrants announces “Not enough players!” and
  continues accepting entries.
- With at least two entrants, **Roll** unregisters entry chat, registers
  `CHAT_MSG_SYSTEM`, announces that the game is closed, and enables the host's
  Self Roll button only if the host entered.
- The same **Roll** control remains usable while rolling. Pressing it again
  sends one chat line for every entrant who has not rolled.

### 4. Track rolls

The host parses a system roll in the form represented by
`RANDOM_ROLL_RESULT`: player name, result, minimum, and maximum. A roll counts
only when:

- its range is exactly `1` through the configured wager;
- its player name is in the entrant list; and
- that entrant has not already produced an accepted roll.

Thus wrong-range rolls, non-entrants, and second rolls are ignored. When every
entrant has one accepted roll, resolution is automatic.

### 5. Resolve and reset

The rolls are sorted descending. The first row is the winner, the last is the
loser, and the loser owes the winner `high - low` gold. The result is announced
in the selected chat and the same amount is applied to general and pairwise
statistics. The legacy implementation has **no explicit tie handling**:
equal extreme rolls are resolved according to the table sort's resulting
order and can produce a zero-gold settlement.

Resolution automatically empties both player and roll tables and unlocks the
game. It does not restore all button states; the user can press **New Game** to
start the next round. Manual **Reset Game** clears the tables, unregisters all
of the frame's events, prints a local reset message, and disables the gameplay
buttons.

## Current gameplay walkthrough

### 1. Configure and start

The current defaults are **10 gold**, **Party**, entry command `1`, and leave
command `0`. The UI permits Party, Raid, Guild, and a local Test mode. A normal
start rejects any selection that does not map to a supported chat event group,
then captures the host, channel, and wager for the life of the game. This
capture correctly prevents mid-game setting changes from redirecting later
messages or changing the valid roll range.

The current announcement uses the configured entry and leave commands. The
host registers entry chat, locks host settings, enables Last Call/Reset/Close,
and sends a `NewGame` addon message so other current-addon clients can mirror
the UI.

### 2. Read entry and withdrawal chat

Host-side chat handling preserves the core legacy filters: exact configured
command, selected channel, realm suffix removal, ban rejection, duplicate
suppression, and harmless withdrawal by a non-entrant. Accepted changes are
broadcast as addon `AddPlayer`/`RemovePlayer` events. Consequently:

- players do not need the addon to enter or roll; ordinary chat/system roll
  messages remain authoritative at the host;
- current-addon clients can mirror the roster and button state; and
- only the host processes entry chat after a synchronized `NewGame` (receivers
  rely on host addon events rather than independently accepting entries).

The Join and Withdraw buttons send the local client's configured commands to
the captured channel and update their button state immediately.

### 3. Last call and close entries

Last Call and the fewer-than-two-player behavior match the legacy chat flow.
With two or more entrants, Close unregisters entry chat, registers system-roll
chat, announces closure, broadcasts `CloseGame`, and enables Roll for an
entered local player. Every current-addon receiver also registers system-roll
chat, so its display can track rolls independently.

### 4. Track rolls

The accepted-roll predicates match the legacy version: exact `1..wager` range,
known entrant, and only the entrant's first valid roll. The host sorts and
resolves only when all entrants have rolled; non-host clients update their
roster locally and wait for the host's result event.

### 5. Resolve ties, results, and statistics

The current version adds explicit result rules:

- a unique high and unique low settle for `high - low`;
- tied highs reroll to select the winner;
- tied lows reroll to select the loser;
- if everyone has the same roll in the initial round, the game is a draw; and
- tie rounds repeat until both extremes are unique.

The host announces the result, records history and expanded statistics, and
broadcasts the result payload. Receiving addon clients account the same result.
The completed roster remains visible and the host must use Reset before Start
is enabled again.

## Compatibility matrix

| Stage | Legacy behavior retained? | Assessment |
| --- | --- | --- |
| Start announcement | Same purpose and chat transport; current text reflects configurable commands | Compatible when configured to legacy values |
| Supported live channels | Party, Raid, Guild | Match |
| Entry | Exact `1`, ban check, de-duplicate, strip realm | Match with default settings |
| Withdrawal | Exact `-1` | **Default mismatch** (`0` now) |
| Minimum entrants | Two | Match |
| Close announcement | Announces closure and asks players to roll | Match |
| Missing-roll reminder | Reusing Roll/Close announces missing players | **UI regression** |
| Roll acceptance | Entrant's first `1..wager` system roll only | Match |
| Automatic resolution | After every entrant rolls | Match |
| Payout | Highest minus lowest | Match for unique extremes |
| Ties/draws | No special rule; possible zero payout | **Intentional rule change** |
| Post-result next game | Roster clears automatically; New Game remains usable | **Workflow mismatch** |
| Non-addon players | Can enter and roll via normal chat | Match |
| Addon synchronization | Not present in legacy | New enhancement, with risks below |

## Problems and correction decisions

### P0 — remote `NewGame` messages can replace an active synchronized game

`CHAT_MSG_ADDON` deliberately exempts every `NewGame` from the current-host
sender check. `Events.NewGame` then unconditionally wipes the receiver's roster
and replaces `Host`, `GameChannel`, and `GameWager`. A second addon user starting
a game in the same Party/Raid/Guild can therefore hijack clients that are
already observing another game. The original host remains internally correct,
but affected player clients display and interact with the wrong game.

**Suggested correction:** ignore `NewGame` while `Host` is already set (unless
it is an explicitly supported replacement/reset protocol), and consider adding
a match identifier to every addon event.

### P1 — the legacy missing-roll reminder is unreachable from the current UI

`CloseGame` still contains the locked-game reminder branch, but the current
implementation disables **Close** as soon as rolling starts. Legacy kept its
Roll control enabled, allowing the host to press it again and name each missing
roller. The current host has no normal button path to that branch.

**Suggested correction:** leave Close enabled during rolling (possibly relabel
it “Remind”), or add a dedicated reminder control. Add a test that closes a
three-player game, accepts two rolls, invokes the control, and verifies that the
third display name appears in chat.

### P1 — default withdrawal protocol is not legacy-compatible

Legacy announces and accepts `-1`; current defaults announce and accept `0`.
This is self-consistent for a fresh current installation, but it does not “work
exactly the same,” and players following the old convention cannot withdraw.
Saved settings can also make different clients' optimistic Join/Withdraw
buttons send commands that disagree with the host, because addon `NewGame`
synchronizes channel and wager but not entry/leave commands.

**Suggested correction:** restore `-1` as the leave default. Put the host's entry
and leave commands in `NewGame`, store them as per-game values on receivers,
and make Join/Withdraw use those captured values.

### P1 — tie and draw semantics differ from legacy gameplay

The current tie breakers are clearer gameplay, but they are not behavioral
parity. Legacy would select sorted endpoints even when equal and could announce
zero gold; current code rerolls tied extrema and declares an all-equal opening
round a draw.

**Suggested correction:** make a product decision and document it. For strict
compatibility, remove tie/draw special cases. If the new rules are desired,
label this an intentional rules upgrade and test unique high, unique low,
winning tie, losing tie, repeated tie, and all-player draw paths.

### P2 — next-game workflow and reset visibility differ

Legacy resolution clears entrants and permits New Game directly. Current
resolution leaves the resolved roster in place and Start remains disabled until
Reset. This extra step is not necessarily wrong, but it is not the old process.
Also, the current Reset sends its reset text to group chat, whereas legacy
prints reset only locally.

**Suggested correction:** either restore automatic post-result cleanup and
Start availability, or explicitly retain the result screen and provide a
“Next Game” action that performs Reset plus Start. Decide whether group-visible
reset announcements are wanted.

### P2 — default wager and channel changed

Legacy starts at 1,000/Raid; current starts at 10/Party. This changes the first
run but not the state machine.

**Suggested correction:** restore the legacy defaults if exact out-of-box
compatibility is required. Otherwise treat them as intentional UX defaults and
call them out in release notes.

### P2 — short-name normalization can collide in cross-realm groups

Both versions discard realm suffixes. Two players with the same character name
from different realms collapse into one entrant, and roll matching cannot
reliably distinguish them. The new version receives GUIDs but still keys active
players by the shortened name.

**Suggested correction:** retain a stable full name or GUID as identity, retain
a display name separately, and normalize system-roll names using the same
strategy. This is inherited rather than newly introduced, but it prevents the
new version from being reliably equivalent in modern cross-realm groups.

### P3 — `PlayerRoll` synchronization is implemented but never emitted

Receivers currently observe `CHAT_MSG_SYSTEM` directly, so normal group play can
still work. However, the addon protocol defines a `PlayerRoll` receiver without
any corresponding send call. If a receiver misses/suppresses system messages,
its progress display remains stale until the authoritative result arrives.

**Suggested correction:** have the host emit `PlayerRoll` after accepting each
roll, or remove the unused event and explicitly document system chat as the
only roll replication mechanism. A host-emitted event is more consistent with
host-authoritative entry and resolution.

## Acceptance checklist for an in-game parity test

Use two addon clients plus one client without vGambler where possible.

1. Select Party, wager 1,000, entry `1`, leave `-1`; start and verify the exact
   channel and announced values.
2. Send unrelated chat, wrong-case/whitespace variants, duplicate joins, an
   absent-player withdrawal, a valid withdrawal/rejoin, and a banned join.
3. Close with zero and one entrant; verify rejection without losing entry
   listening. Close with two or more; verify later entry/withdraw messages are
   ignored.
4. Roll from a non-entrant, roll the wrong range, and roll twice; verify none can
   replace the one accepted roll.
5. Leave one entrant unrolled and verify the host can announce that name.
6. Complete unique-extreme, high-tie, low-tie, repeated-tie, and all-equal games;
   compare announcements, payout, history, and all clients' statistics against
   the chosen legacy-or-new tie policy.
7. Start a competing game from another addon client during step 4 and verify it
   cannot replace the active game.
8. Change local settings after start and verify the captured host channel,
   wager, and commands remain authoritative.
9. Resolve, then verify the intended one-click New Game or explicit Next Game
   workflow and that no old entrant or roll leaks into the next match.
10. Repeat with two same-named characters from different realms.

## Conclusion

The current implementation preserves the central host workflow for unique
rolls: announce, accept exact chat commands, de-duplicate entrants, close at two
players, accept one correctly ranged system roll per entrant, and settle high
minus low. It is **not exactly legacy-equivalent** yet. The most actionable
regression is the inaccessible missing-roll reminder; the most serious new
multi-client risk is active-game replacement by another `NewGame`; and the
withdraw command, tie rules, next-game flow, and defaults require explicit
compatibility decisions.
