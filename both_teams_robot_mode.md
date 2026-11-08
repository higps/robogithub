# Both-Team Robot Mode

Select `sm_manned_machines_mode 3`. The `sm_boss_mode` command still starts and
stops the selected mode. The existing automatic volunteer selection also works.

## Allocation

`both_team_has_robots_ratio` defaults to `3`. Each team's player count triggers
the following slot count, rather than plain `ceil(players / 3)`:

| Players on a team | Robot slots |
| --- | --- |
| 0 | 0 |
| 1-3 | 1 |
| 4-5 | 2 |
| 6-8 | 3 |
| 9-11 | 4 |
| 12-14 | 5 |

For a configurable ratio, a nonempty team up to that ratio targets one robot;
larger teams target `floor(players / ratio) + 1`, capped at their player count.
Six players on each side therefore target three robots and three humans each.

Both teams receive the larger of the two triggered targets: either team crossing
a threshold raises the target on both sides (OR logic). RED with four players
and BLU with three therefore target two robots each. The shared target is capped
at the smaller team's population; if either team is empty, both target zero.

Startup balances playing clients across RED and BLU, placing selected volunteers
first, then enforcing equal assigned robot counts. Spectators are not drafted. During
play, RED/BLU populations are rebalanced to differ by at most one, preferring
human transfers. Existing robot assignments are redistributed toward an even
split before filling vacancies. Joining volunteers fill the side with room and fewer assigned robots;
cross-team volunteer placement swaps a human the other way to preserve team
sizes. Unvolunteering makes the player human on their current side.

Initial selection and vacancy filling use volunteers only. When counts are equal,
new assignments are made in volunteer pairs. An odd volunteer remains human and
queued until a partner is available. If an existing robot leaves and no volunteer
can fill the other side, an unmatched robot returns to human to restore equality.
Its volunteering preference remains available for future selection.

Thus assigned robot counts are equal, and human counts differ by at most one
because total team populations differ by at most one. If insufficient players
volunteer, symmetric robot slots remain open. Per-team targets are refreshed on
spawns, team changes, round starts, volunteer changes, disconnects, and ratio changes. Excess
assigned robots become human when their team's target falls.

## Integration

- The controller owns this mode's per-team targets. The standard dynamic-count
  plugin does not overwrite them.
- Leaving mode 3 restores the standard dynamic-ratio target before a new
  volunteer selection, or restores the saved fixed cap if dynamic counting is
  disabled. Mode-3 slot targets cannot leak into standard startup.
- `GetRobotCountPerTeam` remains the combined slot target for the volunteer UI.
- `GetRobotTeam` returns Unassigned during active mode 3 because there is no
  single robot side. Humans and robots are distinguished by volunteer role and
  robot tracking, not their RED/BLU team.
- Volunteer eligibility stays inside the controller and is checked before its
  selection paths call `CreateRobot`, using the existing `SetRobot` and
  `ForceRobot` APIs. No additional native is needed in `berobot_core.inc`.
  Direct low-level `CreateRobot` calls retain the factory's existing permissions
  and bypass this controller-local check.
- Cross-team creation permission is temporarily enabled for modes 2 and 3,
  with its previous value restored on exit or controller unload.
- Existing per-robot-type limits remain global; this change does not make
  duplicate-robot caps independent per team.
- Legacy reporting plugins that assume one robot team need separate adaptation
  before their mode-3 team statistics can be considered accurate.

## Deployment And Verification

Rebuild and deploy `berobot_mode_controller`, `berobot_factory`,
`berobot_volunteer`, and `berobot_dynamicRobotCount` together. No new native in
`include/berobot_core.inc` is required. Do not load the archived original handler
alongside the controller.

The controller compiles with SourcePawn 1.11, with warnings. Arithmetic checks
cover the requested robot-target boundaries, OR threshold crossings, and all
volunteer counts for balanced populations up to 24 players. These are not
live-server gameplay tests or proof of successful robot equipment creation.

Standard-mode source checks confirm that its initial draft fallback, single-team
creation restriction, spawn enforcement, and global per-robot limits remain in
their existing paths. A transition regression check verifies that 24 players
switch from ten mode-3 slots back to six standard slots with the default ratios.

Live checks still required: initial volunteer selection, insufficient
volunteers, new volunteers and unvolunteering, spectators and reconnects,
ratio increases/decreases, team swaps, named robot picks on both teams, coin
awards and purchases, and start/stop and transitions back to standard or April.