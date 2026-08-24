include_controls 'canonical-ubuntu-22.04-lts-stig-baseline' do
  # SV-260650: Debian ships no FIPS-validated modules, so this keeps the
  # kernel-flag evidence but always fails; see README, "FIPS 140 on Debian".
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

  # SV-278951: rewritten for Debian 12's identity and published lifecycle —
  # free Debian LTS to 2028-06-30, then Freexian Extended LTS to 2033-06-30.
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
      # Past free LTS: vendor support requires the commercial Freexian ELTS repo.
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
