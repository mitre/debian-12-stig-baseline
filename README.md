# debian-12-stig-baseline

STIG-ready InSpec validation baseline for Debian 12 (bookworm).

There is no DISA STIG for Debian. This profile is an overlay of the
[Canonical Ubuntu 22.04 LTS STIG baseline](https://github.com/mitre/canonical-ubuntu-22.04-lts-stig-baseline)
maintained by the MITRE SAF team, chosen because Ubuntu 22.04's component set
(OpenSSL 3.0, systemd 24x/25x era, matching PAM generation) is the closest
STIG-covered match to Debian 12. Ubuntu-specific checks are adapted or marked
not applicable for Debian in `controls/overlay.rb`.

This is **not** DISA-published content. It is a STIG-ready baseline mapped to
the same GPOS SRG requirements the Ubuntu STIG is derived from.

## Running

```sh
inspec exec . -t ssh://user@debian12-host --input-file inputs.yml --reporter cli json:results.json
```

## Overlay structure

- `inspec.yml` — profile metadata; declares the pinned upstream dependency
- `controls/overlay.rb` — `include_controls` of the upstream profile plus
  per-control Debian overrides
