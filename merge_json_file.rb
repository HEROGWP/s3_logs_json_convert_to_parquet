# pip install awscli --upgrade --user
# pip install json2parquet
require 'date'
require 'json'

first_layer = ARGV[0] || 'your_name'
time = ARGV[1] || (DateTime.now - (1/24.0)).strftime('%Y-%m-%d-%H')
year, month, day, hour = time.split('-')

log_folder = `aws s3 ls s3://log/#{first_layer}/`
servers = log_folder.split("\n").map(&:strip).map{|s| s[/PRE (.*)\//, 1] }
puts servers
servers.compact.each do |server|
  next if server.empty?
  path = "#{first_layer}/#{server}/year=#{year}/month=#{month}/day=#{day}/hour=#{hour}"
  # path = 'your_name/www.your_name.org/year=2018/month=06/day=13/hour=09'

  puts path
  `aws s3 cp --recursive s3://log/your_name/www.your_name.org/year=2018/month=06/day=13/hour=09 ./logs`

  Dir['./logs/*/*.gz'].each{|f| `gunzip #{f}` }

  `cat ./logs/*/*.log > logstasher.log`

  # check_each_line
  # MacOS
  `sed -i '' '/Encoding/d' ./logstasher.log`
  `sed -i '' '/^\s*$/d' ./logstasher.log`
  # Lunix
  # `sed -i '/Encoding/d' ./logstasher.log`
  # `sed -i '/^\s*$/d' ./logstasher.log`

  # write_file = File.new('logstasher_checked.log', "w")
  # File.open('./logstasher.log', 'r') do |f|
  #   f.each_line.with_index do |line, index|
  #     begin
  #       JSON.parse(line)
  #     rescue => e
  #       puts line
  #       puts index + 1
  #       break
  #     end
  #   end
  # end

  `python convert_json_to_parquet.py`

  `aws s3 cp ./logstasher_current.log s3://parquet_logs/#{path}/logstasher_current.log`
  `rm -rf logs`
  `rm logstasher.log`
  `rm logstasher_current.log`
end
