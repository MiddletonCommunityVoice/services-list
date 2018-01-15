#!/usr/local/bin/ruby

require 'csv'
require 'fileutils'
require 'pry'

# This is a quick and dirty import script that produces a structure
# matching the sections of the original tracking spreadsheet and
# creates a corresponding hierarchy of files with the correct
# data

class Hash
  def deep_reject(&blk)
    self.dup.deep_reject!(&blk)
  end

  def deep_reject!(&blk)
    self.each do |k, v|
      v.deep_reject!(&blk)  if v.is_a?(Hash)
      self.delete(k)  if blk.call(k, v)
    end
  end
end


TARGET_DIR = "../content"

TAG_MAPPING = {
  "IT" => ["Information Technology", "Training"],
  "Social" => ["Social"],
  "Supp" => ["Support Services"],
  "alc" => ["Alcohol", "Addiction"],
  "bow" => ["Bowel Cancer", "Cancer"],
  "bre" => ["Breast Cancer", "Cancer"],
  "child" => ["Children"],
  "dis" => ["Disability"],
  "drug" => ["Drugs", "Addiction"],
  "health" => ["Health"],
  "help" => ["Help at Home"],
  "lgbt" => ["LGBT"],
  "mental" => ["Mental Health"],
  "money" => ["Money"],
  "ova" => ["Ovarian Cancer", "Cancer"],
  "pro" => ["Prostate Cancer", "Cancer"],
  "sex" => ["Sexual Health", "Health"],
  "sign" => ["Signposting"],
  "smo" => ["Smoking", "Addiction"],
  "sport" => ["Sport"],
  "supp" => ["Support"],
}

SECTION_MAPPING = {
  "50+"   => "Fifty Plus",
  "Adult" => "Adult",
  "Eye" => "Eye",
  "Sign" => "Sign",
  "supp" => "Support Services",
  "T" => "Transport",
  "add" => "Addiction",
  "adult" => "Adult Services",
  "advice" => "Advice Services",
  "aut" => "Autism",
  "café" => "Café",
  "can" => "Cancer",
  "child" => "Children’s Services",
  "com" => "Community Centres",
  "dem" => "Dementure",
  "Derma" => "Dermatology",
  "dent" => "Dentistry",
  "dia" => "Diabetes",
  "dis" => "Disabilities",
  "ed" => "Education",
  "em" => "Emergency Services",
  "eye" => "Eyes",
  "feet" => "Feet",
  "gp" => "GP Surgeries",
  "health" => "Health",
  "hosp" => "Hospitals",
  "it" => "IT",
  "job" => "Jobs",
  "life" => "Life",
  "mental" => "Mental Health",
  "money" => "Money Advice",
  "serices" => "Services",
  "services" => "Services",
  "sign" => "Signposting",
  "sport" => "Sports",
  "Supp" => "Support",
  "vol" => "Volunteering"
}


# some helper methods
#
def slug(value)
  value
    .gsub(/[']+/, '')
    .gsub(/\W+/, ' ')
    .strip
    .downcase
    .gsub(' ', '-')
end


# before we start, remove and create a fresh output dir
FileUtils.rm_rf(TARGET_DIR)
FileUtils.mkdir(TARGET_DIR)

rows = CSV.read("data.csv", col_sep: ",", row_sep: "\r\n", headers: true)

sections = rows.map{|r| r["index"]}.compact.sort.uniq

sections.each do |section|
  File.join(TARGET_DIR, slug(SECTION_MAPPING[section])).tap do |dir_path|
    FileUtils.mkdir(dir_path) unless Dir.exist?(dir_path)
  end
end

sections.each do |section|

  File.open(File.join(TARGET_DIR, slug(SECTION_MAPPING[section]), "_index.md"), 'w') do |index_file|

    index_fm = {
      "title" => SECTION_MAPPING[section],
    }

    index_file.puts index_fm.to_yaml
    index_file.puts "---"

    index_file.puts "# #{SECTION_MAPPING[section]}"
  end

  rows
    .select{|r| r["index"] == section }
    .reject {|r| !r['Operator']}
    .group_by {|r| r['Operator']}
    .each do |op, recs|

      if !op
        puts "WARNING UNPARSEABLE LINE:", recs
        next
      end
      File.open(File.join(TARGET_DIR, slug(SECTION_MAPPING[section]), "#{slug(op)}.md"), 'w') do |entry_file|

        entry_file.puts(
          {
            "title" => op,
            "draft" => true,
            "tags" => recs
              .map{|r| TAG_MAPPING[r['tag']]}
              .flatten
              .compact
              .reject(&:empty?)
              .sort
              .uniq,
            "areas" => recs
              .map{|r| r['Area Covered']}
              .join(", ")
              .split(/[\&\,]/)
              .map(&:strip)
              .compact
              .reject(&:empty?)
              .sort
              .uniq,
            "contact" => {

              "addresses" => recs
                .map{|r| r['Address']}
                .compact
                .reject(&:empty?)
                .sort
                .uniq,

              "phone" => recs
                .map{|r| r['Phone #']}
                .compact
                .reject(&:empty?)
                .sort
                .uniq,

              "web_addresses" => [
                recs.map{|r| r['Main Web address']},
                recs.map{|r| r['2nd web address']}
              ]
                .flatten
                .compact
                .reject(&:empty?)
                .map(&:strip)
                .sort
                .uniq
            }
          }
            .deep_reject { |k, v| !(v == true || v == false) && (v.nil? || v.empty?) }
            .to_yaml
        )

        entry_file.puts "---"
        entry_file.puts "\n"

        # Info
        info = recs.map{|r| r['Information']}.compact.reject(&:empty?)

        if info.any?
          entry_file.puts("### Information")

          info.uniq.each do |inf|
          next if !inf
          entry_file.puts(inf)
          end

          entry_file.puts "\n"
        end

        # Opening Hours
        opening_hours = recs.map{|r| r['Opening times']}.compact.reject(&:empty?)

        if opening_hours.any?
          entry_file.puts("### Opening Times")

          opening_hours.uniq.each do |ot|
          next if !ot
          entry_file.puts("* #{ot}")
          end
          entry_file.puts "\n"
        end

      end

	  print "."

  end

end

puts "\nDone"
