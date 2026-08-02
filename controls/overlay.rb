# Debian 12 overlay of the Canonical Ubuntu 22.04 LTS STIG baseline.
#
# All controls from the upstream profile are included as-is except the spot
# overrides below, which implement the dispositions ruled on the 1fx.3 audit
# card (see its notes for the full control-status table and decision record).
#
# A control block inside include_controls REPLACES the upstream control's
# checks (verified empirically), so a control is only overlaid when its
# behavior on Debian must actually differ; anything that would merely add
# commentary runs pure upstream, with the nuance documented in the README
# (see "FIPS 140 on Debian" for the FIPS-family controls SV-260531,
# SV-260532, SV-260533, and SV-260572, which verify approved-algorithm
# configuration and run unmodified here).
include_controls 'canonical-ubuntu-22.04-lts-stig-baseline' do
  # SV-260650: the requirement is NIST FIPS-*validated* cryptography. On
  # Ubuntu, fips_enabled=1 implies the Ubuntu Pro validated module stack; on
  # Debian the same flag is reachable with stock, uncertified builds, so the
  # upstream proxy check would pass misleadingly. Ruling (ported from
  # debian-11's SV-238363): keep the kernel check as posture evidence and ADD
  # an assertion that always fails on Debian — a deliberate standing CAT I
  # finding so this profile never presents an uncertified platform as
  # FIPS-validated.
  control 'SV-260650' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    describe kernel_parameter('crypto.fips_enabled') do
      its('value') { should eq 1 }
    end

    describe 'NIST FIPS-validated cryptographic modules' do
      it 'are available and in use on this platform' do
        expect(false).to eq(true), 'Debian provides no CMVP/NIST-validated cryptographic modules. A fips=1 kernel and approved-algorithm configuration establish a FIPS-capable posture at best; they do not constitute the FIPS-validated cryptography this requirement mandates (see README, "FIPS 140 on Debian"). This is a permanent finding on Debian — deployments operating under a FIPS mandate need a documented waiver/risk acceptance or a platform with validated modules.'
      end
    end
  end

  # SV-278951: the upstream control verifies Ubuntu 22.04's identity and
  # support lifecycle (standard support -> Ubuntu Pro ESM). Rewritten for
  # Debian 12's identity and published lifecycle: Debian LTS covers bookworm
  # through 2028-06-30 (free, part of the regular archive); beyond that,
  # Extended LTS (Freexian ELTS, commercial) runs through 2033-06-30 via its
  # own apt repository — the Debian analog of the upstream's `pro status`
  # subscription branch.
  control 'SV-278951' do
    only_if('This control is Not Applicable to containers', impact: 0.0) {
      !%w[docker podman kubepods lxc].include?(virtualization.system)
    }

    describe 'Debian release identity' do
      subject { os }
      its('name') { should eq 'debian' }
      its('release') { should match(/^12(\.|$)/) }
    end

    lts_eol = Time.new(2028, 6, 30, 23, 59, 59, '+00:00')
    elts_eol = Time.new(2033, 6, 30, 23, 59, 59, '+00:00')
    now = Time.now.utc

    if now <= lts_eol
      describe 'Debian 12 support lifecycle' do
        it 'is within the Debian LTS window' do
          expect(now <= lts_eol).to be true
        end
      end
    elsif now <= elts_eol
      # Beyond free LTS; vendor support requires the commercial Freexian
      # Extended LTS repository to be configured.
      elts_sources = command('grep -rsiE "deb\\.freexian\\.com/extended-lts|extended-lts" /etc/apt/sources.list /etc/apt/sources.list.d/ 2>/dev/null')

      describe 'Debian 12 Extended LTS (Freexian) apt source' do
        subject { elts_sources.stdout.strip }
        it 'is configured, providing vendor security support beyond the Debian LTS window' do
          expect(subject).to_not be_empty, "Debian LTS for bookworm ended #{lts_eol.strftime('%Y-%m-%d')}; no Extended LTS (Freexian) apt source found, so this release no longer receives vendor security support."
        end
      end
    else
      describe 'Debian 12 support lifecycle' do
        it 'is within a vendor support window' do
          expect(now <= elts_eol).to be true, "All security support for Debian 12 (including Extended LTS) ended #{elts_eol.strftime('%Y-%m-%d')}; current date: #{now.strftime('%Y-%m-%d')}. Upgrade to a supported Debian release."
        end
      end
    end
  end
end
