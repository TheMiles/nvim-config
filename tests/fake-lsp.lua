-----------------------------------------------------------
--  Minimal language server for tests/run.sh
-----------------------------------------------------------
--
-- Run with nvim -l. Answers initialize, shutdown and any other
-- request with an empty result, ignores notifications.

local function read_message()
  local length
  while true do
    local line = io.stdin:read('l')
    if not line then
      os.exit(0)
    end
    line = line:gsub('\r$', '')
    if line == '' then
      break
    end
    length = tonumber(line:match('^Content%-Length: (%d+)')) or length
  end
  return vim.json.decode(io.stdin:read(length))
end

local function send(message)
  local body = vim.json.encode(message)
  io.stdout:write('Content-Length: ' .. #body .. '\r\n\r\n' .. body)
  io.stdout:flush()
end

while true do
  local message = read_message()
  if message.method == 'exit' then
    os.exit(0)
  elseif message.method == 'initialize' then
    send({ jsonrpc = '2.0', id = message.id, result = { capabilities = {} } })
  elseif message.id then
    send({ jsonrpc = '2.0', id = message.id, result = vim.NIL })
  end
end
