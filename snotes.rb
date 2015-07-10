require 'digest/sha1'
require 'io/console'

require 'colorize'
require 'gibberish'
require 'readline'
require 'sqlite3'

def initialize_db
  @db = SQLite3::Database.new 'main.sqlite'
  create_table if @db.execute("SELECT * FROM sqlite_master WHERE name='data' and type='table';").empty?
  stored_hashed_password = @db.execute('SELECT * FROM data WHERE key = \'hashed password\'').first[1] rescue set_password
  while hashed_password != stored_hashed_password do
    get_password
  end
  @cipher = Gibberish::AES.new(@password + ENV.fetch('SALT'))
end

def get_password
  print ("\n[#{"#{'Password'}".colorize(:yellow)}]>> ")
  @password = STDIN.noecho(&:gets).chomp
  puts "\n\n"
  hashed_password
end

def encrypt(data)
  @cipher.encrypt(data)
end

def decrypt(encrypted_data)
  @cipher.decrypt(encrypted_data)
end

def make_a_selection(question, selections, prompt)
  puts "\n#{question}\n".colorize(:green)
  selections.each_with_index { |s,i| puts "#{i + 1}: #{s.to_s.split('_').map(&:capitalize).join(' ').colorize(:light_blue)}" }
  invalid_answer, index = true, nil
  while invalid_answer do
    index = prompt(prompt).to_i - 1
    invalid_answer = false if index != -1 && selections[index]
  end
  puts "\n"
  selections[index]
end

def prompt(value)
  Readline.readline("\n[#{"#{value}".colorize(:yellow)}]>> ")
end

def create_table
  @db.execute <<-SQL
    CREATE TABLE data (
      key TEXT,
      val TEXT
    );
  SQL
end


def set_password
  puts 'Insert your new password'
  new_password = get_password
  if new_password == get_password
    @db.execute("insert into data values ( ?, ? )", ['hashed password', hashed_password])
  else
    puts 'Passwords did not match. Try Again.'
    set_password
  end
  @db.execute('SELECT * FROM data WHERE key = \'hashed password\'').first[1]
end

def hashed_password
  @password ||= ''
  Digest::SHA1.hexdigest(@password + ENV.fetch('SALT'))
end

def add_entry(key,value)
  encrypted_value = encrypt(value)
  @db.execute 'insert into data values (?, ?)', [key, encrypted_value]
end

def retrieve_entry
  # Find some records
  @db.execute 'SELECT * FROM data' do |row|
    key = row[0]
    next if row[0] == 'hashed password'
    value = decrypt(row[1])
    puts "#{key}: #{value}"
  end
end

def remove_entry
end

def change_password
end

def make_selection
  selection = make_a_selection(
    'What would you like to do?',
    [
      :add_entry,
      :retrieve_entry,
      :remove_entry,
      :change_password
    ],
  'input'
  )
  case selection
  when :add_entry
    key = prompt(:key)
    value = prompt(:value)
    add_entry(key,value)
  when :retrieve_entry
    retrieve_entry
  when :remove_entry
    retrieve_entry
  when :change_password
    change_password
  end
end



initialize_db
make_selection
