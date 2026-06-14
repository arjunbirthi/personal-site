#!/usr/bin/env ruby
# frozen_string_literal: true
#
# Logs reading / listening into _data/*.yml — the site's "database".
#
# Interactive (just run it and answer the prompts):
#     ruby scripts/log.rb
#
# Or drive it directly (handy for scripting):
#     ruby scripts/log.rb book reading "Title" --author "Name" --tags fiction
#     ruby scripts/log.rb book finish  "Title" --rating 5 --review /reviews/slug/
#     ruby scripts/log.rb book read    "Title" --author "Name" --year 2024
#     ruby scripts/log.rb music listening "Album" --artist "Artist"
#     ruby scripts/log.rb music finish    "Album"
#     ruby scripts/log.rb now status "What I'm up to."
#     ruby scripts/log.rb now quote  "Quote text" --source "Author"
#     ruby scripts/log.rb list books        # or: list music
#
# Every entry stores a hidden `logged` date (the day you recorded it); no
# date is ever shown on the site. Commit _data afterward to publish.

require "yaml"
require "date"
require "optparse"

# Terminals can hand us args tagged ASCII-8BIT; reinterpret as UTF-8 so accented
# names (e.g. "le Carré") round-trip as text instead of base64 (!binary) in YAML.
ARGV.map! { |a| a.dup.force_encoding("UTF-8") }

DATA_DIR = File.expand_path("../_data", __dir__)

# Per-medium vocabulary: the byline key and the two status values.
MEDIA = {
  "books" => { who: "author", active: "reading",   done: "read" },
  "music" => { who: "artist", active: "listening", done: "listened" },
}.freeze

def path_for(name) = File.join(DATA_DIR, "#{name}.yml")

# Ruby 3.x safe-loads YAML; Date must be permitted since we store dates.
def read_yaml(path)
  return nil unless File.exist?(path)
  YAML.load_file(path, permitted_classes: [Date])
end

def load_list(name) = read_yaml(path_for(name)) || []

def save(name, data)
  File.write(path_for(name), YAML.dump(data))
  puts "Wrote #{path_for(name)}"
end

# ---- core operations (shared by interactive + flag-driven modes) ----

def new_entry(media, status, title, who: nil, tags: nil, rating: nil, review: nil, year: nil)
  m = MEDIA.fetch(media)
  entry = { "title" => title, m[:who] => who, "status" => status, "logged" => Date.today }
  if status == m[:active]
    entry["started"] = Date.today
  else
    entry["finished"] = Date.today
    entry["year"] = (year || Date.today.year).to_i
  end
  entry["rating"] = rating.to_i if rating
  entry["review"] = review if review
  entry["tags"]   = tags if tags && !tags.empty?
  entry.compact!
  list = load_list(media)
  list << entry
  save(media, list)
  entry
end

def finish_entry(media, title, rating: nil, review: nil)
  m = MEDIA.fetch(media)
  list = load_list(media)
  entry = list.find { |e| e["title"].to_s.downcase == title.downcase && e["status"] == m[:active] }
  return nil unless entry
  entry["status"]   = m[:done]
  entry["finished"] = Date.today
  entry["logged"]   = Date.today
  entry["year"]   ||= Date.today.year
  entry["rating"]   = rating.to_i if rating
  entry["review"]   = review if review
  save(media, list)
  entry
end

def set_field(entry, field, value)
  case field
  when "tags"          then entry["tags"] = value.to_s.split(",").map(&:strip)
  when "rating", "year" then entry[field] = value.to_i
  else                       entry[field] = value
  end
  entry["logged"] = Date.today
end

# ---- interactive prompts ----

def ask(prompt, default: nil)
  print default ? "#{prompt} [#{default}]: " : "#{prompt}: "
  input = $stdin.gets&.strip
  input.nil? || input.empty? ? default : input
end

def choose(prompt, options)
  puts prompt
  options.each_with_index { |o, i| puts "  #{i + 1}) #{o}" }
  loop do
    print "> "
    line = $stdin.gets
    abort "\nNo input — aborting." if line.nil?
    n = line.strip.to_i
    return n - 1 if n.between?(1, options.size)
    puts "Please enter a number between 1 and #{options.size}."
  end
end

def interactive
  case choose("What do you want to do?",
              ["Log something new", "Edit an existing entry", "Update the Now page"])
  when 0 then interactive_new
  when 1 then interactive_edit
  when 2 then interactive_now
  end
