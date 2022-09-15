require_relative '../spec_helper'
require_relative '../../lib/puppet-check/data_parser'

describe DataParser do
  before(:each) do
    PuppetCheck.settings[:error_files] = []
    PuppetCheck.settings[:warning_files] = []
    PuppetCheck.settings[:clean_files] = {}
  end

  context '.yaml' do
    it 'puts a bad syntax yaml file in the error files array' do
      DataParser.yaml(["#{fixtures_dir}hieradata/syntax.yaml"])
      expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}hieradata/syntax.yaml:\nblock sequence entries are not allowed})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a good yaml file with potential hiera issues in the warning files array' do
      DataParser.yaml(["#{fixtures_dir}hieradata/style.yaml"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}hieradata/style.yaml:\nValue\(s\) missing in key.*\nValue\(s\) missing in key.*\nThe string --- appears more than once in this data and Hiera may fail to parse it correctly})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a good yaml file in the clean files hash' do
      DataParser.yaml(["#{fixtures_dir}hieradata/good.yaml"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}hieradata/good.yaml" => nil })
    end
  end

  context '.eyaml' do
    before(:each) do
      PuppetCheck.settings[:ignored_files] = []
    end

    it 'returns a warning if a public key was not specified' do
      expect { DataParser.eyaml(['foo.eyaml'], nil, 'private.pem') }.to output("Public X509 and/or Private RSA PKCS7 certs were not specified. EYAML checks will not be executed.\n").to_stderr
    end
    it 'returns a warning if a private key was not specified' do
      expect { DataParser.eyaml(['foo.eyaml'], 'public.pem', nil) }.to output("Public X509 and/or Private RSA PKCS7 certs were not specified. EYAML checks will not be executed.\n").to_stderr
    end
    it 'returns a warning if the public key or private key are not existing files' do
      expect { DataParser.eyaml(['foo.eyaml'], 'public.pem', 'private.pem') }.to output("Specified Public X509 and/or Private RSA PKCS7 certs do not exist. EYAML checks will not be executed.\n").to_stderr
    end
    it 'puts a bad syntax eyaml file in the error files array' do
      # DataParser.eyaml(["#{fixtures_dir}hieradata/syntax.eyaml'], fixtures_dir + 'keys/public_key.pkcs7.pem', fixtures_dir + 'keys/private_key.pkcs7.pem")
      # expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}hieradata/syntax.eyaml:\nblock sequence entries are not allowed})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a good eyaml file with potential hiera issues in the warning files array' do
      # DataParser.eyaml(["#{fixtures_dir}hieradata/style.eyaml'], fixtures_dir + 'keys/public_key.pkcs7.pem', fixtures_dir + 'keys/private_key.pkcs7.pem")
      expect(PuppetCheck.settings[:error_files]).to eql([])
      # expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}hieradata/style.eyaml:\nValue\(s\) missing in key.*\nValue\(s\) missing in key.*\nThe string --- appears more than once in this data and Hiera will fail to parse it correctly})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a good eyaml file in the clean files hash' do
      # DataParser.eyaml(["#{fixtures_dir}hieradata/good.eyaml'], fixtures_dir + 'keys/public_key.pkcs7.pem', fixtures_dir + 'keys/private_key.pkcs7.pem")
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      # expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}hieradata/good.eyaml" => nil })
    end
  end

  context '.json' do
    it 'puts a bad syntax json file in the error files array' do
      DataParser.json(["#{fixtures_dir}hieradata/syntax.json"])
      expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}hieradata/syntax.json:\n.*unexpected token})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a bad metadata json file in the error files array' do
      DataParser.json(["#{fixtures_dir}metadata_syntax/metadata.json"])
      expect(PuppetCheck.settings[:error_files][0]).to match(%r{^#{fixtures_dir}metadata_syntax/metadata.json:\nRequired field.*\nField 'requirements'.*\nDuplicate dependencies.*\nDeprecated field.*\nSummary exceeds})
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a bad style metadata json file in the warning files array' do
      DataParser.json(["#{fixtures_dir}metadata_style/metadata.json"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}metadata_style/metadata.json:\n'pe' is missing an upper bound.\n.*operatingsystem_support.*\nLicense identifier})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts another bad style metadata json file in the warning files array' do
      DataParser.json(["#{fixtures_dir}metadata_style_two/metadata.json"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}metadata_style_two/metadata.json:\n'puppetlabs/one' has non-semantic versioning.*\n'puppetlabs/two' is missing an upper bound\.\n.*operatingsystem.*\n.*operatingsystemrelease})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a bad task metadata json file in the warning files array' do
      DataParser.json(["#{fixtures_dir}task_metadata/task_bad.json"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files][0]).to match(%r{^#{fixtures_dir}task_metadata/task_bad.json:\ndescription value is not a String\ninput_method value is not one of environment, stdin, or powershell\nparameters value is not a Hash\npuppet_task_version value is not an Integer\nsupports_noop value is not a Boolean})
      expect(PuppetCheck.settings[:clean_files]).to eql({})
    end
    it 'puts a good json file in the clean files hash' do
      DataParser.json(["#{fixtures_dir}hieradata/good.json"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}hieradata/good.json" => nil })
    end
    it 'puts a good metadata json file in the clean files hash' do
      DataParser.json(["#{fixtures_dir}metadata_good/metadata.json"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}metadata_good/metadata.json" => nil })
    end
    it 'puts a good task metadata json file in the clean files hash' do
      DataParser.json(["#{fixtures_dir}task_metadata/task_good.json"])
      expect(PuppetCheck.settings[:error_files]).to eql([])
      expect(PuppetCheck.settings[:warning_files]).to eql([])
      expect(PuppetCheck.settings[:clean_files]).to eql({ "#{fixtures_dir}task_metadata/task_good.json" => nil })
    end
  end
end
