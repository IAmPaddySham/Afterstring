#!/usr/bin/env ruby
# frozen_string_literal: true
# Harness: verify ALLOWLIST.json hashes. Not an agent. Not 1/0.

require "json"
require "digest"
require "time"

root = File.expand_path("../../..", __dir__)
manifest_path = File.join(__dir__, "ALLOWLIST.json")
man = JSON.parse(File.read(manifest_path))

if ARGV.include?("--expiry")
  deadline = Time.parse("2026-08-19T20:03:00Z")
  now = Time.now.utc
  puts "propose_opened=2026-08-17T20:03Z deadline=#{deadline.iso8601} now=#{now.iso8601} paused=#{now > deadline}"
  exit 0
end

ok = true
man.fetch("items").each do |item|
  rel = item["path"]
  next if rel.nil? || item["sha256"].nil?
  path = File.join(File.dirname(root), rel.sub(%r{\Aafterstring/}, "afterstring/"))
  path = File.expand_path("~/#{rel}") if rel.start_with?("afterstring/")
  unless File.file?(path)
    warn "MISSING #{rel}"
    ok = false
    next
  end
  hex = Digest::SHA256.file(path).hexdigest
  if hex != item["sha256"]
    warn "HASH_MISMATCH #{rel}"
    ok = false
  else
    puts "OK #{rel}"
  end
end
exit(ok ? 0 : 1)
