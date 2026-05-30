# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "socket"
require "timeout"
require "fileutils"

puts "Seeding database via HTTP API..."

module Seeds
  API_HOST = ENV.fetch("SEED_API_HOST", "127.0.0.1")
  API_PORT = ENV.fetch("SEED_API_PORT", "3099").to_i
  TIMEOUT_SECONDS = 20
  SEED_IPS = Array.new(20) { |i| "10.0.#{i / 10}.#{i % 10 + 1}" }.freeze
  COMMUNITY_DEFINITIONS = [
    { name: "ruby-developers",   description: "A community for Ruby and Rails enthusiasts." },
    { name: "devops-hub",        description: "Infrastructure, CI/CD, containers and automation." },
    { name: "open-source-talks", description: "Discuss open source projects and contributions." },
    { name: "frontend-crafters", description: "HTML, CSS, JavaScript and beyond." },
    { name: "data-engineering",  description: "Pipelines, warehouses and data at scale." }
  ].freeze

  class HttpClient
    def initialize(host: API_HOST, port: API_PORT)
      @host = host
      @port = port
    end

    def post(path, payload)
      uri = URI::HTTP.build(host: @host, port: @port, path: path)
      request = Net::HTTP::Post.new(uri, {
        "Content-Type" => "application/json",
        "User-Agent" => "Mozilla/5.0 AppleWebKit/537.36 Chrome/120 Safari/537.36"
      })
      request.body = JSON.generate(payload)

      Response.new(Net::HTTP.start(@host, @port, open_timeout: 5, read_timeout: 10) do |http|
        http.request(request)
      end, path)
    end

    class Response
      def initialize(http_response, path)
        @http_response = http_response
        @path = path
      end

      def body
        @http_response.body.to_s
      end

      def parse
        JSON.parse(body)
      rescue JSON::ParserError
        {}
      end

      def status
        @http_response.code.to_i
      end

      def conflict?
        status == 409
      end

      def ensure_success!
        return if status.between?(200, 299)

        error_payload = parse
        message = error_payload["error"] || error_payload["errors"] || body.presence || @http_response.message
        raise StandardError, "Seed API request failed #{@path} (#{status}): #{message}"
      end
    end
  end

  class LocalServer
    PID_FILE = Rails.root.join("tmp/pids/seed_server.pid").freeze
    LOG_DIR = Rails.root.join("tmp/log").freeze
    OUT_LOG = LOG_DIR.join("seed_server.stdout.log").freeze
    ERR_LOG = LOG_DIR.join("seed_server.stderr.log").freeze

    def initialize(host: API_HOST, port: API_PORT)
      @host = host
      @port = port
      @pid = nil
    end

    def start
      cleanup_stale_pid!
      return if running?

      FileUtils.mkdir_p(PID_FILE.dirname)
      FileUtils.mkdir_p(LOG_DIR)
      @pid = Process.spawn(*server_command, chdir: Rails.root.to_s, out: OUT_LOG.to_s, err: ERR_LOG.to_s)
      wait_until_ready!
    end

    def stop
      return unless @pid

      Process.kill("TERM", @pid)
      Process.wait(@pid)
    rescue Errno::ESRCH, Interrupt
      nil
    ensure
      @pid = nil
      PID_FILE.delete if PID_FILE.exist?
    end

    def running?
      pid = read_pid
      return false unless pid

      server_pid_match?(pid)
    end

    private

    def cleanup_stale_pid!
      pid = read_pid
      return unless pid
      PID_FILE.delete unless server_pid_match?(pid)
    rescue StandardError
      nil
    end

    def read_pid
      PID_FILE.exist? ? Integer(PID_FILE.read) : nil
    rescue ArgumentError, Errno::ENOENT
      nil
    end

    def process_alive?(pid)
      Process.kill(0, pid)
      true
    rescue Errno::ESRCH
      false
    rescue Errno::EPERM
      true
    end

    def server_pid_match?(pid)
      return false unless process_alive?(pid)

      cmdline = File.read("/proc/#{pid}/cmdline").tr("\0", " ")
      return false if cmdline.include?("db:seed")

      cmdline.include?("rails server") || cmdline.include?("bin/rails server") || cmdline.include?("puma")
    rescue Errno::ENOENT, Errno::EACCES
      false
    end

    def server_command
      [
        "bundle",
        "exec",
        "bin/rails",
        "server",
        "-b",
        @host,
        "-p",
        @port.to_s,
        "-e",
        ENV.fetch("RAILS_ENV", "development"),
        "--pid",
        PID_FILE.to_s
      ]
    end

    def wait_until_ready!
      Timeout.timeout(TIMEOUT_SECONDS) do
        loop do
          raise "Seed server process exited unexpectedly\n#{diagnostic_log_excerpt}" unless process_alive?
          break if server_available?

          sleep 0.2
        end
      end
    end

    def diagnostic_log_excerpt
      output = []
      output << "--- seed_server.stderr.log ---"
      output.concat(read_tail(ERR_LOG, 20)) if ERR_LOG.exist?
      output << "--- seed_server.stdout.log ---"
      output.concat(read_tail(OUT_LOG, 20)) if OUT_LOG.exist?
      output.join("\n")
    rescue StandardError => e
      "failed to read diagnostics: #{e.class}: #{e.message}"
    end

    def read_tail(path, lines)
      path.read.lines.last(lines).map(&:chomp)
    rescue Errno::ENOENT
      []
    end

    def process_alive?
      Process.wait(@pid, Process::WNOHANG).nil?
    rescue Errno::ECHILD
      false
    end

    def server_available?
      socket = TCPSocket.new(@host, @port)
      socket.close
      true
    rescue StandardError
      false
    end
  end

  class Runner
    def initialize
      @client = HttpClient.new
      @server = LocalServer.new
      @community_ids = []
      @user_ids = []
      @message_ids = []
    end

    def run
      @server.start
      create_communities
      create_users
      create_messages
      create_reactions
      puts "Done! Database seeded successfully."
    ensure
      @server.stop
    end

    private

    def create_communities
      return puts "  Communities already seeded; skipping." if Community.exists?

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
      return puts "  Users already seeded; skipping." if User.count >= 50

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
      return puts "  Messages already seeded; skipping." if Message.exists?

      puts "  Creating 700 top-level messages via API..."
      700.times do |index|
        payload = {
          content: Faker::Lorem.paragraph(sentence_count: rand(1..4)),
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
          content: Faker::Lorem.sentence(word_count: rand(5..15)),
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
  end
end

Seeds::Runner.new.run
