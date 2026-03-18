local CONFIGURATION = nil

-- Attempt to load the configuration module
success, result = pcall(function() return require("configuration") end)
if success then
  CONFIGURATION = result
else
  print("configuration.lua not found, skipping...")
end

-- Define your queryChatGPT function
local https = require("ssl.https")
local http = require("socket.http")
local ltn12 = require("ltn12")
local json = require("json")

local function queryChatGPT(message_history)
  -- Use api_key from CONFIGURATION
  local api_key_value = CONFIGURATION and CONFIGURATION.api_key
  local api_url = CONFIGURATION and CONFIGURATION.base_url or "https://api.openai.com/v1/chat/completions"
  local model = CONFIGURATION and CONFIGURATION.model

  -- Determine whether to use http or https
  local request_library = api_url:match("^https://") and https or http

  -- Start building the request body
  local requestBodyTable = {
    model = model,
    messages = message_history,
  }

  -- Add additional parameters if they exist
  if CONFIGURATION and CONFIGURATION.additional_parameters then
    for key, value in pairs(CONFIGURATION.additional_parameters) do
      requestBodyTable[key] = value
    end
  end

  -- Encode the request body as JSON
  local requestBody = json.encode(requestBodyTable)

  local headers = {
    ["Content-Type"] = "application/json",
    ["Authorization"] = "Bearer " .. api_key_value,
  }

  -- Add additional headers if they exist
  if CONFIGURATION and CONFIGURATION.additional_headers then
    for key, value in pairs(CONFIGURATION.additional_headers) do
      headers[key] = value
    end
  end

  local responseBody = {}

  -- Make the HTTP/HTTPS request
  local res, code, responseHeaders = request_library.request {
    url = api_url,
    method = "POST",
    headers = headers,
    source = ltn12.source.string(requestBody),
    sink = ltn12.sink.table(responseBody),
  }

  if code ~= 200 then
    error("Error querying ChatGPT API: " .. code)
  end

  local response = json.decode(table.concat(responseBody))
  return response.choices[1].message.content
end

return queryChatGPT
