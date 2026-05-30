# frozen_string_literal: true

require "rails_helper"

RSpec.describe SentimentAnalyzer do
  describe ".call" do
    it "returns a positive score for positive content" do
      expect(described_class.call("ótimo trabalho, incrível resultado")).to be > 0
    end

    it "returns a negative score for negative content" do
      expect(described_class.call("ruim e péssimo serviço")).to be < 0
    end

    it "returns 0.0 for neutral content" do
      expect(described_class.call("hello world, just a message")).to eq(0.0)
    end

    it "returns a positive score for English positive content" do
      expect(described_class.call("I love this community, it is amazing")).to be > 0
    end

    it "returns a negative score for English negative content" do
      expect(described_class.call("This is terrible and awful")).to be < 0
    end

    it "returns 0.0 for blank text" do
      expect(described_class.call("")).to eq(0.0)
    end

    it "returns a value between -1.0 and 1.0" do
      score = described_class.call("ótimo ótimo ruim")
      expect(score).to be_between(-1.0, 1.0)
    end

    it "is case-insensitive" do
      expect(described_class.call("ÓTIMO")).to eq(described_class.call("ótimo"))
    end
  end
end
