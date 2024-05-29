# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  # easier way of making this short is by converting nil to string and then perform the other steps
  zipcode.to_s.rjust(5, '0').slice(0, 5)

=begin
# if zipcode is nil then replace it with '00000'
  if zipcode.nil?
    zipcode = '00000'
    # if zip code is more than five digits, truncate it to the first five digits
  elsif zipcode.length > 5
    zipcode = zipcode.slice(0, 4) # or zipcode[0..4]
  elsif zipcode.length < 5
    # if zip code is less than five digits, add zeroes to front until it becomes five digits
    zipcode = zipcode.rjust(5, '0')
  end
=end
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  # w stands for opening the file for writing
  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_number(phone_number)
  phone_regex = /[\[\]]|\(\)|-/ # / [\[\]] | \(\) | - / aka look for brackets or parenthesis or -

  phone_number = phone_number.to_s.gsub(phone_regex, '')
  result = nil

  if phone_number.length < 10 || phone_number.length > 12 || phone_number.length == 11 && phone_number[0] != '1'
    result = 'bad number'
  elsif phone_number.length == 11 && phone_number[0] == '1'
    result = phone_number.slice(0, 9)
  end
  result
end

def time_targeting(regdate)
  strip_time = DateTime.strptime(regdate, '%m/%d/%y %H:%M')
  formatted_time = strip_time.strftime('%H')
  formatted_wday = strip_time.wday
  [formatted_time, formatted_wday]
end

puts 'Event Manager Initialized!'

whole_contents = nil

event_attendees_small_path = 'event_attendees_small.csv'
event_attendees_large_path = 'event_attendees_large.csv'

# whole_contents = File.read('event_attendees_small.csv')
# puts whole_contents

=begin 
if File.exist?(event_attendees_small_path)
  File.readlines(event_attendees_small_path).each_with_index do |line, index|
    # next if line == " ,RegDate,first_Name,last_Name,Email_Address,HomePhone,Street,City,State,Zipcode\n"
    next if index.zero?

    columns = line.split(',')
    name = columns[2]
    puts name
  end
end
=end

template_letter = File.read('form_letter.erb')
erb_template = ERB.new(template_letter)

contents = CSV.open(
  event_attendees_small_path,
  headers: true,
  header_converters: :symbol
)

peak_registration_hours = Hash.new(0)
peak_registration_days = Hash.new(0)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phonenumber = clean_phone_number(row[:phonenumber])
  time = time_targeting(row[:regdate])[0]
  day = time_targeting(row[:regdate])[1]

  peak_registration_hours[time] += 1
  peak_registration_days[day] += 1

  puts "#{id}, #{name}, #{zipcode}, #{phonenumber} #{time}"

=begin   
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter) 
=end
end

puts "Peak hours is: #{peak_registration_hours.max[0]}"
puts "Peak day is: #{peak_registration_days.max[0]}"
