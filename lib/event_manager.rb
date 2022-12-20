require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def display_legislators(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    legislators = civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting: www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('form_output') unless Dir.exists?('form_output')
  filename = "form_output/thanks_#{id}.html"
  File.open(filename, 'w') do |file|
    file.puts(form_letter)
    file.close()
  end
  puts "#{filename} created"
end

def check_phone(phone_number)
  puts phone_number.length
  if phone_number.length == 10
    phone_number
  elsif phone_number.length == 11 && phone_number[0] == '1'
    phone_number[1..11]
  else
    'Phone number is formatted incorrectly!'
  end
end

def get_hours(date)
  puts date
  date_time = DateTime.strptime(date, "%m/%d/%y %H:%M")
  date_time.hour
end

def get_average(average_array)
  sum = average_array.sum { |num| num.to_i }
  average = sum / average_array.length
  average
end

puts 'EventManager initialized.'
contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

average_array = []
contents.each do |row|
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = display_legislators(zipcode)
  phone_num = check_phone(row[:homephone])
  person_id = row[0]
  reg_date = row[:regdate]
  average_array << get_hours(reg_date)

  #puts "#{name} #{zipcode}: #{legislators}"

  form_letter = erb_template.result(binding)
  #puts form_letter
  save_thank_you_letter(person_id, form_letter)
end

average = get_average(average_array)
p average_array
puts "average: #{average}"
