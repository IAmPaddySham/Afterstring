#!/usr/bin/env ruby
# frozen_string_literal: true
# Usage: ruby runtime/frme_eval_cli.rb
#        ./bin/afterstring-frme-eval

require_relative "frme_eval"
require "json"

report = Afterstring::FrmeEval.run_suite
puts Afterstring::FrmeEval.summary_line(report)
report["results"].each do |r|
  mark = r.ok ? "PASS" : "FAIL"
  puts "  [#{mark}] #{r.id} (#{r.risk}) gate=#{r.gate} — #{r.detail['note']}"
end
puts
if report["failed"].empty?
  puts "Presence scan: FRME-LITE refuse paths CLEAR (local LITE suite)."
  puts "Not a claim of industrial FRME Gold 100/100."
  puts "Let it stay → ∞ ❤️"
  exit 0
else
  puts "FRME-LITE failures — do not claim Type 4 T3 maturity."
  exit 1
end
