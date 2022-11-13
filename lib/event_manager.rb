require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone_number(phone_number)
  phone_number.gsub!(/[^\d]/,'')
  if phone_number.length==10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == "1"
    phone_number[1..10]
  else
    "Bad Number"
  end
end

def clean_hour(hour_hash, date)
  hour = date.split(' ')[1].split(':')[0]
  if hour_hash[hour]
    hour_hash[hour] += 1
  else
    hour_hash[hour] = 1
  end
  hour_hash
end

def get_frequent_wday(hash, date)
  weekday = Date.strptime(date.split(' ')[0], '%y/%d/%m').wday
  if hash[weekday]
    hash[weekday] += 1
  else
    hash[weekday] = 1
  end
  p hash
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

hour_hash = {}
wday_hash = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  homephone = clean_phone_number(row[:homephone])
  frequents_hours = clean_hour(hour_hash, row[:regdate])
  frequent_weekday = get_frequent_wday(wday_hash, row[:regdate])
  legislators = legislators_by_zipcode(zipcode)
  form_letter = erb_template.result(binding)
  # p frequents_hours
  save_thank_you_letter(id,form_letter)
end
