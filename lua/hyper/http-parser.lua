local M = {}

local function reset_request()
  return {
    method = "",
    url = "",
    query_params = {},
    headers = {},
    body = nil,
    variables = {},
    _end = nil,
  }
end

local function is_method(method)
  local methods = {
    GET = true,
    PUT = true,
    POST = true,
    PATCH = true,
    DELETE = true,
  }
  return methods[method] and true or false
end

local function replace_token(token, value, str)
  return str:gsub("{{" .. token .. "}}", value)
end

local function replace_variables(globals, request)
  local vars = {}
  local raw_vars = {}
  for _, v in ipairs(globals) do
    table.insert(raw_vars, v)
  end

  if request.variables ~= nil then
    for _, v in ipairs(request.variables) do
      table.insert(raw_vars, v)
    end
  end

  -- fill in variables from last to first to catch any dependencies
  for i = #raw_vars, 1, -1 do
    local var = raw_vars[i].value
    for j = #raw_vars - 1, 1, -1 do
      var = replace_token(raw_vars[j].token, raw_vars[j].value, var)
    end
    table.insert(vars, { token = raw_vars[i].token, value = var })
  end

  -- replace variables in url, params, headers, and body
  for _, v in ipairs(vars) do
    request.url = replace_token(v.token, v.value, request.url)

    if request.query_params ~= nil then
      for name, value in pairs(request.query_params) do
        request.query_params[name] = replace_token(v.token, v.value, value)
      end
    end

    if request.headers ~= nil then
      for header, value in pairs(request.headers) do
        request.headers[header] = replace_token(v.token, v.value, value)
      end
    end

    if request.body and #request.body > 0 then
      local new_body = {}
      for _, line in ipairs(request.body) do
        local new_line = replace_token(v.token, v.value, line)
        table.insert(new_body, new_line)
      end
      request.body = new_body
    end
  end

  request.variables = nil
  return request
end

function M.parse(file)
  local requests = {}
  local variables = {}
  local req = reset_request()

  local globalVars = true
  local gatheringRequest = false
  local gatheringHeaders = false
  local bodyStartPos = 0

  for i, line in ipairs(file) do
    local skip = bodyStartPos ~= 0

    -- check for blank line
    if line == "" then
      if gatheringHeaders then
        gatheringHeaders = false
      end
      skip = true
    end

    -- check for comments and request delimeter
    if not skip then
      local hash_comment = line:match("^(#+).*")
      local slash_comment = line:match("^//.*")
      if hash_comment ~= nil or slash_comment ~= nil then
        skip = true

        if hash_comment == "###" then
          if gatheringRequest then
            gatheringRequest = false
            req._end = i - 1
            table.insert(requests, req)
            req = reset_request()
          end

          if globalVars then
            globalVars = false
          end
        end
      end
    end

    -- check for variable
    if not skip then
      local var, val = line:match("^@([%w_%-]+)=(.+)")
      if var ~= nil and val ~= nil then
        local entry = { token = var, value = val }
        if globalVars then
          table.insert(variables, entry)
        else
          table.insert(req.variables, entry)
        end
        skip = true
      end
    end

    -- check for method and url
    if not skip then
      local method, whole_url = line:match("^(%a+) (.+)")
      if is_method(method) and whole_url ~= nil then
        req.method = method
        local url, params = whole_url:match("(.*)%?(.*)")
        req.url = url or whole_url
        if params ~= nil then
          for k, v in string.gmatch(params, "(.*)=(.*)&?") do
            req.query_params[k] = v
          end
        end
        gatheringRequest = true
        gatheringHeaders = true
        skip = true
      end
    end

    -- check for header
    if not skip and gatheringHeaders then
      local header, value = line:match("^([%a-_]+): (.+)")
      if header ~= nil and value ~= nil then
        req.headers[header] = value
        skip = true
      end
    end

    -- check for request body start
    if not skip then
      if line == "{" then
        bodyStartPos = i
        skip = true
      end
    end

    -- check for request body end
    if bodyStartPos > 0 then
      if line == "}" then
        req.body = { unpack(file, bodyStartPos, i) }
        bodyStartPos = 0
      end
    end

    -- check for end of file, add current request
    if i == #file then
      if gatheringRequest then
        req._end = i
        table.insert(requests, req)
      end
    end
  end

  local filled_requests = {}
  for _, request in ipairs(requests) do
    table.insert(filled_requests, replace_variables(variables, request))
  end

  return requests
end

return M
