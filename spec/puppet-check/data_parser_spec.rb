require_relative '../spec_helper'
require_relative '../../lib/puppet-check/data_parser'

describe DataParser do
  before(:each) do
    PuppetCheck.files = {
      errors: {},
      warnings: {},
      clean: [],
      ignored: []
    }
  end

  context '.yaml' do
    it 'puts a bad syntax yaml file in the error files hash' do
      DataParser.yaml(["#{FIXTURES_DIR}hieradata/syntax.yaml"])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}hieradata/syntax.yaml"])
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}hieradata/syntax.yaml"].join("\n")).to match(/^block sequence entries are not allowed/)
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a good yaml file with potential hiera issues in the warning files array' do
      DataParser.yaml(["#{FIXTURES_DIR}hieradata/style.yaml"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}hieradata/style.yaml"])
      expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}hieradata/style.yaml"].join("\n")).to match(/^Value\(s\) missing in key.*\nValue\(s\) missing in key.*\nThe string --- appears more than once in this data and Hiera may fail to parse it correctly/)
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a good yaml file in the clean files array' do
      DataParser.yaml(["#{FIXTURES_DIR}hieradata/good.yaml"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}hieradata/good.yaml"])
    end
  end

  context '.eyaml' do
    it 'returns a warning if a public key was not specified' do
      expect { DataParser.eyaml(['foo.eyaml'], nil, 'private.pem') }.to output("Public X509 and/or Private RSA PKCS7 certs were not specified. EYAML checks will not be executed.\n").to_stderr
    end
    it 'returns a warning if a private key was not specified' do
      expect { DataParser.eyaml(['foo.eyaml'], 'public.pem', nil) }.to output("Public X509 and/or Private RSA PKCS7 certs were not specified. EYAML checks will not be executed.\n").to_stderr
    end
    it 'returns a warning if the public key or private key are not existing files' do
      expect { DataParser.eyaml(['foo.eyaml'], 'public.pem', 'private.pem') }.to output("Specified Public X509 and/or Private RSA PKCS7 certs do not exist or are not readable. EYAML checks will not be executed.\n").to_stderr
    end
    it 'puts a bad syntax eyaml file in the error files hash' do
      DataParser.eyaml(["#{FIXTURES_DIR}hieradata/syntax.eyaml"], "#{FIXTURES_DIR}keys/public_key.pkcs7.pem", "#{FIXTURES_DIR}keys/private_key.pkcs7.pem")
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}hieradata/syntax.eyaml"])
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}hieradata/syntax.eyaml"].join("\n")).to match(/^block sequence entries are not allowed/)
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a good eyaml file with potential hiera issues in the warning files array' do
      DataParser.eyaml(["#{FIXTURES_DIR}hieradata/style.eyaml"], "#{FIXTURES_DIR}keys/public_key.pkcs7.pem", "#{FIXTURES_DIR}keys/private_key.pkcs7.pem")
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}hieradata/style.eyaml"])
      expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}hieradata/style.eyaml"].join("\n")).to match(/^Value\(s\) missing in key.*\nValue\(s\) missing in key.*\nThe string --- appears more than once in this data and Hiera may fail to parse it correctly/)
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a good eyaml file in the clean files array' do
      DataParser.eyaml(["#{FIXTURES_DIR}hieradata/good.eyaml"], "#{FIXTURES_DIR}keys/public_key.pkcs7.pem", "#{FIXTURES_DIR}keys/private_key.pkcs7.pem")
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}hieradata/good.eyaml"])
    end
    it 'puts an eyaml file with an undecryptable PKCS7 payload in the error files hash; distinctly from a YAML syntax error' do
      DataParser.eyaml(["#{FIXTURES_DIR}hieradata/decrypt_error.eyaml"], "#{FIXTURES_DIR}keys/public_key.pkcs7.pem", "#{FIXTURES_DIR}keys/private_key.pkcs7.pem")
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}hieradata/decrypt_error.eyaml"])
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}hieradata/decrypt_error.eyaml"].join("\n")).to match(/PKCS7/i)
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}hieradata/decrypt_error.eyaml"].join("\n")).not_to match(/^block sequence entries are not allowed/)
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'decrypts an ENC[PKCS7,...] value nested inside an array of hashes and puts the file in the clean files array' do
      DataParser.eyaml(["#{FIXTURES_DIR}hieradata/nested_array.eyaml"], "#{FIXTURES_DIR}keys/public_key.pkcs7.pem", "#{FIXTURES_DIR}keys/private_key.pkcs7.pem")
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}hieradata/nested_array.eyaml"])
    end
  end

  context '.decrypt_eyaml' do
    before(:all) do
      require 'openssl'
      require 'base64'
    end

    let(:rsa) { OpenSSL::PKey::RSA.new(File.read("#{FIXTURES_DIR}keys/private_key.pkcs7.pem")) }
    let(:x509) { OpenSSL::X509::Certificate.new(File.read("#{FIXTURES_DIR}keys/public_key.pkcs7.pem")) }

    # encrypts a plaintext value against the fixture cert and wraps it as eyaml expects
    def encrypt(plaintext)
      pkcs7 = OpenSSL::PKCS7.encrypt([x509], plaintext, OpenSSL::Cipher.new('AES-256-CBC'), OpenSSL::PKCS7::BINARY)
      "ENC[PKCS7,#{Base64.strict_encode64(pkcs7.to_der)}]"
    end

    it 'decrypts a single ENC[PKCS7,...] string to its original plaintext' do
      expect(DataParser.send(:decrypt_eyaml, encrypt('puppetcheck'), rsa, x509)).to eql('puppetcheck')
    end
    it 'leaves a plain non-ENC string untouched' do
      expect(DataParser.send(:decrypt_eyaml, 'plaintext value', rsa, x509)).to eql('plaintext value')
    end
    it 'leaves a string that merely resembles but does not fully match the ENC[PKCS7,...] pattern untouched' do
      expect(DataParser.send(:decrypt_eyaml, 'prefix ENC[PKCS7,abc] suffix', rsa, x509)).to eql('prefix ENC[PKCS7,abc] suffix')
    end
    it 'recurses into hash values and decrypts them, while never decrypting hash keys' do
      encrypted = encrypt('secret-value')
      result = DataParser.send(:decrypt_eyaml, { encrypted => 'plain-key-value', 'plain-key' => encrypted }, rsa, x509)
      expect(result.keys).to eql([encrypted, 'plain-key'])
      expect(result[encrypted]).to eql('plain-key-value')
      expect(result['plain-key']).to eql('secret-value')
    end
    it 'recurses into array elements and decrypts them' do
      expect(DataParser.send(:decrypt_eyaml, ['plain', encrypt('array-secret')], rsa, x509)).to eql(['plain', 'array-secret'])
    end
    it 'recurses through nested hash/array/hash structures' do
      expect(DataParser.send(:decrypt_eyaml, { 'list' => [{ 'inner' => encrypt('nested-secret') }] }, rsa, x509)).to eql({ 'list' => [{ 'inner' => 'nested-secret' }] })
    end
    it 'returns non-string/hash/array scalars unchanged' do
      expect(DataParser.send(:decrypt_eyaml, 42, rsa, x509)).to eql(42)
      expect(DataParser.send(:decrypt_eyaml, nil, rsa, x509)).to be_nil
      expect(DataParser.send(:decrypt_eyaml, true, rsa, x509)).to be true
    end
  end

  context '.json' do
    it 'puts a bad syntax json file in the error files hash' do
      DataParser.json(["#{FIXTURES_DIR}hieradata/syntax.json"])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}hieradata/syntax.json"])
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}hieradata/syntax.json"].join("\n")).to match(/after object value, got.*at line 3 column 3/)
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad metadata json file in the error files hash' do
      DataParser.json(["#{FIXTURES_DIR}metadata_syntax/metadata.json"])
      expect(PuppetCheck.files[:errors].keys).to eql(["#{FIXTURES_DIR}metadata_syntax/metadata.json"])
      expect(PuppetCheck.files[:errors]["#{FIXTURES_DIR}metadata_syntax/metadata.json"].join("\n")).to match(/^Required field.*\nField 'requirements'.*\nDuplicate dependencies.*\nDeprecated field.*\nSummary exceeds/)
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad style metadata json file in the warning files array' do
      DataParser.json(["#{FIXTURES_DIR}metadata_style/metadata.json"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}metadata_style/metadata.json"])
      expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}metadata_style/metadata.json"].join("\n")).to match(/^'pe' is missing an upper bound.\n.*operatingsystem_support.*\nLicense identifier/)
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts another bad style metadata json file in the warning files array' do
      DataParser.json(["#{FIXTURES_DIR}metadata_style_two/metadata.json"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}metadata_style_two/metadata.json"])
      expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}metadata_style_two/metadata.json"].join("\n")).to match(%r{^'puppetlabs/one' has non-semantic versioning.*\n'puppetlabs/two' is missing an upper bound\.\n.*operatingsystem.*\n.*operatingsystemrelease})
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a bad task metadata json file in the warning files array' do
      DataParser.json(["#{FIXTURES_DIR}task_metadata/task_bad.json"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings].keys).to eql(["#{FIXTURES_DIR}task_metadata/task_bad.json"])
      expect(PuppetCheck.files[:warnings]["#{FIXTURES_DIR}task_metadata/task_bad.json"].join("\n")).to match(/^description value is not a String\ninput_method value is not one of environment, stdin, or powershell\nparameters value is not a Hash\npuppet_task_version value is not an Integer\nsupports_noop value is not a Boolean/)
      expect(PuppetCheck.files[:clean]).to eql([])
    end
    it 'puts a good json file in the clean files array' do
      DataParser.json(["#{FIXTURES_DIR}hieradata/good.json"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}hieradata/good.json"])
    end
    it 'puts a good metadata json file in the clean files array' do
      DataParser.json(["#{FIXTURES_DIR}metadata_good/metadata.json"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}metadata_good/metadata.json"])
    end
    it 'puts a good task metadata json file in the clean files array' do
      DataParser.json(["#{FIXTURES_DIR}task_metadata/task_good.json"])
      expect(PuppetCheck.files[:errors]).to eql({})
      expect(PuppetCheck.files[:warnings]).to eql({})
      expect(PuppetCheck.files[:clean]).to eql(["#{FIXTURES_DIR}task_metadata/task_good.json"])
    end
  end
end