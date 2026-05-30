# frozen_string_literal: true

require "json"

puts "Seeding database via HTTP API..."

module Seeds
  SEED_IPS = Array.new(20) { |i| "10.0.#{i / 10}.#{i % 10 + 1}" }.freeze
  MESSAGE_TOPICS = [
    "Ruby on Rails",
    "deploy automation",
    "community moderation",
    "frontend polish",
    "data pipelines",
    "open source",
    "product feedback",
    "testing strategy"
  ].freeze
  SENTIMENT_PHRASES = [
    "This is an awesome idea and I love the direction.",
    "Great work from the community so far.",
    "I have a neutral observation about the current discussion.",
    "This part feels bad and needs more attention.",
    "The proposal is good, practical, and easy to follow."
  ].freeze
  COMMUNITY_DEFINITIONS = [
    { name: "ruby-developers",   description: "A community for Ruby and Rails enthusiasts." },
    { name: "devops-hub",        description: "Infrastructure, CI/CD, containers and automation." },
    { name: "open-source-talks", description: "Discuss open source projects and contributions." },
    { name: "frontend-crafters", description: "HTML, CSS, JavaScript and beyond." },
    { name: "data-engineering",  description: "Pipelines, warehouses and data at scale." }
  ].freeze

  class HttpClient
    def initialize(app: Rails.application)
      @request = Rack::MockRequest.new(app)
    end

    def post(path, payload)
      Response.new(
        @request.post(
          path,
          "CONTENT_TYPE" => "application/json",
          "HTTP_ACCEPT" => "application/json",
          "HTTP_HOST" => "localhost",
          "HTTP_USER_AGENT" => "Mozilla/5.0 AppleWebKit/537.36 Chrome/120 Safari/537.36",
          input: JSON.generate(payload)
        ),
        path
      )
    end

    class Response
      def initialize(response, path)
        @response = response
        @path = path
      end

      def body
        @response.body.to_s
      end

      def parse
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      def status
        @response.status.to_i
      end

      def conflict?
        status == 409
      end

      def ensure_success!
        return if status.between?(200, 299)

        error_payload = parse
        message = error_payload["error"] || error_payload["errors"] || body.presence || "HTTP #{status}"
        raise StandardError, "Seed API request failed #{@path} (#{status}): #{message}"
      end
    end
  end

  class Runner
    def initialize
      @client = HttpClient.new
      @community_ids = []
      @user_ids = []
      @message_ids = []
    end

    def run
      create_communities
      create_users
      create_messages
      create_reactions
      puts "Done! Database seeded successfully."
    end

    private

    def create_communities
      if Community.exists?
        @community_ids = Community.pluck(:id)
        return puts "  Communities already seeded; loaded #{@community_ids.size} existing communities."
      end

      puts "  Creating #{COMMUNITY_DEFINITIONS.size} communities via API..."
      COMMUNITY_DEFINITIONS.each do |attrs|
        response = @client.post("/api/v1/communities", attrs)
        response.ensure_success!
        community_data = response.parse
        @community_ids << community_data["id"]
        puts "    ✓ Created community: #{attrs[:name]}"
      end
      puts "  Total communities created: #{@community_ids.size}"
    end

    def create_users
      if User.count >= 50
        @user_ids = User.pluck(:id)
        return puts "  Users already seeded; loaded #{@user_ids.size} existing users."
      end

      puts "  Creating 50 unique users via API..."
      usernames = Array.new(50) { |i| "user_#{format('%02d', i + 1)}" }
      usernames.each do |username|
        response = @client.post("/api/v1/users", { username: username })
        response.ensure_success!
        user_data = response.parse
        @user_ids << user_data["id"]
      end
      puts "  Total users created: #{@user_ids.size}"
    end

    def create_messages
      if Message.exists?
        @message_ids = Message.pluck(:id)
        return puts "  Messages already seeded; loaded #{@message_ids.size} existing messages."
      end

      puts "  Creating 700 top-level messages via API..."
      700.times do |index|
        payload = {
          content: message_content(index),
          community_id: @community_ids.sample,
          user_id: @user_ids.sample,
          user_ip: SEED_IPS.sample
        }

        response = @client.post("/api/v1/messages", payload)
        response.ensure_success!
        message_data = response.parse
        @message_ids << message_data["id"]

        puts "    ✓ Created message #{index + 1}/700" if (index + 1) % 100 == 0
      end

      puts "  Creating 300 reply messages via API..."
      300.times do |index|
        # Pick a random parent message ID from already created messages
        parent_id = @message_ids.sample
        # Query parent to get its community_id (only for routing, not for HTTP-first ethos)
        parent = Message.find(parent_id)

        payload = {
          content: reply_content(index),
          community_id: parent.community_id,
          user_id: @user_ids.sample,
          parent_message_id: parent_id,
          user_ip: SEED_IPS.sample
        }

        response = @client.post("/api/v1/messages", payload)
        response.ensure_success!
        message_data = response.parse
        @message_ids << message_data["id"]

        puts "    ✓ Created reply #{index + 1}/300" if (index + 1) % 100 == 0
      end

      puts "  Total messages created: #{@message_ids.size}"
    end

    def create_reactions
      return puts "  Reactions already seeded; skipping." if Reaction.exists?

      @message_ids = Message.pluck(:id) if @message_ids.empty?

      puts "  Adding reactions to ~80% of messages via API..."
      target_count = (@message_ids.size * 0.8).ceil
      sampled_message_ids = @message_ids.sample(target_count)

      sampled_message_ids.each_with_index do |message_id, index|
        payload = {
          message_id: message_id,
          user_id: @user_ids.sample,
          reaction_type: Reaction::TYPES.sample
        }

        response = @client.post("/api/v1/reactions", payload)
        if response.conflict?
          puts "    ⊘ Reaction already exists for message #{message_id}" if index % 200 == 0
          next
        end

        response.ensure_success!
        puts "    ✓ Created reaction #{index + 1}/#{target_count}" if (index + 1) % 200 == 0
      end

      puts "  Total reactions processed: #{target_count}"
    end

    def message_content(index)
      topic = MESSAGE_TOPICS[index % MESSAGE_TOPICS.size]
      phrase = SENTIMENT_PHRASES[index % SENTIMENT_PHRASES.size]

      "#{phrase} Topic: #{topic}. Message ##{index + 1} adds context for people following this community."
    end

    def reply_content(index)
      topic = MESSAGE_TOPICS[(index + 3) % MESSAGE_TOPICS.size]

      "Reply ##{index + 1}: adding a follow-up thought about #{topic} and keeping the thread moving."
    end
  end
end

Seeds::Runner.new.run
