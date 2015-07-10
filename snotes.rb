require 'bcrypt'
require 'colorize'
require 'digest/sha1'
require 'io/console'
require 'readline'
require 'sqlite3'

# Open a SQLite 3 database file
@db = SQLite3::Database.new 'main.sqlite'
@stored_hashed_password = @db.execute('SELECT * FROM data WHERE key = \'hashed password\'').flatten[1]

def get_password
  print ("\n[#{"#{'Password'}".colorize(:yellow)}]>> ")
  @password = STDIN.noecho(&:gets).chomp
  @hashed_password = Digest::SHA1.hexdigest(@password + ENV.fetch('SALT'))
  puts "\n\n"
end


while @hashed_password != @stored_hashed_password do
  get_password
end


def make_a_selection(question, selections, prompt)
  puts "\n#{question}\n".colorize(:green)
  selections.each_with_index { |s,i| puts "#{i + 1}: #{s.to_s.split('_').map(&:capitalize).join(' ').colorize(:light_blue)}" }
  invalid_answer, index = true, nil
  while invalid_answer do
    index = prompt(prompt, :yellow).to_i - 1
    invalid_answer = false if index != -1 && selections[index]
  end
  puts "\n"
  selections[index]
end

def prompt(value)
  Readline.readline("\n[#{"#{value}".colorize(:yellow)}]>> ")
end

def create_table
  result = @db.execute <<-SQL
    CREATE TABLE data (
      key VARCHAR(255),
      val BLOB
    );
  SQL
end



def add_entry(key,value)
  # Insert some data into it
  { 'one' => 1, 'two' => 2 }.each do |pair|
    db.execute 'insert into data values (?, ?)', pair
  end
end

def retrieve_entry
  # Find some records
  db.execute 'SELECT * FROM data' do |row|
    p row
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
  end
end
