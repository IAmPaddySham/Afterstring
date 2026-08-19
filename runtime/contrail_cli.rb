#!/usr/bin/env ruby
# frozen_string_literal: true
# Contrail chain check (public Merkle / A.L.T. integrity).
# Usage:
#   ruby runtime/contrail_cli.rb --verify
#   ruby runtime/contrail_cli.rb --verify --path ~/.afterstring/contrail.jsonl

require_relative "contrail"

path = File.expand_path("~/.afterstring/contrail.jsonl")
do_verify = false

ARGV.each_with_index do |arg, i|
  case arg
  when "--path" then path = File.expand_path(ARGV[i + 1])
  when "--verify" then do_verify = true
  when "--help", "-h"
    puts "Usage: contrail_cli.rb --verify [--path FILE]"
    exit 0
  end
end

unless do_verify
  puts "Usage: contrail_cli.rb --verify [--path FILE]"
  exit 1
end

ct = Afterstring::Contrail.new(path)
begin
  ct.verify_file!
  puts "CONTRAIL_OK"
  puts "entries=#{ct.entries.size} tip=#{ct.last_hash[0, 16]}… logical=#{ct.logical_head_hash[0, 16]}…"
  exit 0
rescue Afterstring::Contrail::TamperError => e
  puts "TRIGGER_REALITY_VETO"
  puts "A.L.T._VOID_IF_TAMPERED"
  warn e.message
  exit 2
end
