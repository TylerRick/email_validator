require 'spec_helper'

class TestUser < TestModel
  validates :email, :email => true
end

class StrictUser < TestModel
  validates :email, :email => {:strict_mode => true}
end

class DomainUser < TestModel
  validates :email, email: {domain: 'example.com'}
end

class StrictDomainUser < TestModel
  validates :email, email: {domain: 'example.com', strict_mode: true}
end

class TestUserAllowsNil < TestModel
  validates :email, :email => {:allow_nil => true}
end

class TestUserAllowsNilFalse < TestModel
  validates :email, :email => {:allow_nil => false}
end

class TestUserWithMessage < TestModel
  validates :email_address, :email => {:message => 'is not looking very good!'}
end

describe EmailValidator do
  describe "validation" do
    valid_special_chars = {
      ampersand: '&',
      asterisk: '*',
      backtick: '`',
      braceleft: '{',
      braceright: '}',
      caret: '^',
      dollar: '$',
      equals: '=',
      exclaim: '!',
      hash: '#',
      hyphen: '-',
      percent: '%',
      plus: '+',
      pipe: '|',
      question: '?',
      quotedouble: '"',
      quotesingle: "'",
      slash: '/',
      tilde: '~',
      underscore: '_',
    }

    invalid_special_chars = {
      backslash: '\\',
      braketleft: '[',
      braketright: ']',
      colon: ':',
      comma: ',',
      greater: '>',
      lesser: '<',
      parenleft: '(',
      parenright: ')',
      semicolon: ';',
    }

    valid_includable            = valid_special_chars.merge( {dot: '.'} )
    valid_beginable             = valid_special_chars
    valid_endable               = valid_special_chars
    invalid_includable          = { at: '@', space: ' ' }
    strictly_invalid_includable = invalid_special_chars
    strictly_invalid_beginable  = strictly_invalid_includable.merge( {dot: '.'} )
    strictly_invalid_endable    = strictly_invalid_beginable
    domain_invalid_beginable    = invalid_special_chars.merge(valid_special_chars)
    domain_invalid_endable      = domain_invalid_beginable
    domain_invalid_includable   = domain_invalid_beginable.reject {|k,v| k == :hyphen }

    context "given the valid email" do
      valid_includable.map { |k,v| [
        "include-#{v}-#{k.to_s}@valid-characters-in-local.dev",
      ]}.concat(valid_beginable.map { |k,v| [
        "#{v}start-with-#{k.to_s}@valid-characters-in-local.dev",
      ]}).concat(valid_endable.map { |k,v| [
        "end-with-#{k.to_s}-#{v}@valid-characters-in-local.dev",
      ]}).concat([
        "a+b@plus-in-local.com",
        "a_b@underscore-in-local.com",
        "user@example.com",
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ@letters-in-local.dev",
        "01234567890@numbers-in-local.dev",
        "a@single-character-in-local.dev",
        "one-character-third-level@a.example.com",
        "single-character-in-sld@x.dev",
        "local@dash-in-sld.com",
        "numbers-in-sld@s123.com",
        "one-letter-sld@x.dev",
        "uncommon-tld@sld.museum",
        "uncommon-tld@sld.travel",
        "uncommon-tld@sld.mobi",
        "country-code-tld@sld.uk",
        "country-code-tld@sld.rw",
        "local@sld.newTLD",
        "local@sub.domains.com",
        "aaa@bbb.co.jp",
        "nigel.worthington@big.co.uk",
        "f@c.com",
        "f@s",
        "f@s.c",
        "user@localhost",
        "mixed-1234-in-{+^}-local@sld.dev",
        "partially.\"quoted\"@sld.com",
        "areallylongnameaasdfasdfasdfasdf@asdfasdfasdfasdfasdf.ab.cd.ef.gh.co.ca",
      ]).flatten.each do |email|
        it "#{email} should be valid" do
          expect(TestUser.new(:email => email)).to be_valid
        end

        it "#{email} should be valid in strict_mode" do
          expect(StrictUser.new(:email => email)).to be_valid
        end

        it "#{email} should be valid using EmailValidator.valid?" do
          expect(EmailValidator.valid?(email)).to be true
        end

        it "#{email} should be valid using EmailValidator.valid? in strict_mode" do
          expect(EmailValidator.valid?(email, strict_mode: true)).to be true
        end

        it "#{email} should not be invalid using EmailValidator.invalid?" do
          expect(EmailValidator.invalid?(email)).to be false
        end

        it "#{email} should not be invalid using EmailValidator.invalid? in strict_mode" do
          expect(EmailValidator.invalid?(email, strict_mode: true)).to be false
        end

        it "#{email} should match the regexp" do
          expect( !!(email.strip =~ EmailValidator.regexp) ).to be true
        end

        it "#{email} should match the strict regexp" do
          expect( !!(email.strip =~ EmailValidator.regexp(strict_mode: true)) ).to be true
        end
      end
    end

    context "given the invalid email" do
      invalid_includable.map { |k,v| [
        "include-#{v}-#{k.to_s}@invalid-characters-in-local.dev",
      ]}.concat(domain_invalid_beginable.map { |k,v| [
        "start-with-#{k.to_s}@#{v}invalid-characters-in-domain.dev",
      ]}).concat(domain_invalid_endable.map { |k,v| [
        "end-with-#{k.to_s}@invalid-characters-in-domain#{v}.dev",
      ]}).concat(domain_invalid_includable.map { |k,v| [
        "include-#{k.to_s}@invalid-characters-#{v}-in-domain.dev",
      ]}).concat([
        "",
        "@bar.com",
        "test@example.com@example.com",
        "test@",
        "@missing-local.dev",
        "missing-sld@.com",
        "missing-tld@sld.",
        " ",
        "missing-at-sign.dev",
        "only-numbers-in-domain-label@sub.123.com",
        "only-numbers-in-domain-label@123.example.com",
        "unbracketed-IP@127.0.0.1",
        "invalid-ip@127.0.0.1.26",
        "another-invalid-ip@127.0.0.256",
        "IP-and-port@127.0.0.1:25",
        "host-beginning-with-dot@.example.com",
        "domain-beginning-with-dash@-example.com",
        "domain-ending-with-dash@example-.com",
        "the-local-part-is-invalid-if-it-is-longer-than-sixty-four-characters@sld.dev",
        "user@example.com\n<script>alert('hello')</script>",
      ]).flatten.each do |email|
        it "#{email} should not be valid" do
          expect(TestUser.new(:email => email)).not_to be_valid
        end

        it "#{email} should not be valid in strict_mode" do
          expect(StrictUser.new(:email => email)).not_to be_valid
        end

        it "#{email} should not be valid using EmailValidator.valid?" do
          expect(EmailValidator.valid?(email)).to be false
        end

        it "#{email} should not be valid using EmailValidator.valid? in strict_mode" do
          expect(EmailValidator.valid?(email, strict_mode: true)).to be false
        end

        it "#{email} should be invalid using EmailValidator.invalid?" do
          expect(EmailValidator.invalid?(email)).to be true
        end

        it "#{email} should be invalid using EmailValidator.invalid? in strict_mode" do
          expect(EmailValidator.invalid?(email, strict_mode: true)).to be true
        end

        it "#{email} should not match the regexp" do
          expect( !!(email.strip =~ EmailValidator.regexp) ).to be false
        end

        it "#{email} should not match the strict regexp" do
          expect( !!(email.strip =~ EmailValidator.regexp(strict_mode: true)) ).to be false
        end
      end
    end

    context "given the strictly invalid email" do
      strictly_invalid_includable.map { |k,v| [
        "include-#{v}-#{k.to_s}@invalid-characters-in-local.dev",
      ]}.concat(strictly_invalid_beginable.map { |k,v| [
        "#{v}start-with-#{k.to_s}@invalid-characters-in-local.dev",
      ]}).concat(strictly_invalid_endable.map { |k,v| [
        "end-with-#{k.to_s}#{v}@invalid-characters-in-local.dev",
      ]}).concat([
        " leading-and-trailing-whitespace@example.com ",
        "user..-with-double-dots@example.com",
        ".user-beginning-with-dot@example.com",
        "user-ending-with-dot.@example.com",
        " user-with-leading-whitespace-space@example.com",
        "	user-with-leading-whitespace-tab@example.com",
        "
        user-with-leading-whitespace-newline@example.com",
        "domain-with-trailing-whitespace-space@example.com ",
        "domain-with-trailing-whitespace-tab@example.com	",
        "domain-with-trailing-whitespace-newline@example.com
        ",
      ]).flatten.each do |email|

        it "#{email.strip} a model should be valid" do
          expect(TestUser.new(:email => email)).to be_valid
        end

        it "#{email.strip} a model should not be valid in strict_mode" do
          expect(StrictUser.new(:email => email)).not_to be_valid
        end

        it "#{email.strip} should be valid using EmailValidator.valid?" do
          expect(EmailValidator.valid?(email)).to be true
        end

        it "#{email.strip} should not be valid using EmailValidator.valid? in strict_mode" do
          expect(EmailValidator.valid?(email, strict_mode: true)).to be false
        end

        it "#{email.strip} should not be invalid using EmailValidator.invalid?" do
          expect(EmailValidator.invalid?(email)).to be false
        end

        it "#{email.strip} should be invalid using EmailValidator.invalid? in strict_mode" do
          expect(EmailValidator.invalid?(email, strict_mode: true)).to be true
        end

        it "#{email.strip} should match the regexp" do
          expect( !!(email =~ EmailValidator.regexp) ).to be true
        end

        it "#{email.strip} should not match the strict regexp" do
          expect( !!(email =~ EmailValidator.regexp(strict_mode: true)) ).to be false
        end
      end
    end
  end

  describe "error messages" do
    context "when the message is not defined" do
      subject { TestUser.new :email => 'invalidemail@' }
      before { subject.valid? }

      it "should add the default message" do
        expect(subject.errors[:email]).to include "is invalid"
      end
    end

    context "when the message is defined" do
      subject { TestUserWithMessage.new :email_address => 'invalidemail@' }
      before { subject.valid? }

      it "should add the customized message" do
        expect(subject.errors[:email_address]).to include "is not looking very good!"
      end
    end
  end

  describe "nil email" do
    it "should not be valid when :allow_nil option is missing" do
      expect(TestUser.new(:email => nil)).not_to be_valid
    end

    it "should be valid when :allow_nil options is set to true" do
      expect(TestUserAllowsNil.new(:email => nil)).to be_valid
    end

    it "should not be valid when :allow_nil option is set to false" do
      expect(TestUserAllowsNilFalse.new(:email => nil)).not_to be_valid
    end
  end

  describe "limited to a domain" do
    it "should not be valid with mismatched domain" do
      expect(DomainUser.new(email: 'user@not-matching.io')).not_to be_valid
    end

    it "should be valid with matching domain" do
      expect(DomainUser.new(email: 'user@example.com')).to be_valid
    end

    it "should not interpret the dot as any character" do
      expect(DomainUser.new(email: 'user@example-com')).not_to be_valid
    end

    describe "in strict mode" do
      it "should not be valid with mismatched domain" do
        expect(StrictDomainUser.new(email: 'user@not-matching.io')).not_to be_valid
      end

      it "should be valid with matching domain" do
        expect(StrictDomainUser.new(email: 'user@example.com')).to be_valid
      end
    end
  end

  describe "default_options" do
    context "when 'email_validator/strict' has been required" do
      before { require 'email_validator/strict' }

      it "should not validate using strict mode" do
        expect(TestUser.new(:email => "()<>@,;:\".[]@other-invalid-characters-in-local.dev")).not_to be_valid
      end
    end
  end
end
