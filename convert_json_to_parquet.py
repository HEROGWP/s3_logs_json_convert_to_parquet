from json2parquet import convert_json
columns = [
  "method", "path", "format", "controller", "action", "status", "duration",
  "view", "db", "ip", "route", "request_id", "req_params", "user_id", "realname",
  "nickname", "email", "source", "tags", "@timestamp", "@version"
]

convert_json('logstasher.log', 'logstasher_current.log', columns)
