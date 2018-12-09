# frozen_string_literal: true

require "mock_redis"

RSpec.describe Ayashige::Sources::DomainWatch, :vcr do
  subject { Ayashige::Sources::DomainWatch.new }

  let(:redis) { MockRedis.new }

  before do
    allow(Ayashige::Redis).to receive(:client).and_return(redis)
  end

  after do
    redis.flushdb
  end

  describe "#get_domains_from_doc" do
    it "should return domains in a page as an Array" do
      page = subject.get_page(1)
      domains = subject.get_domains_from_doc(page)

      expect(domains.length).to eq(100)
      domains.each do |domain|
        expect(domain.key?(:domain)).to eq(true)
        expect(domain.key?(:updated)).to eq(true)
      end
    end
  end

  describe "#store_newly_registered_domains" do
    let(:updated_on) { "2018-01-01" }

    before do
      stub_const("Ayashige::Sources::DomainWatch::LIMIT", 2)

      allow(subject).to receive(:get_page).and_return(nil)
      allow(subject).to receive(:get_domains_from_doc).and_return([
        { updated: updated_on, domain: "paypal.pay.pay.world" }
      ])
      allow(Parallel).to receive(:map).with(1..2).and_yield([1, 2])
    end

    it "should store parsed domains into Redis" do
      output = capture(:stdout) { subject.store_newly_registered_domains }
      expect(output.include?("paypal.pay.pay.world")).to eq(true)

      expect(redis.exists(updated_on)).to eq(true)
    end
  end
end