end

def interactive_new
  media = choose("Log a…", ["Book", "Album / music"]).zero? ? "books" : "music"
  m = MEDIA.fetch(media)
  status = choose("Status?", ["Currently #{m[:active]}", "Already finished (#{m[:done]})"]).zero? ? m[:active] : m[:done]

  title = ask("Title")
  who   = ask(m[:who].capitalize)
  tags  = ask("Tags (comma-separated, optional)")
  tags  = tags&.split(",")&.map(&:strip)

  year = rating = review = nil
  if status == m[:done]
    year   = ask("Year", default: Date.today.year.to_s)
    rating = ask("Rating 1–5 (optional)")
    review = ask("Review URL (optional)")
  end

  entry = new_entry(media, status, title, who: who, tags: tags, rating: rating, review: review, year: year)
  puts "Saved: #{entry['title']} (#{entry['status']})"
end

def interactive_edit
  media = choose("Edit which list?", ["Books", "Music"]).zero? ? "books" : "music"
  m = MEDIA.fetch(media)
  list = load_list(media)
  return puts("No entries yet.") if list.empty?

  idx = choose("Pick an entry:",
               list.map { |e| "#{e['title']} — #{e[m[:who]]} (#{e['status']})" })
  entry = list[idx]

  fields = ["status", "title", m[:who], "rating", "review", "tags", "year"]
  field  = fields[choose("Change which field?", fields)]
  value  = field == "status" ? [m[:active], m[:done]][choose("New status?", [m[:active], m[:done]])]
                             : ask("New value for #{field}")
  set_field(entry, field, value)
  save(media, list)
  puts "Updated: #{entry['title']}"
end

def interactive_now
  now = read_yaml(path_for("now")) || {}
  if choose("Update what?", ["Status line", "Quote"]).zero?
    now["status"] = ask("Status line")
  else
    now["quote"] = { "text" => ask("Quote text"), "source" => ask("Source") }.compact
  end
  now["updated"] = Date.today
  save("now", now)
end

# ---- flag-driven mode ----

def parse_opts(args)
  opts = {}
  OptionParser.new do |o|
    o.on("--author AUTHOR")     { |v| opts["author"] = v }
    o.on("--artist ARTIST")     { |v| opts["artist"] = v }
    o.on("--tags TAGS")         { |v| opts["tags"]   = v.split(",").map(&:strip) }
    o.on("--rating N", Integer) { |v| opts["rating"] = v }
    o.on("--review URL")        { |v| opts["review"] = v }
    o.on("--source SOURCE")     { |v| opts["source"] = v }
    o.on("--year YYYY", Integer) { |v| opts["year"] = v }
  end.parse!(args)
  opts
end

def run_cli(command, sub, args)
  case command
  when "book", "music"
    media = command == "book" ? "books" : "music"
    m = MEDIA.fetch(media)
    opts = parse_opts(args)
    title = args.shift or abort "Need a title."
    who = opts["author"] || opts["artist"]
    case sub
    when m[:active]
      new_entry(media, m[:active], title, who: who, tags: opts["tags"])
    when m[:done]
      new_entry(media, m[:done], title, who: who, tags: opts["tags"],
                rating: opts["rating"], review: opts["review"], year: opts["year"])
    when "finish"
      finish_entry(media, title, rating: opts["rating"], review: opts["review"]) ||
        abort("No in-progress #{media} entry matches #{title.inspect}.")
    else
      abort "#{command}: #{m[:active]} | #{m[:done]} | finish"
    end
  when "now"
    opts = parse_opts(args)
    now = read_yaml(path_for("now")) || {}
    case sub
    when "status" then now["status"] = args.shift or abort "Need a status string."
    when "quote"  then now["quote"]  = { "text" => (args.shift or abort("Need quote text.")),
                                          "source" => opts["source"] }.compact
    else abort "now: status | quote"
    end
    now["updated"] = Date.today
    save("now", now)
  when "list"
    load_list(sub).each do |e|
      puts "#{e['status'].to_s.ljust(10)} #{e['title']} — #{e['author'] || e['artist']}"
    end
  else
    abort "Usage: ruby scripts/log.rb [no args for interactive | book|music|now|list ...]"
  end
end

# ---- entry point ----

if ARGV.empty?
  interactive
else
  run_cli(ARGV.shift, ARGV.shift, ARGV)
end
